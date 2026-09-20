extends Node3D
## Prontera reference-detail pass. Adds dense authored geometry around the playable plaza.
const Teleport = preload("res://scripts/TeleportSystem.gd")
const SCALE := 0.055
const OX := 365.0
const OY := 120.0
var root: Node3D
var center := Vector3.ZERO

func _ready() -> void:
    process_priority = 920
    call_deferred("_build")

func _build() -> void:
    var legacy := get_parent().get_node_or_null("LegacyGame")
    if legacy == null:
        return
    var value: Variant = legacy.get("hero")
    var map_id := int((value as Dictionary).get("map_id", 0)) if value is Dictionary else 0
    if map_id != 0:
        return
    center = _world(Teleport.default_point(0))
    root = Node3D.new()
    root.name = "HWPronteraReferenceDetail"
    get_parent().add_child(root)
    _clear_center_obstructions()
    _build_plaza()
    _build_harbor()
    _build_market()
    _build_landmarks()
    _build_flowers_and_lamps()

func _clear_center_obstructions() -> void:
    var boost := get_parent().get_node_or_null("HWMapDetailBoost")
    if boost == null:
        return
    var boost_root := boost.get_node_or_null("HWMapDetailBoost_00")
    if boost_root == null:
        return
    for child in boost_root.get_children():
        if child is MeshInstance3D:
            var distance := Vector2(child.position.x - center.x, child.position.z - center.z).length()
            if distance < 8.0 and child.position.y > 0.4:
                child.visible = false

func _build_plaza() -> void:
    var stone := Color("c7c0ad")
    var light_stone := Color("e1dac6")
    root.add_child(_box(Vector3(30, 0.16, 22), center + Vector3(0, 0.12, 5), stone))
    for x in range(-14, 15, 2):
        for z in range(-4, 16, 2):
            var tile := _box(Vector3(1.75, 0.035, 1.75), center + Vector3(x, 0.22, z + 5), light_stone if (x + z) % 4 == 0 else stone.lightened(0.04))
            root.add_child(tile)
    _statue(center + Vector3(0, 0.25, 5))
    _fountain(center + Vector3(-7, 0.2, 10))
    _fountain(center + Vector3(7, 0.2, 10))

func _build_harbor() -> void:
    var water := Color("4d9fba")
    var wood := Color("6f4932")
    var dark := Color("3f2b22")
    root.add_child(_box(Vector3(25, 0.22, 18), center + Vector3(26, -0.02, 4), water))
    for i in range(7):
        var x := 15.0 + float(i) * 4.0
        root.add_child(_box(Vector3(3.3, 0.28, 1.0), center + Vector3(x, 0.18, -1), wood))
        root.add_child(_box(Vector3(0.22, 2.0, 0.22), center + Vector3(x - 1.2, 1.0, -1), dark))
        root.add_child(_box(Vector3(0.22, 2.0, 0.22), center + Vector3(x + 1.2, 1.0, -1), dark))
    for i in range(5):
        var z := -8.0 + float(i) * 6.0
        root.add_child(_box(Vector3(22, 0.22, 0.75), center + Vector3(26, 0.12, z), wood))
    _boat(center + Vector3(31, 0.3, 10), wood)

func _build_market() -> void:
    var wood := Color("7b5235")
    var cloth := Color("5e86ad")
    var red := Color("a74a3e")
    for i in range(5):
        var p := center + Vector3(-17 + float(i) * 8.5, 0, 17)
        root.add_child(_box(Vector3(5.0, 0.65, 2.5), p + Vector3(0, 0.33, 0), wood))
        root.add_child(_box(Vector3(5.5, 0.16, 3.0), p + Vector3(0, 2.35, 0), cloth if i % 2 == 0 else red))
        root.add_child(_box(Vector3(0.16, 2.3, 0.16), p + Vector3(-2.2, 1.2, -1.1), wood))
        root.add_child(_box(Vector3(0.16, 2.3, 0.16), p + Vector3(2.2, 1.2, -1.1), wood))
        _crate(p + Vector3(-1.2, 0.8, 0.3), wood)
        _crate(p + Vector3(1.2, 0.8, 0.3), wood)

func _build_landmarks() -> void:
    var stone := Color("9b968a")
    var roof := Color("68433b")
    var wall := Color("bda37d")
    var positions := [Vector3(-23,0,-15),Vector3(-11,0,-18),Vector3(2,0,-18),Vector3(15,0,-16),Vector3(-25,0,12),Vector3(20,0,14)]
    for i in range(positions.size()):
        _house(center + positions[i], wall, roof, stone, i)
    _arch(center + Vector3(0, 0, -24), stone)
    _banner(center + Vector3(-5, 0, -10), Color("9b3940"), "HONOUR")
    _banner(center + Vector3(5, 0, -10), Color("315b8a"), "WAR")

func _build_flowers_and_lamps() -> void:
    var flower_a := Color("d86f79")
    var flower_b := Color("e2b75f")
    var green := Color("4c7b4b")
    for i in range(20):
        var a := TAU * float(i) / 20.0
        var p := center + Vector3(cos(a) * 13.5, 0, 5 + sin(a) * 9.0)
        root.add_child(_cylinder(0.55, 0.18, p + Vector3(0, 0.09, 0), green))
        var flower := _sphere(flower_a if i % 2 == 0 else flower_b, 0.13)
        flower.position = p + Vector3(0, 0.3, 0)
        root.add_child(flower)
    for i in range(14):
        var p := center + Vector3(-14 + float(i) * 2.2, 0, -2)
        _lamp(p)

