class_name HDMMOTaskbar
extends CanvasLayer

## Honour War MMORPG HUD. The taskbar owns quick actions plus a readable hit
## overlay and progression-window access.
const PANEL:=Color("#121a26e8")
const BORDER:=Color("#b89959")
const TEXT:=Color("#f3ead7")
const MUTED:=Color("#91a2b8")
const HP:=Color("#c94d57")
const SP:=Color("#557edb")
const XP:=Color("#55a05c")

var game:Node
var legacy:Node
var hp_bar:ProgressBar
var sp_bar:ProgressBar
var xp_bar:ProgressBar
var hp_text:Label
var sp_text:Label
var xp_text:Label
var hero_label:Label
var map_label:Label
var skill_slots:HBoxContainer
var hit_panel:PanelContainer
var hit_title:Label
var hit_number:Label
var hit_detail:Label
var progression_panel:Control
var progression_chrome:Control
var elapsed:float=0.0
var hit_tween:Tween

func _ready()->void:
    game=get_parent()
    if game==null: return
    legacy=game.get("legacy") as Node
    call_deferred("_build_safe")

func _build_safe()->void:
    if game==null: return
    _build()
    _install_progression_window_chrome()
    _connect_hit_feedback()
    _refresh()

func _process(delta:float)->void:
    elapsed+=delta
    if elapsed<0.25: return
    elapsed=0.0
    if game==null: return
    if legacy==null: legacy=game.get("legacy") as Node
    _refresh()

func _panel_style(bg:Color=PANEL)->StyleBoxFlat:
    var s:=StyleBoxFlat.new()
    s.bg_color=bg
    s.border_color=BORDER
    s.set_border_width_all(1)
    s.set_corner_radius_all(5)
    s.shadow_color=Color(0,0,0,0.55)
    s.shadow_size=8
    return s

func _build()->void:
    var root:=Control.new()
    root.name="MMOHUD"
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter=Control.MOUSE_FILTER_PASS
    add_child(root)

    var header:=PanelContainer.new()
    header.position=Vector2(16,12)
    header.size=Vector2(430,72)
    header.add_theme_stylebox_override("panel",_panel_style())
    root.add_child(header)
    var hb:=VBoxContainer.new(); hb.add_theme_constant_override("separation",1); header.add_child(hb)
    hero_label=Label.new(); hero_label.add_theme_font_size_override("font_size",15); hero_label.add_theme_color_override("font_color",TEXT); hb.add_child(hero_label)
    map_label=Label.new(); map_label.add_theme_font_size_override("font_size",11); map_label.add_theme_color_override("font_color",MUTED); hb.add_child(map_label)

    hit_panel=PanelContainer.new()
    hit_panel.name="HITWindow"
    hit_panel.position=Vector2(790,82)
    hit_panel.size=Vector2(340,120)
    hit_panel.visible=false
    hit_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
    hit_panel.add_theme_stylebox_override("panel",_panel_style(Color("#180f12e8")))
    root.add_child(hit_panel)
    var hv:=VBoxContainer.new(); hv.add_theme_constant_override("separation",-2); hit_panel.add_child(hv)
    hit_title=Label.new(); hit_title.text="HIT"; hit_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; hit_title.add_theme_font_size_override("font_size",22); hit_title.add_theme_color_override("font_color",Color("#f0b44b")); hv.add_child(hit_title)
    hit_number=Label.new(); hit_number.text="0"; hit_number.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; hit_number.add_theme_font_size_override("font_size",42); hit_number.add_theme_color_override("font_color",Color("#fff1d0")); hv.add_child(hit_number)
    hit_detail=Label.new(); hit_detail.text="Damage"; hit_detail.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; hit_detail.add_theme_font_size_override("font_size",11); hit_detail.add_theme_color_override("font_color",MUTED); hv.add_child(hit_detail)

    var resources:=PanelContainer.new()
    resources.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
    resources.position=Vector2(-940,-130)
    resources.size=Vector2(350,112)
    resources.add_theme_stylebox_override("panel",_panel_style())
    root.add_child(resources)
    var rb:=VBoxContainer.new(); rb.add_theme_constant_override("separation",2); resources.add_child(rb)
    hp_text=_resource_row(rb,"HP",HP); hp_bar=_bar(HP); rb.add_child(hp_bar)
    sp_text=_resource_row(rb,"SP",SP); sp_bar=_bar(SP); rb.add_child(sp_bar)
    xp_text=_resource_row(rb,"EXP",XP); xp_bar=_bar(XP); rb.add_child(xp_bar)

    var action:=PanelContainer.new()
    action.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
    action.position=Vector2(-555,-130)
    action.size=Vector2(760,112)
    action.add_theme_stylebox_override("panel",_panel_style())
    root.add_child(action)
    var av:=VBoxContainer.new(); av.add_theme_constant_override("separation",4); action.add_child(av)
    var hotkey_title:=Label.new(); hotkey_title.text="SKILL / ITEM QUICK SLOTS     [1] [2] [3] [4] [5] [6] [7] [8]"; hotkey_title.add_theme_color_override("font_color",MUTED); hotkey_title.add_theme_font_size_override("font_size",10); av.add_child(hotkey_title)
    skill_slots=HBoxContainer.new(); skill_slots.add_theme_constant_override("separation",5); av.add_child(skill_slots)
    for i in 8: _add_skill_slot(i)

    var system:=PanelContainer.new()
    system.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
    system.position=Vector2(220,-130)
    system.size=Vector2(740,112)
    system.add_theme_stylebox_override("panel",_panel_style())
    root.add_child(system)
    var sv:=HBoxContainer.new(); sv.alignment=BoxContainer.ALIGNMENT_END; sv.add_theme_constant_override("separation",5); system.add_child(sv)
    var entries:Array=[["CHAR","character"],["PET","pet"],["SKL","skills"],["INV","inventory"],["EQP","equipment"],["REF","refine"],["MAP","character"],["SYS","character"]]
    for entry in entries:
        var b:=Button.new(); b.text=str(entry[0]); b.custom_minimum_size=Vector2(66,74); b.tooltip_text=str(entry[1]).capitalize(); b.add_theme_stylebox_override("normal",_panel_style(Color("#202c3d"))); b.add_theme_stylebox_override("hover",_panel_style(Color("#3b3221"))); b.pressed.connect(_open_mode.bind(str(entry[1]))); sv.add_child(b)

