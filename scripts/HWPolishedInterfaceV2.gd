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
const BIND_RETRY_SECONDS:float=0.50

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
var bound:bool=false
var bind_queued:bool=false
var bind_retry_timer:float=0.0

func _ready()->void:
    layer=120
    _queue_bind()

func _queue_bind()->void:
    if bound or bind_queued:
        return
    bind_queued=true
    call_deferred("_bind")

func _bind()->void:
    bind_queued=false
    if bound:
        return
    scene_root=get_tree().current_scene
    # Autoloads are initialized before the main scene in headless scripts. Do
    # not recursively queue deferred work while current_scene is unavailable.
    # _process() retries at a bounded cadence once a real scene exists.
    if scene_root==null or not is_instance_valid(scene_root):
        return
    if root!=null and is_instance_valid(root):
        bound=true
        return
    legacy=scene_root.get_node_or_null("LegacyGame")
    if legacy==null or not is_instance_valid(legacy):
        return
    _disable_competing_huds()
    _build()
    bound=true
    bind_retry_timer=0.0

func _process(delta:float)->void:
    var safe_delta:float=max(0.0,delta)
    if not bound:
        bind_retry_timer+=safe_delta
        if bind_retry_timer>=BIND_RETRY_SECONDS:
            bind_retry_timer=0.0
            _queue_bind()
        return
    if scene_root==null or not is_instance_valid(scene_root):
        bound=false
        root=null
        bind_retry_timer=0.0
        return
    if legacy==null or not is_instance_valid(legacy):
        legacy=scene_root.get_node_or_null("LegacyGame")
        if legacy==null:
            bound=false
            return
    _refresh_status()

func _disable_competing_huds()->void:
    for node_name:String in ["HWMainInterface","HDMMOTaskbar","HWFunctionalHUD","HDCombatHUD","HWCombatHUD"]:
        var n:Node=scene_root.get_node_or_null(node_name)
        if n!=null and n!=self:
            n.visible=false
            n.process_mode=Node.PROCESS_MODE_DISABLED

func _build()->void:
    if root!=null and is_instance_valid(root):
        return
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
    hp_bar=_bar(Color("#d84f5b"))
    top_box.add_child(hp_bar)
    sp_bar=_bar(Color("#4c91db"))
    top_box.add_child(sp_bar)

    # HUD zoning: status top-left, command/objectives top-right, combat skills bottom-center.
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
        ["character","CHAR"],["pet","PET"],["skills","SKILLS"],["inventory","BAG"],["equipment","EQUIP"],["refine","REFINE"],["map","MAP"],["objectives","OBJECTIVES"],["system","MENU"]
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

func _bar(fill:Color)->ProgressBar:
    var p:ProgressBar=ProgressBar.new()
    p.custom_minimum_size=Vector2(0,13)
    p.show_percentage=false
    p.add_theme_stylebox_override("background",_style(Color("#16202c"),Color("#3c4652")))
    p.add_theme_stylebox_override("fill",_style(fill,Color("#ffffff22")))
    return p

func _open_mode(next_mode:String)->void:
    if not MODES.has(next_mode):
        next_mode="character"
    mode=next_mode
    _close_panel()
    _build_panel()
    _render_mode()

func _build_panel()->void:
    if root==null or not is_instance_valid(root):
        return
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
    head.size=Vector2(1260,58)
    head.add_theme_stylebox_override("panel",_style(Color("#060c14"),Color("#8f783f")))
    panel.add_child(head)
    var row:HBoxContainer=HBoxContainer.new()
    head.add_child(row)
    var panel_title:Label=Label.new()
    panel_title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    panel_title.add_theme_font_size_override("font_size",18)
    row.add_child(panel_title)
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
    footer.text="I Inventory   C Character   K Skills   P Pet   E Equipment   F Refine   M Map   O Objectives   F1 System   ESC Close"
    footer.position=Vector2(20,786)
    footer.size=Vector2(1220,28)
    footer.add_theme_font_size_override("font_size",10)
    footer.add_theme_color_override("font_color",Color("#93a5b9"))
    panel.add_child(footer)
    if mode=="character":
        panel_title.text="HONOUR WAR • CHARACTER"
    elif mode=="pet":
        panel_title.text="HONOUR WAR • PET"
    elif mode=="skills":
        panel_title.text="HONOUR WAR • SKILLS"
    elif mode=="inventory":
        panel_title.text="HONOUR WAR • INVENTORY"
    elif mode=="equipment":
        panel_title.text="HONOUR WAR • EQUIPMENT"
    elif mode=="refine":
        panel_title.text="HONOUR WAR • REFINE"
    elif mode=="map":
        panel_title.text="HONOUR WAR • MAP"
    elif mode=="objectives":
        panel_title.text="HONOUR WAR • OBJECTIVES"
    else:
        panel_title.text="HONOUR WAR • SYSTEM"

