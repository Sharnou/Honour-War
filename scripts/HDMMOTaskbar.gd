class_name HDMMOTaskbar
extends CanvasLayer

const PANEL := Color("#101722ee")
const BORDER := Color("#b99b5b")
const TEXT := Color("#efe8d8")
const MUTED := Color("#93a0af")
const HP := Color("#cf525b")
const SP := Color("#557edb")
const XP := Color("#5eac66")

var game: Node
var legacy: Node
var root: Control
var skill_slots: HBoxContainer
var hp_label: Label
var sp_label: Label
var pet_hp_label: Label
var pet_sp_label: Label
var xp_label: Label
var level_label: Label
var location_label: Label
var status_panel: PanelContainer
var hidden_timer: float = 0.0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    game = get_parent()
    if game == null:
        return
    legacy = game.get("legacy") as Node
    call_deferred("_build")

func _build() -> void:
    _hide_legacy_huds()
    root = Control.new()
    root.name = "HonourWarFinalHUD"
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_PASS
    add_child(root)
    _build_status()
    _build_quickbar()
    call_deferred("_install_runtime_directors")

func _install_runtime_directors() -> void:
    if game == null:
        return
    _add_runtime_script("res://scripts/HDDeathRecovery.gd", "HDDeathRecovery")
    _add_runtime_script("res://scripts/HDHeroDetailDirector.gd", "HDHeroDetailDirector")
    _add_runtime_script("res://scripts/HDMonsterMotionDirector.gd", "HDMonsterMotionDirector")

func _add_runtime_script(path: String, node_name: String) -> void:
    if game.get_node_or_null(node_name) != null:
        return
    var script: GDScript = load(path) as GDScript
    if script == null:
        return
    var node: Node = script.new() as Node
    if node == null:
        return
    node.name = node_name
    game.add_child(node)

func _process(delta: float) -> void:
    hidden_timer += delta
    if hidden_timer >= 0.5:
        hidden_timer = 0.0
        _hide_legacy_huds()
    _refresh()

func _hide_legacy_huds() -> void:
    var names: Array[String] = ["HDUIStyleDirector", "PetCombatHUD3D", "HeroPetComboHUD"]
    for node_name in names:
        var node: Node = get_node_or_null("../" + node_name)
        if node != null:
            node.visible = false
            node.process_mode = Node.PROCESS_MODE_DISABLED
    if game != null:
        var game_hud: Node = game.get("hud") as Node
        if game_hud != null:
            game_hud.visible = false
            game_hud.process_mode = Node.PROCESS_MODE_DISABLED

func _style(bg: Color = PANEL) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = bg
    style.border_color = BORDER
    style.set_border_width_all(1)
    style.set_corner_radius_all(5)
    style.shadow_color = Color(0, 0, 0, 0.55)
    style.shadow_size = 7
    return style

func _build_status() -> void:
    var panel := PanelContainer.new()
    status_panel = panel
    panel.name = "PermanentHeroPetStatus"
    panel.process_mode = Node.PROCESS_MODE_ALWAYS
    panel.position = Vector2(16, 14)
    panel.size = Vector2(610, 78)
    panel.add_theme_stylebox_override("panel", _style())
    root.add_child(panel)

    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 1)
    panel.add_child(box)

    level_label = Label.new()
    level_label.add_theme_font_size_override("font_size", 15)
    level_label.add_theme_color_override("font_color", TEXT)
    level_label.text = "Lv.1 / 250"
    box.add_child(level_label)

    location_label = Label.new()
    location_label.add_theme_font_size_override("font_size", 10)
    location_label.add_theme_color_override("font_color", MUTED)
    location_label.text = "Prontera"
    box.add_child(location_label)

    var row := HBoxContainer.new()
    box.add_child(row)

    hp_label = _small_value("HP", HP)
    row.add_child(hp_label)
    sp_label = _small_value("SP", SP)
    row.add_child(sp_label)
    pet_hp_label = _small_value("PET HP", HP)
    row.add_child(pet_hp_label)
    pet_sp_label = _small_value("PET SP", SP)
    row.add_child(pet_sp_label)
    xp_label = _small_value("EXP", XP)
    row.add_child(xp_label)

