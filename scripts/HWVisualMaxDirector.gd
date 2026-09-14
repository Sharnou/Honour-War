extends Node3D

## Honour War Visual MAX — stable Godot 4 runtime presentation.
## Authored GLB assets are preferred. Procedural art is only a fallback while
## the Blender production asset build is unavailable locally.

var scene:Node3D
var world:Node3D
var built_world:bool = false
var environment_ready:bool = false
var timer:float = 0.0

func _ready() -> void:
    call_deferred("_bind")

func _process(delta:float) -> void:
    timer += delta
    if timer < 0.5:
        return
    timer = 0.0
    _bind()
    if scene == null:
        return
    _hide_labels(scene)
    _ensure_environment()
    _ensure_world_art()
    _ensure_actor_fallbacks()

func _bind() -> void:
    if scene == null or not is_instance_valid(scene):
        scene = get_tree().current_scene as Node3D
    if scene == null:
        return
    world = scene.get_node_or_null("World3D") as Node3D
    if world == null:
        return
    if not built_world:
        built_world = true
        _build_world_set()

func _ensure_environment() -> void:
    if environment_ready:
        return
    var env_node:WorldEnvironment = scene.get_node_or_null("HWVisualMaxEnvironment") as WorldEnvironment
    if env_node == null:
        env_node = WorldEnvironment.new()
        env_node.name = "HWVisualMaxEnvironment"
        scene.add_child(env_node)
    var env:Environment = env_node.environment
    if env == null:
        env = Environment.new()
        env_node.environment = env
    env.background_mode = Environment.BG_SKY
    var sky:Sky = Sky.new()
    var sky_mat:ProceduralSkyMaterial = ProceduralSkyMaterial.new()
    sky_mat.sky_top_color = Color("#163f75")
    sky_mat.sky_horizon_color = Color("#c8ecff")
    sky_mat.ground_bottom_color = Color("#18202a")
    sky_mat.ground_horizon_color = Color("#89a8b7")
    sky.material = sky_mat
    env.sky = sky
    env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    env.ambient_light_energy = 1.0
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env.tonemap_exposure = 1.12
    env.glow_enabled = true
    env.glow_intensity = 1.0
    env.ssao_enabled = true
    env.ssao_radius = 2.0
    env.ssao_intensity = 1.7
    env.fog_enabled = true
    env.fog_light_color = Color("#a9c5cf")
    env.fog_light_energy = 0.35
    env.fog_density = 0.005
    env.fog_height = 2.0
    env.fog_height_density = 0.014
    var sun:DirectionalLight3D = scene.get_node_or_null("HWVisualMaxSun") as DirectionalLight3D
    if sun == null:
        sun = DirectionalLight3D.new()
        sun.name = "HWVisualMaxSun"
        scene.add_child(sun)
    sun.rotation_degrees = Vector3(-48.0,-25.0,0.0)
    sun.light_energy = 1.6
    sun.light_color = Color("#ffe9c1")
    sun.shadow_enabled = true
    sun.directional_shadow_max_distance = 100.0
    sun.shadow_bias = 0.03
    environment_ready = true

func _build_world_set() -> void:
    var root:Node3D = Node3D.new()
    root.name = "HW_VisualMax_World"
    world.add_child(root)
    var center := Vector3(12.9,0.0,12.7)
    _plaza(root,center)
    _fountain(root,center + Vector3(0,0.18,5.0))
    _building(root,center + Vector3(-12,0,-6),Color("#87614b"),Color("#652d3b"),true)
    _building(root,center + Vector3(12,0,-6),Color("#52677a"),Color("#334b73"),true)
    _building(root,center + Vector3(-12,0,13),Color("#795846"),Color("#4b3030"),false)
    _building(root,center + Vector3(12,0,13),Color("#746483"),Color("#4e3a70"),true)
    _market(root,center)
    _lamps(root,center)
    _banners(root,center)
    _trees(root,center)
    _castle(root,center)

