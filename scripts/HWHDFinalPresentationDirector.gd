extends Node3D

## Final HD presentation director.
## Visual-only: never owns gameplay, combat, inventory, networking or progression.
## Production assets remain preferred; this layer adds authored-asset-aware framing,
## equipment readability, combat timing, hit reactions, boss staging and UI polish.

const ROOT_NAME := "HWHDFinalPresentation"
const VFX_ROOT := "HWHDCombatVFX"
const CLASS_ACCENTS := {
    "Warrior": Color("#4f9cff"),
    "Mage": Color("#8f70ff"),
    "Archer": Color("#63c77b"),
    "Thief": Color("#c767ff"),
    "Acolyte": Color("#f4d46d"),
    "Merchant": Color("#d57a3f")
}

var scene_root: Node
var combat: Node
var hero: Node3D
var camera: Camera3D
var sequences: Array[Dictionary] = []
var reaction_tweens: Array[Tween] = []
var boss_seen: Dictionary = {}
var ui_layer: CanvasLayer
var cinematic_bar_top: ColorRect
var cinematic_bar_bottom: ColorRect

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    process_priority = 810
    call_deferred("_initialize")

func _initialize() -> void:
    scene_root = get_tree().current_scene
    if scene_root == null:
        return
    hero = _find_hero()
    camera = _find_camera()
    combat = scene_root.get_node_or_null("LegacyGame/CombatRuntime")
    if combat == null:
        combat = scene_root.get_node_or_null("CombatRuntime")
    _build_root()
    _bind_combat()
    _build_ui_polish()
    _frame_camera()
    _sync_equipment()

func _process(_delta: float) -> void:
    if scene_root == null or not is_instance_valid(scene_root):
        _initialize()
        return
    if hero == null or not is_instance_valid(hero):
        hero = _find_hero()
    if camera == null or not is_instance_valid(camera):
        camera = _find_camera()
    _frame_camera()
    _sync_equipment()
    _sync_bosses()
    _process_sequences()

func _build_root() -> Node3D:
    var root := scene_root.get_node_or_null(ROOT_NAME) as Node3D
    if root == null:
        root = Node3D.new()
        root.name = ROOT_NAME
        scene_root.add_child(root)
    root.set_meta("hd_final_presentation", true)
    return root

func _bind_combat() -> void:
    if combat == null:
        return
    if combat.has_signal("hero_attack_landed") and not combat.hero_attack_landed.is_connected(_on_hero_attack):
        combat.hero_attack_landed.connect(_on_hero_attack)
    if combat.has_signal("pet_attack_landed") and not combat.pet_attack_landed.is_connected(_on_pet_attack):
        combat.pet_attack_landed.connect(_on_pet_attack)
    if combat.has_signal("monster_attack_landed") and not combat.monster_attack_landed.is_connected(_on_monster_attack):
        combat.monster_attack_landed.connect(_on_monster_attack)

func _on_hero_attack(target: Dictionary, damage: int, critical: bool) -> void:
    # CombatRuntime can emit an attack after the previous hero visual was freed.
    # Resolve a live actor at signal time; never pass a stale Object into a typed
    # Node3D parameter.
    var live_hero: Node3D = _live_hero()
    if live_hero == null:
        return
    hero = live_hero
    _start_attack(live_hero, "hero", target, critical)
    _hit_target(target, critical, damage)

func _on_pet_attack(target: Dictionary, damage: int, special: bool) -> void:
    var pet: Node3D = _live_pet()
    if pet == null:
        return
    _start_attack(pet, "pet", target, special)
    _hit_target(target, special, damage)

func _on_monster_attack(target_kind: String, _damage: int) -> void:
    if target_kind != "hero":
        return
    # The hero visual can be replaced during respawn/rebuild between combat
    # ticks. Resolve it again before calling a typed Node3D function.
    var live_hero: Node3D = _live_hero()
    if live_hero == null:
        return
    hero = live_hero
    _start_attack(live_hero, "monster", {}, false)
    _react_actor(live_hero, false)

