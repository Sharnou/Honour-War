extends CanvasLayer

## Final combat quickbar.
## Always shows eight class skills, including locked/passive entries.
## Uses authored SVG icon atlas assets instead of text glyph placeholders.

const SKILLS = preload("res://scripts/SkillSystem.gd")
const ICON_ATLAS_PATH:String = "res://assets/3d/generated/ui/skill_icons_atlas.svg"
const PANEL_BG:Color = Color("#07111df5")
const BORDER:Color = Color("#c9ad68")
const TEXT:Color = Color("#f7f1e4")
const MUTED:Color = Color("#91a3b6")

var scene:Node
var legacy:Node
var panel:PanelContainer
var slots:HBoxContainer
var hero_class:String = "Warrior"
var last_signature:String = ""
var flash_index:int = -1
var flash_time:float = 0.0
var icon_atlas:Texture2D

func _ready()->void:
    layer = 300
    process_mode = Node.PROCESS_MODE_ALWAYS
    icon_atlas = load(ICON_ATLAS_PATH) as Texture2D
    call_deferred("_bind_and_build")

func _process(delta:float)->void:
    flash_time = max(0.0, flash_time - delta)
    if scene == null or not is_instance_valid(scene):
        _bind_and_build()
        return
    if legacy == null or not is_instance_valid(legacy):
        legacy = scene.get_node_or_null("LegacyGame")
    _hide_legacy_skillbars()
    _refresh()
    if flash_time <= 0.0 and flash_index >= 0:
        flash_index = -1
        _refresh(true)

func _bind_and_build()->void:
    scene = get_tree().current_scene
    if scene == null:
        return
    legacy = scene.get_node_or_null("LegacyGame")
    _hide_legacy_skillbars()
    if icon_atlas == null:
        icon_atlas = load(ICON_ATLAS_PATH) as Texture2D
    if panel == null or not is_instance_valid(panel):
        _build()

func _hide_legacy_skillbars()->void:
    var old_bar:Node = get_node_or_null("/root/HWSkillBarRuntime")
    if old_bar != null:
        old_bar.process_mode = Node.PROCESS_MODE_DISABLED
        var old_panel:Node = old_bar.get_node_or_null("HWSkillBar")
        if old_panel != null:
            old_panel.visible = false
    var old_taskbar:Node = get_node_or_null("/root/HDMMOTaskbar")
    if old_taskbar != null:
        var hud:Control = old_taskbar.get_node_or_null("HonourWarFinalHUD") as Control
        if hud != null:
            for child:Node in hud.get_children():
                if child is PanelContainer:
                    var c:Control = child as Control
                    if c.position.x < 0.0 and c.position.y < 0.0:
                        c.visible = false

func _build()->void:
    panel = PanelContainer.new()
    panel.name = "HWFinalSkillQuickbar"
    panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
    panel.position = Vector2(-560, -128)
    panel.size = Vector2(1120, 116)
    panel.add_theme_stylebox_override("panel", _style(PANEL_BG, BORDER, 10))
    add_child(panel)

    var outer := VBoxContainer.new()
    outer.add_theme_constant_override("separation", 3)
    panel.add_child(outer)

    var header := HBoxContainer.new()
    outer.add_child(header)
    var title := Label.new()
    title.name = "Title"
    title.text = "COMBAT SKILLS"
    title.add_theme_font_size_override("font_size", 12)
    title.add_theme_color_override("font_color", TEXT)
    header.add_child(title)
    var hint := Label.new()
    hint.text = "1–8 CAST   •   K SKILL TREE   •   PASSIVES ALWAYS ACTIVE"
    hint.add_theme_font_size_override("font_size", 9)
    hint.add_theme_color_override("font_color", MUTED)
    hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    header.add_child(hint)

    slots = HBoxContainer.new()
    slots.alignment = BoxContainer.ALIGNMENT_CENTER
    slots.add_theme_constant_override("separation", 7)
    outer.add_child(slots)

    for i in range(8):
        var slot := Button.new()
        slot.name = "SkillSlot_%d" % (i + 1)
        slot.custom_minimum_size = Vector2(132, 82)
        slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        slot.alignment = HORIZONTAL_ALIGNMENT_CENTER
        slot.focus_mode = Control.FOCUS_ALL
        slot.add_theme_font_size_override("font_size", 9)
        slot.add_theme_color_override("font_color", TEXT)
        slot.add_theme_color_override("font_hover_color", TEXT)
        slot.add_theme_stylebox_override("normal", _style(Color("#101d2e"), Color("#42536a"), 8))
        slot.add_theme_stylebox_override("hover", _style(Color("#20324a"), BORDER, 8))
        slot.add_theme_stylebox_override("pressed", _style(Color("#293c58"), Color("#f0d587"), 8))
        slot.pressed.connect(_cast_slot.bind(i))
        slots.add_child(slot)

