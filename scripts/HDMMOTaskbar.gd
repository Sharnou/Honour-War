class_name HDMMOTaskbar
extends CanvasLayer

## Clean Honour War MMORPG HUD.
## The world remains unobstructed; progression opens as a single modal-style window.
const PANEL:=Color("#101722e8")
const BORDER:=Color("#b89959")
const TEXT:=Color("#f3ead7")
const MUTED:=Color("#91a2b8")
const HP:=Color("#c94d57")
const SP:=Color("#557edb")
const XP:=Color("#55a05c")

var game:Node
var legacy:Node
var progression_panel:Control
var progression_minimized:bool=false
var skill_slots:HBoxContainer
var hp_bar:ProgressBar
var sp_bar:ProgressBar
var xp_bar:ProgressBar
var hp_label:Label
var sp_label:Label
var xp_label:Label
var hero_label:Label
var location_label:Label
var elapsed:float=0.0

func _ready()->void:
    game=get_parent()
    if game==null: return
    legacy=game.get("legacy") as Node
    call_deferred("_build_clean_hud")

func _build_clean_hud()->void:
    _hide_redundant_huds()
    _build()
    call_deferred("_close_progression")
    _refresh()

func _hide_redundant_huds()->void:
    var names:Array[String]=["HDUIStyleDirector","PetCombatHUD3D","HeroPetComboHUD"]
    for node_name in names:
        var node:Node=get_node_or_null("../"+node_name)
        if node!=null:
            node.visible=false
            node.process_mode=Node.PROCESS_MODE_DISABLED
    if game!=null:
        var game_hud:CanvasLayer=game.get("hud") as CanvasLayer
        if game_hud!=null:
            game_hud.visible=false

func _panel_style(bg:Color=PANEL)->StyleBoxFlat:
    var s:=StyleBoxFlat.new()
    s.bg_color=bg
    s.border_color=BORDER
    s.set_border_width_all(1)
    s.set_corner_radius_all(5)
    s.shadow_color=Color(0,0,0,0.6)
    s.shadow_size=8
    return s

func _build()->void:
    var root:=Control.new()
    root.name="HonourWarCleanHUD"
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter=Control.MOUSE_FILTER_PASS
    add_child(root)

    var header:=PanelContainer.new()
    header.name="CharacterHeader"
    header.position=Vector2(16,12)
    header.size=Vector2(370,82)
    header.add_theme_stylebox_override("panel",_panel_style())
    root.add_child(header)
    var hb:=VBoxContainer.new()
    hb.add_theme_constant_override("separation",1)
    header.add_child(hb)
    hero_label=Label.new()
    hero_label.add_theme_font_size_override("font_size",16)
    hero_label.add_theme_color_override("font_color",TEXT)
    hb.add_child(hero_label)
    location_label=Label.new()
    location_label.add_theme_font_size_override("font_size",11)
    location_label.add_theme_color_override("font_color",MUTED)
    hb.add_child(location_label)

    var resources:=PanelContainer.new()
    resources.name="CharacterResources"
    resources.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
    resources.position=Vector2(-945,-96)
    resources.size=Vector2(300,82)
    resources.add_theme_stylebox_override("panel",_panel_style())
    root.add_child(resources)
    var rb:=VBoxContainer.new()
    rb.add_theme_constant_override("separation",1)
    resources.add_child(rb)
    hp_label=_resource_text(rb,"HP",HP)
    hp_bar=_bar(HP,270,10)
    rb.add_child(hp_bar)
    sp_label=_resource_text(rb,"SP",SP)
    sp_bar=_bar(SP,270,9)
    rb.add_child(sp_bar)
    xp_label=_resource_text(rb,"EXP",XP)
    xp_bar=_bar(XP,270,8)
    rb.add_child(xp_bar)

    var skills:=PanelContainer.new()
    skills.name="QuickSlotsPanel"
    skills.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
    skills.position=Vector2(-620,-96)
    skills.size=Vector2(615,82)
    skills.add_theme_stylebox_override("panel",_panel_style())
    root.add_child(skills)
    var skill_box:=VBoxContainer.new()
    skill_box.add_theme_constant_override("separation",2)
    skills.add_child(skill_box)
    var title:=Label.new()
    title.text="QUICK SLOTS   [1] [2] [3] [4] [5] [6] [7] [8]"
    title.add_theme_color_override("font_color",MUTED)
    title.add_theme_font_size_override("font_size",10)
    skill_box.add_child(title)
    skill_slots=HBoxContainer.new()
    skill_slots.add_theme_constant_override("separation",4)
    skill_box.add_child(skill_slots)
    for i in 8:
        _add_skill_slot(i)

    var system:=PanelContainer.new()
    system.name="SystemBar"
    system.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
    system.position=Vector2(15,-96)
    system.size=Vector2(590,82)
    system.add_theme_stylebox_override("panel",_panel_style())
    root.add_child(system)
    var sys_box:=HBoxContainer.new()
    sys_box.alignment=BoxContainer.ALIGNMENT_END
    sys_box.add_theme_constant_override("separation",4)
    system.add_child(sys_box)
    var entries:Array=[["CHAR","character"],["PET","pet"],["SKILLS","skills"],["INV","inventory"],["EQUIP","equipment"],["REFINE","refine"],["MAP","character"],["SYS","character"]]
    for entry in entries:
        var b:=Button.new()
        b.text=str(entry[0])
        b.custom_minimum_size=Vector2(67,62)
        b.tooltip_text=str(entry[1]).capitalize()
        b.add_theme_font_size_override("font_size",10)
        b.add_theme_stylebox_override("normal",_panel_style(Color("#202c3d")))
        b.add_theme_stylebox_override("hover",_panel_style(Color("#3b3221")))
        b.pressed.connect(_open_progression_mode.bind(str(entry[1])))
        sys_box.add_child(b)