func _resource_row(parent:VBoxContainer,title:String,tint:Color)->Label:
    var label:=Label.new(); label.text=title; label.add_theme_font_size_override("font_size",10); label.add_theme_color_override("font_color",tint); parent.add_child(label); return label

func _bar(tint:Color)->ProgressBar:
    var bar:=ProgressBar.new(); bar.custom_minimum_size=Vector2(320,14); bar.show_percentage=false
    var bg:=StyleBoxFlat.new(); bg.bg_color=Color("#090d14"); bg.set_corner_radius_all(3)
    var fill:=StyleBoxFlat.new(); fill.bg_color=tint; fill.set_corner_radius_all(3)
    bar.add_theme_stylebox_override("background",bg); bar.add_theme_stylebox_override("fill",fill); return bar

func _add_skill_slot(index:int)->void:
    var b:=Button.new(); b.name="QuickSlot_%d" % (index+1); b.custom_minimum_size=Vector2(84,58); b.text="%d\n--" % (index+1); b.tooltip_text="Quick slot %d" % (index+1); b.add_theme_stylebox_override("normal",_panel_style(Color("#1b2635"))); b.add_theme_stylebox_override("hover",_panel_style(Color("#3b3221"))); b.pressed.connect(_use_slot.bind(index)); skill_slots.add_child(b)

func _open_mode(mode:String)->void:
    var ui:Node=game.get_node_or_null("GameplaySystemsRuntime")
    if ui!=null: ui.call("_set_mode",mode)
    _show_progression()

func _show_progression()->void:
    if progression_panel==null: _install_progression_window_chrome()
    if progression_panel!=null: progression_panel.visible=true
    if progression_chrome!=null: progression_chrome.visible=true

func _use_slot(index:int)->void:
    if legacy==null: return
    var value:Variant=legacy.get("hero")
    if not value is Dictionary: return
    var hero:Dictionary=value
    var system_script:GDScript=load("res://scripts/SkillSystem.gd") as GDScript
    if system_script==null: return
    system_script.ensure_state(hero)
    var class_id:String=str(hero.get("class","Warrior"))
    var skills:Array=system_script.all_skills(class_id)
    if index<skills.size():
        var id:String=str(skills[index].get("id",""))
        var result:Dictionary=system_script.use(hero,id,Time.get_ticks_msec()/1000.0)
        if not bool(result.get("ok",false)): _open_mode("skills")
    else: _open_mode("inventory")

func _connect_hit_feedback()->void:
    var feedback:Node=game.get_node_or_null("HDCombatFeedback")
    if feedback==null or not feedback.has_signal("damage_number_requested"): return
    var callback:=Callable(self,"_show_hit_window")
    if not feedback.is_connected("damage_number_requested",callback): feedback.connect("damage_number_requested",callback)

