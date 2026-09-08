class_name PetSkillOverlay3D
extends CanvasLayer

const PetSkillSystem = preload("res://scripts/PetSkillSystem.gd")

@export var toggle_key:Key = KEY_P

var legacy:Node
var hero:Dictionary
var panel:PanelContainer
var tree_box:VBoxContainer
var title:Label
var points_label:Label
var status_label:Label
var open:bool = false

func _ready()->void:
    legacy = get_parent().get_node_or_null("LegacyGame") if get_parent() else null
    _build()
    visible = false

func _unhandled_input(event:InputEvent)->void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == toggle_key:
        _toggle()
        get_viewport().set_input_as_handled()

func _toggle()->void:
    open = not open
    visible = open
    if open:
        _refresh()

func _build()->void:
    panel = PanelContainer.new()
    panel.position = Vector2(340,90)
    panel.size = Vector2(560,620)
    add_child(panel)
    var margin:=MarginContainer.new()
    margin.add_theme_constant_override("margin_left",18)
    margin.add_theme_constant_override("margin_right",18)
    margin.add_theme_constant_override("margin_top",14)
    margin.add_theme_constant_override("margin_bottom",14)
    panel.add_child(margin)
    var box:=VBoxContainer.new()
    margin.add_child(box)
    title=Label.new()
    title.add_theme_font_size_override("font_size",24)
    box.add_child(title)
    points_label=Label.new()
    box.add_child(points_label)
    status_label=Label.new()
    box.add_child(status_label)
    var scroll:=ScrollContainer.new()
    scroll.custom_minimum_size=Vector2(0,500)
    box.add_child(scroll)
    tree_box=VBoxContainer.new()
    scroll.add_child(tree_box)

func _refresh()->void:
    if legacy==null:
        legacy=get_parent().get_node_or_null("LegacyGame") if get_parent() else null
    if legacy==null: return
    var hero_value:Variant=legacy.get("hero")
    if not hero_value is Dictionary: return
    hero=hero_value
    var pet_value:Variant=hero.get("pet",{})
    if not pet_value is Dictionary: return
    var pet:Dictionary=pet_value
    PetSkillSystem.ensure_state(pet)
    var species:String=str(pet.get("species","Wolf Cub"))
    title.text="PET SKILL TREE  •  "+species
    points_label.text="Skill Points: "+str(int(pet.get("skill_points",0)))+"    Pet Level: "+str(int(pet.get("level",1)))
    status_label.text="P = toggle    Skills are permanent unlocks. Active skills use independent cooldowns."
    for child in tree_box.get_children():
        child.queue_free()
    for skill in PetSkillSystem.all_skills(species):
        var row:=HBoxContainer.new()
        row.custom_minimum_size=Vector2(0,58)
        var text:=Label.new()
        var level:int=PetSkillSystem.skill_level(pet,str(skill["id"]))
        text.text="T%d  %s  Lv.%d/%d\n%s" % [int(skill["tier"]),str(skill["name"]),level,int(skill["max_level"]),str(skill["description"])]
        text.size_flags_horizontal=Control.SIZE_EXPAND_FILL
        row.add_child(text)
        var button:=Button.new()
        button.text="LEARN"
        button.disabled=not PetSkillSystem.can_learn(pet,str(skill["id"]))
        button.pressed.connect(_learn.bind(str(skill["id"])))
        row.add_child(button)
        tree_box.add_child(row)

func _learn(skill_id:String)->void:
    var pet_value:Variant=hero.get("pet",{})
    if not pet_value is Dictionary: return
    var pet:Dictionary=pet_value
    if PetSkillSystem.learn(pet,skill_id):
        status_label.text="Learned: "+skill_id
    else:
        status_label.text="Cannot learn this skill yet. Check level, prerequisites and skill points."
    _refresh()
