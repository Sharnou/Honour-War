extends Node3D
## Honour War HD Detail Pass vNext.
## Original native Godot geometry/material pass: dense readable 3D detail without
## external model formats, reference-image pasting, or gameplay-state ownership.
##
## This layer supplements the existing map systems. It is deliberately authored
## from reusable fantasy-MMORPG construction primitives so every visible frame
## gains primary, secondary and tertiary information instead of a flat template.

const ROOT_NAME := "HWHDDetailPassVNext"
const Teleport = preload("res://scripts/TeleportSystem.gd")
const SCALE := 0.055
const OX := 365.0
const OY := 120.0

var scene_root: Node3D
var legacy: Node
var root: Node3D
var built_map := -999
var elapsed := 0.0

func _ready() -> void:
    process_priority = 935
    scene_root = get_parent() as Node3D
    legacy = scene_root.get_node_or_null("LegacyGame") if scene_root != null else null
    call_deferred("_rebuild")

func _process(delta: float) -> void:
    elapsed += delta
    if elapsed < 0.5:
        return
    elapsed = 0.0
    if legacy == null and scene_root != null:
        legacy = scene_root.get_node_or_null("LegacyGame")
    if legacy == null:
        return
    var hero_value: Variant = legacy.get("hero")
    if hero_value is Dictionary:
        var map_id := int((hero_value as Dictionary).get("map_id", 0))
        if map_id != built_map:
            _rebuild()

func _rebuild() -> void:
    if scene_root == null or legacy == null:
        return
    var hero_value: Variant = legacy.get("hero")
    var map_id := int((hero_value as Dictionary).get("map_id", 0)) if hero_value is Dictionary else 0
    built_map = map_id

    if root != null and is_instance_valid(root):
        root.queue_free()

    root = Node3D.new()
    root.name = ROOT_NAME + "_%02d" % map_id
    scene_root.add_child(root)

    var center := _world(Teleport.default_point(map_id))
    var kind := str(Teleport.MAPS.get(map_id, {}).get("type", "town"))
    var theme := _theme(map_id)

    _build_ground_frame(center, theme)
    if kind == "town":
        _build_town(center, theme, map_id)
    elif kind == "field":
        _build_field(center, theme, map_id)
    else:
        _build_dungeon(center, theme, map_id)

func _build_ground_frame(center: Vector3, t: Dictionary) -> void:
    # Layered ground seams make the camera read a constructed environment rather
    # than one large plane.
    for z in [-15.0, -7.5, 0.0, 7.5, 15.0]:
        var seam := _box(Vector3(58.0, 0.035, 0.12), center + Vector3(0, 0.035, z), t.ground_dark)
        root.add_child(seam)
    for x in [-22.0, -11.0, 0.0, 11.0, 22.0]:
        var seam := _box(Vector3(0.12, 0.038, 40.0), center + Vector3(x, 0.038, 0), t.ground_variation)
        root.add_child(seam)

func _build_town(center: Vector3, t: Dictionary, map_id: int) -> void:
    _build_main_avenue(center, t)
    _build_city_block(center + Vector3(-16, 0, -11), t, 0)
    _build_city_block(center + Vector3(16, 0, -11), t, 1)
    _build_city_block(center + Vector3(-17, 0, 12), t, 2)
    _build_city_block(center + Vector3(17, 0, 12), t, 3)
    _build_market_row(center, t)
    _build_city_gate(center + Vector3(0, 0, -23), t, Teleport.map_name(map_id))
    _build_street_furniture(center, t)
    _build_tree_groves(center, t)
    if map_id == 0:
        _build_prontera_landmark(center, t)
    if _is_coastal(map_id):
        _build_docks(center, t)

