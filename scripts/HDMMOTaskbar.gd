class_name HDMMOTaskbar
extends CanvasLayer

const EquipmentWindow=preload("res://scripts/HDEquipmentWindow.gd")
const PANEL:=Color("#111923e8")
const BORDER:=Color("#b99b5b")
const TEXT:=Color("#efe8d8")
const MUTED:=Color("#93a0af")
const HP:=Color("#cf525b")
const SP:=Color("#557edb")
const XP:=Color("#5eac66")

var game:Node
var legacy:Node
var root:Control
var equipment_window:HDEquipmentWindow
var progression_panel:Control
var hp_bar:ProgressBar
var sp_bar:ProgressBar
var xp_bar:ProgressBar
var hp_label:Label
var sp_label:Label
var xp_label:Label
var level_label:Label
var location_label:Label
var skill_slots:HBoxContainer
var hidden_timer:float=0.0

func _ready()->void:
    game=get_parent()
    if game==null: return
    legacy=game.get("legacy") as Node
    call_deferred("_build")

func _build()->void:
    _hide_legacy_huds()
    root=Control.new()
    root.name="HonourWarFinalHUD"
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter=Control.MOUSE_FILTER_PASS
    add_child(root)
    _build_status()
    _build_quickbar()
    _build_systembar()
    call_deferred("_hide_legacy_huds")

func _process(delta:float)->void:
    hidden_timer+=delta
    if hidden_timer>0.5:
        hidden_timer=0.0
        _hide_legacy_huds()
    _refresh()

func _hide_legacy_huds()->void:
    var names:Array[String]=["HDUIStyleDirector","PetCombatHUD3D","HeroPetComboHUD"]
    for node_name in names:
        var node:Node=get_node_or_null("../"+node_name)
        if node!=null:
            node.visible=false
            node.process_mode=Node.PROCESS_MODE_DISABLED
    if game!=null:
        var game_hud:Node=game.get("hud") as Node
        if game_hud!=null:
            game_hud.visible=false
            game_hud.process_mode=Node.PROCESS_MODE_DISABLED

func _style(bg:Color=PANEL)->StyleBoxFlat:
    var style:=StyleBoxFlat.new()
    style.bg_color=bg
    style.border_color=BORDER
    style.set_border_width_all(1)
    style.set_corner_radius_all(5)
    style.shadow_color=Color(0,0,0,0.55)
    style.shadow_size=7
    return style

func _build_status()->void:
    var panel:=PanelContainer.new()
    panel.position=Vector2(16,14)
    panel.size=Vector2(300,76)
    panel.add_theme_stylebox_override("panel",_style())
    root.add_child(panel)
    var box:=VBoxContainer.new()
    box.add_theme_constant_override("separation",1)
    panel.add_child(box)
    level_label=Label.new()
    level_label.add_theme_font_size_override("font_size",16)
    level_label.add_theme_color_override("font_color",TEXT)
    box.add_child(level_label)
    location_label=Label.new()
    location_label.add_theme_font_size_override("font_size",10)
    location_label.add_theme_color_override("font_color",MUTED)
    box.add_child(location_label)
    var bars:=HBoxContainer.new()
    bars.add_theme_constant_override("separation",5)
    box.add_child(bars)
    hp_label=Label.new()
    hp_label.add_theme_font_size_override("font_size",9)
    hp_label.add_theme_color_override("font_color",HP)
    bars.add_child(hp_label)
    sp_label=Label.new()
    sp_label.add_theme_font_size_override("font_size",9)
    sp_label.add_theme_color_override("font_color",SP)
    bars.add_child(sp_label)
    xp_label=Label.new()
    xp_label.add_theme_font_size_override("font_size",9)
    xp_label.add_theme_color_override("font_color",XP)
    bars.add_child(xp_label)

func _build_quickbar()->void:
    var panel:=PanelContainer.new()
    panel.position=Vector2(385,705)
    panel.size=Vector2(730,105)
    panel.add_theme_stylebox_override("panel",_style())
    root.add_child(panel)
    var box:=VBoxContainer.new()
    panel.add_child(box)
    var title:=Label.new()
    title.text="QUICK SLOTS"
    title.add_theme_font_size_override("font_size",9)
    title.add_theme_color_override("font_color",MUTED)
    box.add_child(title)
    skill_slots=HBoxContainer.new()
    skill_slots.add_theme_constant_override("separation",4)
    box.add_child(skill_slots)
    for i in range(8):
        var slot:=Button.new()
        slot.custom_minimum_size=Vector2(82,60)
        slot.name="QuickSlot_%d" % (i+1)
        slot.add_theme_font_size_override("font_size",9)
        slot.add_theme_stylebox_override("normal",_style(Color("#1b2531")))
        slot.add_theme_stylebox_override("hover",_style(Color("#3a3222")))
        slot.pressed.connect(_use_slot.bind(i))
        skill_slots.add_child(slot)