func _plaza(root:Node3D,center:Vector3) -> void:
    var stone := _mat(Color("#777d84"),0.0,0.72)
    var trim := _mat(Color("#4d545b"),0.0,0.62)
    for x in range(-9,10):
        for z in range(-4,5):
            root.add_child(_box(stone,Vector3(0.9,0.08,0.86),center+Vector3(float(x)*0.95,0.0,float(z)*0.92),0.0))
    root.add_child(_box(trim,Vector3(19.0,0.18,0.3),center+Vector3(0,0.03,-4.45),0.02))
    root.add_child(_box(trim,Vector3(19.0,0.18,0.3),center+Vector3(0,0.03,4.45),0.02))
    root.add_child(_box(trim,Vector3(0.3,0.18,9.0),center+Vector3(-9.45,0.03,0),0.02))
    root.add_child(_box(trim,Vector3(0.3,0.18,9.0),center+Vector3(9.45,0.03,0),0.02))

func _fountain(root:Node3D,center:Vector3) -> void:
    var stone := _mat(Color("#a4aab0"),0.05,0.56)
    var water := _mat(Color("#51c9ef"),0.08,0.12)
    var gold := _mat(Color("#d0ac56"),0.8,0.22)
    root.add_child(_cyl(stone,4.3,0.3,center,64))
    root.add_child(_cyl(water,3.75,0.06,center+Vector3(0,0.35,0),64))
    root.add_child(_cyl(stone,1.65,1.0,center+Vector3(0,0.72,0),48))
    root.add_child(_cyl(water,1.35,0.05,center+Vector3(0,1.25,0),48))
    for i in range(8):
        var a := TAU * float(i) / 8.0
        root.add_child(_cyl(gold,0.08,0.78,center+Vector3(cos(a)*2.9,0.55,sin(a)*2.9),20))
        root.add_child(_sphere(gold,0.16,center+Vector3(cos(a)*2.9,0.99,sin(a)*2.9)))

func _building(root:Node3D,pos:Vector3,wall_color:Color,roof_color:Color,windows:bool) -> void:
    var wall := _mat(wall_color,0.0,0.78)
    var wood := _mat(Color("#3d2a22"),0.0,0.7)
    var roof := _mat(roof_color,0.08,0.58)
    var glass := _mat(Color("#79c9db"),0.15,0.18)
    root.add_child(_box(wall,Vector3(6.0,3.8,4.8),pos+Vector3(0,1.9,0),0.0))
    root.add_child(_pyramid_roof(roof,4.4,2.25,pos+Vector3(0,4.9,0)))
    root.add_child(_box(wood,Vector3(1.25,2.15,0.1),pos+Vector3(0,1.08,2.45),0.03))
    root.add_child(_box(wood,Vector3(6.15,0.18,0.2),pos+Vector3(0,3.0,2.46),0.0))
    if windows:
        for x in [-1.75,1.75]:
            root.add_child(_box(glass,Vector3(1.05,1.05,0.07),pos+Vector3(x,2.0,2.47),0.02))
            root.add_child(_box(wood,Vector3(1.1,0.08,0.09),pos+Vector3(x,2.0,2.53),0.0))
            root.add_child(_box(wood,Vector3(0.08,1.1,0.09),pos+Vector3(x,2.0,2.53),0.0))

func _market(root:Node3D,center:Vector3) -> void:
    var wood := _mat(Color("#6d432d"),0.0,0.72)
    var red := _mat(Color("#be4b43"),0.0,0.78)
    var cream := _mat(Color("#d8bd69"),0.0,0.7)
    for side in [-1.0,1.0]:
        var p := center + Vector3(side*7.0,0,6.3)
        root.add_child(_box(wood,Vector3(3.2,0.2,1.45),p+Vector3(0,1.0,0),0.0))
        for x in [-1.3,1.3]:
            root.add_child(_cyl(wood,0.1,2.0,p+Vector3(x,1.0,0),20))
        root.add_child(_box(red if side < 0 else cream,Vector3(3.6,0.12,1.75),p+Vector3(0,2.28,0),0.0))
        for i in range(5):
            root.add_child(_sphere(_mat(Color("#d5a651"),0.55,0.4),0.15,p+Vector3(-0.9+0.45*float(i),1.28,0.3)))

