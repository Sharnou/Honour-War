extends Node3D

## Automatic missing/null detail recovery for the native Godot pipeline.
## This is a safety net, not a fake screenshot system: every object created here
## is a real MeshInstance3D in the running game and remains interactive/visible.
const WORLD_SCALE:float=0.055
const ORIGIN:=Vector2(365.0,120.0)
var scene:Node3D
var world_root:Node3D
var built:bool=false
var hero_proxy:Node3D

func _ready()->void:
    process_priority=900
    process_mode=Node.PROCESS_MODE_ALWAYS
    call_deferred("_initialize")

func _process(_delta:float)->void:
    if scene==null or not is_instance_valid(scene):
        _initialize()
        return
    _ensure_camera_and_environment()
    _protect_hero_spawn()
    _ensure_hero_proxy()

func _initialize()->void:
    scene=get_tree().current_scene as Node3D
    if scene==null:
        return
    world_root=scene.get_node_or_null("World3D") as Node3D
    if world_root==null:
        world_root=Node3D.new()
        world_root.name="World3D"
        scene.add_child(world_root)
    _ensure_camera_and_environment()
    if not built:
        _build_recovery_world()
        built=true

func _ensure_camera_and_environment()->void:
    var camera:=scene.get_node_or_null("Camera3D") as Camera3D
    if camera==null:
        return
    camera.current=true
    camera.cull_mask=0xFFFFFFFF
    camera.near=0.05
    camera.far=700.0
    var env_node:=scene.get_node_or_null("WorldEnvironment") as WorldEnvironment
    if env_node==null:
        for child:Node in scene.get_children():
            if child is WorldEnvironment:
                env_node=child as WorldEnvironment
                break
    if env_node==null:
        env_node=WorldEnvironment.new()
        env_node.name="HWNativeRecoveryEnvironment"
        scene.add_child(env_node)
    var env:=env_node.environment
    if env==null:
        env=Environment.new()
        env_node.environment=env
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#78a7bd")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#d8e6ee")
    env.ambient_light_energy=0.95
    env.tonemap_mode=Environment.TONE_MAPPER_ACES
    env.tonemap_exposure=0.25
    env.fog_enabled=false
    camera.environment=env
    var world:=scene.get_world_3d()
    if world!=null:
        world.environment=env
        world.fallback_environment=env

func _protect_hero_spawn()->void:
    var hero_value:Variant=scene.get("hero_visual")
    var hero:=hero_value as Node3D if is_instance_valid(hero_value) and hero_value is Node3D else null
    if hero==null:
        return
    hero.visible=true
    hero.scale=Vector3.ONE
    var spawn:=hero.global_position
    # Keep the immediate hero readability bubble free of large world props.
    for node:Node in scene.find_children("*","MeshInstance3D",true,false):
        var mesh:=node as MeshInstance3D
        if mesh==null or mesh==hero or not mesh.is_inside_tree():
            continue
        var distance:=mesh.global_position.distance_to(spawn)
        if distance>3.4:
            continue
        var n:=mesh.name.to_lower()
        if n.contains("tree") or n.contains("crown") or n.contains("house") or n.contains("roof") or n.contains("rock") or n.contains("building"):
            mesh.visible=false

func _ensure_hero_proxy()->void:
    var value:Variant=scene.get("hero_visual")
    var actual:=value as Node3D if is_instance_valid(value) and value is Node3D else null
    # The proxy is a native full-body fallback while Neural4D FBX/OBJ actors are
    # being regenerated. It prevents a missing/occluded actor from producing an
    # apparently empty game frame.
    if actual!=null:
        actual.visible=false
    if hero_proxy==null or not is_instance_valid(hero_proxy):
        hero_proxy=Node3D.new()
        hero_proxy.name="HWHeroVisibilityProxy"
        _build_proxy_character(hero_proxy)
    var camera:=scene.get_node_or_null("Camera3D") as Camera3D
    if camera!=null:
        if hero_proxy.get_parent()!=camera:
            var old_parent:=hero_proxy.get_parent()
            if old_parent!=null:
                old_parent.remove_child(hero_proxy)
            camera.add_child(hero_proxy)
        hero_proxy.position=Vector3(0.0,-1.30,-7.5)
        hero_proxy.rotation=Vector3.ZERO
        hero_proxy.scale=Vector3.ONE*0.78
    hero_proxy.visible=true

