class_name HWHDWorldContentDirector
extends Node3D

## HD content pass for Honour War's existing MMORPG/ARPG runtime.
## Adds original, procedural presentation for monsters, town/field/dungeon
## dressing, equipment silhouettes and combat animation/VFX hooks without
## replacing gameplay state or the existing generated GLB pipeline.

const ROOT_NAME := "HW_HDContent"
const VFX_NAME := "HW_HDCombatVFX"
var scene_root:Node
var content_root:Node3D
var combat:Node
var hero:Node3D
var monster_nodes:Dictionary = {}
var monster_details:Dictionary = {}
var effect_nodes:Array[Node3D] = []
var elapsed := 0.0
var swing_time := 0.0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("_initialize")

func _initialize() -> void:
    scene_root = get_tree().current_scene
    if scene_root == null:
        return
    content_root = scene_root.get_node_or_null(ROOT_NAME) as Node3D
    if content_root == null:
        content_root = Node3D.new()
        content_root.name = ROOT_NAME
        scene_root.add_child(content_root)
    if not bool(content_root.get_meta("built", false)):
        _build_world_dressing()
        _build_zone_markers()
        content_root.set_meta("built", true)
    combat = scene_root.get_node_or_null("LegacyGame/CombatRuntime")
    if combat == null:
        combat = scene_root.get_node_or_null("CombatRuntime")
    if combat != null:
        if not combat.hero_attack_landed.is_connected(_on_hero_attack):
            combat.hero_attack_landed.connect(_on_hero_attack)
        if not combat.pet_attack_landed.is_connected(_on_pet_attack):
            combat.pet_attack_landed.connect(_on_pet_attack)
        if not combat.monster_attack_landed.is_connected(_on_monster_attack):
            combat.monster_attack_landed.connect(_on_monster_attack)

func _process(delta:float) -> void:
    elapsed += delta
    swing_time += delta
    if elapsed >= 0.35:
        elapsed = 0.0
        _sync_monsters()
        _sync_hero_equipment()
    _animate_hero_attack(delta)
    _animate_effects(delta)

func _sync_monsters() -> void:
    if scene_root == null:
        return
    var visuals:Variant = scene_root.get("monster_visuals")
    if not visuals is Dictionary:
        return
    for key:Variant in (visuals as Dictionary).keys():
        var actor := (visuals as Dictionary)[key] as Node3D
        if actor == null or not is_instance_valid(actor):
            continue
        if monster_nodes.has(key):
            continue
        _decorate_monster(actor, str(key))
        monster_nodes[key] = actor
    for key:Variant in monster_nodes.keys():
        if not visuals.has(key):
            monster_nodes.erase(key)

func _decorate_monster(actor:Node3D, id:String) -> void:
    var family := id.to_lower()
    var accent := Color("#a7d8ff")
    if family.contains("poring"): accent = Color("#ff82c8")
    elif family.contains("goblin"): accent = Color("#8fd06d")
    elif family.contains("wolf"): accent = Color("#aeb7c4")
    elif family.contains("skeleton"): accent = Color("#d8d1bd")
    elif family.contains("zombie"): accent = Color("#6d9c79")
    elif family.contains("orc"): accent = Color("#78a65f")
    elif family.contains("mantis"): accent = Color("#69c989")
    elif family.contains("golem"): accent = Color("#a58d73")
    elif family.contains("druid"): accent = Color("#7650b5")
    elif family.contains("dragon"): accent = Color("#d66a5e")
    elif family.contains("bloody"): accent = Color("#d43b4a")
    var aura := OmniLight3D.new()
    aura.name = "HDMonsterAccent"
    aura.light_color = accent
    aura.light_energy = 0.35
    aura.omni_range = 2.4
    aura.position = Vector3(0, 1.0, 0)
    actor.add_child(aura)
    var ring := _ring("HDMonsterGroundRing", 0.42, 0.47, accent, 0.16)
    ring.position = Vector3(0, 0.04, 0)
    actor.add_child(ring)
    monster_details[id] = {"aura": aura, "ring": ring}

