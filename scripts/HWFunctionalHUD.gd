extends CanvasLayer

const CHARACTER = preload("res://scripts/CharacterProgressionSystem.gd")
const SKILLS = preload("res://scripts/SkillSystem.gd")
const PET = preload("res://scripts/PetProgressionSystem.gd")
const PET_SKILLS = preload("res://scripts/PetSkillSystem.gd")
const INVENTORY = preload("res://scripts/CharacterInventorySystem.gd")
const AGE = preload("res://scripts/OnlineAgeSystem.gd")
const SAVE = preload("res://scripts/SaveSystem.gd")

var scene_root: Node
var legacy: Node
var window: Panel
var body: VBoxContainer
var title: Label
var status: Label
var mode: String = "character"
var timer: float = 0.0

func _ready() -> void:
    layer = 80
    call_deferred("_bind")

func _bind() -> void:
    scene_root = get_tree().current_scene
    if scene_root == null:
        call_deferred("_bind")
        return
    legacy = scene_root.get_node_or_null("LegacyGame")
    var old: Node = scene_root.get_node_or_null("HDMMOTaskbar")
    if old != null:
        old.visible = false
        old.process_mode = Node.PROCESS_MODE_DISABLED
    _build()

func _process(delta: float) -> void:
    timer += delta
    if timer < 0.35:
        return
    timer = 0.0
    if legacy == null or not is_instance_valid(legacy):
        legacy = scene_root.get_node_or_null("LegacyGame") if scene_root != null else null
        return
    _refresh_header()

func _build() -> void:
    var root := Control.new()
    root.name = "HonourWarFunctionalHUD"
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(root)

    var top := PanelContainer.new()
    top.position = Vector2(18, 18)
    top.size = Vector2(520, 92)
    top.add_theme_stylebox_override("panel", _style(Color("#0b1320e8"), Color("#d2b66b")))
    root.add_child(top)
    var head := VBoxContainer.new()
    top.add_child(head)
    title = Label.new()
    title.add_theme_font_size_override("font_size", 18)
    head.add_child(title)
    status = Label.new()
    status.add_theme_font_size_override("font_size", 11)
    head.add_child(status)

    var bar := PanelContainer.new()
    bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
    bar.position = Vector2(-470, -96)
    bar.size = Vector2(940, 78)
    bar.add_theme_stylebox_override("panel", _style(Color("#0b1320ef"), Color("#d2b66b")))
    root.add_child(bar)
    var buttons := HBoxContainer.new()
    buttons.alignment = BoxContainer.ALIGNMENT_CENTER
    buttons.add_theme_constant_override("separation", 6)
    bar.add_child(buttons)
    var entries := [["CHAR", "character", "⚔"], ["PET", "pet", "✦"], ["SKILLS", "skills", "✹"], ["INV", "inventory", "▣"], ["EQUIP", "equipment", "◆"], ["REFINE", "refine", "⌁"], ["MAP", "map", "◎"], ["SYSTEM", "system", "⚙"]]
    for entry in entries:
        var b := Button.new()
        b.custom_minimum_size = Vector2(108, 62)
        b.text = str(entry[2]) + "\n" + str(entry[0])
        b.add_theme_font_size_override("font_size", 13)
        b.add_theme_stylebox_override("normal", _style(Color("#172334"), Color("#866f3f")))
        b.add_theme_stylebox_override("hover", _style(Color("#293a50"), Color("#e2c777")))
        b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
        b.pressed.connect(_open.bind(str(entry[1])))
        buttons.add_child(b)
    _refresh_header()

func _open(next: String) -> void:
    mode = "character" if next == "system" else next
    _close_window()
    _build_window()
    _render_mode()

