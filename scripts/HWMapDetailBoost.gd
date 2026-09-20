extends Node3D
## Dense map-detail booster. Runs alongside the existing native world system.
const Teleport = preload("res://scripts/TeleportSystem.gd")
const SCALE := 0.055
const OX := 365.0
const OY := 120.0
var legacy: Node
var root: Node3D
var last_map := -999
var center := Vector3.ZERO

func _ready() -> void:
    process_priority = 900
    legacy = get_parent().get_node_or_null("LegacyGame")
    call_deferred("_rebuild")

func _process(_delta: float) -> void:
    if legacy == null:
        legacy = get_parent().get_node_or_null("LegacyGame")
    if legacy == null:
        return
    var value: Variant = legacy.get("hero")
    if value is Dictionary:
        var map_id := int((value as Dictionary).get("map_id", 0))
        if map_id != last_map:
            _rebuild()

func _rebuild() -> void:
    var value: Variant = legacy.get("hero") if legacy else null
    var map_id := int((value as Dictionary).get("map_id", 0)) if value is Dictionary else 0
    last_map = map_id
    center = _world(Teleport.default_point(map_id))
    if root != null and is_instance_valid(root):
        root.queue_free()
    root = Node3D.new()
    root.name = "HWMapDetailBoost_%02d" % map_id
    get_parent().add_child(root)
    var kind := str(Teleport.MAPS.get(map_id, {}).get("type", "town"))
    var theme := _theme(map_id)
    _terrain_accents(theme)
    if kind == "town":
        _town_detail(theme, map_id)
    elif kind == "field":
        _field_detail(theme, map_id)
    else:
        _dungeon_detail(theme, map_id)
    _identity_detail(theme, map_id)

func _terrain_accents(t: Dictionary) -> void:
    for i in range(44):
        var p := center + Vector3(_pos(i, 34.0), 0.05, _pos(i + 100, 24.0))
        var rock := _sphere(t.stone, 0.12 + float(i % 4) * 0.07)
        rock.position = p
        rock.scale = Vector3(1.3, 0.55, 0.9)
        root.add_child(rock)

func _town_detail(t: Dictionary, map_id: int) -> void:
    var plaza := _cylinder(6.8, 0.18, center + Vector3(0, 0.16, 5), t.stone)
    root.add_child(plaza)
    for i in range(20):
        var a := TAU * float(i) / 20.0
        var tile := _box(Vector3(0.5, 0.07, 2.8), center + Vector3(cos(a) * 4.7, 0.28, 5 + sin(a) * 4.7), t.trim)
        tile.rotation.y = -a
        root.add_child(tile)
    for i in range(12):
        var a := TAU * float(i) / 12.0
        _tree(center + Vector3(cos(a) * 27.0, 0, sin(a) * 19.0), t, i)
    for i in range(10):
        _lamp(center + Vector3(-22 + float(i) * 4.8, 0, 15), t.light)
    _wall_gate(center + Vector3(0, 0, -25), t, Teleport.map_name(map_id))

func _field_detail(t: Dictionary, map_id: int) -> void:
    for i in range(50):
        _grass(center + Vector3(_pos(i + 200, 31), 0, _pos(i + 300, 22)), t, i)
    for i in range(22):
        _tree(center + Vector3(_pos(i + 400, 30), 0, _pos(i + 500, 21)), t, i)
    for i in range(18):
        _fence(center + Vector3(-21, 0, -22 + float(i) * 2.7), t.wood)
    var town := Teleport.town_for_field(map_id)
    if town >= 0:
        _wall_gate(center + Vector3(0, 0, -24), t, "ROAD TO " + Teleport.map_name(town))

func _dungeon_detail(t: Dictionary, _map_id: int) -> void:
    for i in range(18):
        var p := center + Vector3(_pos(i + 700, 29), 0, _pos(i + 800, 20))
        _column(p, t.stone, 2.2 + float(i % 4) * 0.4)
    for i in range(18):
        var p := center + Vector3(_pos(i + 900, 27), 0, _pos(i + 1000, 19))
        _torch(p, t.fire, t.stone_dark)
    for i in range(16):
        var p := center + Vector3(_pos(i + 1100, 27), 0, _pos(i + 1200, 19))
        _crystal(p, t.magic, i)