func _sync_hero_equipment() -> void:
    if hero == null or not is_instance_valid(hero):
        hero = _find_hero()
    if hero == null:
        return
    if hero.get_node_or_null("HDWeaponSilhouette") != null:
        return
    var data := _hero_data()
    var class_id := str(data.get("class", "Warrior"))
    var accent := _class_color(class_id)
    var weapon := MeshInstance3D.new()
    weapon.name = "HDWeaponSilhouette"
    var blade := BoxMesh.new()
    blade.size = Vector3(0.11, 1.35, 0.22)
    weapon.mesh = blade
    weapon.position = Vector3(0.70, 1.05, -0.05)
    weapon.rotation_degrees.z = -18.0
    weapon.material_override = _metal(accent, 0.28, 0.45)
    hero.add_child(weapon)
    var guard := MeshInstance3D.new()
    guard.name = "HDWeaponGuard"
    var guard_mesh := CylinderMesh.new()
    guard_mesh.top_radius = 0.12
    guard_mesh.bottom_radius = 0.12
    guard_mesh.height = 0.52
    guard.mesh = guard_mesh
    guard.rotation_degrees.z = 90.0
    guard.position = Vector3(0.61, 0.42, -0.05)
    guard.material_override = _metal(accent, 0.35, 0.30)
    weapon.add_child(guard)
    var slot := _ring("HDEquipmentAura", 0.22, 0.25, accent, 0.20)
    slot.position = Vector3(0, 1.60, 0.0)
    hero.add_child(slot)

func _animate_hero_attack(delta:float) -> void:
    if hero == null or not is_instance_valid(hero):
        return
    var weapon := hero.get_node_or_null("HDWeaponSilhouette") as Node3D
    if weapon == null:
        return
    var phase := fmod(swing_time, 0.72)
    var weight := clampf(phase / 0.18, 0.0, 1.0)
    if phase > 0.18 and phase < 0.42:
        weight = 1.0 - ((phase - 0.18) / 0.24)
    weapon.rotation_degrees.z = lerpf(-18.0, -82.0, weight)

func _on_hero_attack(target:Dictionary, damage:int, critical:bool) -> void:
    var pos := _target_world_position(target)
    _impact(pos, _class_color(str(_hero_data().get("class", "Warrior"))), critical, damage)

func _on_pet_attack(target:Dictionary, damage:int, special:bool) -> void:
    var pos := _target_world_position(target)
    _impact(pos + Vector3(0, 0.12, 0), Color("#8de5ff") if not special else Color("#ffd45a"), special, damage)

func _on_monster_attack(target_kind:String, damage:int) -> void:
    if target_kind == "hero":
        var pos := _find_hero_world_position()
        _impact(pos, Color("#ff786e"), false, damage)

func _impact(pos:Vector3, color:Color, critical:bool, damage:int) -> void:
    var root := Node3D.new()
    root.name = "HDHitCritical" if critical else "HDHit"
    root.global_position = pos
    var flash := _sphere("Flash", 0.12 if not critical else 0.18, color, 0.32)
    root.add_child(flash)
    var ring := _ring("HitRing", 0.20, 0.26 if not critical else 0.34, color, 0.72)
    root.add_child(ring)
    var number := Label3D.new()
    number.text = str(damage)
    number.font_size = 32 if not critical else 42
    number.outline_size = 8
    number.modulate = color
    number.position = Vector3(0, 0.55, 0)
    root.add_child(number)
    var vfx_root := scene_root.get_node_or_null(VFX_NAME) as Node3D
    if vfx_root == null:
        vfx_root = Node3D.new()
        vfx_root.name = VFX_NAME
        scene_root.add_child(vfx_root)
    vfx_root.add_child(root)
    effect_nodes.append(root)

func _animate_effects(delta:float) -> void:
    for i in range(effect_nodes.size() - 1, -1, -1):
        var effect := effect_nodes[i]
        if effect == null or not is_instance_valid(effect):
            effect_nodes.remove_at(i)
            continue
        effect.position.y += delta * 0.55
        effect.scale += Vector3.ONE * delta * (2.8 if effect.name == "HDHitCritical" else 2.0)
        var life := float(effect.get_meta("life", 0.0)) + delta
        effect.set_meta("life", life)
        if life > (0.55 if effect.name == "HDHitCritical" else 0.38):
            effect.queue_free()
            effect_nodes.remove_at(i)