func _build_main_avenue(center: Vector3, t: Dictionary) -> void:
    var road := _box(Vector3(8.0, 0.08, 43.0), center + Vector3(0, 0.05, 0), t.road)
    root.add_child(road)
    for z in range(-20, 21, 4):
        var curb_l := _box(Vector3(0.22, 0.18, 3.6), center + Vector3(-4.25, 0.15, z), t.curb)
        var curb_r := _box(Vector3(0.22, 0.18, 3.6), center + Vector3(4.25, 0.15, z), t.curb)
        root.add_child(curb_l)
        root.add_child(curb_r)
        for side in [-1.0, 1.0]:
            var paver := _box(Vector3(3.2, 0.06, 0.48), center + Vector3(side * 6.1, 0.12, z), t.paving)
            root.add_child(paver)

func _build_city_block(p: Vector3, t: Dictionary, variant: int) -> void:
    var wall: Color = t["wall"] if variant % 2 == 0 else t["wall_alt"]
    var roof: Color = t["roof"] if variant != 2 else t["roof_alt"]
    _build_house(p + Vector3(-3.7, 0, 0), wall, roof, t, 0)
    _build_house(p + Vector3(3.7, 0, 0), wall.lightened(0.035), roof, t, 1)
    _build_house(p + Vector3(0, 0, -5.0), wall.darkened(0.04), roof.lightened(0.04), t, 2)
    _build_small_garden(p + Vector3(0, 0, 4.7), t, variant)

func _build_house(p: Vector3, wall: Color, roof: Color, t: Dictionary, variant: int) -> void:
    var foundation := _box(Vector3(6.8, 0.28, 5.6), p + Vector3(0, 0.14, 0), t.foundation)
    root.add_child(foundation)
    var body := _box(Vector3(6.25, 3.25, 5.1), p + Vector3(0, 1.78, 0), wall)
    root.add_child(body)

    # Structural trim breaks up the large wall surfaces.
    for x in [-2.75, 0.0, 2.75]:
        var beam := _box(Vector3(0.16, 3.2, 0.18), p + Vector3(x, 1.8, -2.58), t.trim_dark)
        root.add_child(beam)
    var sill := _box(Vector3(6.0, 0.15, 0.22), p + Vector3(0, 2.95, -2.60), t.trim)
    root.add_child(sill)

    # Two-story windows with frames and glass.
    for x in [-1.65, 1.65]:
        _window(p + Vector3(x, 1.85, -2.64), t)
        if variant % 2 == 0:
            _window(p + Vector3(x, 2.78, -2.64), t)

    var door := _box(Vector3(0.95, 1.85, 0.18), p + Vector3(0, 0.96, -2.66), t.door)
    root.add_child(door)
    root.add_child(_box(Vector3(1.15, 0.13, 0.25), p + Vector3(0, 1.93, -2.68), t.trim))

    # Layered roof with ridge cap and eaves.
    var roof_base := _prism(Vector3(6.9, 2.0, 5.8), p + Vector3(0, 4.30, 0), roof)
    root.add_child(roof_base)
    var ridge := _box(Vector3(6.1, 0.22, 0.32), p + Vector3(0, 5.38, 0), t.roof_trim)
    root.add_child(ridge)
    for x in [-2.7, 2.7]:
        root.add_child(_box(Vector3(0.25, 0.18, 5.9), p + Vector3(x, 3.85, 0), t.roof_trim))

    if variant == 1:
        _build_chimney(p + Vector3(1.7, 0, -0.8), t)
    elif variant == 2:
        _build_banner(p + Vector3(-2.2, 0, -2.9), t.banner_a, "H")
    else:
        _build_flower_box(p + Vector3(0, 0, -2.86), t)

func _window(p: Vector3, t: Dictionary) -> void:
    root.add_child(_box(Vector3(1.35, 1.05, 0.10), p, t.window_frame))
    root.add_child(_box(Vector3(0.92, 0.70, 0.12), p + Vector3(0, 0, -0.08), t.window))
    root.add_child(_box(Vector3(0.07, 0.72, 0.15), p + Vector3(0, 0, -0.16), t.window_frame))
    root.add_child(_box(Vector3(0.95, 0.07, 0.15), p + Vector3(0, 0, -0.16), t.window_frame))