func _start_attack(actor_value: Variant, kind: String, target: Dictionary, critical: bool) -> void:
    # Keep the boundary untyped: a combat signal can race a visual respawn/free.
    # Validate the Object before converting it to Node3D so a freed instance can
    # never trigger GDScript typed-argument validation before this guard runs.
    if not is_instance_valid(actor_value) or not actor_value is Node3D:
        return
    var actor: Node3D = actor_value as Node3D
    if actor == null or not is_instance_valid(actor):
        return
    sequences.append({
        "actor": actor,
        "kind": kind,
        "target": target,
        "started": Time.get_ticks_msec() / 1000.0,
        "anticipation": 0.14 if critical else 0.11,
        "contact": 0.075 if critical else 0.06,
        "recovery": 0.30 if critical else 0.24,
        "critical": critical,
        "contact_done": false,
        "base_scale": actor.scale,
        "base_rotation": actor.rotation
    })

func _process_sequences() -> void:
    var now := Time.get_ticks_msec() / 1000.0
    for i in range(sequences.size() - 1, -1, -1):
        var seq: Dictionary = sequences[i]
        var actor_value: Variant = seq.get("actor", null)
        if not is_instance_valid(actor_value) or not actor_value is Node3D:
            sequences.remove_at(i)
            continue
        var actor: Node3D = actor_value as Node3D
        if actor == null or not is_instance_valid(actor):
            sequences.remove_at(i)
            continue
        var elapsed: float = now - float(seq.get("started", now))
        var a: float = float(seq.get("anticipation", 0.11))
        var c: float = float(seq.get("contact", 0.06))
        var r: float = float(seq.get("recovery", 0.24))
        var total := a + c + r
        var base_scale: Vector3 = seq.get("base_scale", actor.scale)
        var base_rot: Vector3 = seq.get("base_rotation", actor.rotation)
        if elapsed < a:
            var t := clampf(elapsed / maxf(a, 0.001), 0.0, 1.0)
            actor.scale = base_scale.lerp(base_scale * Vector3(1.035, 0.965, 1.045), t)
            actor.rotation = base_rot + Vector3(0.0, 0.0, -0.07 * t)
        elif elapsed < a + c:
            if not bool(seq.get("contact_done", false)):
                seq["contact_done"] = true
                sequences[i] = seq
                _spawn_contact_fx(seq)
            actor.scale = base_scale * Vector3(1.055, 0.94, 1.055)
        elif elapsed < total:
            var t := clampf((elapsed - a - c) / maxf(r, 0.001), 0.0, 1.0)
            actor.scale = (base_scale * Vector3(1.055, 0.94, 1.055)).lerp(base_scale, t)
            actor.rotation = (base_rot + Vector3(0.0, 0.0, -0.07)).lerp(base_rot, t)
        else:
            actor.scale = base_scale
            actor.rotation = base_rot
            sequences.remove_at(i)

func _hit_target(target: Dictionary, critical: bool, damage: int) -> void:
    var target_node := _target_node(target)
    if target_node == null:
        return
    _react_actor(target_node, critical)
    if _is_boss(_monster_data(str(target.get("id", "")))):
        _boss_impact(target_node, critical)
    _spawn_damage_fx(target_node.global_position + Vector3(0, 0.85, 0), critical, damage)

func _react_actor(actor: Node3D, critical: bool) -> void:
    if actor == null or not is_instance_valid(actor):
        return
    var base := actor.rotation
    var kick := 0.12 if critical else 0.075
    var tween := create_tween()
    tween.tween_property(actor, "rotation", base + Vector3(0, 0, kick), 0.045)
    tween.tween_property(actor, "rotation", base + Vector3(0, 0, -kick * 0.7), 0.055)
    tween.tween_property(actor, "rotation", base, 0.10)
    reaction_tweens.append(tween)