func _build_window() -> void:
    var root := Control.new()
    root.name = "WindowRoot"
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(root)
    var blocker := ColorRect.new()
    blocker.color = Color(0.02, 0.03, 0.05, 0.58)
    blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.add_child(blocker)
    window = Panel.new()
    window.position = Vector2(500, 105)
    window.size = Vector2(900, 710)
    window.add_theme_stylebox_override("panel", _style(Color("#0d1623f8"), Color("#d2b66b")))
    root.add_child(window)
    var top := PanelContainer.new()
    top.position = Vector2(0, 0)
    top.size = Vector2(900, 50)
    top.add_theme_stylebox_override("panel", _style(Color("#08101a"), Color("#8f773d")))
    window.add_child(top)
    var row := HBoxContainer.new()
    top.add_child(row)
    title = Label.new()
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title.add_theme_font_size_override("font_size", 18)
    row.add_child(title)
    var close := Button.new()
    close.text = "CLOSE"
    close.custom_minimum_size = Vector2(96, 34)
    close.pressed.connect(_close_window)
    row.add_child(close)
    var scroll := ScrollContainer.new()
    scroll.position = Vector2(18, 64)
    scroll.size = Vector2(864, 590)
    window.add_child(scroll)
    body = VBoxContainer.new()
    body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    body.add_theme_constant_override("separation", 8)
    scroll.add_child(body)
    status = Label.new()
    status.position = Vector2(18, 665)
    status.size = Vector2(864, 32)
    window.add_child(status)

func _close_window() -> void:
    var old: Node = get_node_or_null("WindowRoot")
    if old != null:
        old.queue_free()
    window = null
    body = null

func _render_mode() -> void:
    if body == null or legacy == null:
        return
    var value: Variant = legacy.get("hero")
    if not value is Dictionary:
        return
    var hero: Dictionary = value
    CHARACTER.ensure_state(hero)
    INVENTORY.ensure_state(hero)
    SKILLS.ensure_state(hero)
    AGE.normalize(hero)
    match mode:
        "character": _render_character(hero)
        "pet": _render_pet(hero)
        "skills": _render_skills(hero)
        "inventory": _render_inventory(hero)
        "equipment": _render_equipment(hero)
        "refine": _render_refine(hero)
        "map": _render_map(hero)
        _: _render_character(hero)
    _refresh_header()

func _render_character(hero: Dictionary) -> void:
    _heading("CHARACTER — LIVE BUILD")
    var s: Dictionary = CHARACTER.stats(hero)
    var xp: Dictionary = CHARACTER.xp_progress(hero)
    _label("Level %d / 250    Class: %s    Power: %d" % [int(hero.get("level", 1)), str(hero.get("class", "Warrior")), CHARACTER.combat_power(hero)])
    _label("Age %d (%s)    Online %.2f days    Zeny %d" % [int(hero.get("age", 18)), AGE.title(int(hero.get("age", 18))), float(hero.get("online_days", 0.0)), int(hero.get("zeny", 0))])
    _label("HP %d / %d    SP %d / %d    ATK %d    MATK %d    DEF %d    MDEF %d" % [int(hero.get("hp", 0)), int(s["max_hp"]), int(hero.get("sp", 0)), int(s["max_sp"]), int(s["atk"]), int(s["matk"]), int(s["def"]), int(s["mdef"])])
    _label("XP %d / %d    %.1f%%    Stat Points %d    Skill Points %d" % [int(xp["xp"]), int(xp["next"]), float(xp["ratio"]) * 100.0, int(hero.get("stat_points", 0)), int(hero.get("skill_points", 0))])
    _heading("STAT ALLOCATION")
    var stats: Dictionary = hero.get("stats", {})
    for stat in CHARACTER.STAT_NAMES:
        var row := HBoxContainer.new()
        body.add_child(row)
        var label := Label.new()
        label.text = "%s  %d / 99" % [stat.to_upper(), int(stats.get(stat, 1))]
        label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_child(label)
        var one := Button.new()
        one.text = "+1"
        one.disabled = int(hero.get("stat_points", 0)) < 1
        one.pressed.connect(_stat_up.bind(stat, 1))
        row.add_child(one)
        var five := Button.new()
        five.text = "+5"
        five.disabled = int(hero.get("stat_points", 0)) < 5
        five.pressed.connect(_stat_up.bind(stat, 5))
        row.add_child(five)