func _build_chimney(p: Vector3, t: Dictionary) -> void:
    root.add_child(_box(Vector3(0.7, 1.4, 0.7), p + Vector3(0, 4.65, 0), t.chimney))
    root.add_child(_box(Vector3(0.9, 0.12, 0.9), p + Vector3(0, 5.36, 0), t.chimney_cap))

func _build_flower_box(p: Vector3, t: Dictionary) -> void:
    root.add_child(_box(Vector3(1.5, 0.28, 0.42), p + Vector3(0, 0.28, 0), t.wood_dark))
    for x in [-0.52, 0.0, 0.52]:
        var flower := _sphere(t.flower_a if int((x + 1.0) * 10) % 2 == 0 else t.flower_b, 0.11)
        flower.position = p + Vector3(x, 0.55, 0)
        root.add_child(flower)
        root.add_child(_sphere(t.foliage_light, 0.10).duplicate())

func _build_small_garden(p: Vector3, t: Dictionary, variant: int) -> void:
    for x in [-2.0, -0.7, 0.7, 2.0]:
        var planter := _box(Vector3(0.8, 0.24, 0.5), p + Vector3(x, 0.12, 0), t.foundation)
        root.add_child(planter)
        var shrub := _sphere(t.foliage_light if variant % 2 == 0 else t.foliage, 0.30)
        shrub.position = p + Vector3(x, 0.48, 0)
        shrub.scale = Vector3(1.0, 0.7, 0.8)
        root.add_child(shrub)

func _build_market_row(center: Vector3, t: Dictionary) -> void:
    for i in range(6):
        var x := -15.0 + float(i) * 6.0
        var p := center + Vector3(x, 0, 18.0)
        root.add_child(_box(Vector3(4.5, 0.48, 2.1), p + Vector3(0, 0.24, 0), t.market_wood))
        root.add_child(_box(Vector3(4.9, 0.16, 2.6), p + Vector3(0, 2.35, 0), t.market_cloth_a if i % 2 == 0 else t.market_cloth_b))
        for side in [-2.0, 2.0]:
            root.add_child(_box(Vector3(0.14, 2.3, 0.14), p + Vector3(side, 1.2, 0.0), t.market_wood_dark))
        _crate(p + Vector3(-1.25, 0, 0.35), t)
        _crate(p + Vector3(1.20, 0, 0.35), t)
        _barrel(p + Vector3(0, 0, -0.35), t)
        _lamp(p + Vector3(0, 0, -1.45), t)

func _build_city_gate(p: Vector3, t: Dictionary, title: String) -> void:
    root.add_child(_box(Vector3(1.5, 6.0, 1.8), p + Vector3(-4.0, 3.0, 0), t.stone))
    root.add_child(_box(Vector3(1.5, 6.0, 1.8), p + Vector3(4.0, 3.0, 0), t.stone))
    root.add_child(_box(Vector3(9.6, 1.35, 1.8), p + Vector3(0, 5.55, 0), t.stone))
    root.add_child(_box(Vector3(8.4, 0.35, 1.5), p + Vector3(0, 6.30, 0), t.trim))
    _build_banner(p + Vector3(-2.4, 0, -0.95), t.banner_a, "HONOUR")
    _build_banner(p + Vector3(2.4, 0, -0.95), t.banner_b, "WAR")

func _build_banner(p: Vector3, color: Color, text: String) -> void:
    root.add_child(_box(Vector3(0.10, 2.7, 0.10), p + Vector3(0, 1.35, 0), Color("#473126")))
    root.add_child(_box(Vector3(1.2, 1.55, 0.08), p + Vector3(0, 2.05, 0), color))
    var label := Label3D.new()
    label.text = text
    label.font_size = 14
    label.outline_size = 4
    label.modulate = Color("#fff0c2")
    label.position = p + Vector3(0, 2.02, -0.06)
    root.add_child(label)

