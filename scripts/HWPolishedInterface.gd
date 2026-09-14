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

var scene_root:Node
var legacy:Node
var root:Control
var panel:Panel
var body:VBoxContainer
var title:Label
var status:Label
var hp_bar:ProgressBar
var sp_bar:ProgressBar
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
    for node_name in ["HWMainInterface","HDMMOTaskbar","HWFunctionalHUD","HDCombatHUD","HWCombatHUD"]:
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
    top.size=Vector2(500,104)
    top.add_theme_stylebox_override("panel",_style(Color("#07101cf2"),Color("#c9ad68")))
    root.add_child(top)
    var top_box=VBoxContainer.new()
    top.add_child(top_box)
    title=Label.new()
    title.add_theme_font_size_override("font_size",18)
    top_box.add_child(title)
    status=Label.new()
    status.add_theme_font_size_override("font_size",11)
    top_box.add_child(status)
    hp_bar=_bar("HP",Color("#d84f5b")); top_box.add_child(hp_bar)
    sp_bar=_bar("SP",Color("#4c91db")); top_box.add_child(sp_bar)

    var bar=PanelContainer.new()
    bar.anchor_left=1.0; bar.anchor_top=1.0; bar.anchor_right=1.0; bar.anchor_bottom=1.0
    bar.offset_left=-920; bar.offset_top=-112; bar.offset_right=-24; bar.offset_bottom=-24
    bar.mouse_filter=Control.MOUSE_FILTER_STOP
    bar.add_theme_stylebox_override("panel",_style(Color("#07101cf8"),Color("#c9ad68")))
    root.add_child(bar)
    var outer=VBoxContainer.new(); outer.add_theme_constant_override("separation",4); bar.add_child(outer)
    var caption=Label.new(); caption.text="COMMAND • CHARACTER • WORLD"; caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; caption.add_theme_font_size_override("font_size",10); caption.add_theme_color_override("font_color",Color("#d9bd73")); outer.add_child(caption)
    var buttons=HBoxContainer.new(); buttons.alignment=BoxContainer.ALIGNMENT_CENTER; buttons.add_theme_constant_override("separation",4); outer.add_child(buttons)
    var entries:Array=[["character","CHAR"],["pet","PET"],["skills","SKILL"],["inventory","BAG"],["equipment","EQUIP"],["refine","REFINE"],["map","MAP"],["system","MENU"]]
    for entry in entries:
        var b=ICON.new()
        b.custom_minimum_size=Vector2(104,74)
        b.setup(str(entry[0]),str(entry[1]))
        b.add_theme_stylebox_override("normal",_style(Color("#101b2a"),Color("#5e533d")))
        b.add_theme_stylebox_override("hover",_style(Color("#20334b"),Color("#e7ca7a")))
        b.add_theme_stylebox_override("pressed",_style(Color("#2a3e55"),Color("#f2d78c")))
        b.pressed.connect(_open_mode.bind(str(entry[0])))
        buttons.add_child(b)

    _refresh_status()

func _bar(label_text:String,_fill:Color)->ProgressBar:
    var p=ProgressBar.new()
    p.custom_minimum_size=Vector2(0,12)
    p.show_percentage=false
    p.tooltip_text=label_text
    var bg=_style(Color("#16202c"),Color("#3c4652")); var fill=_style(_fill,Color("#ffffff22"))
    p.add_theme_stylebox_override("background",bg)
    p.add_theme_stylebox_override("fill",fill)
    return p

func _open_mode(mode:String)->void:
    current_mode="character" if mode=="system" else mode
    _close_panel()
    _build_panel()
    _render_mode()