func _lamps(root:Node3D,center:Vector3) -> void:
    var metal := _mat(Color("#242a31"),0.84,0.24)
    var glow := _emissive(Color("#ffe18b"),Color("#ffae3e"),3.0)
    for p in [center+Vector3(-5,0,1),center+Vector3(5,0,1),center+Vector3(-5,0,9),center+Vector3(5,0,9),center+Vector3(-16,0,5),center+Vector3(16,0,5)]:
        root.add_child(_cyl(metal,0.09,3.4,p+Vector3(0,1.7,0),20))
        root.add_child(_sphere(glow,0.20,p+Vector3(0,3.42,0)))

func _banners(root:Node3D,center:Vector3) -> void:
    var pole := _mat(Color("#68472d"),0.15,0.56)
    var cloth := _mat(Color("#173f78"),0.0,0.68)
    var gold := _emissive(Color("#e2c76b"),Color("#9b762a"),0.7)
    for x in [-9.0,9.0]:
        root.add_child(_cyl(pole,0.08,5.8,center+Vector3(x,2.9,-1.5),20))
        root.add_child(_box(cloth,Vector3(0.95,1.7,0.05),center+Vector3(x,2.8,-1.5),0.0))
        root.add_child(_sphere(gold,0.14,center+Vector3(x,5.85,-1.5)))

func _trees(root:Node3D,center:Vector3) -> void:
    var trunk := _mat(Color("#563928"),0.0,0.9)
    var leaves := _mat(Color("#2e7b53"),0.0,0.9)
    var leaves2 := _mat(Color("#4c9564"),0.0,0.86)
    var points:Array[Vector3]=[
        center+Vector3(-22,0,-7),center+Vector3(-19,0,13),center+Vector3(20,0,-6),center+Vector3(22,0,14),
        center+Vector3(-24,0,4),center+Vector3(25,0,4),center+Vector3(-4,0,-11),center+Vector3(5,0,-11)
    ]
    for p in points:
        root.add_child(_cyl(trunk,0.22,2.9,p+Vector3(0,1.45,0),20))
        root.add_child(_sphere(leaves,1.25,p+Vector3(0,3.05,0)))
        root.add_child(_sphere(leaves2,0.8,p+Vector3(-0.55,3.65,0.1)))
        root.add_child(_sphere(leaves2,0.78,p+Vector3(0.58,3.55,-0.08)))

func _castle(root:Node3D,center:Vector3) -> void:
    var stone := _mat(Color("#9ea8b1"),0.1,0.56)
    var roof := _mat(Color("#3b4662"),0.18,0.44)
    var base := center + Vector3(0,0,-28)
    root.add_child(_box(stone,Vector3(22,8,4.8),base+Vector3(0,4,0),0.0))
    for x in [-9.0,-4.5,0.0,4.5,9.0]:
        root.add_child(_cyl(stone,2.0,13.0,base+Vector3(x,6.5,0),32))
        root.add_child(_pyramid_roof(roof,2.5,3.3,base+Vector3(x,14.7,0)))

func _ensure_actor_fallbacks() -> void:
    _ensure_hero()
    _ensure_pet()
    _ensure_monsters()

func _ensure_hero() -> void:
    var hero:Node3D = scene.get("hero_visual") as Node3D
    if hero == null or not is_instance_valid(hero):
        return
    if hero.get_node_or_null("HW_VisualFallback") != null or hero.get_node_or_null("HW_GeneratedGLB") != null:
        return
    if hero.get_child_count() > 0:
        var has_mesh := false
        for c in hero.get_children():
            if c is MeshInstance3D:
                has_mesh = true
                break
        if not has_mesh:
            return
    _build_hero_fallback(hero)