func _stat_up(stat: String, amount: int) -> void:
    var value: Variant = legacy.get("hero")
    if value is Dictionary and CHARACTER.allocate(value, stat, amount):
        SAVE.save_game(value)
        status.text = "Updated %s by %d." % [stat.to_upper(), amount]
    _render_mode()

func _render_pet(hero: Dictionary) -> void:
    _heading("PET — AUTOMATIC COMBAT PARTNER")
    var value: Variant = hero.get("pet", {})
    if not value is Dictionary:
        _label("No pet state found.")
        return
    var pet: Dictionary = value
    PET.ensure_state(pet)
    var stats: Dictionary = PET.combat_stats(pet)
    _label("%s — %s    Level %d / 250" % [str(pet.get("name", "Pet")), str(pet.get("species", "Pet")), int(pet.get("level", 1))])
    _label("XP %d    Skill Points %d    Refine +%d    Loyalty %d%%" % [int(pet.get("xp", 0)), int(pet.get("skill_points", 0)), int(pet.get("refine", 0)), int(pet.get("loyalty", 100))])
    _label("Attack %d    Magic %d    Defense %d    HP %d    Crit %d    Range %.1fm" % [int(stats["attack"]), int(stats["magic"]), int(stats["defense"]), int(stats["hp"]), int(stats["crit"]), float(stats["range"])])
    _heading("PET SKILLS")
    PET_SKILLS.ensure_state(pet)
    for skill in PET_SKILLS.all_skills(str(pet.get("species", "Pet"))):
        var id: String = str(skill["id"])
        var lvl: int = PET_SKILLS.skill_level(pet, id)
        var b := Button.new()
        b.text = "%s   Lv.%d/%d   Cost %d" % [str(skill["name"]), lvl, int(skill["max_level"]), int(skill["cost"])]
        b.pressed.connect(_learn_pet.bind(id))
        body.add_child(b)

func _learn_pet(id: String) -> void:
    var value: Variant = legacy.get("hero")
    if value is Dictionary and value.get("pet", {}) is Dictionary:
        var pet: Dictionary = value["pet"]
        if PET_SKILLS.learn(pet, id):
            SAVE.save_game(value)
            status.text = "Pet skill learned: " + id
    _render_mode()

func _render_skills(hero: Dictionary) -> void:
    _heading("HERO SKILL TREE — %s" % str(hero.get("class", "Warrior")).to_upper())
    for skill in SKILLS.all_skills(str(hero.get("class", "Warrior"))):
        var id: String = str(skill["id"])
        var lvl: int = SKILLS.skill_level(hero, id)
        var b := Button.new()
        b.text = "%s   Lv.%d/%d   Required Lv.%d   Cost %d" % [str(skill["name"]), lvl, int(skill["max_level"]), int(skill["required_level"]), int(skill["cost"])]
        b.pressed.connect(_learn_hero.bind(id))
        body.add_child(b)
        _label(str(skill.get("description", "")))

func _learn_hero(id: String) -> void:
    var value: Variant = legacy.get("hero")
    if value is Dictionary and SKILLS.learn(value, id):
        SAVE.save_game(value)
        status.text = "Skill learned: " + id
    _render_mode()

func _render_inventory(hero: Dictionary) -> void:
    _heading("INVENTORY — ITEMS / CARDS")
    var inventory_value: Variant = hero.get("inventory", {})
    if not inventory_value is Dictionary:
        _label("Inventory unavailable.")
        return
    var inventory: Dictionary = inventory_value
    for id_value in inventory.keys():
        var id: String = str(id_value)
        var raw: Variant = inventory[id]
        var amount: int = int(raw.get("amount", 0)) if raw is Dictionary else int(raw)
        if amount <= 0:
            continue
        var b := Button.new()
        b.text = "%s   x%d" % [id, amount]
        b.pressed.connect(_use_inventory.bind(id))
        body.add_child(b)
    _label("Click an item to attempt equip/use through the live inventory system.")