func _build_panel()->void:
    var window_root=Control.new(); window_root.name="HWPolishedWindow"; window_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); window_root.mouse_filter=Control.MOUSE_FILTER_STOP; root.add_child(window_root)
    var blocker=ColorRect.new(); blocker.color=Color(0,0,0,0.48); blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); window_root.add_child(blocker)
    panel=Panel.new(); panel.position=Vector2(430,74); panel.size=Vector2(1060,820); panel.add_theme_stylebox_override("panel",_style(Color("#091320fc"),Color("#cfb46d"))); window_root.add_child(panel)
    var head=PanelContainer.new(); head.position=Vector2(0,0); head.size=Vector2(1060,54); head.add_theme_stylebox_override("panel",_style(Color("#060c14"),Color("#8f783f"))); panel.add_child(head)
    var row=HBoxContainer.new(); head.add_child(row)
    title=Label.new(); title.size_flags_horizontal=Control.SIZE_EXPAND_FILL; title.add_theme_font_size_override("font_size",17); row.add_child(title)
    var close=Button.new(); close.text="CLOSE"; close.custom_minimum_size=Vector2(96,34); close.pressed.connect(_close_panel); row.add_child(close)
    var scroll=ScrollContainer.new(); scroll.position=Vector2(18,66); scroll.size=Vector2(1024,700); panel.add_child(scroll)
    body=VBoxContainer.new(); body.size_flags_horizontal=Control.SIZE_EXPAND_FILL; body.add_theme_constant_override("separation",8); scroll.add_child(body)
    var footer=Label.new(); footer.text="I Inventory   C Character   K Skills   P Pet   E Equipment   F Refine   M Map   ESC Close"; footer.position=Vector2(18,780); footer.size=Vector2(1024,28); footer.add_theme_font_size_override("font_size",10); panel.add_child(footer)

func _close_panel()->void:
    var old:Node=root.get_node_or_null("HWPolishedWindow") if root!=null else null
    if old!=null: old.queue_free()
    panel=null; body=null

func _render_mode()->void:
    if body==null or legacy==null: return
    var value:Variant=legacy.get("hero")
    if not value is Dictionary: return
    var hero:Dictionary=value
    CHARACTER.ensure_state(hero); INVENTORY.ensure_state(hero); SKILLS.ensure_state(hero); AGE.normalize(hero)
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
    _heading("CHARACTER • LIVE BUILD")
    var s:Dictionary=CHARACTER.stats(hero)
    _card("Lv.%d / 250" % int(hero.get("level",1)),"%s  •  Power %d  •  Age %d" % [str(hero.get("class","Warrior")),CHARACTER.combat_power(hero),int(hero.get("age",18))])
    _label("HP %d/%d   SP %d/%d   ATK %d   MATK %d   DEF %d   MDEF %d   Zeny %d" % [int(hero.get("hp",0)),int(s["max_hp"]),int(hero.get("sp",0)),int(s["max_sp"]),int(s["atk"]),int(s["matk"]),int(s["def"]),int(s["mdef"]),int(hero.get("zeny",0))])
    _heading("STAT POINTS")
    var stats:Dictionary=hero.get("stats",{})
    for stat in CHARACTER.STAT_NAMES:
        var row=HBoxContainer.new(); body.add_child(row)
        var l=Label.new(); l.text="%s   %d/99" % [stat.to_upper(),int(stats.get(stat,1))]; l.size_flags_horizontal=Control.SIZE_EXPAND_FILL; row.add_child(l)
        var one=Button.new(); one.text="+1"; one.disabled=int(hero.get("stat_points",0))<1; one.pressed.connect(_stat_up.bind(stat,1)); row.add_child(one)
        var five=Button.new(); five.text="+5"; five.disabled=int(hero.get("stat_points",0))<5; five.pressed.connect(_stat_up.bind(stat,5)); row.add_child(five)

func _stat_up(stat:String,amount:int)->void:
    var value:Variant=legacy.get("hero")
    if value is Dictionary and CHARACTER.allocate(value,stat,amount): SAVE.save_game(value)
    _render_mode()

func _pet(hero:Dictionary)->void:
    _heading("PET • ALWAYS-ON COMBAT PARTNER")
    var value:Variant=hero.get("pet",{})
    if not value is Dictionary: _label("Pet state unavailable."); return
    var pet:Dictionary=value; PET.ensure_state(pet); PET_SKILLS.ensure_state(pet); var s:Dictionary=PET.combat_stats(pet)
    _card(str(pet.get("species","Pet")),"%s  •  Lv.%d / 250" % [str(pet.get("name","Companion")),int(pet.get("level",1))])
    _label("ATK %d   MAGIC %d   DEF %d   HP %d   CRIT %d   REFINE +%d" % [int(s["attack"]),int(s["magic"]),int(s["defense"]),int(s["hp"]),int(s["crit"]),int(pet.get("refine",0))])
    _heading("PET SKILL TREE")
    for skill in PET_SKILLS.all_skills(str(pet.get("species","Pet"))):
        var id:String=str(skill["id"]); var lvl:int=PET_SKILLS.skill_level(pet,id)
        var b=Button.new(); b.text="%s   Lv.%d/%d   COST %d" % [str(skill["name"]),lvl,int(skill["max_level"]),int(skill["cost"])]; b.pressed.connect(_learn_pet.bind(id)); body.add_child(b)