func _build_hero_fallback(hero:Node3D) -> void:
    for c in hero.get_children():
        if c is MeshInstance3D:
            (c as MeshInstance3D).visible = false
    var root := Node3D.new()
    root.name = "HW_VisualFallback"
    hero.add_child(root)
    var skin := _mat(Color("#c9886a"),0.0,0.48)
    var armor := _mat(Color("#27313c"),0.72,0.24)
    var cloth := _mat(Color("#18202a"),0.0,0.68)
    var steel := _mat(Color("#9caab6"),0.86,0.2)
    var gold := _mat(Color("#d2af59"),0.82,0.2)
    var hair := _mat(Color("#201e29"),0.0,0.3)
    root.add_child(_capsule(cloth,0.40,1.28,Vector3(0,1.2,0)))
    root.add_child(_box(armor,Vector3(0.9,0.65,0.52),Vector3(0,1.65,0),0.0))
    root.add_child(_box(gold,Vector3(0.12,0.68,0.03),Vector3(0,1.35,-0.29),0.0))
    for side in [-1.0,1.0]:
        root.add_child(_sphere(steel,0.24,Vector3(side*0.5,1.8,0)))
        root.add_child(_capsule(armor,0.16,0.72,Vector3(side*0.55,1.28,0)))
        root.add_child(_sphere(skin,0.16,Vector3(side*0.57,0.84,-0.02)))
        root.add_child(_capsule(armor,0.2,0.62,Vector3(side*0.22,0.52,0)))
        root.add_child(_box(steel,Vector3(0.32,0.18,0.55),Vector3(side*0.22,0.16,-0.17),0.0))
    root.add_child(_cyl(skin,0.14,0.22,Vector3(0,2.08,0),24))
    root.add_child(_sphere(skin,0.42,Vector3(0,2.43,0)))
    root.add_child(_sphere(hair,0.45,Vector3(0,2.65,0)))
    var eye := _emissive(Color("#70cfff"),Color("#2c7dc1"),1.5)
    for side in [-1.0,1.0]:
        root.add_child(_sphere(eye,0.035,Vector3(side*0.13,2.43,-0.43)))
    root.add_child(_box(armor,Vector3(0.58,0.04,0.03),Vector3(0,2.24,-0.43),0.0))
    var cls := "Warrior"
    var legacy:Node = scene.get_node_or_null("LegacyGame")
    if legacy != null:
        var value:Variant = legacy.get("hero")
        if value is Dictionary:
            cls = str((value as Dictionary).get("class","Warrior"))
    _add_class_gear(root,cls,steel,gold)
    _add_cape(root,_class_color(cls))

func _add_class_gear(root:Node3D,cls:String,steel:Material,gold:Material) -> void:
    var accent := _mat(_class_color(cls),0.4,0.28)
    match cls:
        "Mage":
            root.add_child(_cyl(steel,0.06,1.75,Vector3(0.86,1.52,0),24))
            root.add_child(_sphere(accent,0.15,Vector3(0.86,2.42,0)))
            root.add_child(_torus(gold,0.45,0.035,Vector3(0,2.92,0)))
        "Archer", "Ranger":
            var bow := _torus(accent,0.46,0.045,Vector3(0.78,1.58,0.08))
            bow.rotation_degrees.x = 90.0
            root.add_child(bow)
            root.add_child(_box(gold,Vector3(0.72,0.02,0.02),Vector3(0.78,1.58,-0.01),0.0))
        "Thief":
            root.add_child(_box(accent,Vector3(0.58,0.11,0.04),Vector3(0,2.4,-0.46),0.0))
            root.add_child(_box(gold,Vector3(0.05,0.75,0.04),Vector3(0.83,1.34,-0.08),0.0))
        "Acolyte":
            root.add_child(_torus(gold,0.44,0.04,Vector3(0,2.94,0)))
            root.add_child(_cyl(gold,0.05,1.45,Vector3(0.86,1.52,0),24))
        "Merchant":
            root.add_child(_box(accent,Vector3(0.62,0.35,0.42),Vector3(0.78,1.76,-0.02),0.0))
        _:
            root.add_child(_box(accent,Vector3(0.10,1.3,0.07),Vector3(0.85,1.56,0),0.0))

