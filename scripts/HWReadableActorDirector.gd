extends Node3D

var game: Node3D
var hero_seen: Node3D
var pet_seen: Node3D
var monsters_seen: Dictionary = {}

func _ready() -> void:
    game = get_parent() as Node3D
    call_deferred("_apply")

func _process(_delta: float) -> void:
    if game == null:
        return
    _apply()

func _apply() -> void:
    var hero: Node3D = game.get("hero_visual") as Node3D
    if hero != null and is_instance_valid(hero):
        hero.scale = Vector3.ONE * 1.28
        hero_seen = hero
        _hero_lighting(hero)
    var pet: Node3D = game.get("pet_visual") as Node3D
    if pet != null and is_instance_valid(pet):
        pet.scale = Vector3.ONE * 1.12
        pet_seen = pet
    var visuals: Variant = game.get("monster_visuals")
    if visuals is Dictionary:
        for key in visuals.keys():
            var monster: Node3D = visuals[key] as Node3D
            if monster == null or not is_instance_valid(monster):
                continue
            var id: String = str(key)
            if not monsters_seen.has(id):
                monsters_seen[id] = true
                _detail_monster(monster, id)
            var scale_value: float = clamp(monster.scale.y, 0.65, 2.2)
            monster.scale = Vector3.ONE * max(1.0, scale_value * 1.10)

func _hero_lighting(hero: Node3D) -> void:
    if hero.get_node_or_null("HW_ReadabilityLight") != null:
        return
    var light := OmniLight3D.new()
    light.name = "HW_ReadabilityLight"
    light.position = Vector3(0.0, 2.1, 1.4)
    light.omni_range = 5.0
    light.light_energy = 0.75
    light.light_color = Color("#fff0d0")
    light.shadow_enabled = false
    hero.add_child(light)

func _detail_monster(monster: Node3D, id: String) -> void:
    var root := Node3D.new()
    root.name = "HW_MonsterReadableDetail"
    monster.add_child(root)
    var name_l := id.to_lower()
    var dark := _mat(Color("#252a32"), 0.25, 0.40)
    var eye := _mat(Color("#ff8e67"), 0.20, 0.20)
    if name_l.contains("poring"):
        _sphere(root, Color("#e78c8c"), 0.17, Vector3(-0.18, 0.55, -0.38))
        _sphere(root, Color("#e78c8c"), 0.17, Vector3(0.18, 0.55, -0.38))
    elif name_l.contains("wolf") or name_l.contains("thief"):
        _box(root, dark, Vector3(0.12, 0.42, 0.08), Vector3(-0.26, 0.95, -0.22))
        _box(root, dark, Vector3(0.12, 0.42, 0.08), Vector3(0.26, 0.95, -0.22))
    elif name_l.contains("baphomet") or name_l.contains("horn"):
        _horn(root, Vector3(-0.32, 1.22, 0.0), -25.0)
        _horn(root, Vector3(0.32, 1.22, 0.0), 25.0)
    else:
        _sphere(root, eye, 0.075, Vector3(-0.18, 1.05, -0.32))
        _sphere(root, eye, 0.075, Vector3(0.18, 1.05, -0.32))
        _box(root, dark, Vector3(0.64, 0.12, 0.12), Vector3(0, 0.72, -0.25))

func _horn(parent: Node3D, pos: Vector3, angle: float) -> void:
    var mesh := CylinderMesh.new()
    mesh.top_radius = 0.0
    mesh.bottom_radius = 0.12
    mesh.height = 0.55
    mesh.radial_segments = 20
    var node := MeshInstance3D.new()
    node.mesh = mesh
    node.position = pos
    node.rotation_degrees.z = angle
    node.material_override = _mat(Color("#5a473e"), 0.1, 0.65)
    parent.add_child(node)

func _box(parent: Node3D, material: Material, size: Vector3, pos: Vector3) -> void:
    var node := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    node.mesh = mesh
    node.position = pos
    node.material_override = material
    parent.add_child(node)

func _sphere(parent: Node3D, color: Color, radius: float, pos: Vector3) -> void:
    var node := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = radius
    mesh.height = radius * 2.0
    mesh.radial_segments = 24
    mesh.rings = 12
    node.mesh = mesh
    node.position = pos
    node.material_override = _mat(color, 0.05, 0.4)
    parent.add_child(node)

func _mat(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.metallic = metallic
    material.roughness = roughness
    return material