func _learn_pet(id:String)->void:
    var value:Variant=legacy.get("hero")
    if value is Dictionary and value.get("pet",{}) is Dictionary and PET_SKILLS.learn(value["pet"],id): SAVE.save_game(value)
    _render_mode()

func _skills(hero:Dictionary)->void:
    _heading("HERO SKILL TREE")
    for skill in SKILLS.all_skills(str(hero.get("class","Warrior"))):
        var id:String=str(skill["id"]); var lvl:int=SKILLS.skill_level(hero,id)
        var b=Button.new(); b.text="%s   Lv.%d/%d   Required %d   Cost %d" % [str(skill["name"]),lvl,int(skill["max_level"]),int(skill["required_level"]),int(skill["cost"])]; b.pressed.connect(_learn_skill.bind(id)); body.add_child(b); _label(str(skill.get("description","")))

func _learn_skill(id:String)->void:
    if SKILLS.learn(legacy.get("hero"),id): SAVE.save_game(legacy.get("hero"))
    _render_mode()

func _inventory(hero:Dictionary)->void:
    _heading("INVENTORY • ITEMS / CARDS")
    var inv:Dictionary=hero.get("inventory",{}) if hero.get("inventory",{}) is Dictionary else {}
    var cards:Array=hero.get("cards",[]) if hero.get("cards",[]) is Array else []
    _label("Cards owned: %d" % cards.size())
    for key in inv.keys():
        var id:String=str(key); var raw:Variant=inv[key]; var amount:int=int(raw.get("amount",0)) if raw is Dictionary else int(raw)
        if amount<=0: continue
        var item:Button=Button.new(); item.text="%s    x%d" % [id,amount]; item.alignment=HORIZONTAL_ALIGNMENT_LEFT; item.pressed.connect(_use_item.bind(id)); body.add_child(item)

func _use_item(id:String)->void:
    var value:Variant=legacy.get("hero")
    if value is Dictionary:
        var result:Dictionary=INVENTORY.equip(value,id)
        if not bool(result.get("ok",false)):
            result=INVENTORY.use_consumable(value,id)
        if bool(result.get("ok",false)): SAVE.save_game(value)
    _render_mode()

func _equipment(hero:Dictionary)->void:
    _heading("EQUIPMENT • LIVE LOADOUT")
    var eq:Dictionary=hero.get("equipment",{}) if hero.get("equipment",{}) is Dictionary else {}
    var slots:Array=["head","head_middle","head_lower","armor","garment","weapon","offhand","shoes","accessory_1","accessory_2"]
    for key in slots:
        var raw:Variant=eq.get(key,null); var text:String="EMPTY"
        if raw is Dictionary: text=str(raw.get("id",raw.get("name","EMPTY")))+"   +"+str(int(raw.get("refine",0)))
        elif raw is String and not str(raw).is_empty(): text=str(raw)
        var b=Button.new(); b.text="%-16s  %s" % [key.to_upper(),text]; b.alignment=HORIZONTAL_ALIGNMENT_LEFT
        if raw!=null: b.pressed.connect(_unequip.bind(key))
        body.add_child(b)
    _label("Click an occupied slot to unequip it back into inventory.")

func _unequip(slot:String)->void:
    var value:Variant=legacy.get("hero")
    if value is Dictionary:
        var result:Dictionary=INVENTORY.unequip(value,slot)
        if bool(result.get("ok",false)): SAVE.save_game(value)
    _render_mode()