func _use_inventory(id: String) -> void:
    var value: Variant = legacy.get("hero")
    if not value is Dictionary:
        return
    var hero: Dictionary = value
    var result: Dictionary = INVENTORY.equip(hero, id)
    status.text = str(result.get("message", result.get("reason", "Item action complete.")))
    if bool(result.get("ok", false)):
        SAVE.save_game(hero)
    _render_mode()

func _render_equipment(hero: Dictionary) -> void:
    _heading("EQUIPMENT — LIVE LOADOUT")
    var equipment: Dictionary = hero.get("equipment", {}) if hero.get("equipment", {}) is Dictionary else {}
    for key in ["head", "head_middle", "head_lower", "armor", "garment", "weapon", "offhand", "shoes", "accessory_1", "accessory_2"]:
        var raw: Variant = equipment.get(key, null)
        var text := "Empty"
        if raw is Dictionary:
            text = str(raw.get("id", raw.get("name", "Empty"))) + " +" + str(int(raw.get("refine", 0)))
        elif raw is String and not str(raw).is_empty():
            text = str(raw)
        _label("%-14s  %s" % [key.to_upper(), text])

func _render_refine(hero: Dictionary) -> void:
    _heading("REFINEMENT — AGE-AFFECTED")
    _label("Age improves refine success and reduces Phracon / Zeny / Emveretarcon / Oridecon use.")
    _label("Age %d    Zeny %d" % [int(hero.get("age", 18)), int(hero.get("zeny", 0))])
    for material in ["Phracon", "Emveretarcon", "Oridecon"]:
        var b := Button.new()
        b.text = "REFINE WITH " + material
        b.pressed.connect(_show_refine_message.bind(material))
        body.add_child(b)

func _show_refine_message(material: String) -> void:
    status.text = "Select an equipped item, then refine with " + material + "."

func _render_map(hero: Dictionary) -> void:
    _heading("WORLD MAP / FAST TRAVEL")
    _label("Current map %d    X %d : Y %d" % [int(hero.get("map_id", 0)), int(hero.get("pos_x", 0)) - 365, int(hero.get("pos_y", 0)) - 120])
    for i in range(8):
        var b := Button.new()
        b.text = "@go %d 230:220" % i
        b.pressed.connect(_warp.bind(i))
        body.add_child(b)
    _label("Command format: @go [map] [x]:[y]")

func _warp(map_id: int) -> void:
    status.text = "Fast-travel: @go %d 230:220" % map_id
    if legacy != null and legacy.has_method("handle_command"):
        legacy.call("handle_command", "@go %d 230:220" % map_id)

func _heading(text: String) -> void:
    var l := Label.new()
    l.text = text
    l.add_theme_font_size_override("font_size", 17)
    l.add_theme_color_override("font_color", Color("#e5cb82"))
    body.add_child(l)

func _label(text: String) -> void:
    var l := Label.new()
    l.text = text
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    l.add_theme_font_size_override("font_size", 12)
    l.add_theme_color_override("font_color", Color("#e5edf5"))
    body.add_child(l)

func _refresh_header() -> void:
    if legacy == null or not is_instance_valid(legacy) or title == null:
        return
    var value: Variant = legacy.get("hero")
    if not value is Dictionary:
        return
    var hero: Dictionary = value
    var stats: Dictionary = CHARACTER.stats(hero)
    title.text = "HONOUR WAR   |   Lv.%d / 250   |   %s   |   Age %d" % [int(hero.get("level", 1)), str(hero.get("class", "Warrior")), int(hero.get("age", 18))]
    status.text = "HP %d/%d   SP %d/%d   ATK %d   DEF %d   Zeny %d" % [int(hero.get("hp", 0)), int(stats["max_hp"]), int(hero.get("sp", 0)), int(stats["max_sp"]), int(stats["atk"]), int(stats["def"]), int(hero.get("zeny", 0))]

func _style(bg: Color, border: Color) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = bg
    s.border_color = border
    s.set_border_width_all(1)
    s.set_corner_radius_all(7)
    s.shadow_color = Color(0, 0, 0, 0.60)
    s.shadow_size = 8
    return s