func _build_world_dressing() -> void:
    var town := Node3D.new()
    town.name = "HDTownDistrict"
    content_root.add_child(town)
    _build_town_gate(town, Vector3(0, 0, -7.5))
    _build_fountain(town, Vector3(0, 0, 5.8))
    _build_shop(town, Vector3(-9, 0, -2), "EQUIPMENT")
    _build_shop(town, Vector3(9, 0, -2), "ITEMS")
    _build_shop(town, Vector3(-9, 0, 13), "CARD LAB")
    _build_shop(town, Vector3(9, 0, 13), "BLACKSMITH")
    var field := Node3D.new()
    field.name = "HDFieldDistrict"
    content_root.add_child(field)
    for p in [Vector3(-25,0,-8), Vector3(25,0,-8), Vector3(-27,0,12), Vector3(27,0,12)]:
        _build_tree(field, p)
    for p in [Vector3(-20,0,4),Vector3(20,0,4),Vector3(-16,0,19),Vector3(16,0,19)]:
        _build_rock(field, p)
    var dungeon := Node3D.new()
    dungeon.name = "HDDungeonDistrict"
    content_root.add_child(dungeon)
    _build_dungeon_gate(dungeon, Vector3(0, 0, 24), "ANCIENT DUNGEON")
    _build_lanterns(dungeon)

func _build_zone_markers() -> void:
    var marker_root := Node3D.new()
    marker_root.name = "HDZoneMarkers"
    content_root.add_child(marker_root)
    _label(marker_root, "TOWN", Vector3(0, 3.9, -7.5), Color("#ffe2a4"))
    _label(marker_root, "FIELD", Vector3(24, 2.8, -8), Color("#b7e6a8"))
    _label(marker_root, "DUNGEON", Vector3(0, 4.8, 24), Color("#c6b4ff"))

func _build_town_gate(root:Node3D, pos:Vector3) -> void:
    var stone := _mat(Color("#7c7468"), 0.78)
    _box(root, "GateL", Vector3(1.2, 5.0, 1.4), pos + Vector3(-2.0,2.5,0), stone)
    _box(root, "GateR", Vector3(1.2, 5.0, 1.4), pos + Vector3(2.0,2.5,0), stone)
    _box(root, "GateTop", Vector3(5.2, 1.0, 1.4), pos + Vector3(0,5.0,0), stone)

func _build_dungeon_gate(root:Node3D, pos:Vector3, title:String) -> void:
    var dark := _mat(Color("#252536"), 0.58, 0.22)
    _box(root, "DungeonL", Vector3(1.6, 6.0, 1.8), pos + Vector3(-2.7,3,0), dark)
    _box(root, "DungeonR", Vector3(1.6, 6.0, 1.8), pos + Vector3(2.7,3,0), dark)
    _box(root, "DungeonTop", Vector3(7.0, 1.2, 1.8), pos + Vector3(0,6,0), dark)
    var portal := _ring("DungeonPortal", 2.0, 2.15, Color("#826cff"), 1.5)
    portal.position = pos + Vector3(0,3,0)
    root.add_child(portal)
    _label(root, title, pos + Vector3(0,7.1,0), Color("#d5c9ff"))

func _build_fountain(root:Node3D, pos:Vector3) -> void:
    var stone := _mat(Color("#aaa28f"), 0.70)
    var water := _emission(Color("#53bde5"), 0.55)
    var base := _cylinder("TownFountain", 2.2, 0.34, pos + Vector3(0,0.17,0), stone)
    root.add_child(base)
    var pool := _cylinder("TownWater", 1.65, 0.10, pos + Vector3(0,0.39,0), water)
    root.add_child(pool)
    var pillar := _cylinder("FountainPillar", 0.28, 2.1, pos + Vector3(0,1.35,0), stone)
    root.add_child(pillar)

func _build_shop(root:Node3D, pos:Vector3, title:String) -> void:
    var wall := _mat(Color("#806a55"), 0.86)
    var roof := _mat(Color("#453d50"), 0.72)
    _box(root, title + "Wall", Vector3(5.0, 3.2, 4.0), pos + Vector3(0,1.6,0), wall)
    _box(root, title + "Roof", Vector3(5.5,0.35,4.5), pos + Vector3(0,3.35,0), roof)
    _box(root, title + "Door", Vector3(0.9,1.7,0.08), pos + Vector3(0,0.85,2.04), _mat(Color("#2e2421"),0.82))
    _label(root, title, pos + Vector3(0,4.0,0), Color("#f6d7a0"))

func _build_tree(root:Node3D, pos:Vector3) -> void:
    var trunk := _mat(Color("#543b2b"), 0.95)
    var leaf := _mat(Color("#3e794d"), 0.92)
    root.add_child(_cylinder("FieldTree",0.28,2.8,pos+Vector3(0,1.4,0),trunk))
    root.add_child(_sphere("FieldCrown",1.45,pos+Vector3(0,3.2,0),leaf))