func _resource_text(parent:VBoxContainer,name_text:String,tint:Color)->Label:
    var label:=Label.new()
    label.text=name_text
    label.add_theme_font_size_override("font_size",9)
    label.add_theme_color_override("font_color",tint)
    parent.add_child(label)
    return label

func _bar(tint:Color,width:float,height:float)->ProgressBar:
    var bar:=ProgressBar.new()
    bar.custom_minimum_size=Vector2(width,height)
    bar.show_percentage=false
    var bg:=StyleBoxFlat.new()
    bg.bg_color=Color("#090d14")
    bg.set_corner_radius_all(3)
    var fill:=StyleBoxFlat.new()
    fill.bg_color=tint
    fill.set_corner_radius_all(3)
    bar.add_theme_stylebox_override("background",bg)
    bar.add_theme_stylebox_override("fill",fill)
    return bar

func _add_skill_slot(index:int)->void:
    var b:=Button.new()
    b.name="QuickSlot_%d" % (index+1)
    b.custom_minimum_size=Vector2(70,51)
    b.text="%d\n--" % (index+1)
    b.tooltip_text="Quick slot %d" % (index+1)
    b.add_theme_font_size_override("font_size",9)
    b.add_theme_stylebox_override("normal",_panel_style(Color("#1b2635")))
    b.add_theme_stylebox_override("hover",_panel_style(Color("#3b3221")))
    b.pressed.connect(_use_slot.bind(index))
    skill_slots.add_child(b)

func _open_progression_mode(mode:String)->void:
    var ui:Node=get_node_or_null("../GameplaySystemsRuntime")
    if ui==null: return
    ui.call("_set_mode",mode)
    progression_panel=ui.get("panel") as Control
    if progression_panel==null: return
    _install_progression_chrome()
    progression_panel.visible=true
    progression_minimized=false
    _set_progression_children_visible(true)
    progression_panel.size=Vector2(520,600)
    progression_panel.position=Vector2(825,64)

func _install_progression_chrome()->void:
    if progression_panel==null: return
    if progression_panel.has_meta("hw_chrome_installed"): return
    progression_panel.set_meta("hw_chrome_installed",true)
    var bar:=PanelContainer.new()
    bar.name="ProgressionTitleBar"
    bar.position=Vector2(0,0)
    bar.size=Vector2(520,36)
    bar.add_theme_stylebox_override("panel",_panel_style(Color("#0b111be8")))
    progression_panel.add_child(bar)
    var row:=HBoxContainer.new()
    row.add_theme_constant_override("separation",3)
    bar.add_child(row)
    var title:=Label.new()
    title.text="HONOUR WAR  •  PROGRESSION"
    title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    title.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
    title.add_theme_color_override("font_color",TEXT)
    title.add_theme_font_size_override("font_size",13)
    row.add_child(title)
    var minimize:=Button.new()
    minimize.text="—"
    minimize.tooltip_text="Minimize"
    minimize.custom_minimum_size=Vector2(32,28)
    minimize.pressed.connect(_toggle_minimize)
    row.add_child(minimize)
    var close:=Button.new()
    close.text="X"
    close.tooltip_text="Close"
    close.custom_minimum_size=Vector2(32,28)
    close.pressed.connect(_close_progression)
    row.add_child(close)
    for child in progression_panel.get_children():
        if child==bar: continue
        if child is Control:
            var c:Control=child
            c.position.y=max(c.position.y,42.0)