func _spawn_contact_fx(seq: Dictionary) -> void:
    var actor_value: Variant = seq.get("actor", null)
    var actor: Node3D = actor_value as Node3D if is_instance_valid(actor_value) and actor_value is Node3D else null
    var target_value: Variant = seq.get("target", {})
    var target: Dictionary = target_value if target_value is Dictionary else {}
    var pos := actor.global_position if actor != null else Vector3.ZERO
    var target_node := _target_node(target)
    if target_node != null:
        pos = target_node.global_position + Vector3(0, 0.7, 0)
    var color: Color = CLASS_ACCENTS.get(_hero_class(), Color.WHITE)
    if str(seq.get("kind", "")) == "pet":
        color = Color("#8de5ff")
    elif str(seq.get("kind", "")) == "monster":
        color = Color("#ff786e")
    _spawn_burst(pos, color, bool(seq.get("critical", false)))

func _spawn_damage_fx(pos: Vector3, critical: bool, damage: int) -> void:
    var color := Color("#ffe28c") if critical else Color("#ffffff")
    _spawn_burst(pos, color, critical)
    var root := _vfx_root()
    var label := Label3D.new()
    label.text = str(damage)
    label.font_size = 46 if critical else 34
    label.outline_size = 8
    label.modulate = color
    label.position = pos + Vector3(0, 0.3, 0)
    root.add_child(label)
    var tween := create_tween()
    tween.tween_property(label, "position:y", label.position.y + 0.65, 0.34)
    tween.tween_callback(label.queue_free)

func _spawn_burst(pos: Vector3, color: Color, critical: bool) -> void:
    var root := _vfx_root()
    var fx := Node3D.new()
    fx.name = "HDImpactBurst"
    root.add_child(fx)
    fx.global_position = pos
    for i in range(6 if critical else 4):
        var shard := MeshInstance3D.new()
        var mesh := SphereMesh.new()
        mesh.radius = 0.045 if critical else 0.035
        mesh.height = mesh.radius * 2.0
        shard.mesh = mesh
        shard.material_override = _emissive(color, 3.0 if critical else 2.0)
        var angle := TAU * float(i) / float(6 if critical else 4)
        shard.position = Vector3(cos(angle), 0.25 + 0.12 * sin(angle * 2.0), sin(angle)) * (0.32 if critical else 0.22)
        fx.add_child(shard)
    var ring := MeshInstance3D.new()
    var torus := TorusMesh.new()
    torus.inner_radius = 0.14
    torus.outer_radius = 0.22 if critical else 0.18
    torus.rings = 36
    torus.ring_segments = 12
    ring.mesh = torus
    ring.rotation_degrees.x = 90.0
    ring.material_override = _emissive(color, 2.8 if critical else 1.8)
    fx.add_child(ring)
    var tween := create_tween()
    tween.tween_property(fx, "scale", Vector3.ONE * (1.8 if critical else 1.35), 0.22)
    tween.tween_callback(fx.queue_free)

func _boss_impact(actor: Node3D, critical: bool) -> void:
    var root := _build_root()
    var ring := root.get_node_or_null("BossImpactRing") as MeshInstance3D
    if ring == null:
        ring = MeshInstance3D.new()
        ring.name = "BossImpactRing"
        var mesh := TorusMesh.new()
        mesh.inner_radius = 1.1
        mesh.outer_radius = 1.18
        mesh.rings = 48
        mesh.ring_segments = 16
        ring.mesh = mesh
        ring.rotation_degrees.x = 90.0
        ring.material_override = _emissive(Color("#ffcf62"), 2.4)
        root.add_child(ring)
    ring.global_position = actor.global_position + Vector3(0, 0.08, 0)
    ring.scale = Vector3.ONE * 0.6
    var tween := create_tween()
    tween.tween_property(ring, "scale", Vector3.ONE * (1.35 if critical else 1.05), 0.25)
    tween.tween_callback(func(): ring.scale = Vector3.ONE * 0.6)

func _sync_bosses() -> void:
    if scene_root == null:
        return
    var visuals: Variant = scene_root.get("monster_visuals")
    if not visuals is Dictionary:
        return
    for key in (visuals as Dictionary).keys():
        var id := str(key)
        var actor_value: Variant = (visuals as Dictionary)[key]
        if not is_instance_valid(actor_value) or not actor_value is Node3D:
            continue
        var actor: Node3D = actor_value as Node3D
        if actor == null or not is_instance_valid(actor):
            continue
        var monster := _monster_data(id)
        if _is_boss(monster) and not boss_seen.has(id):
            boss_seen[id] = true
            _stage_boss(actor, id)