func _add_cape(root:Node3D,color:Color) -> void:
    root.add_child(_box(_mat(color,0.0,0.64),Vector3(0.52,0.08,0.92),Vector3(0,1.38,0.4),0.0))

func _ensure_pet() -> void:
    var pet:Node3D = scene.get("pet_visual") as Node3D
    if pet == null or not is_instance_valid(pet):
        return
    if pet.get_node_or_null("HW_VisualFallback") != null or pet.get_node_or_null("HW_GeneratedGLB") != null:
        return
    var root := Node3D.new()
    root.name = "HW_VisualFallback"
    pet.add_child(root)
    var species := "Falcon"
    var legacy:Node = scene.get_node_or_null("LegacyGame")
    if legacy != null:
        var value:Variant = legacy.get("hero")
        if value is Dictionary:
            var pv:Variant = (value as Dictionary).get("pet",{})
            if pv is Dictionary:
                species = str((pv as Dictionary).get("species","Falcon"))
    if species.to_lower().contains("falcon"):
        var feather := _mat(Color("#8c623d"),0.0,0.72)
        root.add_child(_sphere(feather,0.36,Vector3(0,0.72,0)))
        root.add_child(_sphere(_mat(Color("#dac48d"),0.0,0.64),0.25,Vector3(0,1.03,0)))
        for side in [-1.0,1.0]:
            root.add_child(_box(feather,Vector3(0.10,0.12,1.05),Vector3(side*0.45,0.73,0),0.0))
    else:
        var fur := _mat(Color("#525d68"),0.0,0.9)
        var dark := _mat(Color("#222a34"),0.1,0.66)
        root.add_child(_sphere(fur,0.54,Vector3(0,0.72,0)))
        root.add_child(_sphere(dark,0.36,Vector3(0,0.96,-0.4)))
        for side in [-1.0,1.0]:
            root.add_child(_capsule(dark,0.13,0.5,Vector3(side*0.3,0.35,0)))

func _ensure_monsters() -> void:
    var visuals:Variant = scene.get("monster_visuals")
    if not visuals is Dictionary:
        return
    for key in visuals.keys():
        var monster:Node3D = visuals[key] as Node3D
        if monster == null or not is_instance_valid(monster):
            continue
        if monster.get_node_or_null("HW_VisualFallback") != null or monster.get_node_or_null("HW_GeneratedGLB") != null:
            continue
        _build_monster_fallback(monster,str(key))

func _build_monster_fallback(monster:Node3D,id:String) -> void:
    var root := Node3D.new()
    root.name = "HW_VisualFallback"
    monster.add_child(root)
    var n := id.to_lower()
    if n.contains("poring"):
        root.add_child(_sphere(_mat(Color("#df6f9c"),0.0,0.34),0.58,Vector3(0,0.65,0)))
        root.add_child(_sphere(_emissive(Color("#4a263b"),Color("#22121c"),0.8),0.06,Vector3(-0.17,0.78,-0.5)))
        root.add_child(_sphere(_emissive(Color("#4a263b"),Color("#22121c"),0.8),0.06,Vector3(0.17,0.78,-0.5)))
    elif n.contains("wolf"):
        var fur := _mat(Color("#626c77"),0.0,0.92)
        root.add_child(_sphere(fur,0.7,Vector3(0,0.82,0)))
        root.add_child(_sphere(_mat(Color("#28303a"),0.1,0.68),0.44,Vector3(0,1.06,-0.52)))
        for side in [-1.0,1.0]:
            root.add_child(_cone(fur,0.23,0.58,Vector3(side*0.34,1.55,-0.2),4))
    elif n.contains("knight") or n.contains("bloody"):
        var steel := _mat(Color("#4d5a66"),0.88,0.23)
        var blood := _mat(Color("#7d1f2f"),0.18,0.33)
        root.add_child(_capsule(_mat(Color("#171b23"),0.5,0.3),0.68,1.58,Vector3(0,1.05,0)))
        root.add_child(_box(steel,Vector3(1.18,0.72,0.64),Vector3(0,1.62,0),0.0))
        root.add_child(_sphere(_mat(Color("#151922"),0.65,0.28),0.56,Vector3(0,2.2,0)))
        root.add_child(_box(blood,Vector3(0.12,1.62,0.12),Vector3(0.92,1.5,0),0.0))
        root.add_child(_sphere(_emissive(Color("#ff3d46"),Color("#7d121a"),3.0),0.08,Vector3(0,2.2,-0.58)))
    else:
        var body := _mat(Color("#55606a"),0.12,0.84)
        root.add_child(_capsule(body,0.62,1.4,Vector3(0,0.96,0)))
        root.add_child(_sphere(body,0.5,Vector3(0,1.96,0)))
        root.add_child(_sphere(_emissive(Color("#ffb65c"),Color("#7a2d20"),2.0),0.07,Vector3(-0.17,1.98,-0.49)))
        root.add_child(_sphere(_emissive(Color("#ffb65c"),Color("#7a2d20"),2.0),0.07,Vector3(0.17,1.98,-0.49)))