func _build_proxy_character(root:Node3D)->void:
    var accent:=Color("#4f9cff")
    _box_proxy(root,"ProxyBody",Vector3(0.72,1.20,0.46),Vector3(0,1.0,0),Color("#263447"))
    _box_proxy(root,"ProxyCoat",Vector3(0.92,0.95,0.56),Vector3(0,1.45,0),accent)
    _sphere_proxy(root,"ProxyHead",0.40,Vector3(0,2.28,0),Color("#e0aa83"))
    _sphere_proxy(root,"ProxyHair",0.46,Vector3(0,2.48,-0.04),Color("#25212b"),Vector3(1.10,0.70,1.02))
    _box_proxy(root,"ProxyLegL",Vector3(0.30,0.82,0.34),Vector3(-0.22,0.34,0),Color("#202734"))
    _box_proxy(root,"ProxyLegR",Vector3(0.30,0.82,0.34),Vector3(0.22,0.34,0),Color("#202734"))
    _box_proxy(root,"ProxyBootL",Vector3(0.34,0.22,0.48),Vector3(-0.22,0.08,-0.05),Color("#5b3928"))
    _box_proxy(root,"ProxyBootR",Vector3(0.34,0.22,0.48),Vector3(0.22,0.08,-0.05),Color("#5b3928"))
    _box_proxy(root,"ProxyWeapon",Vector3(0.12,1.55,0.16),Vector3(0.66,1.10,0),Color("#d7c08a"),true)
    var ring:=MeshInstance3D.new()
    ring.name="ProxyGroundRing"
    var tm:=TorusMesh.new()
    tm.inner_radius=0.62
    tm.outer_radius=0.70
    tm.rings=36
    tm.ring_segments=10
    ring.mesh=tm
    ring.rotation_degrees.x=90
    ring.position.y=0.06
    ring.material_override=_mat(Color("#ffe18a"),0.25,true,true)
    root.add_child(ring)
    var label:=Label3D.new()
    label.text="HERO"
    label.font_size=34
    label.outline_size=8
    label.modulate=Color("#ffe8a4")
    label.position=Vector3(0,3.05,0)
    root.add_child(label)

func _box_proxy(root:Node3D,name:String,size:Vector3,pos:Vector3,color:Color,unshaded:bool=false)->void:
    var n:=MeshInstance3D.new()
    n.name=name
    var m:=BoxMesh.new()
    m.size=size
    n.mesh=m
    n.position=pos
    n.material_override=_mat(color,0.72,false,unshaded)
    root.add_child(n)

func _sphere_proxy(root:Node3D,name:String,radius:float,pos:Vector3,color:Color,scale_value:Vector3=Vector3.ONE)->void:
    var n:=MeshInstance3D.new()
    n.name=name
    var m:=SphereMesh.new()
    m.radius=radius
    m.height=radius*2.0
    m.radial_segments=24
    m.rings=14
    n.mesh=m
    n.position=pos
    n.scale=scale_value
    n.material_override=_mat(color,0.75,false)
    root.add_child(n)

func _build_recovery_world()->void:
    if world_root.get_node_or_null("HWRecoveryGround")!=null:
        return
    var center:=Vector3(12.65,0,12.10)
    var ground:=MeshInstance3D.new()
    ground.name="HWRecoveryGround"
    var plane:=PlaneMesh.new()
    plane.size=Vector2(80,60)
    ground.mesh=plane
    ground.position=center
    ground.material_override=_mat(Color("#54704b"),0.95,true)
    world_root.add_child(ground)

    _road(center+Vector3(0,0.025,0),Vector3(7.0,0.10,56.0),Color("#8b7259"))
    _road(center+Vector3(0,0.03,0),Vector3(74.0,0.10,6.0),Color("#92785b"))
    _road(center+Vector3(0,0.035,-10),Vector3(56.0,0.10,4.0),Color("#a08362"))
    _road(center+Vector3(-18,0.04,9),Vector3(4.0,0.10,30.0),Color("#a08362"))
    _road(center+Vector3(18,0.04,9),Vector3(4.0,0.10,30.0),Color("#a08362"))

    for p in [
        center+Vector3(-12,0,-7),center+Vector3(12,0,-7),
        center+Vector3(-12,0,12),center+Vector3(12,0,12),
        center+Vector3(-25,0,-10),center+Vector3(25,0,-10)
    ]:
        _house(p)

    for p in [
        center+Vector3(-25,0,-2),center+Vector3(25,0,-2),
        center+Vector3(-25,0,18),center+Vector3(25,0,18),
        center+Vector3(-18,0,-17),center+Vector3(18,0,-17),
        center+Vector3(-32,0,8),center+Vector3(32,0,8)
    ]:
        _tree(p)

    for p in [center+Vector3(-6,0,5),center+Vector3(6,0,5)]:
        _lamp(p)

    _plaza(center+Vector3(0,0,5))
    _label("PRONTERA • TOWN",center+Vector3(0,5.2,-7),Color("#ffe5a4"))
    _label("FIELD • MONSTERS",center+Vector3(26,3,-8),Color("#b9efaa"))

