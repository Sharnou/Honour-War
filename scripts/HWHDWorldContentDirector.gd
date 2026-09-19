extends Node3D

## HD presentation pass for Honour War's MMORPG/ARPG runtime.
## This layer is visual only: gameplay authority, combat state, inventory,
## progression, pets, cities and networking remain owned by their existing systems.

const ROOT_NAME := "HWHDContent"
const VFX_NAME := "HWHDCombatVFX"
var scene_root:Node
var content_root:Node3D
var combat:Node
var hero:Node3D
var monster_nodes:Dictionary = {}
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
        if combat.has_signal("hero_attack_landed") and not combat.hero_attack_landed.is_connected(_on_hero_attack):
            combat.hero_attack_landed.connect(_on_hero_attack)
        if combat.has_signal("pet_attack_landed") and not combat.pet_attack_landed.is_connected(_on_pet_attack):
            combat.pet_attack_landed.connect(_on_pet_attack)
        if combat.has_signal("monster_attack_landed") and not combat.monster_attack_landed.is_connected(_on_monster_attack):
            combat.monster_attack_landed.connect(_on_monster_attack)

func _process(delta:float) -> void:
    elapsed += delta
    swing_time += delta
    if elapsed >= 0.35:
        elapsed = 0.0
        _sync_monsters()
        _sync_hero_equipment()
    _animate_hero_attack()
    _animate_effects(delta)

func _sync_monsters() -> void:
    if scene_root == null:
        return
    var visuals:Variant = scene_root.get("monster_visuals")
    if not visuals is Dictionary:
        return
    for key:Variant in (visuals as Dictionary).keys():
        var actor := (visuals as Dictionary)[key] as Node3D
        if actor == null or not is_instance_valid(actor) or monster_nodes.has(key):
            continue
        _decorate_monster(actor, str(key))
        monster_nodes[key] = actor
    for key:Variant in monster_nodes.keys():
        if not visuals.has(key):
            monster_nodes.erase(key)

func _decorate_monster(actor:Node3D, id:String) -> void:
    if actor.get_node_or_null("HDMonsterPresentation") != null:
        return
    var family := id.to_lower()
    var accent := _monster_color(family)
    var presentation := Node3D.new()
    presentation.name = "HDMonsterPresentation"
    actor.add_child(presentation)
    var aura := OmniLight3D.new()
    aura.name = "HDMonsterAccent"
    aura.light_color = accent
    aura.light_energy = 0.25
    aura.omni_range = 2.4
    aura.position = Vector3(0, 1.0, 0)
    presentation.add_child(aura)
    var ring := _ring("HDMonsterGroundRing", 0.42, 0.47, accent, 0.16)
    ring.position = Vector3(0, 0.04, 0)
    presentation.add_child(ring)

func _sync_hero_equipment() -> void:
    if hero == null or not is_instance_valid(hero):
        hero = _find_hero()
    if hero == null or hero.get_node_or_null("HDWeaponSilhouette") != null:
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
    var aura := _ring("HDEquipmentAura", 0.22, 0.25, accent, 0.20)
    aura.position = Vector3(0, 1.60, 0)
    hero.add_child(aura)

func _animate_hero_attack() -> void:
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
    _impact(_target_world_position(target), _class_color(str(_hero_data().get("class", "Warrior"))), critical, damage)

func _on_pet_attack(target:Dictionary, damage:int, special:bool) -> void:
    _impact(_target_world_position(target) + Vector3(0, 0.12, 0), Color("#ffd45a") if special else Color("#8de5ff"), special, damage)

func _on_monster_attack(target_kind:String, damage:int) -> void:
    if target_kind == "hero":
        _impact(_find_hero_world_position(), Color("#ff786e"), false, damage)