func _build_street_furniture(center: Vector3, t: Dictionary) -> void:
    for z in range(-17, 18, 7):
        for side in [-1.0, 1.0]:
            _lamp(center + Vector3(side * 5.6, 0, z), t)
            _bench(center + Vector3(side * 7.7, 0, z + 1.6), t)
    for i in range(16):
        var p := center + Vector3(_hash(i, 25), 0, _hash(i + 40, 17))
        _crate(p, t)

func _build_tree_groves(center: Vector3, t: Dictionary) -> void:
    for i in range(24):
        var p := center + Vector3(_hash(i + 90, 27), 0, _hash(i + 130, 19))
        if p.distance_to(center) < 9.0:
            continue
        _tree(p, t, i)

func _build_prontera_landmark(center: Vector3, t: Dictionary) -> void:
    var p := center + Vector3(0, 0, 5)
    root.add_child(_cylinder(3.3, 0.30, p + Vector3(0, 0.16, 0), t.foundation))
    root.add_child(_cylinder(2.65, 0.16, p + Vector3(0, 0.36, 0), t.water, true))
    root.add_child(_cylinder(0.55, 2.5, p + Vector3(0, 1.65, 0), t.stone))
    root.add_child(_sphere(t.magic, 0.45).duplicate())
    var crown := _sphere(t.stone_light, 0.82)
    crown.position = p + Vector3(0, 3.25, 0)
    crown.scale = Vector3(0.75, 1.2, 0.75)
    root.add_child(crown)
    _build_banner(p + Vector3(-1.5, 0, 0), t.banner_a, "HW")

func _build_docks(center: Vector3, t: Dictionary) -> void:
    var water := _box(Vector3(30, 0.14, 12), center + Vector3(22, -0.01, 8), t.water)
    water.material_override = _mat(t.water, 0.05, 0.12, true)
    root.add_child(water)
    for i in range(8):
        var x := 10.0 + float(i) * 3.4
        root.add_child(_box(Vector3(2.8, 0.22, 0.8), center + Vector3(x, 0.12, 1.5), t.wood_dark))
        root.add_child(_box(Vector3(0.18, 1.8, 0.18), center + Vector3(x - 1.1, 0.9, 1.5), t.wood_dark))
        root.add_child(_box(Vector3(0.18, 1.8, 0.18), center + Vector3(x + 1.1, 0.9, 1.5), t.wood_dark))
    _boat(center + Vector3(27, 0.32, 10), t)

func _build_field(center: Vector3, t: Dictionary, map_id: int) -> void:
    for i in range(36):
        var p := center + Vector3(_hash(i, 28), 0, _hash(i + 60, 18))
        _tree(p, t, i)
    for i in range(75):
        var p := center + Vector3(_hash(i + 160, 30), 0, _hash(i + 240, 19))
        _grass_clump(p, t, i)
    for i in range(18):
        var p := center + Vector3(_hash(i + 300, 29), 0, _hash(i + 390, 18))
        _rock_cluster(p, t, i)
    for i in range(16):
        var p := center + Vector3(-24.0, 0, -18.0 + float(i) * 2.35)
        _fence(p, t)
    _build_road_marker(center, t, "ROAD TO " + Teleport.map_name(Teleport.town_for_field(map_id)))

func _build_dungeon(center: Vector3, t: Dictionary, _map_id: int) -> void:
    for i in range(28):
        var p := center + Vector3(_hash(i, 28), 0, _hash(i + 50, 18))
        _column_cluster(p, t, i)
    for i in range(26):
        var p := center + Vector3(_hash(i + 100, 27), 0, _hash(i + 160, 18))
        _torch_cluster(p, t, i)
    for i in range(18):
        var p := center + Vector3(_hash(i + 220, 26), 0, _hash(i + 280, 18))
        _crystal_cluster(p, t, i)
    _build_dungeon_altar(center + Vector3(0, 0, -7), t)
    _build_dungeon_arch(center + Vector3(0, 0, -21), t)

