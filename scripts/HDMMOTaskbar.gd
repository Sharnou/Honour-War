class_name HDMMOTaskbar
extends CanvasLayer

const EquipmentWindowScript = preload("res://scripts/HDEquipmentWindow.gd")
const PANEL := Color("#101722ee")
const PANEL_DARK := Color("#0a1018f4")
const BORDER := Color("#b99b5b")
const TEXT := Color("#efe8d8")
const MUTED := Color("#93a0af")
const HP := Color("#cf525b")
const SP := Color("#557edb")
const XP := Color("#5eac66")

var game: Node
var legacy: Node
var root: Control
var equipment_window: Node
var progression_panel: Control
var skill_slots: HBoxContainer
var hp_label: Label
var sp_label: Label
var xp_label: Label
var level_label: Label
var location_label: Label
var hidden_timer: float = 0.0
var action_status: Label

func _ready() -> void:
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
    _build_systembar()
    _build_action_status()
    call_deferred("_close_progression")
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
    _layout_responsive()
    _refresh()

func _unhandled_input(event: InputEvent) -> void:
    if not event is InputEventKey:
        return
    if not event.pressed or event.echo:
        return
    if event.keycode == KEY_ESCAPE:
        if equipment_window != null and equipment_window.has_method("hide_window"):
            equipment_window.call("hide_window")
        _close_progression()

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
    panel.position = Vector2(16, 14)
    panel.size = Vector2(330, 72)
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
    xp_label = _small_value("EXP", XP)
    row.add_child(xp_label)

func _small_value(prefix: String, tint: Color) -> Label:
    var label := Label.new()
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

func _build_systembar() -> void:
    var panel := PanelContainer.new()
    panel.name = "FinalSystemToolbarPanel"
    panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
    panel.position = Vector2(-380, -116)
    panel.size = Vector2(760, 106)
    panel.add_theme_stylebox_override("panel", _style())
    root.add_child(panel)

    var row := HBoxContainer.new()
    row.alignment = BoxContainer.ALIGNMENT_END
    row.add_theme_constant_override("separation", 4)
    panel.add_child(row)

    var entries: Array = [
        ["CHAR", "character", 0],
        ["PET", "pet", 1],
        ["SKILLS", "skills", 2],
        ["INV", "inventory", 3],
        ["EQUIP", "equipment", 4],
        ["REFINE", "refine", 5],
        ["MAP", "map", 6],
        ["SYS", "system", 7]
    ]

    for entry in entries:
        var button := Button.new()
        button.custom_minimum_size = Vector2(88, 76)
        button.tooltip_text = str(entry[1]).capitalize()
        button.add_theme_stylebox_override("normal", _style(Color("#1b2531")))
        button.add_theme_stylebox_override("hover", _style(Color("#3a3222")))

        var icon := HUDIcon.new()
        icon.kind = int(entry[2])
        icon.position = Vector2(29, 6)
        icon.size = Vector2(30, 34)
        icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
        button.add_child(icon)

        var text := Label.new()
        text.text = str(entry[0])
        text.position = Vector2(0, 45)
        text.size = Vector2(88, 26)
        text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        text.add_theme_font_size_override("font_size", 8)
        text.add_theme_color_override("font_color", TEXT)
        text.mouse_filter = Control.MOUSE_FILTER_IGNORE
        button.add_child(text)

        button.pressed.connect(_open.bind(str(entry[1])))
        button.pressed.connect(_show_action.bind(str(entry[0])))
        row.add_child(button)

func _build_action_status() -> void:
    action_status = Label.new()
    action_status.name = "UIActionStatus"
    action_status.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
    action_status.position = Vector2(-210, -150)
    action_status.size = Vector2(420, 28)
    action_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    action_status.add_theme_font_size_override("font_size", 12)
    action_status.add_theme_color_override("font_color", TEXT)
    action_status.text = "UI READY • click any toolbar icon to test it"
    action_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(action_status)

func _show_action(label: String) -> void:
    if action_status != null:
        action_status.text = "✓ " + label + " opened • input accepted"

func _open(mode: String) -> void:
    if mode == "equipment":
        _close_progression()
        if equipment_window == null:
            equipment_window = EquipmentWindowScript.new() as Node
            if equipment_window == null:
                return
            equipment_window.name = "EquipmentWindow"
            game.add_child(equipment_window)
        if equipment_window.has_method("show_window"):
            equipment_window.call("show_window")
        return

    if equipment_window != null and equipment_window.has_method("hide_window"):
        equipment_window.call("hide_window")

    var ui: Node = game.get_node_or_null("GameplaySystemsRuntime")
    if ui == null:
        return
    var mode_to_use: String = mode
    ui.call("_set_mode", mode_to_use)
    progression_panel = ui.get("panel") as Control
    if progression_panel == null:
        return
    progression_panel.visible = true
    progression_panel.position = Vector2(760, 76)
    progression_panel.size = Vector2(590, 625)
    _install_closebar()

func _install_closebar() -> void:
    if progression_panel == null:
        return
    if progression_panel.has_meta("hw_final_closebar"):
        return
    progression_panel.set_meta("hw_final_closebar", true)

    var bar := PanelContainer.new()
    bar.name = "FinalCloseBar"
    bar.position = Vector2(0, 0)
    bar.size = Vector2(590, 36)
    bar.add_theme_stylebox_override("panel", _style(PANEL_DARK))
    progression_panel.add_child(bar)

    var row := HBoxContainer.new()
    bar.add_child(row)

    var title := Label.new()
    title.text = "HONOUR WAR"
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title.add_theme_color_override("font_color", TEXT)
    row.add_child(title)

    var close := Button.new()
    close.text = "X"
    close.custom_minimum_size = Vector2(34, 28)
    close.pressed.connect(_close_progression)
    row.add_child(close)

func _close_progression() -> void:
    if progression_panel == null and game != null:
        var ui: Node = game.get_node_or_null("GameplaySystemsRuntime")
        if ui != null:
            progression_panel = ui.get("panel") as Control
    if progression_panel != null:
        progression_panel.visible = false

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

func _layout_responsive() -> void:
    if root == null:
        return
    var v := get_viewport().get_visible_rect().size
    if action_status != null:
        action_status.position = Vector2((v.x - 420.0) * 0.5, v.y - 151.0)
    for child in root.get_children():
        if child is PanelContainer:
            var panel := child as Control
            if panel.size.y >= 100.0 and panel.position.y < 0.0:
                panel.position.x = (v.x - panel.size.x) * 0.5
                panel.position.y = v.y - panel.size.y - 12.0

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