func _refine(hero:Dictionary)->void:
    _heading("REFINEMENT • AGE-ASSISTED")
    _label("Age improves success and reduces material/zeny burden. Select an equipped slot below.")
    var eq:Dictionary=hero.get("equipment",{}) if hero.get("equipment",{}) is Dictionary else {}
    for key in INVENTORY.EQUIPMENT_SLOTS:
        if not eq.has(key): continue
        var item:Variant=eq[key]
        var b=Button.new(); b.text="REFINE  %s  +%d" % [str(item.get("id",key)),int(item.get("refine",0))]; b.pressed.connect(_refine_slot.bind(key)); body.add_child(b)

func _refine_slot(slot:String)->void:
    var value:Variant=legacy.get("hero")
    if value is Dictionary:
        var rng:=RandomNumberGenerator.new(); rng.randomize()
        var result:Dictionary=INVENTORY.refine(value,slot,rng.randf())
        if bool(result.get("ok",false)): SAVE.save_game(value)
        elif status!=null: status.text="Refine: "+str(result.get("reason","failed"))
    _render_mode()

func _map(hero:Dictionary)->void:
    _heading("WORLD MAP • TOWNS / FIELDS / DUNGEONS")
    _label("Current: "+TELEPORT.map_name(int(hero.get("map_id",0))))
    _label("Fast travel command: @go [map]  •  No coordinate requirement")
    _map_section("TOWNS",range(0,10))
    _map_section("FIELDS",range(20,30))
    _map_section("DUNGEONS",range(10,20))

func _map_section(header:String,ids:Array)->void:
    _heading(header)
    for map_id in ids:
        var b=Button.new(); b.text="⟶  @go "+TELEPORT.map_name(int(map_id)); b.alignment=HORIZONTAL_ALIGNMENT_LEFT; b.pressed.connect(_warp.bind(int(map_id))); body.add_child(b)

func _warp(map_id:int)->void:
    var command:String="@go "+TELEPORT.map_name(map_id)
    if legacy!=null and legacy.has_method("handle_command"): legacy.call("handle_command",command)
    _render_mode()

func _heading(text:String)->void:
    var l=Label.new(); l.text=text; l.add_theme_font_size_override("font_size",16); l.add_theme_color_override("font_color",Color("#e7ca7a")); body.add_child(l)

func _label(text:String)->void:
    var l=Label.new(); l.text=text; l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; l.add_theme_font_size_override("font_size",12); l.add_theme_color_override("font_color",Color("#e8edf3")); body.add_child(l)

func _card(head_text:String,sub_text:String)->void:
    var p=PanelContainer.new(); p.custom_minimum_size=Vector2(0,72); p.add_theme_stylebox_override("panel",_style(Color("#101d2e"),Color("#5f7086"))); body.add_child(p)
    var vb=VBoxContainer.new(); p.add_child(vb)
    var h=Label.new(); h.text=head_text; h.add_theme_font_size_override("font_size",20); h.add_theme_color_override("font_color",Color("#f1d98d")); vb.add_child(h)
    var s=Label.new(); s.text=sub_text; s.add_theme_font_size_override("font_size",12); vb.add_child(s)

func _refresh_status()->void:
    if legacy==null or title==null: return
    var value:Variant=legacy.get("hero")
    if not value is Dictionary: return
    var hero:Dictionary=value; var s:Dictionary=CHARACTER.stats(hero)
    title.text="HONOUR WAR  •  Lv.%d  •  %s  •  Age %d" % [int(hero.get("level",1)),str(hero.get("class","Warrior")),int(hero.get("age",18))]
    status.text="HP %d/%d   SP %d/%d   ATK %d   DEF %d   Zeny %d   •   %s" % [int(hero.get("hp",0)),int(s["max_hp"]),int(hero.get("sp",0)),int(s["max_sp"]),int(s["atk"]),int(s["def"]),int(hero.get("zeny",0)),TELEPORT.map_name(int(hero.get("map_id",0)))]
    if hp_bar!=null: hp_bar.value=float(int(hero.get("hp",0))); hp_bar.max_value=max(1,float(int(s["max_hp"])))
    if sp_bar!=null: sp_bar.value=float(int(hero.get("sp",0))); sp_bar.max_value=max(1,float(int(s["max_sp"])))

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
    var s=StyleBoxFlat.new(); s.bg_color=bg; s.border_color=border; s.set_border_width_all(1); s.set_corner_radius_all(8); s.shadow_color=Color(0,0,0,0.62); s.shadow_size=8; return s