func _close_panel()->void:
    var old:Node=root.get_node_or_null("HWPolishedWindowV2") if root!=null else null
    if old!=null:
        old.queue_free()
    panel=null
    body=null

func _render_mode()->void:
    if body==null or legacy==null or not is_instance_valid(legacy):
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
    if value is Dictionary and CHARACTER.allocate(value,stat,amount):
        SAVE.save_game(value)
    _render_mode()

func _pet(hero:Dictionary)->void:
    _heading("PET • ALWAYS-ON COMBAT PARTNER")
    var value:Variant=hero.get("pet",{})
    if not value is Dictionary:
        _label("Pet state unavailable.")
        return
    var pet:Dictionary=value
    PET.ensure_state(pet)
    PET_SKILLS.ensure_state(pet)
    var s:Dictionary=PET.combat_stats(pet)
    _card(str(pet.get("species","Pet")),"%s  •  Lv.%d / 250" % [str(pet.get("name","Companion")),int(pet.get("level",1))])
    _label("ATK %d    MAGIC %d    DEF %d    HP %d    CRIT %d    REFINE +%d" % [int(s["attack"]),int(s["magic"]),int(s["defense"]),int(s["hp"]),int(s["crit"]),int(pet.get("refine",0))])
    _heading("PET SKILL TREE")
    for skill in PET_SKILLS.all_skills(str(pet.get("species","Pet"))):
        var id:String=str(skill["id"])
        var lvl:int=PET_SKILLS.skill_level(pet,id)
        var b:Button=Button.new()
        b.text="%s    Lv.%d / %d    COST %d" % [str(skill["name"]),lvl,int(skill["max_level"]),int(skill["cost"])]
        b.pressed.connect(_learn_pet.bind(id))
        body.add_child(b)

func _learn_pet(id:String)->void:
    var value:Variant=legacy.get("hero")
    if value is Dictionary:
        var pv:Variant=value.get("pet",{})
        if pv is Dictionary and PET_SKILLS.learn(pv,id):
            SAVE.save_game(value)
    _render_mode()

func _skills(hero:Dictionary)->void:
    _heading("HERO SKILL TREE")
    for skill in SKILLS.all_skills(str(hero.get("class","Warrior"))):
        var id:String=str(skill["id"])
        var lvl:int=SKILLS.skill_level(hero,id)
        var b:Button=Button.new()
        b.text="%s    Lv.%d / %d    Required %d    Cost %d" % [str(skill["name"]),lvl,int(skill["max_level"]),int(skill["required_level"]),int(skill["cost"])]
        b.pressed.connect(_learn_skill.bind(id))
        body.add_child(b)
        _label(str(skill.get("description","")))

func _learn_skill(id:String)->void:
    var value:Variant=legacy.get("hero")
    if value is Dictionary and SKILLS.learn(value,id):
        SAVE.save_game(value)
    _render_mode()

func _inventory(hero:Dictionary)->void:
    _heading("INVENTORY • ITEMS / CARDS")
    var inv:Dictionary=hero.get("inventory",{}) if hero.get("inventory",{}) is Dictionary else {}
    var cards:Array=hero.get("cards",[]) if hero.get("cards",[]) is Array else []
    _card("ITEM BAG","Cards owned: %d" % cards.size())
    var count:int=0
    for key in inv.keys():
        var id:String=str(key)
        var raw:Variant=inv[key]
        var amount:int=int(raw.get("amount",0)) if raw is Dictionary else int(raw)
        if amount<=0:
            continue
        count+=1
        var item:Button=Button.new()
        item.text="USE / EQUIP    %s    x%d" % [id,amount]
        item.alignment=HORIZONTAL_ALIGNMENT_LEFT
        item.pressed.connect(_use_item.bind(id))
        body.add_child(item)
    if count==0:
        _label("Inventory is empty. Defeat monsters to acquire loot.")

func _use_item(id:String)->void:
    var value:Variant=legacy.get("hero")
    if value is Dictionary:
        var result:Dictionary=INVENTORY.equip(value,id)
        if not bool(result.get("ok",false)):
            result=INVENTORY.use_consumable(value,id)
        if bool(result.get("ok",false)):
            SAVE.save_game(value)
    _render_mode()