func _tree(p: Vector3, t: Dictionary, index: int) -> void:
    var h := 2.7 + float(index % 5) * 0.35
    root.add_child(_cylinder(0.38, h, p + Vector3(0, h * 0.5, 0), t.wood_dark))
    for j in range(4):
        var c := _sphere(t.foliage if j % 2 == 0 else t.foliage_light, 1.18 - float(j) * 0.10)
        c.position = p + Vector3((float(j % 2) - 0.5) * 0.75, h + 0.35 + float(j) * 0.38, (float(j / 2) - 0.5) * 0.6)
        c.scale = Vector3(1.2, 0.78, 1.0)
        root.add_child(c)
    if index % 3 == 0:
        root.add_child(_box(Vector3(0.11, 1.0, 0.11), p + Vector3(0.55, h + 0.4, 0), t.wood_dark))

func _grass_clump(p: Vector3, t: Dictionary, index: int) -> void:
    for j in range(7):
        var blade := _box(Vector3(0.055, 0.34 + float((index + j) % 3) * 0.12, 0.10), p + Vector3(float(j - 3) * 0.09, 0.20, float((j % 2) - 0.5) * 0.10), t.grass)
        blade.rotation.z = -0.28 + float(j) * 0.09
        root.add_child(blade)

func _rock_cluster(p: Vector3, t: Dictionary, index: int) -> void:
    for j in range(3):
        var rock := _sphere(t.stone_dark if j == 0 else t.stone, 0.22 + float((index + j) % 4) * 0.10)
        rock.position = p + Vector3(float(j) * 0.35, 0.25, float(j % 2) * 0.28)
        rock.scale = Vector3(1.35, 0.75, 0.95)
        root.add_child(rock)

func _fence(p: Vector3, t: Dictionary) -> void:
    root.add_child(_box(Vector3(0.18, 1.35, 0.18), p + Vector3(0, 0.68, 0), t.wood))
    root.add_child(_box(Vector3(2.5, 0.12, 0.12), p + Vector3(0, 0.92, 0), t.wood))
    root.add_child(_box(Vector3(2.5, 0.12, 0.12), p + Vector3(0, 0.55, 0), t.wood_dark))

func _column_cluster(p: Vector3, t: Dictionary, index: int) -> void:
    var h := 2.2 + float(index % 5) * 0.38
    root.add_child(_cylinder(0.42, h, p + Vector3(0, h * 0.5, 0), t.stone))
    root.add_child(_cylinder(0.62, 0.16, p + Vector3(0, h + 0.08, 0), t.stone_light))
    if index % 2 == 0:
        root.add_child(_box(Vector3(1.4, 0.18, 0.18), p + Vector3(0, h * 0.62, 0), t.stone_dark))

func _torch_cluster(p: Vector3, t: Dictionary, index: int) -> void:
    root.add_child(_box(Vector3(0.13, 1.5, 0.13), p + Vector3(0, 0.75, 0), t.wood_dark))
    var flame := _sphere(t.fire, 0.22 + float(index % 3) * 0.04)
    flame.position = p + Vector3(0, 1.62, 0)
    flame.material_override = _mat(t.fire, 0.0, 0.14, true)
    root.add_child(flame)
    var light := OmniLight3D.new()
    light.light_color = t.fire
    light.light_energy = 0.65
    light.omni_range = 4.0
    light.position = p + Vector3(0, 1.5, 0)
    root.add_child(light)

func _crystal_cluster(p: Vector3, t: Dictionary, index: int) -> void:
    for j in range(3):
        var crystal := _cylinder(0.13, 0.65 + float((index + j) % 4) * 0.22, p + Vector3(float(j - 1) * 0.28, 0.42, 0), t.magic, true)
        crystal.rotation_degrees = Vector3(7.0 * j, float(index * 21 + j * 17), -4.0 * j)
        root.add_child(crystal)