func _stage_boss(actor: Node3D, id: String) -> void:
    var root := _build_root()
    var marker := MeshInstance3D.new()
    marker.name = "BossStage_" + id
    var mesh := CylinderMesh.new()
    mesh.top_radius = 1.05
    mesh.bottom_radius = 1.25
    mesh.height = 0.055
    mesh.radial_segments = 48
    marker.mesh = mesh
    marker.material_override = _emissive(Color("#8c72ff"), 1.8)
    root.add_child(marker)
    marker.global_position = actor.global_position + Vector3(0, 0.035, 0)
    var aura := OmniLight3D.new()
    aura.name = "BossAura_" + id
    aura.light_color = Color("#9a7cff")
    aura.light_energy = 0.55
    aura.omni_range = 4.5
    root.add_child(aura)
    aura.global_position = actor.global_position + Vector3(0, 1.3, 0)
    var label := Label3D.new()
    label.name = "BossTitle_" + id
    label.text = "MVP  •  " + id.replace("_", " ").to_upper()
    label.font_size = 40
    label.outline_size = 9
    label.modulate = Color("#ffe29a")
    root.add_child(label)
    label.global_position = actor.global_position + Vector3(0, 2.7, 0)

func _sync_equipment() -> void:
    if hero == null or not is_instance_valid(hero):
        return
    var data := _hero_data()
    var equipment: Variant = data.get("equipment", {})
    if not equipment is Dictionary:
        return
    var root := hero.get_node_or_null("HDEquipmentPresentation") as Node3D
    if root == null:
        root = Node3D.new()
        root.name = "HDEquipmentPresentation"
        hero.add_child(root)
    var signature := str(equipment) + ":" + str(data.get("class", "Warrior"))
    if str(root.get_meta("signature", "")) == signature:
        return
    for child in root.get_children():
        child.queue_free()
    root.set_meta("signature", signature)
    var accent: Color = CLASS_ACCENTS.get(str(data.get("class", "Warrior")), Color("#4f9cff"))
    _add_armor_plate(root, "ChestPlate", Vector3(0, 1.42, -0.26), Vector3(0.62, 0.68, 0.16), accent)
    _add_armor_plate(root, "ShoulderL", Vector3(-0.50, 1.48, 0), Vector3(0.22, 0.34, 0.30), accent)
    _add_armor_plate(root, "ShoulderR", Vector3(0.50, 1.48, 0), Vector3(0.22, 0.34, 0.30), accent)
    _add_armor_plate(root, "BeltBadge", Vector3(0, 1.04, -0.47), Vector3(0.20, 0.20, 0.08), Color("#f3d277"))
    if equipment.size() > 0:
        var weapon := root.get_node_or_null("Weapon") as MeshInstance3D
        if weapon == null:
            weapon = MeshInstance3D.new()
            weapon.name = "Weapon"
            var blade := BoxMesh.new()
            blade.size = Vector3(0.12, 1.45, 0.24)
            weapon.mesh = blade
            weapon.position = Vector3(0.66, 1.10, -0.08)
            weapon.rotation_degrees.z = -20.0
            root.add_child(weapon)
        weapon.material_override = _metal(accent)

func _add_armor_plate(root: Node3D, name: String, pos: Vector3, size: Vector3, color: Color) -> void:
    var n := MeshInstance3D.new()
    n.name = name
    var mesh := BoxMesh.new()
    mesh.size = size
    n.mesh = mesh
    n.position = pos
    n.material_override = _metal(color)
    root.add_child(n)

func _build_ui_polish() -> void:
    if ui_layer != null:
        return
    ui_layer = CanvasLayer.new()
    ui_layer.name = "HWHDUIPolish"
    ui_layer.layer = 450
    scene_root.add_child(ui_layer)
    cinematic_bar_top = ColorRect.new()
    cinematic_bar_top.color = Color(0.01, 0.02, 0.04, 0.24)
    cinematic_bar_top.anchor_right = 1.0
    cinematic_bar_top.offset_bottom = 5.0
    ui_layer.add_child(cinematic_bar_top)
    cinematic_bar_bottom = ColorRect.new()
    cinematic_bar_bottom.color = Color(0.01, 0.02, 0.04, 0.24)
    cinematic_bar_bottom.anchor_top = 1.0
    cinematic_bar_bottom.anchor_right = 1.0
    cinematic_bar_bottom.offset_top = -5.0
    ui_layer.add_child(cinematic_bar_bottom)