func _set_progression_children_visible(showing:bool)->void:
    if progression_panel==null: return
    for child in progression_panel.get_children():
        if child.name=="ProgressionTitleBar": continue
        if child is Control:
            (child as Control).visible=showing

func _close_progression()->void:
    if progression_panel!=null:
        progression_panel.visible=false

func _toggle_minimize()->void:
    if progression_panel==null: return
    progression_minimized=not progression_minimized
    _set_progression_children_visible(not progression_minimized)
    progression_panel.size.y=44.0 if progression_minimized else 600.0

func _use_slot(index:int)->void:
    if legacy==null: return
    var value:Variant=legacy.get("hero")
    if not value is Dictionary: return
    var hero:Dictionary=value
    var system_script:GDScript=load("res://scripts/SkillSystem.gd") as GDScript
    if system_script==null: return
    system_script.ensure_state(hero)
    var skills:Array=system_script.all_skills(str(hero.get("class","Warrior")))
    if index>=skills.size():
        _open_progression_mode("inventory")
        return
    var id:String=str(skills[index].get("id",""))
    system_script.use(hero,id,Time.get_ticks_msec()/1000.0)

func _refresh()->void:
    if legacy==null: return
    var value:Variant=legacy.get("hero")
    if not value is Dictionary: return
    var hero:Dictionary=value
    var character:GDScript=load("res://scripts/CharacterProgressionSystem.gd") as GDScript
    if character==null: return
    var stats:Dictionary=character.stats(hero)
    var hp_max:float=float(stats.get("max_hp",1))
    var sp_max:float=float(stats.get("max_sp",1))
    var xp_progress:Dictionary=character.xp_progress(hero)
    var xp_next:int=max(1,int(xp_progress.get("next",1)))
    hp_bar.value=clamp(float(hero.get("hp",0))/max(1.0,hp_max)*100.0,0.0,100.0)
    sp_bar.value=clamp(float(hero.get("sp",0))/max(1.0,sp_max)*100.0,0.0,100.0)
    xp_bar.value=clamp(float(hero.get("xp",0))/float(xp_next)*100.0,0.0,100.0)
    hp_label.text="HP %d / %d" % [int(hero.get("hp",0)),int(hp_max)]
    sp_label.text="SP %d / %d" % [int(hero.get("sp",0)),int(sp_max)]
    xp_label.text="EXP %d / %d" % [int(hero.get("xp",0)),xp_next]
    hero_label.text="%s   Lv.%d   %s" % [str(hero.get("name","Hero")),int(hero.get("level",1)),str(hero.get("class","Warrior"))]
    location_label.text="%s   •   X %d : Y %d   •   Age %d" % [str(_map_name(hero)),int(hero.get("pos_x",0))-365,int(hero.get("pos_y",0))-120,int(hero.get("age",18))]
    if skill_slots==null: return
    var skills_script:GDScript=load("res://scripts/SkillSystem.gd") as GDScript
    if skills_script==null: return
    var skills:Array=skills_script.all_skills(str(hero.get("class","Warrior")))
    for i in skill_slots.get_child_count():
        var slot:Button=skill_slots.get_child(i) as Button
        if slot==null: continue
        if i<skills.size():
            var data:Dictionary=skills[i]
            var id:String=str(data.get("id",""))
            var level:int=skills_script.skill_level(hero,id)
            var short_name:String=str(data.get("name","SKILL"))
            if short_name.length()>9: short_name=short_name.substr(0,9)
            slot.text="%d\n%s\nLv.%d" % [i+1,short_name,level]
        else:
            slot.text="%d\nITEM" % (i+1)

func _map_name(hero:Dictionary)->String:
    var teleport:GDScript=load("res://scripts/TeleportSystem.gd") as GDScript
    if teleport!=null:
        return str(teleport.map_name(int(hero.get("map_id",0))))
    return "Map %d" % int(hero.get("map_id",0))