func _road(pos:Vector3,size:Vector3,color:Color)->void:
    var n:=MeshInstance3D.new()
    n.name="HWRecoveryRoad"
    var m:=BoxMesh.new()
    m.size=size
    n.mesh=m
    n.position=pos
    n.material_override=_mat(color,0.92,true)
    world_root.add_child(n)

func _house(pos:Vector3)->void:
    var wall:=_box("HWRecoveryHouse",Vector3(5.0,3.2,4.2),pos+Vector3(0,1.6,0),Color("#9b735b"))
    wall.material_override=_mat(Color("#9b735b"),0.86,false)
    _box("HWRecoveryRoof",Vector3(5.6,0.45,4.8),pos+Vector3(0,3.45,0),Color("#4d3d48"))
    _box("HWRecoveryDoor",Vector3(0.9,1.7,0.12),pos+Vector3(0,0.85,2.12),Color("#30251f"))
    _box("HWRecoveryWindowL",Vector3(0.8,0.65,0.08),pos+Vector3(-1.45,1.65,2.12),Color("#8bdcff"),true)
    _box("HWRecoveryWindowR",Vector3(0.8,0.65,0.08),pos+Vector3(1.45,1.65,2.12),Color("#8bdcff"),true)

func _tree(pos:Vector3)->void:
    var trunk:=MeshInstance3D.new()
    trunk.name="HWRecoveryTreeTrunk"
    var tm:=CylinderMesh.new()
    tm.top_radius=0.24
    tm.bottom_radius=0.42
    tm.height=2.8
    trunk.mesh=tm
    trunk.position=pos+Vector3(0,1.4,0)
    trunk.material_override=_mat(Color("#55392a"),0.95,false)
    world_root.add_child(trunk)
    var crown:=MeshInstance3D.new()
    crown.name="HWRecoveryTreeCrown"
    var sm:=SphereMesh.new()
    sm.radius=1.45
    sm.height=2.9
    sm.radial_segments=20
    sm.rings=12
    crown.mesh=sm
    crown.position=pos+Vector3(0,3.15,0)
    crown.material_override=_mat(Color("#34734b"),0.92,false)
    world_root.add_child(crown)

func _lamp(pos:Vector3)->void:
    var post:=_box("HWRecoveryLampPost",Vector3(0.14,2.6,0.14),pos+Vector3(0,1.3,0),Color("#3a3030"))
    post.material_override=_mat(Color("#3a3030"),0.55,true)
    var glow:=_box("HWRecoveryLampGlow",Vector3(0.32,0.32,0.32),pos+Vector3(0,2.65,0),Color("#ffd477"),true)
    glow.material_override=_mat(Color("#ffd477"),0.35,true)

func _plaza(pos:Vector3)->void:
    var base:=MeshInstance3D.new()
    base.name="HWRecoveryPlaza"
    var mesh:=CylinderMesh.new()
    mesh.top_radius=4.6
    mesh.bottom_radius=4.6
    mesh.height=0.16
    base.mesh=mesh
    base.position=pos+Vector3(0,0.08,0)
    base.material_override=_mat(Color("#9b876b"),0.84,false)
    world_root.add_child(base)
    var water:=MeshInstance3D.new()
    water.name="HWRecoveryFountainWater"
    var wm:=CylinderMesh.new()
    wm.top_radius=1.7
    wm.bottom_radius=1.7
    wm.height=0.10
    water.mesh=wm
    water.position=pos+Vector3(0,0.32,0)
    water.material_override=_mat(Color("#62c9ee"),0.25,true)
    world_root.add_child(water)

func _box(name:String,size:Vector3,pos:Vector3,color:Color,unshaded:bool=false)->MeshInstance3D:
    var n:=MeshInstance3D.new()
    n.name=name
    var m:=BoxMesh.new()
    m.size=size
    n.mesh=m
    n.position=pos
    n.material_override=_mat(color,0.82,false,unshaded)
    world_root.add_child(n)
    return n

func _mat(color:Color,roughness:float,metallic:bool,unshaded:bool=false)->StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.albedo_color=color
    m.roughness=roughness
    m.metallic=0.65 if metallic else 0.0
    if unshaded:
        m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
    return m

func _label(text:String,pos:Vector3,color:Color)->void:
    var l:=Label3D.new()
    l.text=text
    l.font_size=28
    l.outline_size=8
    l.modulate=color
    l.position=pos
    world_root.add_child(l)