func _show_hit_window(amount:int,_world_position:Vector3,critical:bool)->void:
    if hit_panel==null: return
    hit_number.text="%d" % amount
    hit_title.text="CRITICAL HIT" if critical else "HIT"
    hit_title.add_theme_color_override("font_color",Color("#fff0a2") if critical else Color("#f0b44b"))
    hit_detail.text="Critical damage" if critical else "Damage dealt"
    hit_panel.visible=true
    hit_panel.modulate=Color(1,1,1,1)
    if hit_tween!=null and hit_tween.is_valid(): hit_tween.kill()
    hit_tween=create_tween()
    hit_tween.tween_property(hit_panel,"position",Vector2(790,64),0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    hit_tween.tween_interval(0.42)
    hit_tween.tween_property(hit_panel,"modulate",Color(1,1,1,0),0.22)
    hit_tween.tween_callback(func(): hit_panel.visible=false)

func _install_progression_window_chrome()->void:
    var ui:Node=game.get_node_or_null("GameplaySystemsRuntime")
    if ui==null: return
    progression_panel=ui.get("panel") as Control
    if progression_panel==null or progression_panel.has_meta("hw_chrome_installed"): return
    progression_panel.set_meta("hw_chrome_installed",true)
    var parent:=progression_panel.get_parent()
    if parent==null: return
    progression_chrome=PanelContainer.new()
    progression_chrome.name="ProgressionWindowTitleBar"
    progression_chrome.position=progression_panel.position+Vector2(0,0)
    progression_chrome.size=Vector2(progression_panel.size.x,38)
    progression_chrome.z_index=30
    progression_chrome.add_theme_stylebox_override("panel",_panel_style(Color("#0b111be8")))
    parent.add_child(progression_chrome)
    var row:=HBoxContainer.new(); row.add_theme_constant_override("separation",4); progression_chrome.add_child(row)
    var title:=Label.new(); title.text="HONOUR WAR  •  PROGRESSION"; title.size_flags_horizontal=Control.SIZE_EXPAND_FILL; title.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; title.add_theme_color_override("font_color",TEXT); row.add_child(title)
    var minimize:=Button.new(); minimize.text="—"; minimize.tooltip_text="Minimize"; minimize.custom_minimum_size=Vector2(36,30); minimize.pressed.connect(_minimize_progression); row.add_child(minimize)
    var close:=Button.new(); close.text="X"; close.tooltip_text="Close"; close.custom_minimum_size=Vector2(36,30); close.pressed.connect(_close_progression); row.add_child(close)

func _close_progression()->void:
    if progression_panel!=null: progression_panel.visible=false
    if progression_chrome!=null: progression_chrome.visible=false

func _minimize_progression()->void:
    if progression_panel==null: return
    var minimized:bool=bool(progression_panel.get_meta("hw_minimized",false))
    minimized=not minimized
    progression_panel.set_meta("hw_minimized",minimized)
    var panel_box:Node=progression_panel.get_child(0) if progression_panel.get_child_count()>0 else null
    if panel_box!=null: panel_box.visible=not minimized
    progression_panel.size.y=48.0 if minimized else 735.0
    if progression_chrome!=null: progression_chrome.visible=true

func _refresh()->void:
    if legacy==null: return
    var value:Variant=legacy.get("hero")
    if not value is Dictionary: return
    var hero:Dictionary=value
    var character_script:GDScript=load("res://scripts/CharacterProgressionSystem.gd") as GDScript
    if character_script==null: return
    var stats:Dictionary=character_script.stats(hero)
    var hp_max:float=float(stats.get("max_hp",max(1,int(hero.get("hp",1)))))
    var sp_max:float=float(stats.get("max_sp",max(1,int(hero.get("sp",1)))))
    var xp:int=int(hero.get("xp",0))
    var progress:Dictionary=character_script.xp_progress(hero)
    var next_xp:int=max(1,int(progress.get("next",1)))
    hp_bar.value=clamp(float(hero.get("hp",0)),0.0,hp_max)/hp_max*100.0
    sp_bar.value=clamp(float(hero.get("sp",0)),0.0,sp_max)/sp_max*100.0
    xp_bar.value=clamp(float(xp),0.0,float(next_xp))/float(next_xp)*100.0
    hp_text.text="HP  %d / %d" % [int(hero.get("hp",0)),int(hp_max)]
    sp_text.text="SP  %d / %d" % [int(hero.get("sp",0)),int(sp_max)]
    xp_text.text="EXP %d / %d" % [xp,next_xp]
    hero_label.text="%s   Lv.%d   %s" % [str(hero.get("name","Hero")),int(hero.get("level",1)),str(hero.get("class","Warrior"))]
    map_label.text="Map %d    X %d : Y %d    Age %d" % [int(hero.get("map_id",0)),int(hero.get("pos_x",0))-365,int(hero.get("pos_y",0))-120,int(hero.get("age",18))]
    if skill_slots==null: return
    var skill_system:GDScript=load("res://scripts/SkillSystem.gd") as GDScript
    if skill_system==null: return
    var skills:Array=skill_system.all_skills(str(hero.get("class","Warrior")))
    for i in skill_slots.get_child_count():
        var slot:Button=skill_slots.get_child(i) as Button
        if slot==null: continue
        if i<skills.size():
            var data:Dictionary=skills[i]
            var level_value:int=skill_system.skill_level(hero,str(data.get("id","")))
            slot.text="%d\n%s\nLv.%d" % [i+1,str(data.get("name","SKILL")).substr(0,10),level_value]
        else: slot.text="%d\nITEM" % [i+1]
