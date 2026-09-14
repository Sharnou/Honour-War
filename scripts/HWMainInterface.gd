extends CanvasLayer

const CHARACTER=preload("res://scripts/CharacterProgressionSystem.gd")
const SKILLS=preload("res://scripts/SkillSystem.gd")
const PET=preload("res://scripts/PetProgressionSystem.gd")
const PET_SKILLS=preload("res://scripts/PetSkillSystem.gd")
const INVENTORY=preload("res://scripts/CharacterInventorySystem.gd")
const AGE=preload("res://scripts/OnlineAgeSystem.gd")
const SAVE=preload("res://scripts/SaveSystem.gd")
const TELEPORT=preload("res://scripts/TeleportSystem.gd")

var scene_root:Node
var legacy:Node
var root:Control
var panel:Panel
var body:VBoxContainer
var title:Label
var status:Label
var current_mode:String="character"

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
    if legacy==null and scene_root!=null:
        legacy=scene_root.get_node_or_null("LegacyGame")
    _refresh_status()

func _disable_competing_huds()->void:
    for node_name in ["HDMMOTaskbar","GameplaySystemsRuntime","HDUIStyleDirector","HWCombatHUD"]:
        var n:Node=scene_root.get_node_or_null(node_name)
        if n!=null and n!=self:
            n.visible=false
            n.process_mode=Node.PROCESS_MODE_DISABLED

func _build()->void:
    root=Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter=Control.MOUSE_FILTER_IGNORE
    add_child(root)

    var top=PanelContainer.new()
    top.position=Vector2(18,16)
    top.size=Vector2(470,86)
    top.add_theme_stylebox_override("panel",_style(Color("#07101cf0"),Color("#c9ad68")))
    root.add_child(top)
    var top_box=VBoxContainer.new()
    top.add_child(top_box)
    title=Label.new()
    title.add_theme_font_size_override("font_size",18)
    top_box.add_child(title)
    status=Label.new()
    status.add_theme_font_size_override("font_size",11)
    top_box.add_child(status)

    var bar=PanelContainer.new()
    bar.position=Vector2(1040,938)
    bar.size=Vector2(820,70)
    bar.add_theme_stylebox_override("panel",_style(Color("#07101cf5"),Color("#c9ad68")))
    root.add_child(bar)
    var buttons=HBoxContainer.new()
    buttons.alignment=BoxContainer.ALIGNMENT_CENTER
    buttons.add_theme_constant_override("separation",4)
    bar.add_child(buttons)
    var entries:Array=[["⚔","CHAR","character"],["✦","PET","pet"],["✹","SKILLS","skills"],["▣","INV","inventory"],["◆","EQUIP","equipment"],["⌁","REFINE","refine"],["◎","MAP","map"],["⚙","SYSTEM","system"]]
    for entry in entries:
        var b=Button.new()
        b.custom_minimum_size=Vector2(94,58)
        b.text=str(entry[0])+"\n"+str(entry[1])
        b.add_theme_font_size_override("font_size",11)
        b.add_theme_stylebox_override("normal",_style(Color("#162335"),Color("#7f6a3f")))
        b.add_theme_stylebox_override("hover",_style(Color("#293a50"),Color("#e1c16b")))
        b.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
        b.pressed.connect(_open_mode.bind(str(entry[2])))
        buttons.add_child(b)

    _refresh_status()

func _open_mode(mode:String)->void:
    current_mode="character" if mode=="system" else mode
    _close_panel()
    _build_panel()
    _render_mode()

func _build_panel()->void:
    var window_root=Control.new()
    window_root.name="HWMainWindow"
    window_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    window_root.mouse_filter=Control.MOUSE_FILTER_STOP
    root.add_child(window_root)
    var blocker=ColorRect.new()
    blocker.color=Color(0.0,0.0,0.0,0.48)
    blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    window_root.add_child(blocker)
    panel=Panel.new()
    panel.position=Vector2(500,95)
    panel.size=Vector2(900,780)
    panel.add_theme_stylebox_override("panel",_style(Color("#0b1420fa"),Color("#cfb46d")))
    window_root.add_child(panel)
    var head=PanelContainer.new()
    head.position=Vector2(0,0)
    head.size=Vector2(900,48)
    head.add_theme_stylebox_override("panel",_style(Color("#060c14"),Color("#8f783f")))
    panel.add_child(head)
    var row=HBoxContainer.new()
    head.add_child(row)
    title=Label.new()
    title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    title.add_theme_font_size_override("font_size",17)
    row.add_child(title)
    var close=Button.new()
    close.text="CLOSE"
    close.custom_minimum_size=Vector2(92,34)
    close.pressed.connect(_close_panel)
    row.add_child(close)
    var scroll=ScrollContainer.new()
    scroll.position=Vector2(18,62)
    scroll.size=Vector2(864,650)
    panel.add_child(scroll)
    body=VBoxContainer.new()
    body.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    body.add_theme_constant_override("separation",7)
    scroll.add_child(body)
    var footer=Label.new()
    footer.text="Mouse: click • Keyboard: I inventory, C character, K skills, P pet, M map, ESC close"
    footer.position=Vector2(18,724)
    footer.size=Vector2(864,26)
    footer.add_theme_font_size_override("font_size",10)
    panel.add_child(footer)

