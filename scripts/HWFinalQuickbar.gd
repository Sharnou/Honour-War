extends CanvasLayer

const SkillSystemClass = preload("res://scripts/SkillSystem.gd")
const ICON_ATLAS_PATH:String = "res://assets/ui/skill_icons_atlas.svg"

const PANEL_BG:Color = Color("#07111df8")
const PANEL_INNER:Color = Color("#0c1928fa")
const BORDER:Color = Color("#d2b36c")
const BORDER_DIM:Color = Color("#4f6178")
const TEXT:Color = Color("#f6f0e4")
const MUTED:Color = Color("#9eacbb")

var scene:Node
var legacy:Node
var panel:PanelContainer
var slots:HBoxContainer
var hero_class:String="Warrior"
var last_signature:String=""
var icon_atlas:Texture2D
var flash_index:int=-1
var flash_time:float=0.0

func _ready()->void:
    layer=300
    process_mode=Node.PROCESS_MODE_ALWAYS
    if DisplayServer.get_name()!="headless":
        icon_atlas=load(ICON_ATLAS_PATH) as Texture2D
    call_deferred("_bind_and_build")

func _process(delta:float)->void:
    flash_time=max(0.0,flash_time-delta)
    if scene==null or not is_instance_valid(scene):
        _bind_and_build()
        return
    if legacy==null or not is_instance_valid(legacy):
        legacy=scene.get_node_or_null("LegacyGame")
    _hide_legacy_skillbars()
    _refresh()
    _layout()
    if flash_time<=0.0 and flash_index>=0:
        flash_index=-1
        _refresh(true)

func _bind_and_build()->void:
    scene=get_tree().current_scene
    if scene==null:
        scene=get_parent() as Node
    if scene==null:
        return
    legacy=scene.get_node_or_null("LegacyGame")
    _hide_legacy_skillbars()
    if icon_atlas==null and DisplayServer.get_name()!="headless":
        icon_atlas=load(ICON_ATLAS_PATH) as Texture2D
    if panel==null or not is_instance_valid(panel):
        _build()

func _hide_legacy_skillbars()->void:
    for node_path:String in ["/root/HWSkillBarRuntime","/root/HDMMOTaskbar"]:
        var old_bar:=get_node_or_null(node_path) as Node
        if old_bar==null:
            continue
        old_bar.process_mode=Node.PROCESS_MODE_DISABLED
        var old_panel:=old_bar.get_node_or_null("HWSkillBar")
        if old_panel!=null:
            old_panel.visible=false
        var hud:=old_bar.get_node_or_null("HonourWarFinalHUD")
        if hud!=null:
            for child in hud.get_children():
                var n:=str(child.name).to_lower()
                if n.contains("skill") or n.contains("quick"):
                    child.visible=false

func _build()->void:
    panel=PanelContainer.new()
    panel.name="HWFinalSkillQuickbar"
    panel.position=Vector2(0,0)
    panel.size=Vector2(900,98)
    panel.add_theme_stylebox_override("panel",_style(PANEL_BG,BORDER,12))
    panel.mouse_filter=Control.MOUSE_FILTER_STOP
    add_child(panel)

    var outer:=VBoxContainer.new()
    outer.add_theme_constant_override("separation",4)
    panel.add_child(outer)

    var header:=HBoxContainer.new()
    header.custom_minimum_size=Vector2(0,20)
    outer.add_child(header)
    var title:=Label.new()
    title.text="COMBAT SKILLS"
    title.add_theme_font_size_override("font_size",11)
    title.add_theme_color_override("font_color",BORDER)
    title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    header.add_child(title)
    var help:=Label.new()
    help.text="1–8   •   K Skill Tree"
    help.add_theme_font_size_override("font_size",10)
    help.add_theme_color_override("font_color",MUTED)
    header.add_child(help)

    slots=HBoxContainer.new()
    slots.add_theme_constant_override("separation",6)
    slots.size_flags_vertical=Control.SIZE_EXPAND_FILL
    outer.add_child(slots)
    for i in range(8):
        var slot:=Button.new()
        slot.name="SkillSlot_%d"%(i+1)
        slot.custom_minimum_size=Vector2(103,69)
        slot.size_flags_horizontal=Control.SIZE_EXPAND_FILL
        slot.expand_icon=true
        slot.alignment=HORIZONTAL_ALIGNMENT_CENTER
        slot.add_theme_font_size_override("font_size",10)
        slot.add_theme_color_override("font_color",TEXT)
        slot.add_theme_color_override("font_hover_color",TEXT)
        slot.add_theme_stylebox_override("normal",_style(PANEL_INNER,BORDER_DIM,9))
        slot.add_theme_stylebox_override("hover",_style(Color("#182944"),BORDER,9))
        slot.add_theme_stylebox_override("pressed",_style(Color("#2d405d"),Color("#f0d788"),9))
        slot.pressed.connect(_cast_slot.bind(i))
        slots.add_child(slot)

