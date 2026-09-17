extends Node3D

## Runtime production-content generator.
## Adds dense HD 3D detail while preserving the existing MMORPG/ARPG runtime.

const ROOT_NAME := "HWProductionGenerated"
const HERO_DETAILS := "HWProductionHeroDetails"
const WORLD_DETAILS := "HWProductionWorldDetails"
var _elapsed: float = 0.0

func _process(delta: float) -> void:
    _elapsed += delta
    if _elapsed < 0.75:
        return
    _elapsed = 0.0
    _ensure_content()

func _ensure_content() -> void:
    var scene_root := get_tree().current_scene
    if scene_root == null:
        return
    var actors := scene_root.get_node_or_null("Actors3D") as Node3D
    var world := scene_root.get_node_or_null("World3D") as Node3D
    if actors != null:
        var hero := actors.get_node_or_null("Hero") as Node3D
        if hero != null:
            _enhance_hero(hero, str(hero.get_meta("class", "Warrior")))
        var pet := actors.get_node_or_null("Pet") as Node3D
        if pet != null:
            _enhance_pet(pet)
        for child: Node in actors.get_children():
            if child is Node3D and child.name != "Hero" and child.name != "Pet":
                _enhance_monster(child as Node3D)
    if world != null:
        _enhance_world(world)

func _enhance_hero(hero: Node3D, class_id: String) -> void:
    if hero.has_node(HERO_DETAILS):
        return
    var root := Node3D.new()
    root.name = HERO_DETAILS
    hero.add_child(root)
    var accent := _class_color(class_id)
    _add_mesh(root, "LeftLeg", _box(Color("#222832"), Vector3(0.28, 0.72, 0.30)), Vector3(-0.20, 0.54, 0.0))
    _add_mesh(root, "RightLeg", _box(Color("#222832"), Vector3(0.28, 0.72, 0.30)), Vector3(0.20, 0.54, 0.0))
    _add_mesh(root, "LeftBoot", _box(Color("#11151b"), Vector3(0.34, 0.22, 0.46)), Vector3(-0.20, 0.16, -0.06))
    _add_mesh(root, "RightBoot", _box(Color("#11151b"), Vector3(0.34, 0.22, 0.46)), Vector3(0.20, 0.16, -0.06))
    _add_mesh(root, "LeftArm", _capsule(accent.darkened(0.18), 0.18, 0.74), Vector3(-0.61, 1.34, 0.0))
    _add_mesh(root, "RightArm", _capsule(accent.darkened(0.18), 0.18, 0.74), Vector3(0.61, 1.34, 0.0))
    _add_mesh(root, "Belt", _box(accent.lightened(0.12), Vector3(0.82, 0.12, 0.48)), Vector3(0.0, 1.05, -0.01))
    _add_mesh(root, "FaceLeftEye", _sphere(Color("#18212a"), 0.055), Vector3(-0.13, 2.31, -0.345))
    _add_mesh(root, "FaceRightEye", _sphere(Color("#18212a"), 0.055), Vector3(0.13, 2.31, -0.345))
    _add_mesh(root, "Nose", _sphere(Color("#c58d6d"), 0.055), Vector3(0.0, 2.22, -0.355))
    _add_mesh(root, "EarL", _sphere(Color("#c99474"), 0.10), Vector3(-0.37, 2.28, 0.0))
    _add_mesh(root, "EarR", _sphere(Color("#c99474"), 0.10), Vector3(0.37, 2.28, 0.0))
    var cape := _box(accent.darkened(0.30), Vector3(0.95, 1.20, 0.08))
    cape.position = Vector3(0.0, 1.42, 0.28)
    root.add_child(cape)
    _add_mesh(root, "ChestGem", _sphere(accent.lightened(0.22), 0.10), Vector3(0.0, 1.54, -0.50))
    if class_id == "Archer":
        _add_mesh(root, "Quiver", _box(Color("#5b3928"), Vector3(0.20, 0.68, 0.22)), Vector3(-0.48, 1.42, 0.30))
        _add_mesh(root, "Bow", _ring(accent.lightened(0.20), 0.56, 0.055), Vector3(0.73, 1.40, 0.02))
    elif class_id == "Mage":
        _add_mesh(root, "ShoulderOrb", _sphere(accent.lightened(0.32), 0.15), Vector3(0.0, 1.95, 0.0))
    elif class_id == "Acolyte":
        var halo := _ring(accent.lightened(0.35), 0.48, 0.045)
        halo.rotation_degrees.x = 90.0
        halo.position = Vector3(0.0, 2.85, 0.0)
        root.add_child(halo)
    elif class_id == "Thief":
        _add_mesh(root, "ShoulderClaw", _box(accent, Vector3(0.12, 0.36, 0.58)), Vector3(0.55, 1.55, -0.12))
    elif class_id == "Merchant":
        _add_mesh(root, "MerchantPack", _box(Color("#684b31"), Vector3(0.62, 0.72, 0.34)), Vector3(0.0, 1.55, 0.34))
    else:
        _add_mesh(root, "Shield", _cylinder(accent.lightened(0.08), 0.42, 0.12), Vector3(-0.66, 1.28, -0.18))