func _build_dungeon_altar(p: Vector3, t: Dictionary) -> void:
    root.add_child(_cylinder(2.0, 0.22, p + Vector3(0, 0.11, 0), t.stone_dark))
    root.add_child(_cylinder(1.5, 0.16, p + Vector3(0, 0.30, 0), t.magic, true))
    root.add_child(_cylinder(0.30, 2.2, p + Vector3(0, 1.25, 0), t.stone_light))
    var orb := _sphere(t.magic, 0.40)
    orb.position = p + Vector3(0, 2.55, 0)
    orb.material_override = _mat(t.magic, 0, 0.10, true)
    root.add_child(orb)

func _build_dungeon_arch(p: Vector3, t: Dictionary) -> void:
    root.add_child(_box(Vector3(1.5, 5.2, 1.6), p + Vector3(-4, 2.6, 0), t.stone_dark))
    root.add_child(_box(Vector3(1.5, 5.2, 1.6), p + Vector3(4, 2.6, 0), t.stone_dark))
    root.add_child(_box(Vector3(9.5, 1.0, 1.6), p + Vector3(0, 5.1, 0), t.stone_dark))
    var portal := _ring(t.magic, 2.0, 2.08)
    portal.position = p + Vector3(0, 2.7, -0.05)
    root.add_child(portal)

func _build_road_marker(center: Vector3, t: Dictionary, title: String) -> void:
    _build_banner(center + Vector3(0, 0, -22), t.banner_a, title)

func _bench(p: Vector3, t: Dictionary) -> void:
    root.add_child(_box(Vector3(2.0, 0.18, 0.55), p + Vector3(0, 0.65, 0), t.wood))
    root.add_child(_box(Vector3(0.16, 0.70, 0.16), p + Vector3(-0.72, 0.35, 0), t.wood_dark))
    root.add_child(_box(Vector3(0.16, 0.70, 0.16), p + Vector3(0.72, 0.35, 0), t.wood_dark))

func _build_bench(p: Vector3, t: Dictionary) -> void:
    root.add_child(_box(Vector3(2.0, 0.18, 0.55), p + Vector3(0, 0.65, 0), t.wood))
    root.add_child(_box(Vector3(0.16, 0.70, 0.16), p + Vector3(-0.72, 0.35, 0), t.wood_dark))
    root.add_child(_box(Vector3(0.16, 0.70, 0.16), p + Vector3(0.72, 0.35, 0), t.wood_dark))

func _lamp(p: Vector3, t: Dictionary) -> void:
    root.add_child(_cylinder(0.10, 2.5, p + Vector3(0, 1.25, 0), t.metal))
    var cap := _box(Vector3(0.44, 0.10, 0.44), p + Vector3(0, 2.55, 0), t.metal)
    root.add_child(cap)
    var glow := _sphere(t.light, 0.17)
    glow.position = p + Vector3(0, 2.35, 0)
    glow.material_override = _mat(t.light, 0.0, 0.10, true)
    root.add_child(glow)
    var light := OmniLight3D.new()
    light.light_color = t.light
    light.light_energy = 0.45
    light.omni_range = 4.5
    light.position = p + Vector3(0, 2.25, 0)
    root.add_child(light)

func _crate(p: Vector3, t: Dictionary) -> void:
    root.add_child(_box(Vector3(0.82, 0.72, 0.82), p + Vector3(0, 0.36, 0), t.crate))
    for side in [-1.0, 1.0]:
        root.add_child(_box(Vector3(0.08, 0.76, 0.88), p + Vector3(side * 0.30, 0.36, 0), t.crate_trim))
        root.add_child(_box(Vector3(0.88, 0.08, 0.88), p + Vector3(0, 0.36 + side * 0.28, 0), t.crate_trim))