func _equipment(hero:Dictionary)->void:
    _heading("EQUIPMENT • LIVE LOADOUT")
    var eq:Dictionary=hero.get("equipment",{}) if hero.get("equipment",{}) is Dictionary else {}
    for slot in INVENTORY.EQUIPMENT_SLOTS:
        var raw:Variant=eq.get(slot,null)
        var text:String="EMPTY"
        if raw is Dictionary:
            text=str(raw.get("id",raw.get("name",slot)))+"    +"+str(int(raw.get("refine",0)))
        elif raw is String and not str(raw).is_empty():
            text=str(raw)
        var b:Button=Button.new()
        b.text="%-16s  %s" % [slot.to_upper(),text]
        b.alignment=HORIZONTAL_ALIGNMENT_LEFT
        b.disabled=raw==null
        if raw!=null:
            b.pressed.connect(_unequip.bind(slot))
        body.add_child(b)
    _label("Click an occupied slot to unequip.")

func _unequip(slot:String)->void:
    var value:Variant=legacy.get("hero")
    if value is Dictionary:
        var result:Dictionary=INVENTORY.unequip(value,slot)
        if bool(result.get("ok",false)):
            SAVE.save_game(value)
    _render_mode()

func _refine(hero:Dictionary)->void:
    _heading("REFINEMENT • AGE-ASSISTED")
    _label("Age raises refine success and lowers Phracon / Emveretarcon / Oridecon and Zeny burden.")
    var eq:Dictionary=hero.get("equipment",{}) if hero.get("equipment",{}) is Dictionary else {}
    var count:int=0
    for slot in INVENTORY.EQUIPMENT_SLOTS:
        if not eq.has(slot):
            continue
        count+=1
        var item:Variant=eq[slot]
        var b:Button=Button.new()
        b.text="REFINE    %-16s    +%d" % [str(item.get("id",slot)),int(item.get("refine",0))]
        b.alignment=HORIZONTAL_ALIGNMENT_LEFT
        b.pressed.connect(_refine_slot.bind(slot))
        body.add_child(b)
    if count==0:
        _label("Equip an item before refining.")

func _refine_slot(slot:String)->void:
    var value:Variant=legacy.get("hero")
    if value is Dictionary:
        var rng:RandomNumberGenerator=RandomNumberGenerator.new()
        rng.randomize()
        var result:Dictionary=INVENTORY.refine(value,slot,rng.randf())
        if bool(result.get("ok",false)):
            SAVE.save_game(value)
        elif status!=null:
            status.text="Refine: "+str(result.get("reason","failed"))
    _render_mode()

func _map(hero:Dictionary)->void:
    _heading("WORLD MAP • TOWNS / FIELDS / DUNGEONS")
    _card("CURRENT LOCATION",TELEPORT.map_name(int(hero.get("map_id",0)))+"   •   @go [map]")
    _map_section("TOWNS",range(0,10))
    _map_section("FIELDS",range(20,30))
    _map_section("DUNGEONS",range(10,20))

func _map_section(header:String,ids:Array)->void:
    _heading(header)
    for map_id in ids:
        var b:Button=Button.new()
        b.text="FAST TRAVEL   @go "+TELEPORT.map_name(int(map_id))
        b.alignment=HORIZONTAL_ALIGNMENT_LEFT
        b.pressed.connect(_warp.bind(int(map_id)))
        body.add_child(b)

func _warp(map_id:int)->void:
    var command:String="@go "+TELEPORT.map_name(map_id)
    if legacy!=null and legacy.has_method("handle_command"):
        legacy.call("handle_command",command)
    _render_mode()

func _objectives(hero:Dictionary)->void:
    _heading("OBJECTIVES • PROGRESSION")
    var completed:Variant=hero.get("quests_completed",[])
    var progress:Variant=hero.get("quest_progress",{})
    var completed_count:int=completed.size() if completed is Array else 0
    _card("QUEST LOG","Completed %d" % completed_count)
    if progress is Dictionary and not progress.is_empty():
        for key in progress.keys():
            _label(str(key)+"  •  "+str(progress[key]))
    else:
        _label("No active quest objectives yet.")
    _heading("CORE OBJECTIVES")
    _objective_row("Reach level 25 to unlock Specialization",int(hero.get("level",1))>=25)
    _objective_row("Reach level 50 to unlock Advanced class",int(hero.get("level",1))>=50)
    _objective_row("Reach level 100 to unlock Mastery",int(hero.get("level",1))>=100)
    _objective_row("Reach level 200 to unlock Transcendence",int(hero.get("level",1))>=200)
    _objective_row("Reach level 250 — hero level cap",int(hero.get("level",1))>=250)
    var city:Variant=hero.get("city_building",{})
    _objective_row("Build a city base",city is Dictionary and not (city as Dictionary).is_empty())

func _objective_row(text:String,done:bool)->void:
    var b:Button=Button.new()
    b.text=("✓  " if done else "□  ")+text
    b.disabled=true
    b.alignment=HORIZONTAL_ALIGNMENT_LEFT
    body.add_child(b)