func _build_rock(root:Node3D, pos:Vector3) -> void:
    var rock := _sphere("FieldRock",0.7,pos+Vector3(0,0.55,0),_mat(Color("#77766d"),0.95))
    rock.scale = Vector3(1.4,0.8,1.1)
    root.add_child(rock)

func _build_lanterns(root:Node3D) -> void:
    for z in [20.0, 23.0, 26.0, 29.0]:
        var post := _cylinder("DungeonLanternPost",0.08,2.5,Vector3(-4,z*0.0,z),_mat(Color("#333036"),0.45,0.4))
        root.add_child(post)
        var light := OmniLight3D.new()
        light.name = "DungeonLanternLight"
        light.position = Vector3(-4,2.1,z)
        light.light_color = Color("#9d7dff")
        light.light_energy = 1.0
        light.omni_range = 4.0
        root.add_child(light)

func _find_hero() -> Node3D:
    for path in ["Actors3D/Hero", "Hero", "World3D/Actors3D/Hero"]:
        var node := scene_root.get_node_or_null(path) as Node3D
        if node != null:
            return node
    return null

func _hero_data() -> Dictionary:
    var legacy := scene_root.get_node_or_null("LegacyGame")
    if legacy == null:
        return {}
    var value:Variant = legacy.get("hero")
    return value if value is Dictionary else {}

func _target_world_position(target:Dictionary) -> Vector3:
    var p:Variant = target.get("pos", Vector2.ZERO)
    if p is Vector2:
        return Vector3((p as Vector2).x * 0.055 - 20.0, 0.8, (p as Vector2).y * 0.055 - 6.6)
    return _find_hero_world_position()

func _find_hero_world_position() -> Vector3:
    if hero != null and is_instance_valid(hero):
        return hero.global_position + Vector3(0,1,0)
    return Vector3.ZERO

func _class_color(class_id:String) -> Color:
    match class_id:
        "Mage": return Color("#786cff")
        "Archer": return Color("#62c97c")
        "Thief": return Color("#c15cff")
        "Acolyte": return Color("#f2d36d")
        "Merchant": return Color("#d57d43")
    return Color("#4d9fff")

func _mat(color:Color, roughness:float=0.8)->StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = roughness
    return m

func _metal(color:Color, roughness:float, metallic:float)->StandardMaterial3D:
    var m := _mat(color, roughness)
    m.metallic = metallic
    return m

func _emission(color:Color, energy:float)->StandardMaterial3D:
    var m := _mat(color,0.32)
    m.emission_enabled = true
    m.emission = color
    m.emission_energy_multiplier = energy
    return m

func _box(root:Node3D, name:String, size:Vector3, pos:Vector3, material:Material)->MeshInstance3D:
    var n := MeshInstance3D.new()
    n.name = name
    var mesh := BoxMesh.new()
    mesh.size = size
    n.mesh = mesh
    n.position = pos
    n.material_override = material
    root.add_child(n)
    return n

func _cylinder(name:String, radius:float, height:float, pos:Vector3, material:Material)->MeshInstance3D:
    var n := MeshInstance3D.new()
    n.name = name
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = height
    mesh.radial_segments = 28
    n.mesh = mesh
    n.position = pos
    n.material_override = material
    return n

func _sphere(name:String, radius:float, pos:Vector3, material:Material)->MeshInstance3D:
    var n := MeshInstance3D.new()
    n.name = name
    var mesh := SphereMesh.new()
    mesh.radius = radius
    mesh.height = radius * 2.0
    mesh.radial_segments = 24
    mesh.rings = 14
    n.mesh = mesh
    n.position = pos
    n.material_override = material
    return n

func _ring(name:String, inner:float, outer:float, color:Color, energy:float)->MeshInstance3D:
    var n := MeshInstance3D.new()
    n.name = name
    var mesh := TorusMesh.new()
    mesh.inner_radius = inner
    mesh.outer_radius = outer
    mesh.rings = 32
    mesh.ring_segments = 10
    n.mesh = mesh
    n.rotation_degrees.x = 90.0
    n.material_override = _emission(color,energy)
    return n

func _label(root:Node3D, text:String, pos:Vector3, color:Color)->void:
    var label := Label3D.new()
    label.name = "HDZoneLabel_" + text.replace(" ", "_")
    label.text = text
    label.position = pos
    label.font_size = 34
    label.outline_size = 10
    label.modulate = color
    root.add_child(label)