func _frame_camera() -> void:
    if camera == null or hero == null or not is_instance_valid(hero):
        return
    if camera.get_meta("hw_hd_camera_locked", false):
        return
    camera.set_meta("hw_hd_camera_locked", true)
    camera.fov = 52.0
    camera.near = 0.05
    camera.far = 350.0

func _target_node(target: Dictionary) -> Node3D:
    if scene_root == null or not target is Dictionary:
        return null
    var id := str(target.get("id", ""))
    if id.is_empty():
        return null
    var visuals: Variant = scene_root.get("monster_visuals")
    if visuals is Dictionary and visuals.has(id):
        var target_value: Variant = (visuals as Dictionary)[id]
        if not is_instance_valid(target_value) or not target_value is Node3D:
            return null
        return target_value as Node3D
    return null

func _monster_data(id: String) -> Dictionary:
    var visuals: Variant = scene_root.get("monster_visuals")
    if visuals is Dictionary and visuals.has(id):
        var actor_value: Variant = visuals[id]
        if not is_instance_valid(actor_value) or not actor_value is Node:
            return {"id": id, "name": id, "level": 1}
        var actor: Node = actor_value as Node
        var value: Variant = actor.get_meta("monster_data", {})
        if value is Dictionary:
            return value
    return {"id": id, "name": id, "level": 1}

func _is_boss(value: Dictionary) -> bool:
    var level := int(value.get("level", 1))
    var name := str(value.get("name", value.get("id", ""))).to_lower()
    return level >= 250 or name.contains("mvp") or name.contains("boss") or name.contains("dragon") or name.contains("bloody knight")

func _hero_data() -> Dictionary:
    var value: Variant = scene_root.get("hero") if scene_root != null else null
    if not value is Dictionary:
        var legacy := scene_root.get_node_or_null("LegacyGame") if scene_root != null else null
        value = legacy.get("hero") if legacy != null else null
    return value if value is Dictionary else {}

func _hero_class() -> String:
    return str(_hero_data().get("class", "Warrior"))

func _live_hero() -> Node3D:
    if scene_root == null or not is_instance_valid(scene_root):
        return null
    var value: Variant = scene_root.get("hero_visual")
    if is_instance_valid(value) and value is Node3D:
        return value as Node3D
    var fallback: Node3D = scene_root.get_node_or_null("Actors3D/Hero") as Node3D
    return fallback if is_instance_valid(fallback) else null

func _live_pet() -> Node3D:
    if scene_root == null or not is_instance_valid(scene_root):
        return null
    var value: Variant = scene_root.get("pet_visual")
    if is_instance_valid(value) and value is Node3D:
        return value as Node3D
    var fallback: Node3D = scene_root.get_node_or_null("Actors3D/Pet") as Node3D
    return fallback if is_instance_valid(fallback) else null

func _find_hero() -> Node3D:
    return _live_hero()

func _find_pet() -> Node3D:
    return _live_pet()

func _find_camera() -> Camera3D:
    if scene_root == null:
        return null
    var current := scene_root.get_viewport().get_camera_3d()
    if current != null:
        return current
    return scene_root.find_child("Camera3D", true, false) as Camera3D

func _vfx_root() -> Node3D:
    var root := scene_root.get_node_or_null(VFX_ROOT) as Node3D
    if root == null:
        root = Node3D.new()
        root.name = VFX_ROOT
        scene_root.add_child(root)
    return root

func _metal(color: Color) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.metallic = 0.72
    m.roughness = 0.28
    return m

func _emissive(color: Color, energy: float) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.emission_enabled = true
    m.emission = color
    m.emission_energy_multiplier = energy
    m.roughness = 0.24
    m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    return m