func _hide_labels(node:Node) -> void:
    for child in node.get_children():
        if child is Label3D:
            (child as Label3D).visible = false
        if child.get_child_count() > 0:
            _hide_labels(child)

func _class_color(cls:String) -> Color:
    match cls:
        "Mage": return Color("#876fe2")
        "Archer", "Ranger": return Color("#55b978")
        "Thief": return Color("#cf5d9b")
        "Acolyte": return Color("#d5b653")
        "Merchant": return Color("#55acd1")
        _ : return Color("#c7803f")

func _mat(color:Color,metallic:float,roughness:float) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.metallic = metallic
    m.roughness = roughness
    return m

func _emissive(color:Color,emission:Color,energy:float) -> StandardMaterial3D:
    var m := _mat(color,0.05,0.22)
    m.emission_enabled = true
    m.emission = emission
    m.emission_energy_multiplier = energy
    return m

func _box(mat:Material,size:Vector3,pos:Vector3,bevel:float=0.0) -> MeshInstance3D:
    var n := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    n.mesh = mesh
    n.material_override = mat
    n.position = pos
    return n

func _sphere(mat:Material,radius:float,pos:Vector3) -> MeshInstance3D:
    var n := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = radius
    mesh.height = radius * 2.0
    mesh.radial_segments = 32
    mesh.rings = 20
    n.mesh = mesh
    n.material_override = mat
    n.position = pos
    return n

func _capsule(mat:Material,radius:float,height:float,pos:Vector3) -> MeshInstance3D:
    var n := MeshInstance3D.new()
    var mesh := CapsuleMesh.new()
    mesh.radius = radius
    mesh.height = height
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

func _cone(mat:Material,radius:float,height:float,pos:Vector3,segments:int=32) -> MeshInstance3D:
    var n := MeshInstance3D.new()
    var mesh := CylinderMesh.new()
    mesh.top_radius = 0.0
    mesh.bottom_radius = radius
    mesh.height = height
    mesh.radial_segments = segments
    n.mesh = mesh
    n.material_override = mat
    n.position = pos
    return n

func _pyramid_roof(mat:Material,radius:float,height:float,pos:Vector3) -> MeshInstance3D:
    var n := _cone(mat,radius,height,pos,4)
    n.rotation_degrees.y = 45.0
    return n

func _torus(mat:Material,major:float,minor:float,pos:Vector3) -> MeshInstance3D:
    var n := MeshInstance3D.new()
    var mesh := TorusMesh.new()
    mesh.inner_radius = major
    mesh.outer_radius = major + minor
    mesh.rings = 48
    mesh.ring_segments = 12
    n.mesh = mesh
    n.material_override = mat
    n.position = pos
    return n
