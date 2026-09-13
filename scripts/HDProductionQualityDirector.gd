class_name HDProductionQualityDirector
extends Node

## Honour War production visual pass.
## Runtime fallback stays lightweight, while production GLB/GLTF assets are left intact.
## Art pipeline target: Blender -> Substance 3D Painter -> GLB/GLTF -> Godot 4.

var scene_root:Node
var applied:bool=false
var pulse_time:float=0.0
var detail_root:Node3D
var hero_last:Node3D
var pet_last:Node3D
var monster_last:Dictionary={}

func _ready()->void:
    set_process(true)
    call_deferred("_apply")

func _process(delta:float)->void:
    pulse_time+=delta
    if scene_root==null or not is_instance_valid(scene_root):
        scene_root=get_tree().current_scene
        applied=false
    if scene_root==null:
        return
    if not applied:
        _apply()
    _refresh_actors()
    _animate_accents()

func _apply()->void:
    scene_root=get_tree().current_scene
    if scene_root==null:
        return
    _setup_world_lighting()
    _setup_camera()
    _dress_world()
    applied=true

func _setup_world_lighting()->void:
    var world:=scene_root.get_node_or_null("HWProductionWorldEnvironment") as WorldEnvironment
    if world==null:
        world=WorldEnvironment.new()
        world.name="HWProductionWorldEnvironment"
        scene_root.add_child(world)
    var env:=world.environment
    if env==null:
        env=Environment.new()
        world.environment=env
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#87a8b8")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#d8e3e8")
    env.ambient_light_energy=0.78
    env.reflected_light_source=Environment.REFLECTION_SOURCE_BG
    env.tonemap_mode=Environment.TONE_MAPPER_FILMIC
    env.tonemap_exposure=1.10
    env.tonemap_white=1.18

    var sun:=scene_root.get_node_or_null("HWProductionSun") as DirectionalLight3D
    if sun==null:
        sun=DirectionalLight3D.new()
        sun.name="HWProductionSun"
        scene_root.add_child(sun)
    sun.rotation_degrees=Vector3(-52.0,-28.0,0.0)
    sun.light_energy=1.15
    sun.shadow_enabled=true
    sun.directional_shadow_max_distance=180.0
    sun.directional_shadow_fade_start=0.78
    sun.directional_shadow_pancake_size=20.0
    sun.light_color=Color("#fff1d4")

func _setup_camera()->void:
    var camera:=_find_camera(scene_root)
    if camera==null:
        return
    camera.projection=Camera3D.PROJECTION_PERSPECTIVE
    camera.fov=58.0
    camera.near=0.05
    camera.far=500.0

func _dress_world()->void:
    detail_root=scene_root.get_node_or_null("HWProductionDetailPass") as Node3D
    if detail_root!=null:
        return
    detail_root=Node3D.new()
    detail_root.name="HWProductionDetailPass"
    scene_root.add_child(detail_root)
    var world:Node3D=scene_root.get_node_or_null("HDPresentationWorld") as Node3D
    if world==null:
        world=scene_root.get_node_or_null("HDEnvironmentDirector") as Node3D
    if world!=null:
        detail_root.position=world.position
    _add_plaza_inlays()
    _add_road_cobbles()
    _add_grass_detail()
    _add_lamp_lights()

func _add_plaza_inlays()->void:
    var stone:=_mat(Color("#b9ad95"),0.92,0.0)
    var dark:=_mat(Color("#6e685e"),0.98,0.0)
    for i in range(10):
        var angle:=float(i)*TAU/10.0
        var p:=Vector3(cos(angle)*4.55,0.09,5.5+sin(angle)*4.55)
        var slab:=_box(Vector3(1.45,0.07,0.44),p,stone)
        slab.rotation.y=angle
        detail_root.add_child(slab)
    for r in [2.0,4.0,6.0]:
        var ring:=_ring_mesh(3.0 if r>3.0 else 2.4,0.055,dark)
        ring.position=Vector3(0,0.10,5.5)
        ring.scale=Vector3(r/4.0,1.0,r/4.0)
        detail_root.add_child(ring)

