extends Node3D

## Honour War Primitive Beauty Pass.
## Makes the procedural fallback art cleaner and more decorative without
## replacing gameplay roots or authored GLB assets.

var scene:Node3D
var world:Node3D
var done:bool = false
var tick:float = 0.0

func _ready() -> void:
    call_deferred("_bind")

func _process(delta:float) -> void:
    tick += delta
    if tick < 0.8:
        return
    tick = 0.0
    _bind()
    if scene == null:
        return
    _beautify_world()
    _beautify_actors()

func _bind() -> void:
    if scene == null or not is_instance_valid(scene):
        scene = get_tree().current_scene as Node3D
    if scene == null:
        return
    world = scene.get_node_or_null("World3D") as Node3D
    if world != null and not done:
        done = true
        _beautify_world()

func _beautify_world() -> void:
    if world == null:
        return
    var root:Node3D = world.get_node_or_null("HW_VisualMax_World") as Node3D
    if root == null:
        return
    if root.get_node_or_null("HW_BeautyPass") != null:
        return
    var beauty := Node3D.new()
    beauty.name = "HW_BeautyPass"
    root.add_child(beauty)
    _add_plaza_inlays(beauty)
    _add_fountain_details(beauty)
    _add_building_trim(beauty)
    _add_market_details(beauty)
    _add_heroic_lighting_props(beauty)

func _add_plaza_inlays(root:Node3D) -> void:
    var dark := _mat(Color("#3f4650"),0.18,0.52)
    var gold := _emissive(Color("#d9b85e"),Color("#8a6528"),0.35)
    for x in [-8.55,-6.65,-4.75,-2.85,-0.95,0.95,2.85,4.75,6.65,8.55]:
        root.add_child(_box(dark,Vector3(0.055,0.04,8.2),Vector3(12.9+x,0.13,12.7),0.0))
    for z in [-3.7,-1.85,0.0,1.85,3.7]:
        root.add_child(_box(dark,Vector3(18.2,0.04,0.055),Vector3(12.9,0.13,12.7+z),0.0))
    for q in [Vector3(-9.0,0.16,-4.0),Vector3(9.0,0.16,-4.0),Vector3(-9.0,0.16,4.0),Vector3(9.0,0.16,4.0)]:
        root.add_child(_torus(gold,0.28,0.028,Vector3(12.9+q.x,0.18,12.7+q.z)))

func _add_fountain_details(root:Node3D) -> void:
    var gold := _mat(Color("#e0be61"),0.9,0.2)
    var blue := _emissive(Color("#5bcff2"),Color("#2ca9d6"),1.15)
    var center := Vector3(12.9,0.0,17.7)
    root.add_child(_torus(gold,4.0,0.08,center+Vector3(0,0.43,0)))
    root.add_child(_torus(gold,1.42,0.07,center+Vector3(0,1.29,0)))
    for i in range(12):
        var a := TAU * float(i) / 12.0
        root.add_child(_sphere(blue,0.055,center+Vector3(cos(a)*2.75,0.48,sin(a)*2.75)))

func _add_building_trim(root:Node3D) -> void:
    var wood := _mat(Color("#33251e"),0.12,0.56)
    var brass := _mat(Color("#bd9143"),0.78,0.22)
    var window_glow := _emissive(Color("#8edaf1"),Color("#55bddf"),0.55)
    var positions := [Vector3(0.9,0.0,-2.0),Vector3(24.9,0.0,-2.0),Vector3(0.9,0.0,17.0),Vector3(24.9,0.0,17.0)]
    for p in positions:
        root.add_child(_box(wood,Vector3(6.2,0.11,0.16),p+Vector3(0,3.02,2.5),0.0))
        root.add_child(_box(brass,Vector3(4.9,0.06,0.06),p+Vector3(0,3.18,2.52),0.0))
        root.add_child(_torus(brass,0.18,0.025,p+Vector3(0,2.0,2.58)))
        root.add_child(_sphere(window_glow,0.045,p+Vector3(-1.75,2.0,2.59)))
        root.add_child(_sphere(window_glow,0.045,p+Vector3(1.75,2.0,2.59)))

func _add_market_details(root:Node3D) -> void:
    var rope := _mat(Color("#b89b61"),0.0,0.82)
    var brass := _mat(Color("#cfa652"),0.72,0.23)
    for side in [-1.0,1.0]:
        var p := Vector3(12.9+side*7.0,0,19.0)
        root.add_child(_cyl(brass,0.07,0.75,p+Vector3(0,2.86,0),18))
        root.add_child(_torus(rope,0.25,0.035,p+Vector3(0,3.22,0)))

func _add_heroic_lighting_props(root:Node3D) -> void:
    var stone := _mat(Color("#59616a"),0.38,0.34)
    var rune := _emissive(Color("#6fd8ff"),Color("#3db7e3"),1.4)
    for p in [Vector3(3.4,0.0,8.0),Vector3(22.4,0.0,8.0)]:
        root.add_child(_cyl(stone,0.32,0.24,p+Vector3(0,0.13,0),32))
        for i in range(3):
            var a := TAU * float(i)/3.0
            root.add_child(_box(rune,Vector3(0.10,0.025,0.55),p+Vector3(cos(a)*0.18,0.27,sin(a)*0.18),a))

