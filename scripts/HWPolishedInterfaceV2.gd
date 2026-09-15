extends CanvasLayer

const CHARACTER=preload("res://scripts/CharacterProgressionSystem.gd")
const SKILLS=preload("res://scripts/SkillSystem.gd")
const PET=preload("res://scripts/PetProgressionSystem.gd")
const PET_SKILLS=preload("res://scripts/PetSkillSystem.gd")
const INVENTORY=preload("res://scripts/CharacterInventorySystem.gd")
const AGE=preload("res://scripts/OnlineAgeSystem.gd")
const SAVE=preload("res://scripts/SaveSystem.gd")
const TELEPORT=preload("res://scripts/TeleportSystem.gd")
const ICON=preload("res://scripts/HWIconButton.gd")

const MODES:Array[String]=["character","pet","skills","inventory","equipment","refine","map","objectives","system"]

var scene_root:Node
var legacy:Node
var root:Control
var panel:Panel
var body:VBoxContainer
var title:Label
var status:Label
var hp_bar:ProgressBar
var sp_bar:ProgressBar
var mode:String="character"
var toolbar:PanelContainer

func _ready()->void:
    layer=120
    call_deferred("_bind")

func _bind()->void:
    scene_root=get_tree().current_scene
    if scene_root==null:
        call_deferred("_bind")
        return
    legacy=scene_root.get_node_or_null("LegacyGame")
    _disable_competing_huds()
    _build()

func _process(_delta:float)->void:
    if scene_root==null:
        return
    if legacy==null:
        legacy=scene_root.get_node_or_null("LegacyGame")
    _refresh_status()

func _disable_competing_huds()->void:
    var names:Array[String]=["HWMainInterface","HDMMOTaskbar","HWFunctionalHUD","HDCombatHUD","HWCombatHUD"]
    for node_name in names:
        var n:Node=scene_root.get_node_or_null(node_name)
        if n!=null and n!=self:
            n.visible=false
            n.process_mode=Node.PROCESS_MODE_DISABLED

func _build()->void:
    root=Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter=Control.MOUSE_FILTER_IGNORE
    add_child(root)

    var top:PanelContainer=PanelContainer.new()
    top.position=Vector2(18,16)
    top.size=Vector2(520,118)
    top.add_theme_stylebox_override("panel",_style(Color("#07101cf5"),Color("#c9ad68")))
    root.add_child(top)
    var top_box:VBoxContainer=VBoxContainer.new()
    top_box.add_theme_constant_override("separation",3)
    top.add_child(top_box)
    title=Label.new()
    title.add_theme_font_size_override("font_size",18)
    top_box.add_child(title)
    status=Label.new()
    status.add_theme_font_size_override("font_size",10)
    status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    top_box.add_child(status)
    hp_bar=_bar("HP",Color("#d84f5b"))
    top_box.add_child(hp_bar)
    sp_bar=_bar("SP",Color("#4c91db"))
    top_box.add_child(sp_bar)

    # Reserved HUD zones:
    # top-left = hero status, top-right = command/objective controls,
    # bottom-center = combat skill quickbar.
    toolbar=PanelContainer.new()
    toolbar.anchor_left=1.0
    toolbar.anchor_top=0.0
    toolbar.anchor_right=1.0
    toolbar.anchor_bottom=0.0
    toolbar.offset_left=-948
    toolbar.offset_top=146
    toolbar.offset_right=-22
    toolbar.offset_bottom=238
    toolbar.mouse_filter=Control.MOUSE_FILTER_STOP
    toolbar.add_theme_stylebox_override("panel",_style(Color("#07101cf9"),Color("#c9ad68")))
    root.add_child(toolbar)

    var outer:VBoxContainer=VBoxContainer.new()
    outer.add_theme_constant_override("separation",3)
    toolbar.add_child(outer)
    var caption:Label=Label.new()
    caption.text="HONOUR WAR COMMAND"
    caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    caption.add_theme_font_size_override("font_size",10)
    caption.add_theme_color_override("font_color",Color("#d9bd73"))
    outer.add_child(caption)

    var buttons:HBoxContainer=HBoxContainer.new()
    buttons.alignment=BoxContainer.ALIGNMENT_CENTER
    buttons.add_theme_constant_override("separation",3)
    outer.add_child(buttons)

    var entries:Array=[
        ["character","CHAR"],["pet","PET"],["skills","SKILLS"],
        ["inventory","BAG"],["equipment","EQUIP"],["refine","REFINE"],
        ["map","MAP"],["objectives","OBJECTIVES"],["system","MENU"]
    ]
    for entry in entries:
        var b:Button=ICON.new()
        b.custom_minimum_size=Vector2(96,80)
        b.setup(str(entry[0]),str(entry[1]))
        b.add_theme_stylebox_override("normal",_style(Color("#0e1928"),Color("#5e533d")))
        b.add_theme_stylebox_override("hover",_style(Color("#20334b"),Color("#e7ca7a")))
        b.add_theme_stylebox_override("pressed",_style(Color("#2a3e55"),Color("#f2d78c")))
        b.pressed.connect(_open_mode.bind(str(entry[0])))
        buttons.add_child(b)

    _refresh_status()