func _add_road_cobbles()->void:
    var road:=_mat(Color("#8d7663"),0.98,0.0)
    var edge:=_mat(Color("#b0a18b"),1.0,0.0)
    for i in range(18):
        var x:float=-9.0+float(i)*1.05
        var p:=Vector3(x,0.065,1.0)
        var tile:=_box(Vector3(0.88,0.045,5.8),p,road)
        tile.rotation.y=0.01 if i%2==0 else -0.01
        detail_root.add_child(tile)
    for i in range(11):
        var x:float=-5.0+float(i)*1.0
        var curb:=_box(Vector3(0.72,0.08,0.22),Vector3(x,0.08,-1.72),edge)
        detail_root.add_child(curb)

func _add_grass_detail()->void:
    var grass:=_mat(Color("#5f8d52"),0.98,0.0)
    var grass2:=_mat(Color("#88a960"),1.0,0.0)
    var points:Array[Vector3]=[
        Vector3(-28,0,-12),Vector3(29,0,-11),Vector3(-31,0,19),Vector3(31,0,20),
        Vector3(-34,0,5),Vector3(34,0,8),Vector3(-17,0,22),Vector3(18,0,23)
    ]
    for point in points:
        for j in range(5):
            var blade:=_box(grass if j%2==0 else grass2,Vector3(0.06,0.26,0.04),point+Vector3(float(j-2)*0.18,0.13,float((j%3)-1)*0.14))
            blade.rotation_degrees.z=float(-8+j*4)
            detail_root.add_child(blade)

func _add_lamp_lights()->void:
    var positions:Array[Vector3]=[
        Vector3(-19,3.0,-1),Vector3(-7,3.0,-1),Vector3(7,3.0,-1),Vector3(19,3.0,-1),
        Vector3(-19,3.0,9.5),Vector3(-7,3.0,9.5),Vector3(7,3.0,9.5),Vector3(19,3.0,9.5)
    ]
    for p in positions:
        var light:=OmniLight3D.new()
        light.position=p
        light.omni_range=4.5
        light.light_energy=0.38
        light.light_color=Color("#ffd590")
        light.shadow_enabled=false
        detail_root.add_child(light)

func _refresh_actors()->void:
    var hero:=_get_visual("hero_visual")
    if hero!=null and hero!=hero_last:
        hero_last=hero
        _decorate_hero(hero)
    var pet:=_get_visual("pet_visual")
    if pet!=null and pet!=pet_last:
        pet_last=pet
        _decorate_pet(pet)
    var visuals:Variant=scene_root.get("monster_visuals")
    if visuals is Dictionary:
        for id in visuals.keys():
            var monster:=visuals[id] as Node3D
            if monster!=null and is_instance_valid(monster) and not monster_last.has(str(id)):
                monster_last[str(id)]=monster
                _decorate_monster(monster)

func _decorate_hero(hero:Node3D)->void:
    _strip_world_labels(hero)
    if hero.has_meta("hw_quality_decorated"):
        return
    hero.set_meta("hw_quality_decorated",true)
    var root:=Node3D.new()
    root.name="HW_QualityHeroDetails"
    hero.add_child(root)
    var belt:=_box(_mat(Color("#1c2229"),0.66,0.18),Vector3(1.0,0.10,0.58),Vector3(0,1.02,0.01))
    root.add_child(belt)
    var buckle:=_box(_mat(Color("#e2c46a"),0.34,0.74),Vector3(0.17,0.16,0.06),Vector3(0,1.03,-0.31))
    root.add_child(buckle)
    for side in [-1.0,1.0]:
        var guard:=_sphere(_mat(Color("#657584"),0.48,0.44),0.22,Vector3(side*0.53,1.68,-0.01))
        guard.scale=Vector3(1.10,0.68,1.18)
        root.add_child(guard)
        var rivet:=_sphere(_mat(Color("#e7c66c"),0.30,0.76),0.045,Vector3(side*0.53,1.68,-0.23))
        root.add_child(rivet)
    var crest:=_sphere(_emission_mat(Color("#dbb85e"),Color("#6f5519")),0.13,Vector3(0,2.53,-0.30))
    root.add_child(crest)
    _add_contact_ring(root,Color("#d9b65a"),0.75)

