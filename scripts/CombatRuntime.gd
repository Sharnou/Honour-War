class_name CombatRuntime
extends Node

const HERO_ATTACK_INTERVAL:=0.72
const PET_ATTACK_INTERVAL:=1.15
const MONSTER_ATTACK_INTERVAL:=1.10
const HERO_RANGE:=105.0
const PET_RANGE:=125.0
const MONSTER_RANGE:=100.0

var game:Node
var hero_attack_timer:=0.0
var pet_attack_timer:=0.0
var monster_attack_timer:=0.0
var combat_active:=true
var target
var rng:=RandomNumberGenerator.new()

func _ready()->void:
	game=get_parent()
	rng.randomize()
	set_process(true)

func _process(delta:float)->void:
	if game==null or not game.get("hero") is Dictionary: return
	var hero:Dictionary=game.get("hero")
	hero_attack_timer+=delta
	pet_attack_timer+=delta
	monster_attack_timer+=delta
	# The legacy timer is held at zero while this runtime owns pet combat.
	if game.get("pet_attack_timer") != null: game.set("pet_attack_timer",0.0)
	update_target(hero)
	if target!=null and hero_attack_timer>=HERO_ATTACK_INTERVAL:
		hero_attack_timer=0.0
		hero_strike(hero,target)
	if target!=null and pet_attack_timer>=PET_ATTACK_INTERVAL:
		pet_attack_timer=0.0
		pet_strike(hero,target)
	if monster_attack_timer>=MONSTER_ATTACK_INTERVAL:
		monster_attack_timer=0.0
		monster_phase(hero)

func update_target(hero:Dictionary)->void:
	var monsters=game.get("monsters")
	if not monsters is Array:
		target=null
		return
	var hero_pos:=Vector2(float(hero.get("pos_x",0.0)),float(hero.get("pos_y",0.0)))
	var best=null
	var best_distance:=HERO_RANGE
	for monster in monsters:
		if not monster is Dictionary: continue
		if int(monster.get("hp",0))<=0: continue
		var distance:=hero_pos.distance_to(monster["pos"])
		if distance<best_distance:
			best=monster
			best_distance=distance
	target=best

func hero_strike(hero:Dictionary,monster:Dictionary)->void:
	var class_id:=str(hero.get("class","Warrior"))
	var base:=18
	var classes:=game.get("CLASSES")
	if classes is Dictionary and classes.has(class_id): base=int(classes[class_id]["base"])
	var passive:=SkillSystem.combat_stats(hero)
	var power:=base+int(hero.get("level",1))*2+int(hero.get("refine",0))*2+int(passive["power_bonus"])
	var critical_chance:=int(passive["crit_bonus"])
	if class_id=="Thief": critical_chance+=10
	if class_id=="Archer": critical_chance+=6
	var critical:=rng.randi_range(1,100)<=critical_chance
	var damage:=power+rng.randi_range(0,9)
	if critical: damage=int(float(damage)*1.75)
	monster["hp"]=int(monster.get("hp",0))-damage
	monster["hit_flash"]=0.16
	call_vfx("hero_attack",monster["pos"],"",false)
	call_vfx("hit",monster["pos"],str(damage),critical)
	game.call("log_message","Auto attack: %s %d%d damage to Lv.%d %s." % ["CRITICAL " if critical else "",damage,0,int(monster.get("level",1)),str(monster.get("name","Monster"))])
	if int(monster["hp"])<=0: finish_monster(monster)