func _close_panel()->void:
    var old:Node=root.get_node_or_null("HWMainWindow") if root!=null else null
    if old!=null: old.queue_free()
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
    for child in body.get_children(): child.queue_free()
    match current_mode:
        "character": _character(hero)
        "pet": _pet(hero)
        "skills": _skills(hero)
        "inventory": _inventory(hero)
        "equipment": _equipment(hero)
        "refine": _refine(hero)
        "map": _map(hero)
        _: _character(hero)

func _character(hero:Dictionary)->void:
    _heading("CHARACTER — LIVE STATUS")
    var s:Dictionary=CHARACTER.stats(hero)
    var xp:Dictionary=CHARACTER.xp_progress(hero)
    _label("Lv.%d / 250 • %s • Power %d" % [int(hero.get("level",1)),str(hero.get("class","Warrior")),CHARACTER.combat_power(hero)])
    _label("Age %d (%s) • Online %.2f days • Zeny %d" % [int(hero.get("age",18)),AGE.title(int(hero.get("age",18))),float(hero.get("online_days",0.0)),int(hero.get("zeny",0))])
    _label("HP %d/%d • SP %d/%d • ATK %d • MATK %d • DEF %d • MDEF %d" % [int(hero.get("hp",0)),int(s["max_hp"]),int(hero.get("sp",0)),int(s["max_sp"]),int(s["atk"]),int(s["matk"]),int(s["def"]),int(s["mdef"])])
    _heading("STAT POINTS")
    var stats:Dictionary=hero.get("stats",{})
    for stat in CHARACTER.STAT_NAMES:
        var row=HBoxContainer.new()
        body.add_child(row)
        var l=Label.new()
        l.text="%s  %d/99" % [stat.to_upper(),int(stats.get(stat,1))]
        l.size_flags_horizontal=Control.SIZE_EXPAND_FILL
        row.add_child(l)
        var one=Button.new(); one.text="+1"; one.disabled=int(hero.get("stat_points",0))<1; one.pressed.connect(_stat_up.bind(stat,1)); row.add_child(one)
        var five=Button.new(); five.text="+5"; five.disabled=int(hero.get("stat_points",0))<5; five.pressed.connect(_stat_up.bind(stat,5)); row.add_child(five)

func _stat_up(stat:String,amount:int)->void:
    var value:Variant=legacy.get("hero")
    if value is Dictionary and CHARACTER.allocate(value,stat,amount): SAVE.save_game(value)
    _render_mode()

func _pet(hero:Dictionary)->void:
    _heading("PET — ALWAYS-ON COMBAT PARTNER")
    var value:Variant=hero.get("pet",{})
    if not value is Dictionary: _label("Pet state unavailable."); return
    var pet:Dictionary=value
    PET.ensure_state(pet)
    var s:Dictionary=PET.combat_stats(pet)
    _label("%s • %s • Lv.%d / 250" % [str(pet.get("name","Pet")),str(pet.get("species","Pet")),int(pet.get("level",1))])
    _label("Attack %d • Magic %d • Defense %d • HP %d • Crit %d • Refine +%d" % [int(s["attack"]),int(s["magic"]),int(s["defense"]),int(s["hp"]),int(s["crit"]),int(pet.get("refine",0))])
    PET_SKILLS.ensure_state(pet)
    _heading("PET SKILL TREE")
    for skill in PET_SKILLS.all_skills(str(pet.get("species","Pet"))):
        var id:String=str(skill["id"]); var lvl:int=PET_SKILLS.skill_level(pet,id)
        var b=Button.new(); b.text="%s • Lv.%d/%d • Cost %d" % [str(skill["name"]),lvl,int(skill["max_level"]),int(skill["cost"])]
        b.pressed.connect(_learn_pet.bind(id)); body.add_child(b)

func _learn_pet(id:String)->void:
    var value:Variant=legacy.get("hero")
    if value is Dictionary and value.get("pet",{}) is Dictionary and PET_SKILLS.learn(value["pet"],id): SAVE.save_game(value)
    _render_mode()

func _skills(hero:Dictionary)->void:
    _heading("HERO SKILL TREE")
    for skill in SKILLS.all_skills(str(hero.get("class","Warrior"))):
        var id:String=str(skill["id"]); var lvl:int=SKILLS.skill_level(hero,id)
        var b=Button.new(); b.text="%s • Lv.%d/%d • Required %d • Cost %d" % [str(skill["name"]),lvl,int(skill["max_level"]),int(skill["required_level"]),int(skill["cost"])]
        b.pressed.connect(_learn_skill.bind(id)); body.add_child(b)
        _label(str(skill.get("description","")))

func _learn_skill(id:String)->void:
    if SKILLS.learn(legacy.get("hero"),id): SAVE.save_game(legacy.get("hero"))
    _render_mode()