func _enhance_pet(pet: Node3D) -> void:
    if pet.has_node(ROOT_NAME):
        return
    var root := Node3D.new()
    root.name = ROOT_NAME
    pet.add_child(root)
    _add_mesh(root, "EyeL", _sphere(Color("#101820"), 0.055), Vector3(-0.16, 0.08, -0.44))
    _add_mesh(root, "EyeR", _sphere(Color("#101820"), 0.055), Vector3(0.16, 0.08, -0.44))
    _add_mesh(root, "Collar", _ring(Color("#d5b36b"), 0.26, 0.035), Vector3(0.0, -0.10, 0.0))

func _enhance_monster(monster: Node3D) -> void:
    if monster.has_node(ROOT_NAME):
        return
    var root := Node3D.new()
    root.name = ROOT_NAME
    monster.add_child(root)
    var name := monster.name.to_lower()
    if name.contains("poring"):
        _add_mesh(root, "Crown", _sphere(Color("#ffe0a8"), 0.10), Vector3(0.0, 0.58, 0.0))
    elif name.contains("wolf"):
        _add_mesh(root, "EyeL", _sphere(Color("#f0c05a"), 0.06), Vector3(-0.18, 0.22, -0.40))
        _add_mesh(root, "EyeR", _sphere(Color("#f0c05a"), 0.06), Vector3(0.18, 0.22, -0.40))
    elif name.contains("golem") or name.contains("orc"):
        _add_mesh(root, "Core", _sphere(Color("#e5a44a"), 0.12), Vector3(0.0, 0.65, -0.28))
    else:
        _add_mesh(root, "Core", _sphere(Color("#d84c63"), 0.08), Vector3(0.0, 0.45, -0.30))

func _enhance_world(world: Node3D) -> void:
    if world.has_node(WORLD_DETAILS):
        return
    var root := Node3D.new()
    root.name = WORLD_DETAILS
    world.add_child(root)
    var positions := [Vector3(-8.0, 0.0, 2.0), Vector3(8.0, 0.0, 2.0), Vector3(-8.0, 0.0, 18.0), Vector3(8.0, 0.0, 18.0)]
    for i in positions.size():
        var lamp := Node3D.new()
        lamp.name = "StreetLamp_%d" % i
        lamp.position = positions[i]
        root.add_child(lamp)
        _add_mesh(lamp, "Pole", _cylinder(Color("#343b44"), 0.09, 2.8), Vector3(0.0, 1.4, 0.0))
        _add_mesh(lamp, "Lantern", _sphere(Color("#ffd47a"), 0.20), Vector3(0.0, 2.85, 0.0))
        var light := OmniLight3D.new()
        light.light_color = Color("#ffd47a")
        light.light_energy = 1.0
        light.omni_range = 5.5
        light.position = Vector3(0.0, 2.85, 0.0)
        lamp.add_child(light)
    for i in 6:
        var bench := _box(Color("#60452f"), Vector3(1.8, 0.16, 0.48))
        bench.position = Vector3(-6.0 + float(i) * 2.4, 0.42, 8.0)
        root.add_child(bench)

func _add_mesh(parent: Node3D, name: String, mesh: MeshInstance3D, position: Vector3) -> void:
    mesh.name = name
    mesh.position = position
    parent.add_child(mesh)

func _material(color: Color, metallic: float = 0.0, roughness: float = 0.72) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.metallic = metallic
    material.roughness = roughness
    return material

func _box(color: Color, size: Vector3) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    node.mesh = mesh
    node.material_override = _material(color)
    return node

func _sphere(color: Color, radius: float) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = radius
    mesh.height = radius * 2.0
    mesh.radial_segments = 24
    mesh.rings = 12
    node.mesh = mesh
    node.material_override = _material(color)
    return node

func _cylinder(color: Color, radius: float, height: float) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = height
    mesh.radial_segments = 24
    node.mesh = mesh
    node.material_override = _material(color, 0.35, 0.48)
    return node

func _capsule(color: Color, radius: float, height: float) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    var mesh := CapsuleMesh.new()
    mesh.radius = radius
    mesh.height = height
    mesh.radial_segments = 24
    mesh.rings = 8
    node.mesh = mesh
    node.material_override = _material(color)
    return node

func _ring(color: Color, radius: float, thickness: float) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    var mesh := TorusMesh.new()
    mesh.inner_radius = max(0.01, radius - thickness)
    mesh.outer_radius = radius
    mesh.rings = 32
    mesh.ring_segments = 10
    node.mesh = mesh
    node.material_override = _material(color, 0.1, 0.38)
    return node

func _class_color(class_id: String) -> Color:
    match class_id:
        "Warrior": return Color("#c94b4b")
        "Mage": return Color("#6b72df")
        "Archer": return Color("#55a56c")
        "Thief": return Color("#9a62c8")
        "Acolyte": return Color("#e0b34e")
        "Merchant": return Color("#5f91c8")
    return Color("#8c96a0")
