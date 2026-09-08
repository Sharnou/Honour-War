class_name PetCombatHUD3D
extends CanvasLayer

const STATES:Array[String] = ["Follow", "Assist", "Defend", "Aggressive", "Hold", "Return"]
const ROLES:Array[String] = ["Guardian", "DPS", "Ranged", "Support", "Hybrid"]

var game:Node
var hero:Dictionary
var panel:PanelContainer
var name_label:Label
var state_label:Label
var role_label:Label
var hp_bar:ProgressBar
var sp_bar:ProgressBar
var skill_box:HBoxContainer
var command_box:HBoxContainer
var role_box:HBoxContainer
var status_label:Label
var skill_buttons:Dictionary={}
var last_signature:String=""

func _ready()->void:
    game=get_parent()
    _build()
    set_process(true)

func _process(_delta:float)->void:
    _refresh_runtime()

func _unhandled_input(event:InputEvent)->void:
    if not event is InputEventKey or not event.pressed or event.echo: return
    var key:int=int(event.keycode)
    if key>=KEY_1 and key<=KEY_6:
        var index:int=key-KEY_1
        var director:Node=game.get_node_or_null("HDPetCombatDirector") if game else null
        if director and index<STATES.size():
            director.set_pet_state(STATES[index])
            _set_status("Pet command: "+STATES[index])
            get_viewport().set_input_as_handled()

func _build()->void:
    panel=PanelContainer.new()
    panel.position=Vector2(18,18)
    panel.size=Vector2(500,205)
    add_child(panel)
    var margin:=MarginContainer.new()
    margin.add_theme_constant_override("margin_left",12)
    margin.add_theme_constant_override("margin_right",12)
    margin.add_theme_constant_override("margin_top",9)
    margin.add_theme_constant_override("margin_bottom",9)
    panel.add_child(margin)
    var root:=VBoxContainer.new()
    margin.add_child(root)
    name_label=Label.new()
    name_label.add_theme_font_size_override("font_size",18)
    root.add_child(name_label)
    state_label=Label.new()
    root.add_child(state_label)
    role_label=Label.new()
    root.add_child(role_label)
    hp_bar=ProgressBar.new()
    hp_bar.custom_minimum_size=Vector2(0,13)
    hp_bar.show_percentage=false
    root.add_child(hp_bar)
    sp_bar=ProgressBar.new()
    sp_bar.custom_minimum_size=Vector2(0,10)
    sp_bar.show_percentage=false
    root.add_child(sp_bar)
    role_box=HBoxContainer.new()
    root.add_child(role_box)
    for role in ROLES:
        var role_button:=Button.new()
        role_button.text=role
        role_button.tooltip_text="Set pet combat role to "+role
        role_button.pressed.connect(_role.bind(role))
        role_box.add_child(role_button)
    skill_box=HBoxContainer.new()
    root.add_child(skill_box)
    command_box=HBoxContainer.new()
    root.add_child(command_box)
    for index in range(STATES.size()):
        var button:=Button.new()
        button.text=str(index+1)+" "+STATES[index]
        button.tooltip_text="Set pet AI state to "+STATES[index]
        button.pressed.connect(_command.bind(STATES[index]))
        command_box.add_child(button)
    status_label=Label.new()
    status_label.text="1-6: commands  •  Role controls pet combat behavior"
    root.add_child(status_label)

func _refresh_runtime()->void:
    if game==null: return
    var legacy:Node=game.get_node_or_null("LegacyGame")
    if legacy==null: return
    var hero_value:Variant=legacy.get("hero")
    if not hero_value is Dictionary: return
    hero=hero_value
    var pet_value:Variant=hero.get("pet",{})
    if not pet_value is Dictionary: return
    var pet:Dictionary=pet_value
    PetSkillSystem.ensure_state(pet)
    var species:String=str(pet.get("species","Wolf Cub"))
    var director:Node=game.get_node_or_null("HDPetCombatDirector")
    if director and director.has_method("configure_role_from_pet"): director.configure_role_from_pet(pet)
    var state:String=str(director.get("pet_state")) if director else "Follow"
    var role:String=str(director.get("pet_role")) if director else str(pet.get("role","Hybrid"))
    name_label.text=str(pet.get("name",species))+"  •  Lv."+str(int(pet.get("level",1)))+"  •  "+species
    state_label.text="State: "+state+"   •   Skill Points: "+str(int(pet.get("skill_points",0)))
    role_label.text="Role: "+role
    hp_bar.max_value=max(1,int(pet.get("max_hp",60)))
    hp_bar.value=clamp(int(pet.get("hp",0)),0,hp_bar.max_value)
    sp_bar.max_value=max(1,int(pet.get("max_sp",30)))
    sp_bar.value=clamp(int(pet.get("sp",0)),0,sp_bar.max_value)
    _refresh_skills(pet,species)

func _refresh_skills(pet:Dictionary,species:String)->void:
    var signature:String=species+":"+str(pet.get("skill_points",0))
    for skill in PetSkillSystem.all_skills(species): signature+=":"+str(PetSkillSystem.skill_level(pet,str(skill["id"])))
    if signature==last_signature:
        _refresh_cooldowns(pet,species)
        return
    last_signature=signature
    for child in skill_box.get_children(): child.queue_free()
    skill_buttons.clear()
    for skill in PetSkillSystem.all_skills(species):
        var id:String=str(skill["id"])
        if str(skill.get("kind",""))=="passive" or PetSkillSystem.skill_level(pet,id)<=0: continue
        var button:=Button.new()
        button.text=str(skill["name"])
        button.custom_minimum_size=Vector2(92,30)
        button.tooltip_text=str(skill["description"])
        button.pressed.connect(_use_skill.bind(id))
        skill_box.add_child(button)
        skill_buttons[id]=button
    _refresh_cooldowns(pet,species)

func _refresh_cooldowns(pet:Dictionary,species:String)->void:
    var now:float=Time.get_ticks_msec()/1000.0
    for skill in PetSkillSystem.all_skills(species):
        var id:String=str(skill["id"])
        var button:Button=skill_buttons.get(id)
        if button==null: continue
        var ready:bool=PetSkillSystem.is_ready(pet,id,now)
        button.disabled=not ready
        var remaining:float=max(0.0,float(pet.get("skill_cooldowns",{}).get(id,0.0))-now)
        button.text=str(skill["name"]) if ready else str(skill["name"])+"  "+("%.1f" % remaining)

func _use_skill(skill_id:String)->void:
    var runtime:Node=game.get_node_or_null("PetSkillRuntime") if game else null
    if runtime and runtime.has_method("request_skill"):
        var result:Dictionary=runtime.request_skill(skill_id)
        if bool(result.get("ok",false)):
            _set_status("Pet skill: "+str(result.get("skill_name",skill_id)))
        else: _set_status("Skill unavailable: "+str(result.get("reason","rejected")))
    else: _set_status("Pet skill runtime is not ready.")

func _command(state:String)->void:
    var director:Node=game.get_node_or_null("HDPetCombatDirector") if game else null
    if director:
        director.set_pet_state(state)
        _set_status("Pet command: "+state)

func _role(role:String)->void:
    var director:Node=game.get_node_or_null("HDPetCombatDirector") if game else null
    if director and director.has_method("set_pet_role"):
        director.set_pet_role(role)
        if hero.has("pet") and hero["pet"] is Dictionary: hero["pet"]["role"]=role
        _set_status("Pet role: "+role)

func _set_status(text:String)->void:
    if status_label: status_label.text=text