func _inventory(hero:Dictionary)->void:
    _heading("INVENTORY — ITEMS AND CARDS")
    var inv:Dictionary=hero.get("inventory",{}) if hero.get("inventory",{}) is Dictionary else {}
    for key in inv.keys():
        var id:String=str(key); var raw:Variant=inv[key]; var amount:int=int(raw.get("amount",0)) if raw is Dictionary else int(raw)
        if amount<=0: continue
        var b=Button.new(); b.text=id+"  x"+str(amount); b.pressed.connect(_use_item.bind(id)); body.add_child(b)

func _use_item(id:String)->void:
    var value:Variant=legacy.get("hero")
    if value is Dictionary:
        var result:Dictionary=INVENTORY.equip(value,id)
        if bool(result.get("ok",false)): SAVE.save_game(value)
    _render_mode()

func _equipment(hero:Dictionary)->void:
    _heading("EQUIPMENT — LIVE LOADOUT")
    var eq:Dictionary=hero.get("equipment",{}) if hero.get("equipment",{}) is Dictionary else {}
    for key in ["head","head_middle","head_lower","armor","garment","weapon","offhand","shoes","accessory_1","accessory_2"]:
        var raw:Variant=eq.get(key,null); var text:String="Empty"
        if raw is Dictionary: text=str(raw.get("id",raw.get("name","Empty")))+" +"+str(int(raw.get("refine",0)))
        elif raw is String and not str(raw).is_empty(): text=str(raw)
        _label(key.to_upper()+"    "+text)

func _refine(hero:Dictionary)->void:
    _heading("REFINEMENT")
    _label("Age improves refine success and lowers Phracon, Zeny, Emveretarcon and Oridecon consumption.")
    _label("Current age %d • Zeny %d" % [int(hero.get("age",18)),int(hero.get("zeny",0))])
    for material in ["Phracon","Emveretarcon","Oridecon"]:
        var b=Button.new(); b.text="REFINE WITH "+material; b.pressed.connect(_refine_message.bind(material)); body.add_child(b)

func _refine_message(material:String)->void:
    status.text="Choose an equipped item to refine with "+material+"."
    if panel!=null: _render_mode()

func _map(hero:Dictionary)->void:
    _heading("WORLD MAP — TOWNS / FIELDS / DUNGEONS")
    _label("Current: "+TELEPORT.map_name(int(hero.get("map_id",0))))
    _label("Fast travel uses destination names only: @go [map]")
    _heading("TOWNS")
    for map_id in range(0,10): _warp_button(map_id)
    _heading("FIELDS")
    for map_id in range(20,30): _warp_button(map_id)
    _heading("DUNGEONS")
    for map_id in range(10,20): _warp_button(map_id)

func _warp_button(map_id:int)->void:
    var b=Button.new()
    b.text="@go "+TELEPORT.map_name(map_id)
    b.pressed.connect(_warp.bind(map_id))
    body.add_child(b)

func _warp(map_id:int)->void:
    var command:String="@go "+TELEPORT.map_name(map_id)
    if legacy!=null and legacy.has_method("handle_command"):
        legacy.call("handle_command",command)
    else:
        status.text="Fast travel request: "+command
    _render_mode()

func _heading(text:String)->void:
    var l=Label.new(); l.text=text; l.add_theme_font_size_override("font_size",16); l.add_theme_color_override("font_color",Color("#e7ca7a")); body.add_child(l)

func _label(text:String)->void:
    var l=Label.new(); l.text=text; l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; l.add_theme_font_size_override("font_size",12); l.add_theme_color_override("font_color",Color("#e8edf3")); body.add_child(l)

func _refresh_status()->void:
    if legacy==null or title==null: return
    var value:Variant=legacy.get("hero")
    if not value is Dictionary: return
    var hero:Dictionary=value
    var s:Dictionary=CHARACTER.stats(hero)
    if title!=null: title.text="HONOUR WAR • Lv.%d • %s • Age %d" % [int(hero.get("level",1)),str(hero.get("class","Warrior")),int(hero.get("age",18))]
    if status!=null: status.text="HP %d/%d  SP %d/%d  ATK %d  DEF %d  Zeny %d  •  %s" % [int(hero.get("hp",0)),int(s["max_hp"]),int(hero.get("sp",0)),int(s["max_sp"]),int(s["atk"]),int(s["def"]),int(hero.get("zeny",0)),TELEPORT.map_name(int(hero.get("map_id",0)))]

func _unhandled_key_input(event:InputEvent)->void:
    if not event is InputEventKey or not event.pressed or event.echo: return
    match event.keycode:
        KEY_ESCAPE: _close_panel()
        KEY_C: _open_mode("character")
        KEY_P: _open_mode("pet")
        KEY_K: _open_mode("skills")
        KEY_I: _open_mode("inventory")
        KEY_E: _open_mode("equipment")
        KEY_F: _open_mode("refine")
        KEY_M: _open_mode("map")

func _style(bg:Color,border:Color)->StyleBoxFlat:
    var s=StyleBoxFlat.new(); s.bg_color=bg; s.border_color=border; s.set_border_width_all(1); s.set_corner_radius_all(7); s.shadow_color=Color(0,0,0,0.62); s.shadow_size=8; return s