func _small_value(prefix: String, tint: Color) -> Label:
    var label := Label.new()
    label.name = prefix
    label.text = prefix
    label.add_theme_font_size_override("font_size", 9)
    label.add_theme_color_override("font_color", tint)
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    return label

func _build_quickbar() -> void:
    var panel := PanelContainer.new()
    panel.name = "LegacyQuickSkillPanel"
    panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
    panel.position = Vector2(-560, -116)
    panel.size = Vector2(760, 106)
    panel.add_theme_stylebox_override("panel", _style())
    root.add_child(panel)

    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 2)
    panel.add_child(box)

    var title := Label.new()
    title.text = "QUICK SKILLS   1 - 8"
    title.add_theme_font_size_override("font_size", 9)
    title.add_theme_color_override("font_color", MUTED)
    box.add_child(title)

    skill_slots = HBoxContainer.new()
    skill_slots.add_theme_constant_override("separation", 4)
    box.add_child(skill_slots)

    for i in range(8):
        var slot := Button.new()
        slot.custom_minimum_size = Vector2(86, 68)
        slot.name = "QuickSlot_%d" % (i + 1)
        slot.add_theme_font_size_override("font_size", 9)
        slot.add_theme_stylebox_override("normal", _style(Color("#1b2531")))
        slot.add_theme_stylebox_override("hover", _style(Color("#3a3222")))
        slot.pressed.connect(_use_slot.bind(i))
        skill_slots.add_child(slot)

func _use_slot(index: int) -> void:
    if legacy == null:
        return
    var value: Variant = legacy.get("hero")
    if not value is Dictionary:
        return
    var hero: Dictionary = value
    var system: GDScript = load("res://scripts/SkillSystem.gd") as GDScript
    if system == null:
        return
    system.ensure_state(hero)
    var skills: Array = system.all_skills(str(hero.get("class", "Warrior")))
    if index >= skills.size():
        return
    var skill_id: String = str(skills[index].get("id", ""))
    system.use(hero, skill_id, Time.get_ticks_msec() / 1000.0)

func _refresh() -> void:
    if legacy == null:
        return
    var value: Variant = legacy.get("hero")
    if not value is Dictionary:
        return
    var hero: Dictionary = value
    var character: GDScript = load("res://scripts/CharacterProgressionSystem.gd") as GDScript
    if character == null:
        return

    var stats: Dictionary = character.stats(hero)
    var xp: Dictionary = character.xp_progress(hero)
    var hp: int = int(hero.get("hp", 0))
    var hp_max: int = max(1, int(stats.get("max_hp", 1)))
    var sp: int = int(hero.get("sp", 0))
    var sp_max: int = max(1, int(stats.get("max_sp", 1)))
    var pet_hp: int = 0
    var pet_sp: int = 0
    var pet_hp_max: int = 1
    var pet_sp_max: int = 1
    var pet_value: Variant = hero.get("pet", {})
    if pet_value is Dictionary:
        var pet: Dictionary = pet_value
        var pet_system: GDScript = load("res://scripts/PetProgressionSystem.gd") as GDScript
        if pet_system != null:
            pet_system.ensure_state(pet)
            var pet_stats: Dictionary = pet_system.combat_stats(pet)
            pet_hp_max = max(1, int(pet_stats.get("hp", 1)))
            pet_sp_max = max(1, int(pet_stats.get("sp", max(1, int(pet_stats.get("magic", 1))))))
            pet_hp = int(pet.get("hp", pet_hp_max))
            pet_sp = int(pet.get("sp", pet_sp_max))

    if level_label != null:
        level_label.text = "Lv.%d / 250" % int(hero.get("level", 1))
    if location_label != null:
        location_label.text = "%s   X %d : Y %d" % [
            _map_name(hero),
            int(hero.get("pos_x", 0)) - 365,
            int(hero.get("pos_y", 0)) - 120
        ]
    if hp_label != null:
        hp_label.text = "HP %d/%d" % [hp, hp_max]
    if sp_label != null:
        sp_label.text = "SP %d/%d" % [sp, sp_max]
    if pet_hp_label != null:
        pet_hp_label.text = "PET HP %d/%d" % [pet_hp, pet_hp_max]
    if pet_sp_label != null:
        pet_sp_label.text = "PET SP %d/%d" % [pet_sp, pet_sp_max]
    if xp_label != null:
        xp_label.text = "EXP %d/%d" % [int(xp.get("xp", 0)), max(1, int(xp.get("next", 1)))]

    if skill_slots == null:
        return
    var skills_script: GDScript = load("res://scripts/SkillSystem.gd") as GDScript
    if skills_script == null:
        return
    var skills: Array = skills_script.all_skills(str(hero.get("class", "Warrior")))

    for i in range(skill_slots.get_child_count()):
        var slot: Button = skill_slots.get_child(i) as Button
        if slot == null:
            continue
        if i < skills.size():
            var data: Dictionary = skills[i]
            var skill_name: String = str(data.get("name", "Skill"))
            if skill_name.length() > 12:
                skill_name = skill_name.substr(0, 12)
            var skill_level: int = skills_script.skill_level(hero, str(data.get("id", "")))
            slot.text = "%d\n%s\nLv.%d" % [i + 1, skill_name, skill_level]
        else:
            slot.text = "%d\n—" % (i + 1)