func pet_strike(hero:Dictionary,monster:Dictionary)->void:
	if not hero.get("pet",{}) is Dictionary: return
	var pet:Dictionary=hero["pet"]
	var hero_pos:=Vector2(float(hero.get("pos_x",0.0)),float(hero.get("pos_y",0.0)))
	if hero_pos.distance_to(monster["pos"])>PET_RANGE: return
	var damage:=PetSystem.power(pet)+rng.randi_range(0,7)
	pet["skill_uses"]=int(pet.get("skill_uses",0))+1
	var special:=int(pet["skill_uses"])%5==0
	if special:
		damage+=PetSystem.skill_power(pet)
		if str(pet.get("role",""))=="Healer":
			var heal:=PetSystem.heal_power(pet)
			hero["hp"]=min(int(hero.get("max_hp",1)),int(hero.get("hp",0))+heal)
			call_vfx("heal",hero_pos,"%d" % heal,false)
		if str(pet.get("role",""))=="Guardian" or str(pet.get("role",""))=="Tank":
			pet["guard_until"]=Time.get_ticks_msec()/1000.0+2.0
	monster["hp"]=int(monster.get("hp",0))-damage
	monster["hit_flash"]=0.20
	var pet_visual=game.get("pet_visual")
	if pet_visual is PetVisual: pet_visual.trigger_attack()
	call_vfx("pet_attack",monster["pos"],str(pet.get("role","")),false)
	call_vfx("hit",monster["pos"],str(damage),special)
	if special: game.call("log_message","%s unleashes %s for %d damage!" % [pet.get("name","Pet"),pet.get("skills",["Pet Skill"])[0],damage])
	if int(monster["hp"])<=0: finish_monster(monster)

func monster_phase(hero:Dictionary)->void:
	var monsters=game.get("monsters")
	if not monsters is Array: return
	var hero_pos:=Vector2(float(hero.get("pos_x",0.0)),float(hero.get("pos_y",0.0)))
	var pet:Dictionary=hero.get("pet",{})
	for monster in monsters.duplicate():
		if not monster is Dictionary or int(monster.get("hp",0))<=0: continue
		var distance:=hero_pos.distance_to(monster["pos"])
		if distance>MONSTER_RANGE: continue
		var attack:=max(1,int(monster.get("attack",int(monster.get("level",1))*4)))
		var target_pet:=false
		var role:=str(pet.get("role",""))
		if role=="Tank" or role=="Guardian": target_pet=rng.randf()<0.55
		if target_pet and int(pet.get("hp",0))>0:
			var reduced:=max(1,int(float(attack)*0.75))
			pet["hp"]=max(0,int(pet.get("hp",0))-reduced)
			call_vfx("hit",game.call("get_pet_visual_position") if game.has_method("get_pet_visual_position") else hero_pos, str(reduced),false)
		else:
			var stats:=SkillSystem.combat_stats(hero)
			var reduced:=max(1,attack-int(stats["defense_bonus"])-int(hero.get("refine",0)))
			hero["hp"]=max(0,int(hero.get("hp",0))-reduced)
			call_vfx("hit",hero_pos,str(reduced),false)
		if int(hero.get("hp",0))<=0:
			respawn_hero(hero)

func finish_monster(monster:Dictionary)->void:
	call_vfx("monster_death",monster["pos"],"",false)
	if game.has_method("defeat_monster"): game.call("defeat_monster",monster)
	target=null

func respawn_hero(hero:Dictionary)->void:
	hero["hp"]=hero["max_hp"]
	hero["pos_x"]=595.0
	hero["pos_y"]=340.0
	if hero.get("pet",{}) is Dictionary: hero["pet"]["hp"]=hero["pet"].get("max_hp",60)
	game.call("log_message","You were defeated. Your bonded pet revived with you at the safe point.")
	call_vfx("heal",Vector2(float(hero["pos_x"]),float(hero["pos_y"])),str(hero["max_hp"]),false)

func call_vfx(kind:String,position:Vector2,text:String,critical:bool)->void:
	var vfx=game.get_node_or_null("CombatVFX")
	if vfx==null: return
	match kind:
		"hero_attack": vfx.hero_attack(position)
		"pet_attack": vfx.pet_attack(position,text)
		"hit": vfx.hit(position,int(text),critical)
		"monster_death": vfx.monster_death(position)
		"heal": vfx.heal(position,int(text))