func _barrel(p: Vector3, t: Dictionary) -> void:
    root.add_child(_cylinder(0.42, 0.82, p + Vector3(0, 0.41, 0), t.barrel))
    for y in [0.25, 0.62]:
        root.add_child(_ring(t.barrel_trim, 0.43, 0.47).duplicate())
        var ring := root.get_child(root.get_child_count() - 1) as MeshInstance3D
        ring.position = p + Vector3(0, y, 0)
        ring.rotation_degrees.x = 90.0

func _build_docks_boat(p: Vector3, t: Dictionary) -> void:
    _boat(p, t)

func _boat(p: Vector3, t: Dictionary) -> void:
    root.add_child(_box(Vector3(5.2, 0.55, 1.55), p, t.boat))
    root.add_child(_box(Vector3(0.22, 3.7, 0.22), p + Vector3(0, 1.95, 0), t.wood_dark))
    root.add_child(_box(Vector3(2.8, 1.9, 0.08), p + Vector3(0, 2.0, 0), t.sail))
    
func _is_coastal(map_id: int) -> bool:
    var name := Teleport.map_name(map_id).to_lower()
    return name.find("izlude") >= 0 or name.find("alberta") >= 0 or name.find("coast") >= 0

func _theme(id: int) -> Dictionary:
    var name := Teleport.map_name(id).to_lower()
    var t: Dictionary = {
        "ground_dark": Color("#46553d"), "ground_variation": Color("#66704b"),
        "road": Color("#89735c"), "paving": Color("#b7ad9c"), "curb": Color("#70695f"),
        "foundation": Color("#8b8070"), "wall": Color("#b59672"), "wall_alt": Color("#a78668"),
        "roof": Color("#62423b"), "roof_alt": Color("#4e3d45"), "roof_trim": Color("#bfa27d"),
        "trim": Color("#d4bc94"), "trim_dark": Color("#675447"), "door": Color("#4c3328"),
        "window": Color("#79bfd2"), "window_frame": Color("#54453c"),
        "stone": Color("#999184"), "stone_dark": Color("#514c48"), "stone_light": Color("#c9c0ae"),
        "wood": Color("#795337"), "wood_dark": Color("#493125"), "metal": Color("#3e434a"),
        "foliage": Color("#2e603d"), "foliage_light": Color("#5f8b4c"), "grass": Color("#6c9147"),
        "flower_a": Color("#d36f7a"), "flower_b": Color("#e2b75f"), "light": Color("#ffd57c"),
        "magic": Color("#66d9ff"), "fire": Color("#ff9149"), "water": Color("#3f9fbd"),
        "market_wood": Color("#795132"), "market_wood_dark": Color("#4a3023"),
        "market_cloth_a": Color("#5f85aa"), "market_cloth_b": Color("#a64b43"),
        "banner_a": Color("#9c3d45"), "banner_b": Color("#315c8d"),
        "crate": Color("#78502f"), "crate_trim": Color("#c08a4f"), "barrel": Color("#6d432a"),
        "barrel_trim": Color("#b58a4d"), "chimney": Color("#66544b"), "chimney_cap": Color("#3d3330"),
        "boat": Color("#68412c"), "sail": Color("#d7c7a9")
    }
    if name.find("geffen") >= 0:
        t.wall = Color("#8c70bd")
        t.wall_alt = Color("#765eaa")
        t.trim = Color("#d0b7ee")
        t.roof = Color("#4c3f6b")
        t.banner_a = Color("#7657b7")
    elif name.find("morroc") >= 0 or name.find("desert") >= 0:
        t.ground_dark = Color("#9b784b")
        t.ground_variation = Color("#c19b61")
        t.wall = Color("#c38a55")
        t.wall_alt = Color("#ad7448")
        t.roof = Color("#6d4531")
        t.foliage = Color("#587d4b")
        t.grass = Color("#8ba04d")
    elif name.find("forest") >= 0 or name.find("payon") >= 0:
        t.ground_dark = Color("#304f39")
        t.ground_variation = Color("#4f7044")
        t.wall = Color("#7e6c54")
        t.roof = Color("#3e5d42")
        t.foliage = Color("#1e4c31")
        t.foliage_light = Color("#4c8147")
    elif name.find("snow") >= 0 or name.find("ice") >= 0 or name.find("lutie") >= 0:
        t.ground_dark = Color("#9baeb9")
        t.ground_variation = Color("#d8e5eb")
        t.road = Color("#8f9fa8")
        t.wall = Color("#c2ccd1")
        t.wall_alt = Color("#aab9c2")
        t.roof = Color("#586b79")
        t.foliage = Color("#57747e")
        t.foliage_light = Color("#88a6ae")
    elif name.find("sewer") >= 0 or name.find("catacomb") >= 0:
        t.ground_dark = Color("#353a38")
        t.ground_variation = Color("#4c514e")
        t.wall = Color("#666b67")
        t.wall_alt = Color("#555b58")
        t.roof = Color("#303333")
        t.stone = Color("#666b67")
        t.stone_dark = Color("#272a29")
        t.magic = Color("#70e1a1")
    elif name.find("clock") >= 0:
        t.ground_dark = Color("#4c4b47")
        t.ground_variation = Color("#65635d")
        t.wall = Color("#77736a")
        t.roof = Color("#45433e")
        t.stone = Color("#77736a")
        t.stone_dark = Color("#30312f")
        t.magic = Color("#d0a64e")
    return t