func _refresh(force:bool = false)->void:
    if legacy == null or not is_instance_valid(legacy) or slots == null:
        return
    var value:Variant = legacy.get("hero")
    if not value is Dictionary:
        return
    var hero:Dictionary = value
    SKILLS.ensure_state(hero)
    hero_class = str(hero.get("class","Warrior"))
    var data:Array = SKILLS.all_skills(hero_class)
    var signature:String = hero_class + ":" + str(hero.get("level",1)) + ":" + str(hero.get("skill_points",0)) + ":" + str(hero.get("skill_cooldowns",{})) + ":" + str(hero.get("skill_levels",{})) + ":" + str(hero.get("hp",0))
    if not force and signature == last_signature and flash_index < 0:
        return
    last_signature = signature

    for i in range(8):
        var slot:Button = slots.get_child(i) as Button
        if slot == null:
            continue
        if i >= data.size():
            slot.text = str(i + 1) + "\n—"
            slot.icon = null
            slot.disabled = true
            continue
        var skill:Dictionary = data[i]
        var kind:String = str(skill.get("kind","active"))
        var level:int = SKILLS.skill_level(hero,str(skill.get("id","")))
        var required:int = int(skill.get("required_level",1))
        var locked:bool = int(hero.get("level",1)) < required
        for req:Variant in skill.get("requires",[]):
            if int(hero.get("skill_levels",{}).get(str(req),0)) < 1:
                locked = true
        var name:String = str(skill.get("name","Skill"))
        if name.length() > 18:
            name = name.substr(0,18)
        var state:String = "Lv.%d" % level
        if locked:
            state = "LOCK • REQ Lv.%d" % required
        elif kind == "ultimate":
            state = "ULTIMATE • Lv.%d" % level
        elif kind == "passive":
            state = "PASSIVE • Lv.%d" % level
        var badge:String = "✓" if level > 0 and not locked else ""
        slot.text = str(i + 1) + "  " + name + "\n" + state + ("  " + badge if not badge.is_empty() else "")
        slot.tooltip_text = str(skill.get("name","Skill")) + "\n" + str(skill.get("description","")) + "\nSP " + str(skill.get("sp_cost",0)) + " • CD " + str(skill.get("cooldown",0.0)) + "s"
        slot.icon = _icon_for_skill(hero_class, i)
        slot.disabled = locked or kind == "passive"
        slot.modulate = Color("#8291a3") if locked else Color.WHITE
        if i == flash_index and flash_time > 0.0:
            slot.add_theme_stylebox_override("normal", _style(Color("#4b3520"), Color("#ffe28c"), 8))
        else:
            slot.add_theme_stylebox_override("normal", _style(Color("#101d2e"), Color("#42536a"), 8))

func _cast_slot(index:int)->void:
    if legacy == null:
        return
    var value:Variant = legacy.get("hero")
    if not value is Dictionary:
        return
    var hero:Dictionary = value
    SKILLS.ensure_state(hero)
    var data:Array = SKILLS.all_skills(str(hero.get("class","Warrior")))
    if index < 0 or index >= data.size():
        return
    var skill:Dictionary = data[index]
    var skill_id:String = str(skill.get("id",""))
    var kind:String = str(skill.get("kind","active"))
    if kind == "passive":
        _log("%s is passive; it is always active when learned." % str(skill.get("name","Skill")))
        return
    if not _can_use(hero, skill):
        return

    var result:Dictionary = SKILLS.use(hero,skill_id,Time.get_ticks_msec() / 1000.0)
    if not bool(result.get("ok",false)):
        _log("%s unavailable: %s" % [str(skill.get("name","Skill")),str(result.get("reason","cooldown or SP"))])
        return

    var power:int = int(result.get("power",0))
    var target:Variant = legacy.call("nearest_monster") if legacy.has_method("nearest_monster") else null
    if target is Dictionary:
        var monster:Dictionary = target
        monster["hp"] = int(monster.get("hp",0)) - power
        _log("%s Lv.%d hits %s for %d." % [str(skill.get("name","Skill")),int(result.get("level",1)),str(monster.get("name","Monster")),power])
        if int(monster.get("hp",0)) <= 0 and legacy.has_method("defeat_monster"):
            legacy.call("defeat_monster",monster)
    elif str(hero.get("class","Warrior")) == "Acolyte":
        var amount:int = power + 10
        hero["hp"] = min(int(hero.get("max_hp",1)),int(hero.get("hp",0)) + amount)
        _log("%s restores %d HP." % [str(skill.get("name","Skill")),amount])
    else:
        _log("%s needs a nearby target." % str(skill.get("name","Skill")))
        return

    if legacy.has_method("save_game"):
        legacy.call("save_game")
    if legacy.has_method("update_ui"):
        legacy.call("update_ui")
    flash_index = index
    flash_time = 0.18
    _refresh(true)

func _can_use(hero:Dictionary,skill:Dictionary)->bool:
    var level:int = int(hero.get("level",1))
    var required:int = int(skill.get("required_level",1))
    if level < required:
        _log("Locked: %s requires Hero Lv.%d." % [str(skill.get("name","Skill")),required])
        return false
    for req:Variant in skill.get("requires",[]):
        if int(hero.get("skill_levels",{}).get(str(req),0)) < 1:
            _log("Locked: %s requires %s." % [str(skill.get("name","Skill")),str(req)])
            return false
    return true

func _log(message:String)->void:
    if legacy != null and legacy.has_method("log_message"):
        legacy.call("log_message",message)

func _icon_for_skill(class_id:String,index:int)->Texture2D:
    if icon_atlas == null:
        return null
    var row:int = 0
    match class_id:
        "Mage": row = 1
        "Archer": row = 2
        "Thief": row = 3
        "Acolyte": row = 4
        "Merchant": row = 5
        _:
            row = 0
    var atlas := AtlasTexture.new()
    atlas.atlas = icon_atlas
    atlas.region = Rect2(float(index * 64),float(row * 64),64.0,64.0)
    return atlas

func _style(bg:Color,border:Color,radius:int)->StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = bg
    style.border_color = border
    style.set_border_width_all(1)
    style.set_corner_radius_all(radius)
    style.shadow_color = Color(0,0,0,0.65)
    style.shadow_size = 8
    return style

func _unhandled_key_input(event:InputEvent)->void:
    if not event is InputEventKey or not event.pressed or event.echo:
        return
    if event.keycode >= KEY_1 and event.keycode <= KEY_8:
        _cast_slot(int(event.keycode - KEY_1))