func _beautify_actors() -> void:
    _beautify_actor(scene.get("hero_visual") as Node3D, true)
    _beautify_actor(scene.get("pet_visual") as Node3D, false)
    var monsters:Variant = scene.get("monster_visuals")
    if monsters is Dictionary:
        for key in monsters.keys():
            _beautify_actor(monsters[key] as Node3D, false)

func _beautify_actor(actor:Node3D,is_hero:bool) -> void:
    if actor == null or not is_instance_valid(actor):
        return
    var fallback:Node3D = actor.get_node_or_null("HW_VisualFallback") as Node3D
    if fallback == null:
        return
    if fallback.get_node_or_null("HW_PrimitiveBeauty") != null:
        _animate_actor_accent(fallback.get_node("HW_PrimitiveBeauty") as Node3D,is_hero)
        return
    var root := Node3D.new()
    root.name = "HW_PrimitiveBeauty"
    fallback.add_child(root)
    if is_hero:
        _add_hero_details(root)
    else:
        _add_generic_actor_details(root)

func _add_hero_details(root:Node3D) -> void:
    var gold := _mat(Color("#e3bd5b"),0.82,0.2)
    var steel := _mat(Color("#b8c4ce"),0.9,0.18)
    var gem := _emissive(Color("#70d9ff"),Color("#3aa6e0"),2.2)
    root.add_child(_torus(gold,0.39,0.035,Vector3(0,2.44,-0.015)))
    root.add_child(_torus(steel,0.22,0.025,Vector3(0,2.64,-0.02)))
    root.add_child(_sphere(gem,0.055,Vector3(0,2.64,-0.245)))
    root.add_child(_box(gold,Vector3(0.08,0.58,0.04),Vector3(-0.59,1.30,-0.12),0.0))
    root.add_child(_box(gold,Vector3(0.08,0.58,0.04),Vector3(0.59,1.30,-0.12),0.0))
    var shadow := _emissive(Color("#7bbfe2"),Color("#275d78"),0.18)
    root.add_child(_cyl(shadow,0.72,0.025,Vector3(0,0.05,0),48))

func _add_generic_actor_details(root:Node3D) -> void:
    var shadow := _mat(Color("#1e2630"),0.12,0.7)
    root.add_child(_cyl(shadow,0.55,0.022,Vector3(0,0.04,0),40))
    var gem := _emissive(Color("#ffcf66"),Color("#c7782f"),1.35)
    root.add_child(_sphere(gem,0.045,Vector3(0,0.65,-0.52)))

func _animate_actor_accent(node:Node3D,is_hero:bool) -> void:
    var phase := Time.get_ticks_msec() * 0.001
    if is_hero:
        node.rotation.y = sin(phase*0.9)*0.015
        var scale_pulse := 1.0 + sin(phase*1.6)*0.018
        node.scale = Vector3(scale_pulse,scale_pulse,scale_pulse)
    else:
        node.rotation.y = sin(phase*1.2)*0.025

func _mat(color:Color,metallic:float,roughness:float) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.metallic = metallic
    m.roughness = roughness
    m.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
    m.cull_mode = BaseMaterial3D.CULL_BACK
    return m

func _emissive(color:Color,emission:Color,energy:float) -> StandardMaterial3D:
    var m := _mat(color,0.05,0.24)
    m.emission_enabled = true
    m.emission = emission
    m.emission_energy_multiplier = energy
    return m

func _box(mat:Material,size:Vector3,pos:Vector3,rot_y:float=0.0) -> MeshInstance3D:
    var n := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    n.mesh = mesh
    n.material_override = mat
    n.position = pos
    n.rotation.y = rot_y
    return n

func _sphere(mat:Material,radius:float,pos:Vector3) -> MeshInstance3D:
    var n := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = radius
    mesh.height = radius*2.0
    mesh.radial_segments = 32
    mesh.rings = 20
    n.mesh = mesh
    n.material_override = mat
    n.position = pos
    return n

func _cyl(mat:Material,radius:float,height:float,pos:Vector3,segments:int=32) -> MeshInstance3D:
    var n := MeshInstance3D.new()
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = height
    mesh.radial_segments = segments
    n.mesh = mesh
    n.material_override = mat
    n.position = pos
    return n

func _torus(mat:Material,major:float,minor:float,pos:Vector3) -> MeshInstance3D:
    var n := MeshInstance3D.new()
    var mesh := TorusMesh.new()
    mesh.inner_radius = major
    mesh.outer_radius = major + minor
    mesh.rings = 48
    mesh.ring_segments = 14
    n.mesh = mesh
    n.material_override = mat
    n.position = pos
    return n