func _refresh(force:bool=false)->void:
    if legacy==null or slots==null or not is_instance_valid(legacy):
        return
    if slots.get_child_count() < 8:
        return
    var value:Variant=legacy.get("hero")
    if not value is Dictionary:
        return
    var hero:Dictionary=value
    SkillSystemClass.ensure_state(hero)
    hero_class=str(hero.get("class","Warrior"))
    var data:Array=SkillSystemClass.all_skills(hero_class)
    var signature:=hero_class+":"+str(hero.get("level",1))+":"+str(hero.get("skill_points",0))+":"+str(hero.get("skill_cooldowns",{}))+":"+str(hero.get("skill_levels",{}))+":"+str(hero.get("sp",0))
    if not force and signature==last_signature and flash_index<0:
        return
    last_signature=signature
    for i in range(8):
        var slot:=slots.get_child(i) as Button
        if slot==null:
            continue
        if i>=data.size():
            slot.text=str(i+1)+"\n--"
            slot.icon=null
            slot.disabled=true
            continue
        var skill:Dictionary=data[i]
        var id:=str(skill.get("id",""))
        var level:=SkillSystemClass.skill_level(hero,id)
        var required:=int(skill.get("required_level",1))
        var locked:=int(hero.get("level",1))<required
        for req:Variant in skill.get("requires",[]):
            if int(hero.get("skill_levels",{}).get(str(req),0))<1:
                locked=true
        var kind:=str(skill.get("kind","active"))
        var name:=str(skill.get("name","Skill"))
        if name.length()>20:
            name=name.substr(0,20)
        var state:="Lv.%d"%level
        if locked:
            state="LOCK • Lv.%d"%required
        elif kind=="ultimate":
            state="ULTIMATE • Lv.%d"%level
        elif kind=="passive":
            state="PASSIVE • Lv.%d"%level
        slot.text="%d   %s\n%s\nSP %d"%[i+1,name,state,int(skill.get("sp_cost",skill.get("cost",0)))]
        slot.icon=_icon_for_skill(hero_class,i)
        slot.disabled=locked or kind=="passive"
        slot.modulate=Color("#728096") if locked else Color.WHITE
        slot.tooltip_text=str(skill.get("name","Skill"))+"\n"+str(skill.get("description",""))+"\nSP "+str(skill.get("sp_cost",0))+" • CD "+str(skill.get("cooldown",0.0))+"s"
        slot.add_theme_stylebox_override("normal",_style(Color("#101d2e") if not locked else Color("#0b1118"),Color("#e1c06b") if i==flash_index and flash_time>0 else BORDER_DIM,9))

func _cast_slot(index:int)->void:
    if legacy==null:
        return
    var value:Variant=legacy.get("hero")
    if not value is Dictionary:
        return
    var hero:Dictionary=value
    var data:Array=SkillSystemClass.all_skills(str(hero.get("class","Warrior")))
    if index<0 or index>=data.size():
        return
    var skill:Dictionary=data[index]
    var skill_id:=str(skill.get("id",""))
    var kind:=str(skill.get("kind","active"))
    if kind=="passive":
        return
    var result:Dictionary=SkillSystemClass.use(hero,skill_id,Time.get_ticks_msec()/1000.0)
    if not bool(result.get("ok",false)):
        return
    var power:=int(result.get("power",0))
    var target:Variant=legacy.call("nearest_monster") if legacy.has_method("nearest_monster") else null
    if target is Dictionary:
        var monster:Dictionary=target
        monster["hp"]=int(monster.get("hp",0))-power
        if int(monster.get("hp",0))<=0 and legacy.has_method("defeat_monster"):
            legacy.call("defeat_monster",monster)
    elif hero_class=="Acolyte":
        hero["hp"]=min(int(hero.get("max_hp",1)),int(hero.get("hp",0))+power+10)
    else:
        return
    if legacy.has_method("save_game"):
        legacy.call("save_game")
    if legacy.has_method("update_ui"):
        legacy.call("update_ui")
    flash_index=index
    flash_time=0.22
    _refresh(true)

func _icon_for_skill(class_id:String,index:int)->Texture2D:
    if icon_atlas==null:
        return null
    var row:=0
    match class_id:
        "Mage": row=1
        "Archer": row=2
        "Thief": row=3
        "Acolyte": row=4
        "Merchant": row=5
    var atlas:=AtlasTexture.new()
    atlas.atlas=icon_atlas
    atlas.region=Rect2(float(index*64),float(row*64),64,64)
    return atlas

func _style(bg:Color,border:Color,radius:int)->StyleBoxFlat:
    var s:=StyleBoxFlat.new()
    s.bg_color=bg
    s.border_color=border
    s.set_border_width_all(1)
    s.set_corner_radius_all(radius)
    s.shadow_color=Color(0,0,0,0.72)
    s.shadow_size=9
    return s

func _layout()->void:
    var size:=get_viewport().get_visible_rect().size
    panel.position=Vector2(max(12.0,(size.x-panel.size.x)*0.5),max(12.0,size.y-panel.size.y-18.0))

func _unhandled_key_input(event:InputEvent)->void:
    if not event is InputEventKey or not event.pressed or event.echo:
        return
    if event.keycode>=KEY_1 and event.keycode<=KEY_8:
        _cast_slot(int(event.keycode-KEY_1))

func _process_layout()->void:
    _layout()