func _house(p: Vector3, wall: Color, roof: Color, stone: Color, index: int) -> void:
    root.add_child(_box(Vector3(7.0, 0.35, 5.8), p + Vector3(0, 0.18, 0), stone))
    root.add_child(_box(Vector3(6.5, 3.5, 5.2), p + Vector3(0, 2.0, 0), wall))
    var r := MeshInstance3D.new()
    var mesh := PrismMesh.new()
    mesh.size = Vector3(7.4, 2.2, 5.8)
    r.mesh = mesh
    r.position = p + Vector3(0, 5.1, 0)
    r.material_override = _mat(roof, 0.05, 0.7)
    root.add_child(r)
    root.add_child(_box(Vector3(0.9, 1.8, 0.15), p + Vector3(0, 0.95, 2.65), Color("4b3328")))
    for side in [-1.0, 1.0]:
        root.add_child(_box(Vector3(1.1, 0.85, 0.12), p + Vector3(side * 1.7, 1.9, 2.66), Color("75b7cf")))
    if index % 2 == 0:
        root.add_child(_box(Vector3(0.65, 1.7, 0.65), p + Vector3(1.7, 4.5, -1.0), stone))

func _statue(p: Vector3) -> void:
    var stone := Color("e4ded0")
    root.add_child(_cylinder(1.4, 0.45, p, Color("8f887a")))
    root.add_child(_cylinder(0.65, 2.6, p + Vector3(0, 1.5, 0), stone))
    var body := _sphere(stone, 0.75)
    body.position = p + Vector3(0, 3.3, 0)
    body.scale = Vector3(0.75, 1.25, 0.75)
    root.add_child(body)
    root.add_child(_cylinder(0.22, 2.2, p + Vector3(0.85, 3.0, 0), Color("bcae94")))

func _fountain(p: Vector3) -> void:
    root.add_child(_cylinder(2.0, 0.3, p, Color("a39c8e")))
    root.add_child(_cylinder(1.55, 0.08, p + Vector3(0, 0.22, 0), Color("63b6c9"), true))
    root.add_child(_cylinder(0.5, 1.3, p + Vector3(0, 0.8, 0), Color("d0c7b7")))
    root.add_child(_cylinder(0.12, 1.2, p + Vector3(0, 1.9, 0), Color("63b6c9"), true))

func _arch(p: Vector3, c: Color) -> void:
    root.add_child(_box(Vector3(1.4, 5.0, 1.5), p + Vector3(-4, 2.5, 0), c))
    root.add_child(_box(Vector3(1.4, 5.0, 1.5), p + Vector3(4, 2.5, 0), c))
    root.add_child(_box(Vector3(9.2, 1.2, 1.5), p + Vector3(0, 4.45, 0), c))

func _banner(p: Vector3, c: Color, text: String) -> void:
    root.add_child(_box(Vector3(0.12, 3.0, 0.12), p + Vector3(0, 1.5, 0), Color("4b3328")))
    root.add_child(_box(Vector3(1.3, 1.7, 0.08), p + Vector3(0, 2.1, 0), c))
    var label := Label3D.new()
    label.text = text
    label.font_size = 15
    label.outline_size = 5
    label.position = p + Vector3(0, 2.05, 0.08)
    root.add_child(label)

func _boat(p: Vector3, wood: Color) -> void:
    root.add_child(_box(Vector3(5.5, 0.55, 1.6), p, wood))
    root.add_child(_box(Vector3(0.22, 4.0, 0.22), p + Vector3(0, 2.1, 0), Color("4b3328")))

func _lamp(p: Vector3) -> void:
    root.add_child(_cylinder(0.1, 2.7, p + Vector3(0, 1.35, 0), Color("303238")))
    var glow := _sphere(Color("ffd477"), 0.2)
    glow.position = p + Vector3(0, 2.7, 0)
    glow.material_override = _mat(Color("ffd477"), 0, 0.12, true)
    root.add_child(glow)

func _crate(p: Vector3, c: Color) -> void:
    root.add_child(_box(Vector3(0.8, 0.75, 0.8), p + Vector3(0, 0.38, 0), c))

func _box(size: Vector3, p: Vector3, c: Color) -> MeshInstance3D:
    var n := MeshInstance3D.new()
    var m := BoxMesh.new()
    m.size = size
    n.mesh = m
    n.position = p
    n.material_override = _mat(c, 0, 0.76)
    return n

func _sphere(c: Color, r: float) -> MeshInstance3D:
    var n := MeshInstance3D.new()
    var m := SphereMesh.new()
    m.radius = r
    m.height = r * 2
    n.mesh = m
    n.material_override = _mat(c, 0, 0.65)
    return n

func _cylinder(r: float, h: float, p: Vector3, c: Color, glow: bool = false) -> MeshInstance3D:
    var n := MeshInstance3D.new()
    var m := CylinderMesh.new()
    m.top_radius = r
    m.bottom_radius = r
    m.height = h
    n.mesh = m
    n.position = p
    n.material_override = _mat(c, 0, 0.5 if glow else 0.78, glow)
    return n

func _mat(c: Color, metal: float, rough: float, glow: bool = false) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = c
    m.metallic = metal
    m.roughness = rough
    if glow:
        m.emission_enabled = true
        m.emission = c
        m.emission_energy_multiplier = 2.0
    return m

func _world(p: Vector2) -> Vector3:
    return Vector3((p.x - OX) * SCALE, 0, (p.y - OY) * SCALE)