func _bar(_label_text:String,_fill:Color)->ProgressBar:
    var p:ProgressBar=ProgressBar.new()
    p.custom_minimum_size=Vector2(0,13)
    p.show_percentage=false
    var bg:StyleBoxFlat=_style(Color("#16202c"),Color("#3c4652"))
    var fill:StyleBoxFlat=_style(_fill,Color("#ffffff22"))
    p.add_theme_stylebox_override("background",bg)
    p.add_theme_stylebox_override("fill",fill)
    return p

func _open_mode(next_mode:String)->void:
    if not MODES.has(next_mode):
        next_mode="character"
    mode=next_mode
    _close_panel()
    _build_panel()
    _render_mode()

func _build_panel()->void:
    var window_root:Control=Control.new()
    window_root.name="HWPolishedWindowV2"
    window_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    window_root.mouse_filter=Control.MOUSE_FILTER_STOP
    root.add_child(window_root)

    var blocker:ColorRect=ColorRect.new()
    blocker.color=Color(0,0,0,0.50)
    blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    window_root.add_child(blocker)

    panel=Panel.new()
    panel.position=Vector2(330,70)
    panel.size=Vector2(1260,830)
    panel.add_theme_stylebox_override("panel",_style(Color("#091320fc"),Color("#cfb46d")))
    window_root.add_child(panel)

    var head:PanelContainer=PanelContainer.new()
    head.position=Vector2(0,0)
    head.size=Vector2(1260,58)
    head.add_theme_stylebox_override("panel",_style(Color("#060c14"),Color("#8f783f")))
    panel.add_child(head)
    var row:HBoxContainer=HBoxContainer.new()
    head.add_child(row)
    title=Label.new()
    title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    title.add_theme_font_size_override("font_size",18)
    row.add_child(title)
    var close:Button=Button.new()
    close.text="CLOSE"
    close.custom_minimum_size=Vector2(96,36)
    close.pressed.connect(_close_panel)
    row.add_child(close)

    var scroll:ScrollContainer=ScrollContainer.new()
    scroll.position=Vector2(20,70)
    scroll.size=Vector2(1220,700)
    panel.add_child(scroll)
    body=VBoxContainer.new()
    body.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    body.add_theme_constant_override("separation",8)
    scroll.add_child(body)

    var footer:Label=Label.new()
    footer.text="I Inventory   C Character   K Skills   P Pet   E Equipment   F Refine   M Map   ESC Close"
    footer.position=Vector2(20,786)
    footer.size=Vector2(1220,28)
    footer.add_theme_font_size_override("font_size",10)
    footer.add_theme_color_override("font_color",Color("#93a5b9"))
    panel.add_child(footer)

func _close_panel()->void:
    var old:Node=root.get_node_or_null("HWPolishedWindowV2") if root!=null else null
    if old!=null:
        old.queue_free()
    panel=null
    body=null

func _render_mode()->void:
    if body==null or legacy==null:
        return
    var value:Variant=legacy.get("hero")
    if not value is Dictionary:
        return
    var hero:Dictionary=value
    CHARACTER.ensure_state(hero)
    INVENTORY.ensure_state(hero)
    SKILLS.ensure_state(hero)
    AGE.normalize(hero)
    for child in body.get_children():
        child.queue_free()
    match mode:
        "character": _character(hero)
        "pet": _pet(hero)
        "skills": _skills(hero)
        "inventory": _inventory(hero)
        "equipment": _equipment(hero)
        "refine": _refine(hero)
        "map": _map(hero)
        "objectives": _objectives(hero)
        "system": _system(hero)
        _: _character(hero)