func _impact(pos:Vector3, color:Color, critical:bool, damage:int) -> void:
    if scene_root == null:
        return
    var vfx_root := scene_root.get_node_or_null(VFX_NAME) as Node3D
    if vfx_root == null:
        vfx_root = Node3D.new()
        vfx_root.name = VFX_NAME
        scene_root.add_child(vfx_root)
    var root := Node3D.new()
    root.name = "HDHitCritical" if critical else "HDHit"
    root.set_meta("life", 0.0)
    # Build the complete VFX tree first. A Node3D is not inside the SceneTree
    # until it is attached; setting global_position before attachment triggers
    # get_global_transform() errors and can leave renderer dependencies in an
    # invalid state during Forward+ capture.
    var flash := _sphere("Flash", 0.18 if critical else 0.12, Vector3.ZERO, _mat(color, 0.32))
    root.add_child(flash)
    var ring := _ring("HitRing", 0.20, 0.34 if critical else 0.26, color, 0.72)
    root.add_child(ring)
    var number := Label3D.new()
    number.text = str(damage)
    number.font_size = 42 if critical else 32
    number.outline_size = 8
    number.modulate = color
    number.position = Vector3(0, 0.55, 0)
    root.add_child(number)
    vfx_root.add_child(root)
    root.global_position = pos
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
    for p in [Vector3(-25,0,-8), Vector3(25,0,-8), Vector3(-27,0,12), Vector3(27,0,12), Vector3(-18,0,17), Vector3(18,0,17)]:
        _build_tree(field, p)
    for p in [Vector3(-20,0,4), Vector3(20,0,4), Vector3(-16,0,19), Vector3(16,0,19)]:
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
    root.add_child(_cylinder("TownFountain", 2.2, 0.34, pos + Vector3(0,0.17,0), stone))
    root.add_child(_cylinder("TownWater", 1.65, 0.10, pos + Vector3(0,0.39,0), water))
    root.add_child(_cylinder("FountainPillar", 0.28, 2.1, pos + Vector3(0,1.35,0), stone))

func _build_shop(root:Node3D, pos:Vector3, title:String) -> void:
    var wall := _mat(Color("#806a55"), 0.86)
    var roof := _mat(Color("#453d50"), 0.72)
    _box(root, title + "Wall", Vector3(5.0, 3.2, 4.0), pos + Vector3(0,1.6,0), wall)
    _box(root, title + "Roof", Vector3(5.5,0.35,4.5), pos + Vector3(0,3.35,0), roof)
    _box(root, title + "Door", Vector3(0.9,1.7,0.08), pos + Vector3(0,0.85,2.04), _mat(Color("#2e2421"),0.82))
    _label(root, title, pos + Vector3(0,4.0,0), Color("#f6d7a0"))

func _build_tree(root:Node3D, pos:Vector3) -> void:
    root.add_child(_cylinder("FieldTree",0.28,2.8,pos+Vector3(0,1.4,0),_mat(Color("#543b2b"),0.95)))
    root.add_child(_sphere("FieldCrown",1.45,pos+Vector3(0,3.2,0),_mat(Color("#3e794d"),0.92)))

func _build_rock(root:Node3D, pos:Vector3) -> void:
    var rock := _sphere("FieldRock",0.7,pos+Vector3(0,0.55,0),_mat(Color("#77766d"),0.95))
    rock.scale = Vector3(1.4,0.8,1.1)
    root.add_child(rock)

func _build_lanterns(root:Node3D) -> void:
    for x in [-5.0, 5.0]:
        var post := _cylinder("DungeonLanternPost",0.10,2.3,Vector3(x,1.15,20),_mat(Color("#342b25"),0.72,0.25))
        root.add_child(post)
        var light := OmniLight3D.new()
        light.name = "DungeonLanternLight"
        light.light_color = Color("#ffcf76")
        light.light_energy = 1.2
        light.omni_range = 5.0
        light.position = Vector3(x,2.35,20)
        root.add_child(light)

func _find_hero() -> Node3D:
    if scene_root == null:
        return null
    var direct := scene_root.get_node_or_null("Hero") as Node3D
    if direct != null:
        return direct
    var visual:Variant = scene_root.get("hero_visual")
    if visual is Node3D:
        return visual as Node3D
    for node in scene_root.get_children():
        if node is Node3D and str(node.name).to_lower().contains("hero"):
            return node as Node3D
    return null

func _hero_data() -> Dictionary:
    if scene_root == null:
        return {}
    var data:Variant = scene_root.get("hero")
    if data is Dictionary:
        return data as Dictionary
    var game := get_node_or_null("/root/HonourWar3D")
    if game != null:
        data = game.get("hero")
        if data is Dictionary:
            return data as Dictionary
    return {}