func _decorate_pet(pet:Node3D)->void:
    if pet.has_meta("hw_quality_decorated"):
        return
    pet.set_meta("hw_quality_decorated",true)
    var root:=Node3D.new()
    root.name="HW_QualityPetDetails"
    pet.add_child(root)
    var species:String=""
    var legacy:=scene_root.get("legacy") as Node
    if legacy!=null:
        var data:Variant=legacy.get("hero")
        if data is Dictionary:
            var pet_data:Variant=(data as Dictionary).get("pet",{})
            if pet_data is Dictionary:
                species=str((pet_data as Dictionary).get("species",""))
    var accent:=Color("#d5bd6b") if species.to_lower().contains("falcon") else Color("#76a8c8")
    _add_contact_ring(root,accent,0.55)
    var eye:=_sphere(_emission_mat(Color("#f6e3a2"),accent),0.075,Vector3(0,0.62,-0.22))
    root.add_child(eye)

func _decorate_monster(monster:Node3D)->void:
    if monster.has_meta("hw_quality_decorated"):
        return
    monster.set_meta("hw_quality_decorated",true)
    var root:=Node3D.new()
    root.name="HW_QualityMonsterDetails"
    monster.add_child(root)
    var aura:=_emission_mat(Color("#d96e63"),Color("#4b1713"))
    _add_contact_ring(root,aura.albedo_color,0.80)
    var scale_factor:=clamp(monster.scale.y,0.5,3.0)
    root.scale=Vector3.ONE*(0.85+scale_factor*0.08)

func _animate_accents()->void:
    if detail_root==null or not is_instance_valid(detail_root):
        return
    var pulse:=0.96+sin(pulse_time*2.2)*0.05
    for node in detail_root.get_children():
        if node is OmniLight3D:
            (node as OmniLight3D).light_energy=0.34+sin(pulse_time*1.7+float(node.get_index()))*0.025
    _animate_actor_ring(hero_last,pulse)
    _animate_actor_ring(pet_last,pulse)

func _animate_actor_ring(actor:Node3D,pulse:float)->void:
    if actor==null or not is_instance_valid(actor):
        return
    var ring:=actor.get_node_or_null("HW_QualityHeroDetails/HW_ContactRing") as MeshInstance3D
    if ring==null:
        ring=actor.get_node_or_null("HW_QualityPetDetails/HW_ContactRing") as MeshInstance3D
    if ring!=null:
        ring.scale=Vector3.ONE*pulse

func _strip_world_labels(root:Node)->void:
    for child in root.get_children():
        if child is Label3D:
            child.visible=false
        _strip_world_labels(child)

func _get_visual(property_name:String)->Node3D:
    var value:Variant=scene_root.get(property_name)
    return value as Node3D

func _find_camera(root:Node)->Camera3D:
    if root is Camera3D:
        return root as Camera3D
    for child in root.get_children():
        var found:=_find_camera(child)
        if found!=null:
            return found
    return null

func _mat(color:Color,roughness:float,metallic:float)->StandardMaterial3D:
    var material:=StandardMaterial3D.new()
    material.albedo_color=color
    material.roughness=roughness
    material.metallic=metallic
    return material

func _emission_mat(color:Color,emission:Color)->StandardMaterial3D:
    var material:=_mat(color,0.35,0.30)
    material.emission_enabled=true
    material.emission=emission
    material.emission_energy_multiplier=0.75
    return material

func _box(material:Material,size:Vector3,pos:Vector3)->MeshInstance3D:
    var node:=MeshInstance3D.new()
    var mesh:=BoxMesh.new()
    mesh.size=size
    node.mesh=mesh
    node.position=pos
    node.material_override=material
    return node

func _sphere(material:Material,radius:float,pos:Vector3)->MeshInstance3D:
    var node:=MeshInstance3D.new()
    var mesh:=SphereMesh.new()
    mesh.radius=radius
    mesh.height=radius*2.0
    mesh.radial_segments=32
    mesh.rings=18
    node.mesh=mesh
    node.position=pos
    node.material_override=material
    return node

func _ring_mesh(radius:float,thickness:float,material:Material)->MeshInstance3D:
    var node:=MeshInstance3D.new()
    var mesh:=TorusMesh.new()
    mesh.inner_radius=radius
    mesh.outer_radius=radius+thickness
    mesh.rings=48
    mesh.ring_segments=10
    node.mesh=mesh
    node.material_override=material
    node.rotation_degrees.x=90.0
    return node

func _add_contact_ring(parent:Node3D,color:Color,radius:float)->void:
    var ring:=_ring_mesh(radius,0.035,_emission_mat(color,color.darkened(0.72)))
    ring.name="HW_ContactRing"
    ring.position=Vector3(0,0.035,0)
    parent.add_child(ring)