func _system(hero:Dictionary)->void:
    _heading("SYSTEM • SAVE / SESSION")
    _card("SESSION","Autosave enabled • visual state and progression persist")
    _label("Hero: %s   •   Class: %s   •   Map: %s" % [str(hero.get("name","Hero")),str(hero.get("class","Warrior")),TELEPORT.map_name(int(hero.get("map_id",0)))])
    _label("Age %d   •   Online %.2f days   •   Level %d / 250" % [int(hero.get("age",18)),float(hero.get("online_days",0.0)),int(hero.get("level",1))])
    var save:Button=Button.new()
    save.text="SAVE GAME NOW"
    save.pressed.connect(_save_now)
    body.add_child(save)
    var full:Button=Button.new()
    full.text="RESTORE HP + SP TO MAX"
    full.pressed.connect(_restore_vitals)
    body.add_child(full)

func _save_now()->void:
    var value:Variant=legacy.get("hero")
    if value is Dictionary:
        SAVE.save_game(value)
        if status!=null:
            status.text="Game saved."

func _restore_vitals()->void:
    var value:Variant=legacy.get("hero")
    if value is Dictionary:
        var s:Dictionary=CHARACTER.stats(value)
        value["hp"]=int(s["max_hp"])
        value["sp"]=int(s["max_sp"])
        SAVE.save_game(value)
    _render_mode()

func _heading(text:String)->void:
    var l:Label=Label.new()
    l.text=text
    l.add_theme_font_size_override("font_size",16)
    l.add_theme_color_override("font_color",Color("#e7ca7a"))
    body.add_child(l)

func _label(text:String)->void:
    var l:Label=Label.new()
    l.text=text
    l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    l.add_theme_font_size_override("font_size",12)
    l.add_theme_color_override("font_color",Color("#e8edf3"))
    body.add_child(l)

func _card(head_text:String,sub_text:String)->void:
    var p:PanelContainer=PanelContainer.new()
    p.custom_minimum_size=Vector2(0,72)
    p.add_theme_stylebox_override("panel",_style(Color("#101d2e"),Color("#5f7086")))
    body.add_child(p)
    var vb:VBoxContainer=VBoxContainer.new()
    vb.add_theme_constant_override("separation",2)
    p.add_child(vb)
    var h:Label=Label.new()
    h.text=head_text
    h.add_theme_font_size_override("font_size",20)
    h.add_theme_color_override("font_color",Color("#f1d98d"))
    vb.add_child(h)
    var s:Label=Label.new()
    s.text=sub_text
    s.add_theme_font_size_override("font_size",12)
    vb.add_child(s)

func _refresh_status()->void:
    if legacy==null or not is_instance_valid(legacy) or title==null or status==null:
        return
    var value:Variant=legacy.get("hero")
    if not value is Dictionary:
        return
    var hero:Dictionary=value
    var s:Dictionary=CHARACTER.stats(hero)
    title.text="HONOUR WAR   •   Lv.%d / 250   •   %s   •   Age %d" % [int(hero.get("level",1)),str(hero.get("class","Warrior")),int(hero.get("age",18))]
    status.text="HP %d / %d    SP %d / %d    ATK %d    DEF %d    Zeny %d    •    %s" % [int(hero.get("hp",0)),int(s["max_hp"]),int(hero.get("sp",0)),int(s["max_sp"]),int(s["atk"]),int(s["def"]),int(hero.get("zeny",0)),TELEPORT.map_name(int(hero.get("map_id",0)))]
    if hp_bar!=null:
        hp_bar.value=float(clamp(int(hero.get("hp",0)),0,int(s["max_hp"])))
        hp_bar.max_value=max(1,int(s["max_hp"]))
    if sp_bar!=null:
        sp_bar.value=float(clamp(int(hero.get("sp",0)),0,int(s["max_sp"])))
        sp_bar.max_value=max(1,int(s["max_sp"]))

func _unhandled_key_input(event:InputEvent)->void:
    if not event is InputEventKey or not event.pressed or event.echo:
        return
    match event.keycode:
        KEY_ESCAPE: _close_panel()
        KEY_C: _open_mode("character")
        KEY_P: _open_mode("pet")
        KEY_K: _open_mode("skills")
        KEY_I: _open_mode("inventory")
        KEY_E: _open_mode("equipment")
        KEY_F: _open_mode("refine")
        KEY_M: _open_mode("map")
        KEY_O: _open_mode("objectives")
        KEY_F1: _open_mode("system")

func _style(fill:Color,border:Color)->StyleBoxFlat:
    var box=StyleBoxFlat.new()
    box.bg_color=fill
    box.border_color=border
    box.set_border_width_all(1)
    box.corner_radius_top_left=6
    box.corner_radius_top_right=6
    box.corner_radius_bottom_left=6
    box.corner_radius_bottom_right=6
    box.content_margin_left=10
    box.content_margin_right=10
    box.content_margin_top=7
    box.content_margin_bottom=7
    return box