func _find_hero_world_position() -> Vector3:
    var h := _find_hero()
    return h.global_position if h != null else Vector3.ZERO

func _target_world_position(target:Dictionary) -> Vector3:
    if target.has("position") and target["position"] is Vector3:
        return target["position"] as Vector3
    if target.has("world_position") and target["world_position"] is Vector3:
        return target["world_position"] as Vector3
    var id := str(target.get("id", target.get("monster_id", "")))
    if scene_root != null:
        var visuals:Variant = scene_root.get("monster_visuals")
        if visuals is Dictionary and visuals.has(id):
            var actor := visuals[id] as Node3D
            if actor != null:
                return actor.global_position
    return _find_hero_world_position()

func _class_color(class_id:String) -> Color:
    match class_id:
        "Mage": return Color("#7d6cff")
        "Archer": return Color("#63c77b")
        "Thief": return Color("#b75cff")
        "Acolyte": return Color("#f4d46d")
        "Merchant": return Color("#d57a3f")
    return Color("#4f9cff")

func _monster_color(family:String) -> Color:
    if family.contains("poring"): return Color("#ff82c8")
    if family.contains("goblin"): return Color("#8fd06d")
    if family.contains("wolf"): return Color("#aeb7c4")
    if family.contains("skeleton"): return Color("#d8d1bd")
    if family.contains("zombie"): return Color("#6d9c79")
    if family.contains("orc"): return Color("#78a65f")
    if family.contains("mantis"): return Color("#69c989")
    if family.contains("golem"): return Color("#a58d73")
    if family.contains("druid"): return Color("#7650b5")
    if family.contains("dragon"): return Color("#d66a5e")
    if family.contains("bloody"): return Color("#d43b4a")
    return Color("#a7d8ff")

func _mat(color:Color, roughness:float=0.72, metallic:float=0.0) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = roughness
    material.metallic = metallic
    material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
    return material

func _metal(color:Color, roughness:float, metallic:float) -> StandardMaterial3D:
    return _mat(color, roughness, metallic)

func _emission(color:Color, energy:float) -> StandardMaterial3D:
    var material := _mat(color,0.38,0.0)
    material.emission_enabled = true
    material.emission = color
    material.emission_energy_multiplier = energy
    return material

func _box(root:Node3D, name:String, size:Vector3, position:Vector3, material:Material) -> MeshInstance3D:
    var mesh_node := MeshInstance3D.new()
    mesh_node.name = name
    var mesh := BoxMesh.new()
    mesh.size = size
    mesh_node.mesh = mesh
    mesh_node.position = position
    mesh_node.material_override = material
    root.add_child(mesh_node)
    return mesh_node

func _cylinder(name:String, radius:float, height:float, position:Vector3, material:Material) -> MeshInstance3D:
    var mesh_node := MeshInstance3D.new()
    mesh_node.name = name
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = height
    mesh.radial_segments = 24
    mesh_node.mesh = mesh
    mesh_node.position = position
    mesh_node.material_override = material
    return mesh_node

func _sphere(name:String, radius:float, position:Vector3, material:Material) -> MeshInstance3D:
    var mesh_node := MeshInstance3D.new()
    mesh_node.name = name
    var mesh := SphereMesh.new()
    mesh.radius = radius
    mesh.height = radius * 2.0
    mesh.radial_segments = 24
    mesh.rings = 12
    mesh_node.mesh = mesh
    mesh_node.position = position
    mesh_node.material_override = material
    return mesh_node

func _ring(name:String, inner_radius:float, outer_radius:float, color:Color, alpha:float) -> MeshInstance3D:
    var ring := MeshInstance3D.new()
    ring.name = name
    var mesh := TorusMesh.new()
    mesh.inner_radius = inner_radius
    mesh.outer_radius = outer_radius
    mesh.rings = 32
    mesh.ring_segments = 10
    ring.mesh = mesh
    var material := _mat(color,0.35,0.05)
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.albedo_color.a = alpha
    ring.material_override = material
    return ring

func _label(root:Node3D, text:String, position:Vector3, color:Color) -> void:
    var label := Label3D.new()
    label.text = text
    label.font_size = 32
    label.outline_size = 8
    label.modulate = color
    label.position = position
    root.add_child(label)