func _identity_detail(t: Dictionary, map_id: int) -> void:
    var name := Teleport.map_name(map_id).to_lower()
    if name.find("desert") >= 0 or name.find("morroc") >= 0:
        for i in range(18):
            _cactus(center + Vector3(_pos(i + 1400, 30), 0, _pos(i + 1500, 21)), t, i)
    elif name.find("coast") >= 0 or name.find("izlude") >= 0 or name.find("alberta") >= 0:
        _water(t)
    elif name.find("forest") >= 0 or name.find("jungle") >= 0 or name.find("wilds") >= 0 or name.find("payon") >= 0:
        for i in range(18):
            _fern(center + Vector3(_pos(i + 1600, 30), 0, _pos(i + 1700, 21)), t)
    elif name.find("snow") >= 0 or name.find("ice") >= 0 or name.find("lutie") >= 0:
        for i in range(20):
            var snow := _sphere(t.snow, 0.35 + float(i % 3) * 0.12)
            snow.position = center + Vector3(_pos(i + 1800, 29), 0.25, _pos(i + 1900, 20))
            root.add_child(snow)

func _tree(p: Vector3, t: Dictionary, index: int) -> void:
    var h := 2.8 + float(index % 4) * 0.45
    root.add_child(_cylinder(0.42, h, p + Vector3(0, h * 0.5, 0), t.wood_dark))
    for j in range(3):
        var crown := _sphere(t.foliage if j == 0 else t.foliage_light, 1.25 - float(j) * 0.14)
        crown.position = p + Vector3((float(j) - 1.0) * 0.65, h + 0.55 + float(j) * 0.32, 0)
        crown.scale = Vector3(1.2, 0.85, 1.0)
        root.add_child(crown)

func _grass(p: Vector3, t: Dictionary, index: int) -> void:
    for j in range(5):
        var blade := _box(Vector3(0.07, 0.4 + float(j % 3) * 0.12, 0.1), p + Vector3(float(j - 2) * 0.12, 0.22, 0), t.grass)
        blade.rotation.z = -0.22 + float(j) * 0.1
        root.add_child(blade)

func _fence(p: Vector3, c: Color) -> void:
    root.add_child(_box(Vector3(0.18, 1.4, 0.18), p + Vector3(0, 0.7, 0), c))
    root.add_child(_box(Vector3(2.7, 0.12, 0.12), p + Vector3(0, 0.95, 0), c))

func _lamp(p: Vector3, c: Color) -> void:
    root.add_child(_cylinder(0.1, 2.5, p + Vector3(0, 1.25, 0), Color("353238")))
    var glow := _sphere(c, 0.22)
    glow.position = p + Vector3(0, 2.55, 0)
    glow.material_override = _mat(c, 0, 0.15, true)
    root.add_child(glow)

func _wall_gate(p: Vector3, t: Dictionary, text: String) -> void:
    root.add_child(_box(Vector3(1.3, 4.8, 1.4), p + Vector3(-4, 2.4, 0), t.stone))
    root.add_child(_box(Vector3(1.3, 4.8, 1.4), p + Vector3(4, 2.4, 0), t.stone))
    root.add_child(_box(Vector3(9.4, 1.1, 1.4), p + Vector3(0, 4.35, 0), t.stone))
    var label := Label3D.new()
    label.text = text.to_upper()
    label.font_size = 22
    label.outline_size = 7
    label.modulate = t.sign
    label.position = p + Vector3(0, 5.1, 0)
    root.add_child(label)

func _column(p: Vector3, c: Color, h: float) -> void:
    root.add_child(_cylinder(0.46, h, p + Vector3(0, h * 0.5, 0), c))
    root.add_child(_cylinder(0.62, 0.16, p + Vector3(0, h + 0.08, 0), c.lightened(0.1)))

func _torch(p: Vector3, fire: Color, stone: Color) -> void:
    root.add_child(_box(Vector3(0.14, 1.4, 0.14), p + Vector3(0, 0.7, 0), stone))
    var flame := _sphere(fire, 0.23)
    flame.position = p + Vector3(0, 1.55, 0)
    flame.material_override = _mat(fire, 0, 0.12, true)
    root.add_child(flame)

func _crystal(p: Vector3, c: Color, index: int) -> void:
    var crystal := _cylinder(0.2, 0.8 + float(index % 4) * 0.2, p + Vector3(0, 0.5, 0), c, true)
    crystal.rotation_degrees = Vector3(float(index % 2) * 10, float(index) * 23, 0)
    root.add_child(crystal)

func _cactus(p: Vector3, t: Dictionary, index: int) -> void:
    root.add_child(_cylinder(0.18, 1.5 + float(index % 3) * 0.35, p + Vector3(0, 0.75, 0), t.cactus))
    if index % 2 == 0:
        root.add_child(_cylinder(0.1, 0.7, p + Vector3(0.35, 1.0, 0), t.cactus))

func _fern(p: Vector3, t: Dictionary) -> void:
    for j in range(5):
        var leaf := _box(Vector3(0.08, 0.85, 0.16), p + Vector3(0, 0.42, 0), t.foliage_light)
        leaf.rotation_degrees = Vector3(0, float(j) * 72, -22 + float(j) * 9)
        root.add_child(leaf)