func _build_systembar()->void:
    var panel:=PanelContainer.new()
    panel.position=Vector2(1130,705)
    panel.size=Vector2(760,105)
    panel.add_theme_stylebox_override("panel",_style())
    root.add_child(panel)
    var row:=HBoxContainer.new()
    row.alignment=BoxContainer.ALIGNMENT_END
    row.add_theme_constant_override("separation",4)
    panel.add_child(row)
    var entries:Array=[
        ["CHAR","character",0],["PET","pet",1],["SKILLS","skills",2],["INV","inventory",3],
        ["EQUIP","equipment",4],["REFINE","refine",5],["MAP","map",6],["SYS","system",7]
    ]
    for entry in entries:
        var button:=Button.new()
        button.custom_minimum_size=Vector2(76,68)
        button.tooltip_text=str(entry[1]).capitalize()
        button.add_theme_stylebox_override("normal",_style(Color("#1b2531")))
        button.add_theme_stylebox_override("hover",_style(Color("#3a3222")))
        var icon:=HUDIcon.new()
        icon.kind=int(entry[2])
        icon.position=Vector2(24,7)
        icon.size=Vector2(28,28)
        icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
        button.add_child(icon)
        var text:=Label.new()
        text.text=str(entry[0])
        text.position=Vector2(0,38)
        text.size=Vector2(76,25)
        text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
        text.add_theme_font_size_override("font_size",8)
        text.add_theme_color_override("font_color",TEXT)
        text.mouse_filter=Control.MOUSE_FILTER_IGNORE
        button.add_child(text)
        button.pressed.connect(_open.bind(str(entry[1])))
        row.add_child(button)

func _open(mode:String)->void:
    if mode=="equipment":
        _close_progression()
        if equipment_window==null:
            equipment_window=EquipmentWindow.new()
            game.add_child(equipment_window)
        equipment_window.show_window()
        return
    if equipment_window!=null:
        equipment_window.hide_window()
    var ui:Node=game.get_node_or_null("GameplaySystemsRuntime")
    if ui==null: return
    ui.call("_set_mode",mode if mode!="map" else "character")
    progression_panel=ui.get("panel") as Control
    if progression_panel==null: return
    progression_panel.visible=true
    progression_panel.position=Vector2(760,76)
    progression_panel.size=Vector2(590,625)
    _install_closebar()

func _install_closebar()->void:
    if progression_panel==null or progression_panel.has_meta("hw_final_closebar"): return
    progression_panel.set_meta("hw_final_closebar",true)
    var bar:=PanelContainer.new()
    bar.name="FinalCloseBar"
    bar.position=Vector2(0,0)
    bar.size=Vector2(590,36)
    bar.add_theme_stylebox_override("panel",_style(Color("#0a1018f4")))
    progression_panel.add_child(bar)
    var row:=HBoxContainer.new()
    bar.add_child(row)
    var title:=Label.new()
    title.text="HONOUR WAR"
    title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    title.add_theme_color_override("font_color",TEXT)
    row.add_child(title)
    var close:=Button.new()
    close.text="X"
    close.custom_minimum_size=Vector2(34,28)
    close.pressed.connect(_close_progression)
    row.add_child(close)
    for child in progression_panel.get_children():
        if child==bar: continue
        if child is Control:
            var control:=child as Control
            if control.position.y<38:
                control.position.y=42.0

func _close_progression()->void:
    if progression_panel!=null:
        progression_panel.visible=false

func _use_slot(index:int)->void:
    if legacy==null: return
    var value:Variant=legacy.get("hero")
    if not value is Dictionary: return
    var hero:Dictionary=value
    var skill_system:GDScript=load("res://scripts/SkillSystem.gd") as GDScript
    if skill_system==null: return
    skill_system.ensure_state(hero)
    var skills:Array=skill_system.all_skills(str(hero.get("class","Warrior")))
    if index>=skills.size(): return
    var id:String=str(skills[index].get("id",""))
    skill_system.use(hero,id,Time.get_ticks_msec()/1000.0)