func _character(hero:Dictionary)->void:
    _heading("CHARACTER • LIVE BUILD")
    var s:Dictionary=CHARACTER.stats(hero)
    _card("LEVEL %d / 250" % int(hero.get("level",1)),"%s  •  Power %d  •  Age %d" % [str(hero.get("class","Warrior")),CHARACTER.combat_power(hero),int(hero.get("age",18))])
    _label("HP %d / %d    SP %d / %d    ATK %d    MATK %d    DEF %d    MDEF %d    Zeny %d" % [int(hero.get("hp",0)),int(s["max_hp"]),int(hero.get("sp",0)),int(s["max_sp"]),int(s["atk"]),int(s["matk"]),int(s["def"]),int(s["mdef"]),int(hero.get("zeny",0))])
    _heading("STAT POINTS")
    var stats:Dictionary=hero.get("stats",{}) if hero.get("stats",{}) is Dictionary else {}
    for stat in CHARACTER.STAT_NAMES:
        var row:HBoxContainer=HBoxContainer.new()
        body.add_child(row)
        var l:Label=Label.new()
        l.text="%s   %d / 99" % [stat.to_upper(),int(stats.get(stat,1))]
        l.size_flags_horizontal=Control.SIZE_EXPAND_FILL
        row.add_child(l)
        var one:Button=Button.new()
        one.text="+1"
        one.disabled=int(hero.get("stat_points",0))<1
        one.pressed.connect(_stat_up.bind(stat,1))
        row.add_child(one)
        var five:Button=Button.new()
        five.text="+5"
        five.disabled=int(hero.get("stat_points",0))<5
        five.pressed.connect(_stat_up.bind(stat,5))
        row.add_child(five)

func _stat_up(stat:String,amount:int)->void:
    var value:Variant=legacy.get("hero")
    if value is Dictionary:
        if CHARACTER.allocate(value,stat,amount):
            SAVE.save_game(value)
    _render_mode()

func _pet(hero:Dictionary)->void:
    _heading("PET • LIVE BUILD")
    var pet_value:Variant=hero.get("pet",{})
    var pet:Dictionary=pet_value if pet_value is Dictionary else {}
    PET.ensure_state(hero)
    PET_SKILLS.ensure_state(pet)
    _card("%s" % str(pet.get("name","Pet")),"Level %d / 250  •  Power %d  •  %s" % [int(pet.get("level",1)),PET.power(pet),str(pet.get("species","Companion"))])

func _skills(hero:Dictionary)->void:
    _heading("SKILL TREE • HERO")
    SKILLS.ensure_state(hero)
    var data:Array=SKILLS.all_skills(str(hero.get("class","Warrior")))
    _label("Skill Points: %d" % int(hero.get("skill_points",0)))
    for skill:Variant in data:
        if not skill is Dictionary:
            continue
        var d:Dictionary=skill
        var id:String=str(d.get("id",""))
        var row:HBoxContainer=HBoxContainer.new()
        body.add_child(row)
        var label:Label=Label.new()
        label.text="%s  •  Lv.%d  •  %s" % [str(d.get("name","Skill")),SKILLS.skill_level(hero,id),str(d.get("description",""))]
        label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
        row.add_child(label)
        var up:Button=Button.new()
        up.text="UPGRADE"
        up.disabled=not SKILLS.can_upgrade(hero,id)
        up.pressed.connect(_skill_up.bind(id))
        row.add_child(up)

func _skill_up(skill_id:String)->void:
    var value:Variant=legacy.get("hero")
    if value is Dictionary:
        if SKILLS.upgrade(value,skill_id):
            SAVE.save_game(value)
    _render_mode()

func _inventory(hero:Dictionary)->void:
    _heading("INVENTORY • ITEMS & CARDS")
    INVENTORY.ensure_state(hero)
    _label("Capacity %d / %d" % [INVENTORY.used_slots(hero),INVENTORY.MAX_SLOTS])
    for item:Variant in INVENTORY.list_items(hero):
        if not item is Dictionary:
            continue
        var d:Dictionary=item
        _card(str(d.get("name","Item")),"Qty %d  •  Type %s  •  Refine +%d" % [int(d.get("qty",0)),str(d.get("type","item")),int(d.get("refine",0))])