func _hash(index: int, extent: float) -> float:
    var n := float((index * 97 + 17) % 1000) / 1000.0
    return (n * 2.0 - 1.0) * extent

func _world(p: Vector2) -> Vector3:
    return Vector3((p.x - OX) * SCALE, 0, (p.y - OY) * SCALE)

func _box(size: Vector3, p: Vector3, c: Color) -> MeshInstance3D:
    var n := MeshInstance3D.new()
    var m := BoxMesh.new()
    m.size = size
    n.mesh = m
    n.position = p
    n.material_override = _mat(c, 0.0, 0.74)
    return n

func _cylinder(radius: float, height: float, p: Vector3, c: Color, glow: bool = false) -> MeshInstance3D:
    var n := MeshInstance3D.new()
    var m := CylinderMesh.new()
    m.top_radius = radius
    m.bottom_radius = radius * 1.06
    m.height = height
    m.radial_segments = 24
    n.mesh = m
    n.position = p
    n.material_override = _mat(c, 0.05, 0.52 if glow else 0.74, glow)
    return n

func _sphere(c: Color, radius: float) -> MeshInstance3D:
    var n := MeshInstance3D.new()
    var m := SphereMesh.new()
    m.radius = radius
    m.height = radius * 2.0
    m.radial_segments = 24
    m.rings = 12
    n.mesh = m
    n.material_override = _mat(c, 0.0, 0.66)
    return n

func _ring(c: Color, inner_radius: float, outer_radius: float) -> MeshInstance3D:
    var n := MeshInstance3D.new()
    var m := TorusMesh.new()
    m.inner_radius = inner_radius
    m.outer_radius = outer_radius
    m.rings = 36
    m.ring_segments = 12
    n.mesh = m
    n.material_override = _mat(c, 0.0, 0.30, true)
    return n

func _prism(size: Vector3, p: Vector3, c: Color) -> MeshInstance3D:
    var n := MeshInstance3D.new()
    var m := PrismMesh.new()
    m.size = size
    n.mesh = m
    n.position = p
    n.material_override = _mat(c, 0.0, 0.68)
    return n

func _mat(c: Color, metal: float, rough: float, glow: bool = false) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = c
    m.metallic = metal
    m.roughness = rough
    m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
    if glow:
        m.emission_enabled = true
        m.emission = c
        m.emission_energy_multiplier = 2.0
    return m