func _map_name(hero: Dictionary) -> String:
    var teleport: GDScript = load("res://scripts/TeleportSystem.gd") as GDScript
    if teleport != null:
        return str(teleport.map_name(int(hero.get("map_id", 0))))
    return "Map %d" % int(hero.get("map_id", 0))

class HUDIcon extends Control:
    var kind: int = 0

    func _draw() -> void:
        var c := Color("#d4bd75")
        var w: float = size.x
        var h: float = size.y
        var mid := Vector2(w * 0.5, h * 0.5)

        if kind == 0:
            draw_line(Vector2(6, h - 6), Vector2(w - 6, 6), c, 4.0)
            draw_line(Vector2(7, h - 11), Vector2(14, h - 4), c, 3.0)
        elif kind == 1:
            draw_arc(mid, 9.0, 0.0, TAU, 20, c, 3.0)
            draw_circle(Vector2(9, 7), 3.0, c)
            draw_circle(Vector2(w - 9, 7), 3.0, c)
        elif kind == 2:
            draw_arc(mid, 10.0, 0.0, TAU, 20, c, 3.0)
            for i in range(8):
                var angle := float(i) * PI * 0.25
                var p1 := mid + Vector2(cos(angle), sin(angle)) * 12.0
                var p2 := mid + Vector2(cos(angle), sin(angle)) * 15.0
                draw_line(p1, p2, c, 2.0)
        elif kind == 3:
            draw_rect(Rect2(5, 8, w - 10, h - 6), c, false, 3.0)
            draw_line(Vector2(9, 9), Vector2(15, 4), c, 3.0)
            draw_line(Vector2(w - 9, 9), Vector2(w - 15, 4), c, 3.0)
        elif kind == 4:
            draw_arc(Vector2(w * 0.5, h * 0.58), 11.0, PI, TAU, 20, c, 3.0)
            draw_line(Vector2(6, h * 0.58), Vector2(w - 6, h * 0.58), c, 3.0)
        elif kind == 5:
            draw_arc(mid, 9.0, 0.0, TAU, 20, c, 3.0)
            draw_line(Vector2(5, mid.y), Vector2(w - 5, mid.y), c, 3.0)
            draw_line(Vector2(mid.x, 5), Vector2(mid.x, h - 5), c, 3.0)
        elif kind == 6:
            draw_arc(mid, 10.0, 0.0, TAU, 20, c, 2.5)
            draw_circle(mid, 3.0, c)
            draw_line(Vector2(mid.x, 2), Vector2(mid.x, 6), c, 2.0)
        else:
            draw_arc(mid, 10.0, 0.0, TAU, 20, c, 3.0)
            draw_circle(mid, 3.0, c)
            draw_line(Vector2(5, 5), Vector2(12, 10), c, 2.0)
            draw_line(Vector2(w - 5, 5), Vector2(w - 12, 10), c, 2.0)
