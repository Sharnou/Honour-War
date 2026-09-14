extends CanvasLayer

const SKILLS=preload("res://scripts/SkillSystem.gd")
const SAVE=preload("res://scripts/SaveSystem.gd")

var scene_root:Node
var legacy:Node
var bar:PanelContainer
var buttons:HBoxContainer
var visible_bar:bool=true
var active_ids:Array[String]=[]

func _ready()->void:
    layer=125
    call_deferred("_bind")

func _process(_delta:float)->void:
    if legacy==null or not is_instance_valid(legacy):
        _bind()
        return
    _refresh_bar()

func _bind()->void:
    scene_root=get_tree().current_scene as Node
    if scene_root==null:
        return
    legacy=scene_root.get_node_or_null("LegacyGame")
    var value:Variant=legacy.get("hero") if legacy!=null else null
    if value is Dictionary:
        var hero:Dictionary=value
        if not hero.has("skill_bar_visible"):
            hero["skill_bar_visible"]=true
        visible_bar=bool(hero.get("skill_bar_visible",true))
    _build()

func _build()->void:
    if bar!=null and is_instance_valid(bar):
        return
    bar=PanelContainer.new()
    bar.name="HWSkillBar"
    bar.anchor_left=0.5
    bar.anchor_right=0.5
    bar.anchor_top=1.0
    bar.anchor_bottom=1.0
    bar.offset_left=-360
    bar.offset_right=360
    bar.offset_top=-108
    bar.offset_bottom=-26
    bar.add_theme_stylebox_override("panel",_style(Color("#07111df2"),Color("#c9ad68")))
    add_child(bar)
    var outer:=VBoxContainer.new()
    outer.add_theme_constant_override("separation",3)
    bar.add_child(outer)
    var caption:=Label.new()
    caption.text="SKILLS  •  F12 TOGGLE"
    caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    caption.add_theme_font_size_override("font_size",9)
    caption.add_theme_color_override("font_color",Color("#d9bd73"))
    outer.add_child(caption)
    buttons=HBoxContainer.new()
    buttons.alignment=BoxContainer.ALIGNMENT_CENTER
    buttons.add_theme_constant_override("separation",4)
    outer.add_child(buttons)
    _refresh_bar()
    _apply_visibility()

func _refresh_bar()->void:
    if buttons==null or legacy==null:
        return
    var value:Variant=legacy.get("hero")
    if not value is Dictionary:
        return
    var hero:Dictionary=value
    var class_id:String=str(hero.get("class","Warrior"))
    var available:Array=SKILLS.all_skills(class_id)
    var wanted:Array=[]
    for skill in available:
        var id:String=str(skill.get("id",""))
        if int(SKILLS.skill_level(hero,id))>0 and str(skill.get("kind","active"))!="passive":
            wanted.append(id)
    if wanted.size()==0:
        for skill in available:
            var id:String=str(skill.get("id",""))
            if int(skill.get("required_level",1))<=int(hero.get("level",1)):
                wanted.append(id)
            if wanted.size()>=7:
                break
    if wanted.size()>8:
        wanted=wanted.slice(0,8)
    if wanted==active_ids:
        return
    active_ids=wanted
    for child in buttons.get_children():
        child.queue_free()
    var index:int=1
    for id in active_ids:
        var info:Dictionary=SKILLS.skill_map(class_id).get(id,{})
        var b:=Button.new()
        b.custom_minimum_size=Vector2(78,46)
        b.text=str(index)+"\n"+str(info.get("name","Skill"))
        b.tooltip_text="["+str(index)+"] "+str(info.get("description",""))
        b.add_theme_font_size_override("font_size",9)
        b.add_theme_stylebox_override("normal",_style(Color("#101c2c"),Color("#4d5c70")))
        b.add_theme_stylebox_override("hover",_style(Color("#24364f"),Color("#e7ca7a")))
        var slot:int=index
        b.pressed.connect(_use_skill.bind(slot))
        buttons.add_child(b)
        index+=1

func _use_skill(slot:int)->void:
    if slot<1 or slot>active_ids.size() or legacy==null:
        return
    var skill_id:String=active_ids[slot-1]
    if legacy.has_method("use_skill"):
        legacy.call("use_skill",skill_id)
    elif legacy.has_method("cast_skill"):
        legacy.call("cast_skill",skill_id)

func _unhandled_key_input(event:InputEvent)->void:
    if not event is InputEventKey or not event.pressed or event.echo:
        return
    if event.keycode==KEY_F12:
        toggle()

func toggle()->void:
    visible_bar=not visible_bar
    var value:Variant=legacy.get("hero") if legacy!=null else null
    if value is Dictionary:
        var hero:Dictionary=value
        hero["skill_bar_visible"]=visible_bar
        SAVE.save_game(hero)
    _apply_visibility()

func _apply_visibility()->void:
    if bar!=null:
        bar.visible=visible_bar

func _style(bg:Color,border:Color)->StyleBoxFlat:
    var s:=StyleBoxFlat.new()
    s.bg_color=bg
    s.border_color=border
    s.set_border_width_all(1)
    s.set_corner_radius_all(8)
    s.shadow_color=Color(0,0,0,0.65)
    s.shadow_size=7
    return s