func _water(t: Dictionary) -> void:
    var water := _box(Vector3(32, 0.18, 13), center + Vector3(0, -0.02, 23), t.water)
    water.material_override = _mat(t.water, 0, 0.1, true)
    root.add_child(water)
    for x in range(-14, 15, 4):
        root.add_child(_box(Vector3(3.2, 0.22, 0.7), center + Vector3(x, 0.12, 18), t.wood_dark))

func _box(size: Vector3, p: Vector3, c: Color) -> MeshInstance3D:
    var n := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    n.mesh = mesh
    n.position = p
    n.material_override = _mat(c, 0, 0.78)
    return n

func _sphere(c: Color, r: float) -> MeshInstance3D:
    var n := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = r
    mesh.height = r * 2
    n.mesh = mesh
    n.material_override = _mat(c, 0, 0.72)
    return n

func _cylinder(r: float, h: float, p: Vector3, c: Color, glow: bool = false) -> MeshInstance3D:
    var n := MeshInstance3D.new()
    var mesh := CylinderMesh.new()
    mesh.top_radius = r
    mesh.bottom_radius = r * 1.08
    mesh.height = h
    n.mesh = mesh
    n.position = p
    n.material_override = _mat(c, 0, 0.42 if glow else 0.78, glow)
    return n

func _mat(c: Color, metal: float, rough: float, glow: bool = false) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = c
    m.metallic = metal
    m.roughness = rough
    if glow:
        m.emission_enabled = true
        m.emission = c
        m.emission_energy_multiplier = 2.2
    return m

func _theme(id: int) -> Dictionary:
    var name := Teleport.map_name(id).to_lower()
    var t: Dictionary = {"stone":Color("a99e8d"),"stone_dark":Color("4c4744"),"wood":Color("815b3e"),"wood_dark":Color("4b3327"),"ground":Color("5d7147"),"foliage":Color("315f3b"),"foliage_light":Color("5f8a45"),"grass":Color("6e9848"),"variation":Color("7f8d58"),"earth":Color("4f5f3d"),"road":Color("a18a6b"),"path":Color("806d56"),"curb":Color("706454"),"wall":Color("b98f67"),"trim":Color("d1b48a"),"roof":Color("6a3f36"),"foundation":Color("746351"),"wall_dark":Color("5d5148"),"window":Color("82c9dc"),"water":Color("3b9fbd"),"magic":Color("73dfff"),"fire":Color("ff9a45"),"light":Color("ffd878"),"accent":Color("d5ad5d"),"banner":Color("9b3c3c"),"sign":Color("fff0b2"),"cactus":Color("4f8d4e"),"snow":Color("dbe7ef")}
    if name.find("geffen") >= 0:
        t.wall = Color("8a6fc0")
        t.trim = Color("c0a5e5")
        t.accent = Color("b7a3ff")
    elif name.find("morroc") >= 0 or name.find("desert") >= 0:
        t.ground = Color("c39a60")
        t.variation = Color("e0b97a")
        t.wall = Color("c28b58")
        t.roof = Color("70462f")
    elif name.find("coast") >= 0 or name.find("izlude") >= 0 or name.find("alberta") >= 0:
        t.ground = Color("5c805d")
        t.water = Color("2e9fc5")
        t.roof = Color("405f73")
    elif name.find("forest") >= 0 or name.find("payon") >= 0:
        t.foliage = Color("234d36")
        t.foliage_light = Color("4f8147")
    elif name.find("jungle") >= 0 or name.find("wilds") >= 0:
        t.ground = Color("385b3c")
        t.foliage = Color("173f2e")
    elif name.find("snow") >= 0 or name.find("ice") >= 0 or name.find("lutie") >= 0:
        t.ground = Color("b7cbd6")
        t.variation = Color("e1ebf0")
        t.road = Color("9eacb3")
        t.roof = Color("5f6f7e")
        t.snow = Color("f5fbff")
    elif name.find("umbala") >= 0:
        t.wall = Color("9b6d46")
        t.roof = Color("4c723c")
        t.banner = Color("5f8f48")
    elif name.find("clock") >= 0:
        t.stone = Color("716f68")
        t.stone_dark = Color("35383a")
        t.accent = Color("d3a64d")
    elif name.find("ship") >= 0:
        t.stone_dark = Color("27383c")
        t.wood = Color("75492f")
        t.wood_dark = Color("3e291f")
    elif name.find("sewer") >= 0 or name.find("catacomb") >= 0:
        t.stone = Color("666c69")
        t.stone_dark = Color("282b2c")
        t.magic = Color("7de5a7")
    return t

func _pos(index: int, extent: float) -> float:
    var x := float((index * 97 + 17) % 1000) / 1000.0
    return (x * 2.0 - 1.0) * extent

func _world(p: Vector2) -> Vector3:
    return Vector3((p.x - OX) * SCALE, 0, (p.y - OY) * SCALE)