func _refresh()->void:
    if legacy==null: return
    var value:Variant=legacy.get("hero")
    if not value is Dictionary: return
    var hero:Dictionary=value
    var character:GDScript=load("res://scripts/CharacterProgressionSystem.gd") as GDScript
    if character==null: return
    var stats:Dictionary=character.stats(hero)
    var xp:Dictionary=character.xp_progress(hero)
    var hp:int=int(hero.get("hp",0))
    var hp_max:int=max(1,int(stats.get("max_hp",1)))
    var sp:int=int(hero.get("sp",0))
    var sp_max:int=max(1,int(stats.get("max_sp",1)))
    level_label.text="Lv.%d / 250" % int(hero.get("level",1))
    location_label.text="X %d : Y %d   •   %s" % [int(hero.get("pos_x",0))-365,int(hero.get("pos_y",0))-120,_map_name(hero)]
    hp_label.text="HP %d/%d" % [hp,hp_max]
    sp_label.text="SP %d/%d" % [sp,sp_max]
    xp_label.text="EXP %d/%d" % [int(xp.get("xp",0)),max(1,int(xp.get("next",1)))]
    for i in range(skill_slots.get_child_count()):
        var slot:Button=skill_slots.get_child(i) as Button
        if slot==null: continue
        var skills_script:GDScript=load("res://scripts/SkillSystem.gd") as GDScript
        if skills_script==null: continue
        var skills:Array=skills_script.all_skills(str(hero.get("class","Warrior")))
        if i<skills.size():
            var data:Dictionary=skills[i]
            var name:String=str(data.get("name","Skill"))
            if name.length()>12: name=name.substr(0,12)
            slot.text="%d\n%s\nLv.%d" % [i+1,name,skills_script.skill_level(hero,str(data.get("id","")))]
        else:
            slot.text=str(i+1)+"\n—"

func _map_name(hero:Dictionary)->String:
    var teleport:GDScript=load("res://scripts/TeleportSystem.gd") as GDScript
    if teleport!=null:
        return str(teleport.map_name(int(hero.get("map_id",0))))
    return "Map %d" % int(hero.get("map_id",0))

class HUDIcon extends Control:
    var kind:int=0
    func _draw()->void:
        var c:=Color("#d4bd75")
        var w:=size.x
        var h:=size.y
        var mid:=Vector2(w*0.5,h*0.5)
        if kind==0:
            draw_line(Vector2(5,h-5),Vector2(w-5,5),c,4.0)
            draw_line(Vector2(7,h-9),Vector2(13,h-3),c,3.0)
        elif kind==1:
            draw_circle(mid,9.0,c,false,3.0)
            draw_circle(Vector2(9,8),3.0,c)
            draw_circle(Vector2(w-9,8),3.0,c)
        elif kind==2:
            draw_circle(mid,10.0,c,false,3.0)
            for i in range(8):
                var a:=float(i)*PI*0.25
                draw_line(mid+Vector2(cos(a),sin(a))*12.0,mid+Vector2(cos(a),sin(a))*15.0,c,2.0)
        elif kind==3:
            draw_rect(Rect2(5,8,w-10,h-6),c,false,3.0)
            draw_line(Vector2(9,9),Vector2(15,4),c,3.0)
            draw_line(Vector2(w-9,9),Vector2(w-15,4),c,3.0)
        elif kind==4:
            draw_arc(Vector2(w*0.5,h*0.58),11.0,PI,TAU,16,c,3.0)
            draw_line(Vector2(6,h*0.58),Vector2(w-6,h*0.58),c,3.0)
        elif kind==5:
            draw_circle(mid,9.0,c,false,3.0)
            draw_line(Vector2(5,mid.y),Vector2(w-5,mid.y),c,3.0)
            draw_line(Vector2(mid.x,5),Vector2(mid.x,h-5),c,3.0)
        elif kind==6:
            draw_circle(mid,10.0,c,false,2.5)
            draw_circle(mid,3.0,c)
            draw_line(Vector2(mid.x,2),Vector2(mid.x,6),c,2.0)
        else:
            draw_circle(mid,10.0,c,false,3.0)
            draw_circle(mid,3.0,c)
            draw_line(Vector2(5,5),Vector2(12,10),c,2.0)
            draw_line(Vector2(w-5,5),Vector2(w-12,10),c,2.0)
