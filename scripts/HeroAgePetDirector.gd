class_name HeroAgePetDirector
extends Node3D

const PetSkillSystem = preload("res://scripts/PetSkillSystem.gd")

const STARTING_AGE:int=18
const AGE_DAYS_PER_YEAR:float=3.0
var game:Node3D
var legacy:Node2D
var age_label:Label
var last_age:int=-1
var last_pet_level:int=-1
var last_pet_hp:int=-1
var age_detail:Node3D
var elapsed:float=0.0

func _ready()->void:
	game=get_parent() as Node3D
	legacy=game.get_node_or_null("LegacyGame") if game!=null else null
	call_deferred("_build_ui")
	set_process(true)

func _process(delta:float)->void:
	elapsed+=delta
	if legacy==null or game==null: return
	var hero_value:Variant=legacy.get("hero")
	if not hero_value is Dictionary: return
	var hero:Dictionary=hero_value
	_update_age(hero,delta)
	_update_pet(hero,delta)
	_update_label(hero)

func _update_age(hero:Dictionary,delta:float)->void:
	var days:float=max(0.0,float(hero.get("online_days",0.0)))
	var age:int=STARTING_AGE+int(days/AGE_DAYS_PER_YEAR)
	if int(hero.get("age",STARTING_AGE))!=age:
		hero["age"]=age
	if age!=last_age:
		last_age=age
		_refresh_age_detail(age)
	hero["online_days"]=days+delta/86400.0

func _update_pet(hero:Dictionary,delta:float)->void:
	var pet_value:Variant=hero.get("pet",{})
	if not pet_value is Dictionary: return
	var pet:Dictionary=pet_value
	PetSkillSystem.ensure_state(pet)
	var pet_node:Node3D=game.get("pet_visual") as Node3D
	if pet_node==null: return
	var level:int=int(pet.get("level",1))
	var hp:int=int(pet.get("hp",0))
	var max_hp:int=max(1,int(pet.get("max_hp",60)))
	var ratio:=clamp(float(hp)/float(max_hp),0.0,1.0)
	var bob:=sin(elapsed*(5.0+float(level)*0.015))*0.035
	pet_node.position.y=lerp(pet_node.position.y,0.45+bob+0.12*(1.0-ratio),0.12)
	if hp<last_pet_hp and last_pet_hp>=0:
		pet_node.rotation.z=sin(elapsed*30.0)*0.10
	else:
		pet_node.rotation.z=lerp(pet_node.rotation.z,0.0,0.15)
	last_pet_hp=hp
	if level!=last_pet_level:
		last_pet_level=level
		pet_node.scale=Vector3.ONE*(1.0+min(0.18,float(level-1)*0.0018))

func _refresh_age_detail(age:int)->void:
	if age_detail!=null and is_instance_valid(age_detail):
		age_detail.queue_free()
		age_detail=null
	var hero:Node3D=game.get("hero_visual") as Node3D
	if hero==null: return
	if age<30: return
	age_detail=Node3D.new()
	age_detail.name="AgeMaturityDetails"
	hero.add_child(age_detail)
	if age>=30:
		var beard:=MeshInstance3D.new()
		var beard_mesh:=SphereMesh.new()
		beard_mesh.radius=0.13
		beard_mesh.height=0.18
		beard.mesh=beard_mesh
		beard.position=Vector3(0.0,1.15,0.34)
		beard.scale=Vector3(0.9,0.55,0.55)
		beard.material_override=_mat(Color("#352d2b"))
		age_detail.add_child(beard)
	if age>=45:
		var streak_left:=MeshInstance3D.new()
		var streak_mesh:=SphereMesh.new()
		streak_mesh.radius=0.07
		streak_mesh.height=0.16
		streak_left.mesh=streak_mesh
		streak_left.position=Vector3(-0.25,1.48,0.15)
		streak_left.material_override=_mat(Color("#c8c8c8"))
		age_detail.add_child(streak_left)
		var streak_right:=streak_left.duplicate() as MeshInstance3D
		streak_right.position.x=0.25
		age_detail.add_child(streak_right)
	if age>=60:
		var elder_aura:=OmniLight3D.new()
		elder_aura.name="ElderAura"
		elder_aura.position=Vector3(0.0,1.2,0.0)
		elder_aura.omni_range=2.8
		elder_aura.light_energy=0.16
		elder_aura.light_color=Color("#e8d6a0")
		age_detail.add_child(elder_aura)

func _mat(color:Color)->StandardMaterial3D:
	var material:=StandardMaterial3D.new()
	material.albedo_color=color
	material.roughness=0.58
	return material

func _build_ui()->void:
	if game==null: return
	var layer:=CanvasLayer.new()
	layer.name="HeroLifePanel"
	game.add_child(layer)
	var panel:=PanelContainer.new()
	panel.position=Vector2(18,18)
	panel.size=Vector2(315,78)
	layer.add_child(panel)
	age_label=Label.new()
	age_label.add_theme_font_size_override("font_size",15)
	panel.add_child(age_label)

func _update_label(hero:Dictionary)->void:
	if age_label==null: return
	var age:int=int(hero.get("age",STARTING_AGE))
	var days:float=float(hero.get("online_days",0.0))
	var pet_value:Variant=hero.get("pet",{})
	var pet_text:String="No bonded pet"
	if pet_value is Dictionary:
		var pet:Dictionary=pet_value
		var stats:Dictionary=PetSkillSystem.combat_stats(pet)
		pet_text="%s  Lv.%d  HP %d/%d  SPK %.2f" % [str(pet.get("name","Pet")),int(pet.get("level",1)),int(pet.get("hp",0)),int(pet.get("max_hp",60)),float(stats.get("damage_multiplier",1.0))]
	age_label.text="HERO AGE  %d years\nOnline %.2f days\nPET  %s" % [age,days,pet_text]