func _equipment(hero:Dictionary)->void:
    _heading("EQUIPMENT • RO WEAPON / ARMOR")
    var equipment:Dictionary=hero.get("equipment",{}) if hero.get("equipment",{}) is Dictionary else {}
    for slot:String in ["weapon","armor","headgear","garment","footgear","accessory1","accessory2"]:
        _card(slot.to_upper(),str(equipment.get(slot,"Empty")))

func _refine(hero:Dictionary)->void:
    _heading("REFINE • PHRACON / ZENY / EMBERETARCON / ORIDECON")
    _label("Age-adjusted success and material consumption are applied by the gameplay systems.")
    _label("Phracon  •  Zeny  •  Emveretarcon  •  Oridecon")

func _map(hero:Dictionary)->void:
    _heading("MAP • FAST TRAVEL")
    _label("@go [map] [x]:[y]   •   Example: @go 0 230:220")
    for map_id:Variant in TELEPORT.MAPS.keys():
        var id:String=str(map_id)
        var row:HBoxContainer=HBoxContainer.new()
        body.add_child(row)
        var b:Button=Button.new()
        b.text="@go %s" % id
        b.pressed.connect(_warp.bind(id,230,220))
        row.add_child(b)

func _warp(map_id:String,x:int,y:int)->void:
    if legacy!=null and legacy.has_method("teleport_to"):
        legacy.call("teleport_to",map_id,x,y)
    else:
        TELEPORT.warp(scene_root,map_id,x,y)
    _close_panel()

func _objectives(hero:Dictionary)->void:
    _heading("OBJECTIVES • HONOUR WAR")
    _label("Defeat monsters • capture guarded banks • build cities • upgrade your hero")
    _label("Every 5 fallen soldiers respawn at the city production point.")
    _label("Hero respawns at the city near the base after defeat.")

func _system(hero:Dictionary)->void:
    _heading("SYSTEM • HD ONLINE")
    _label("Godot 4.7 • Forward+ • online-ready runtime")
    _label("Auto-save enabled • Hero age progression active")

func _refresh_status()->void:
    if legacy==null or title==null or status==null:
        return
    var value:Variant=legacy.get("hero")
    if not value is Dictionary:
        return
    var hero:Dictionary=value
    title.text="HONOUR WAR  •  %s" % str(hero.get("class","Warrior")).to_upper()
    status.text="Lv.%d / 250   HP %d/%d   SP %d/%d   Power %d   Age %d days" % [int(hero.get("level",1)),int(hero.get("hp",0)),int(hero.get("max_hp",1)),int(hero.get("sp",0)),int(hero.get("max_sp",1)),CHARACTER.combat_power(hero),int(hero.get("age",18))]
    if hp_bar!=null:
        hp_bar.max_value=max(1,int(hero.get("max_hp",1)))
        hp_bar.value=int(hero.get("hp",0))
    if sp_bar!=null:
        sp_bar.max_value=max(1,int(hero.get("max_sp",1)))
        sp_bar.value=int(hero.get("sp",0))

func _heading(text:String)->void:
    var label:=Label.new()
    label.text=text
    label.add_theme_font_size_override("font_size",16)
    body.add_child(label)

func _label(text:String)->void:
    var label:=Label.new()
    label.text=text
    label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    body.add_child(label)

func _card(head:String,detail:String)->void:
    var box:=PanelContainer.new()
    box.custom_minimum_size=Vector2(0,58)
    box.add_theme_stylebox_override("panel",_style(Color("#111d2a"),Color("#4f5c6c")))
    var v:=VBoxContainer.new()
    box.add_child(v)
    var h:=Label.new()
    h.text=head
    h.add_theme_font_size_override("font_size",13)
    v.add_child(h)
    var d:=Label.new()
    d.text=detail
    d.add_theme_font_size_override("font_size",10)
    d.add_theme_color_override("font_color",Color("#a7b6c8"))
    v.add_child(d)
    body.add_child(box)

func _style(bg:Color,border:Color)->StyleBoxFlat:
    var s:=StyleBoxFlat.new()
    s.bg_color=bg
    s.border_color=border
    s.set_border_width_all(1)
    s.set_corner_radius_all(8)
    return s
