extends Node2D

const GameDataClass=preload("res://scripts/GameData.gd")
const SaveSystemClass=preload("res://scripts/SaveSystem.gd")
const PetSystemClass=preload("res://scripts/PetSystem.gd")
const EquipmentSystemClass=preload("res://scripts/EquipmentSystem.gd")
const LootSystemClass=preload("res://scripts/LootSystem.gd")
const TeleportSystemClass=preload("res://scripts/TeleportSystemClass.gd")
const SkillSystemClass=preload("res://scripts/SkillSystemClass.gd")
const ClassTreeSystemClass=preload("res://scripts/ClassTreeSystemClass.gd")
const PetVisualClass=preload("res://scripts/PetVisualClass.gd")
const MonsterDetailsSystemClass=preload("res://scripts/MonsterDetailsSystemClass.gd")
const CicciWeeklyEventClass=preload("res://scripts/CicciWeeklyEventClass.gd")

const CLASSES := {
	"Warrior":{"weapon":"Sword","base":18,"color":Color("#e8a34b"),"skill":"Power Slash"},
	"Mage":{"weapon":"Staff","base":23,"color":Color("#b88cff"),"skill":"Arcane Spark"},
	"Archer":{"weapon":"Bow","base":20,"color":Color("#8fe08f"),"skill":"Celestial Arrow"},
	"Thief":{"weapon":"Dagger","base":19,"color":Color("#ff7eb6"),"skill":"Shadow Strike"},
	"Acolyte":{"weapon":"Mace","base":15,"color":Color("#fff0a3"),"skill":"Holy Pulse"},
	"Merchant":{"weapon":"Hammer","base":17,"color":Color("#7ed7ff"),"skill":"Forge Smash"}
}

var hero:Dictionary=GameDataClass.new_hero()
var monsters:Array=[]
var logs:Array[String]=[]
var rng:=RandomNumberGenerator.new()
var spawn_timer:=0.0
var save_timer:=0.0
var age_timer:=0.0
var pet_attack_timer:=0.0
var pet_visual:PetVisualClass
var profile:Label
var status:Label
var log_label:RichTextLabel
var name_edit:LineEdit
var class_box:OptionButton
var command_edit:LineEdit

func _ready()->void:
	rng.randomize()
	hero=SaveSystemClass.load_game(GameDataClass.new_hero())
	ensure_state()
	build_ui()
	pet_visual=PetVisualClass.new()
	add_child(pet_visual)
	pet_visual.z_index=5
	update_pet_visual()
	if TeleportSystemClass.is_dungeon(int(hero.get("map_id",0))):
		for i in 5:
			spawn_monster()
	log_message("Welcome to Honour War. Write @autoloot to toggle automatic loot.")
	queue_redraw()

func ensure_state()->void:
	if not hero.has("pos_x"): hero["pos_x"]=595.0
	if not hero.has("pos_y"): hero["pos_y"]=340.0
	if not hero.has("map_id"): hero["map_id"]=0
	if not hero.has("materials"): hero["materials"]={"Phracon":5,"Emveretarcon":2,"Oridecon":0}
	if not hero.has("inventory"): hero["inventory"]={}
	if not hero.has("equipment"): hero["equipment"]={"weapon":"Novice Sword","armor":"Novice Armor"}
	if not hero.has("cards"): hero["cards"]=[]
	if not hero.has("quests_completed"): hero["quests_completed"]=[]
	if not hero.has("pet") or not hero["pet"] is Dictionary:
		hero["pet"]=PetSystemClass.new_pet(str(hero.get("class","Warrior")))
	EquipmentSystemClass.ensure_state(hero)
	LootSystemClass.ensure_state(hero)
	ensure_pet_state()
	hero["age"]=GameDataClass.STARTING_AGE+int(float(hero.get("online_days",0.0))/GameDataClass.AGE_DAYS_PER_YEAR)
	hero["class_tier"]=max(int(hero.get("class_tier",0)),GameDataClass.class_tier_for_level(int(hero.get("level",1))))
	var parsed:=TeleportSystemClass.parse_go("@go %d %d:%d" % [int(hero["map_id"]),int(hero["pos_x"])-365,int(hero["pos_y"])-120])
	if not parsed["ok"]:
		hero["map_id"]=0
		hero["pos_x"]=595.0
		hero["pos_y"]=340.0

func ensure_pet_state()->void:
	var pet:Dictionary=hero["pet"]
	var class_id:=str(hero.get("class","Warrior"))
	var definition:Dictionary=PetSystemClass.definition(class_id)
	pet["owner_class"]=class_id
	pet["name"]=str(pet.get("name",definition["name"]))
	pet["role"]=str(pet.get("role",definition["role"]))
	pet["species"]=str(pet.get("species",definition["species"]))
	pet["level"]=clamp(int(pet.get("level",1)),1,PetSystemClass.MAX_PET_LEVEL)
	pet["exp"]=int(pet.get("exp",0))
	pet["max_hp"]=int(pet.get("max_hp",60))
	pet["hp"]=clamp(int(pet.get("hp",pet["max_hp"])),0,int(pet["max_hp"]))
	pet["max_sp"]=int(pet.get("max_sp",30))
	pet["sp"]=clamp(int(pet.get("sp",pet["max_sp"])),0,int(pet["max_sp"]))
	pet["skills"]=pet.get("skills",[definition["skill"]])
	pet["skill_level"]=max(1,int(pet.get("skill_level",1)))
	pet["skill_points"]=int(pet.get("skill_points",0))
	pet["skill_uses"]=int(pet.get("skill_uses",0))
	pet["refine"]=clamp(int(pet.get("refine",0)),0,15)
	pet["inventory"]=pet.get("inventory",{})
	pet["materials"]=pet.get("materials",{"Phracon":3,"Emveretarcon":1,"Oridecon":0})
	pet["equipment"]=pet.get("equipment",{"weapon":definition["species"]+" Claw","armor":"Pet Guard Harness"})
	pet["kills"]=int(pet.get("kills",0))
	hero["pet"]=pet

func update_pet_visual()->void:
	if pet_visual:
		pet_visual.setup(hero["pet"])
		pet_visual.position=Vector2(float(hero["pos_x"])-34.0,float(hero["pos_y"])+34.0)

func build_ui()->void:
	var bg:=ColorRect.new()
	bg.color=Color("#071426")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var title:=Label.new()
	title.text="HONOUR WAR"
	title.position=Vector2(24,16)
	title.add_theme_font_size_override("font_size",32)
	title.add_theme_color_override("font_color",Color("#f4c95d"))
	add_child(title)
	var sub:=Label.new()
	sub.text="Adventure • Pets • Skills • Equipment Sockets • Cards • MVPs • Auto Loot"
	sub.position=Vector2(28,55)
	sub.add_theme_color_override("font_color",Color("#9eb8d2"))
	add_child(sub)
	var side:=Panel.new()
	side.position=Vector2(20,95)
	side.size=Vector2(300,525)
	add_child(side)
	var box:=VBoxContainer.new()
	box.position=Vector2(14,14)
	box.size=Vector2(272,495)
	side.add_child(box)
	var heading:=Label.new()
	heading.text="HERO + PET PROFILE"
	heading.add_theme_font_size_override("font_size",20)
	heading.add_theme_color_override("font_color",Color("#f4c95d"))
	box.add_child(heading)
	profile=Label.new()
	profile.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	profile.custom_minimum_size=Vector2(270,300)
	box.add_child(profile)
	name_edit=LineEdit.new()
	name_edit.placeholder_text="Hero name"
	box.add_child(name_edit)
	class_box=OptionButton.new()
	for class_id in CLASSES.keys():
		class_box.add_item(class_id)
	box.add_child(class_box)
	var apply:=Button.new()
	apply.text="Apply Hero / Rebond Pet"
	apply.pressed.connect(apply_hero)
	box.add_child(apply)
	var rest:=Button.new()
	rest.text="Rest (+1 simulated day)"
	rest.pressed.connect(rest_hero)
	box.add_child(rest)
	var save:=Button.new()
	save.text="Save Now"
	save.pressed.connect(save_game)
	box.add_child(save)
	var right:=Panel.new()
	right.position=Vector2(340,95)
	right.size=Vector2(792,525)
	add_child(right)
	status=Label.new()
	status.position=Vector2(18,15)
	right.add_child(status)
	var help:=Label.new()
	help.text="WASD/Arrows move • SPACE attack • R/T refine • Q quest • C craft • B buy • @autoloot"
	help.position=Vector2(18,42)
	help.add_theme_color_override("font_color",Color("#9eb8d2"))
	right.add_child(help)
	command_edit=LineEdit.new()
	command_edit.position=Vector2(18,395)
	command_edit.size=Vector2(650,36)
	command_edit.placeholder_text="@autoloot | @autoloot on/off/status | @loot | @go 0 230:220"
	command_edit.text_submitted.connect(execute_command)
	right.add_child(command_edit)
	var execute:=Button.new()
	execute.text="EXECUTE"
	execute.position=Vector2(678,395)
	execute.size=Vector2(96,36)
	execute.pressed.connect(execute_command_from_button)
	right.add_child(execute)
	log_label=RichTextLabel.new()
	log_label.position=Vector2(18,450)
	log_label.size=Vector2(756,58)
	right.add_child(log_label)
	name_edit.text=str(hero["name"])
	class_box.select(max(0,CLASSES.keys().find(str(hero["class"]))))
	update_ui()

func apply_hero()->void:
	if name_edit.text.strip_edges()!="":
		hero["name"]=name_edit.text.strip_edges()
	var old_class:=str(hero.get("class","Warrior"))
	hero["class"]=class_box.get_item_text(class_box.selected)
	hero["class_tier"]=GameDataClass.class_tier_for_level(int(hero["level"]))
	hero["max_hp"]=100+int(hero["level"])*8
	hero["hp"]=hero["max_hp"]
	if old_class!=str(hero["class"]):
		hero["pet"]=PetSystemClass.new_pet(str(hero["class"]))
		log_message("Class changed to %s. New bonded pet: %s." % [hero["class"],hero["pet"]["name"]])
	ensure_pet_state()
	EquipmentSystemClass.ensure_state(hero)
	update_pet_visual()
	log_message("Hero updated: %s — %s. Pet: %s (%s)." % [hero["name"],GameDataClass.class_title(hero),hero["pet"]["name"],hero["pet"]["role"]])
	save_game()
	update_ui()

func rest_hero()->void:
	hero["online_days"]=float(hero["online_days"])+1.0
	update_age()
	hero["hp"]=hero["max_hp"]
	hero["pet"]["hp"]=hero["pet"]["max_hp"]
	log_message("One simulated online day passed. Age: %d. Pet restored." % hero["age"])
	save_game()
	update_ui()

func update_age()->void:
	hero["age"]=GameDataClass.STARTING_AGE+int(float(hero["online_days"])/GameDataClass.AGE_DAYS_PER_YEAR)

func age_bonus()->int:
	return GameDataClass.age_bonus(int(hero["age"]))

func combat_equipment()->Dictionary:
	return EquipmentSystemClass.combat_stats(hero)

func skill_power()->int:
	var definition:Dictionary=CLASSES[str(hero["class"])]
	var equipment:=combat_equipment()
	return int(definition["base"])+int(hero["level"])*2+int(age_bonus()/3)+int(hero.get("refine",0))*2+int(equipment.get("attack",0))+int(equipment.get("magic",0))+int(equipment.get("power_bonus",0))

func refine_chance()->int:
	return int(WorldSystem.refinement_chance(int(hero["age"]),int(hero["level"]),int(hero.get("refine",0)))*100.0)

func _process(delta:float)->void:
	spawn_timer+=delta
	save_timer+=delta
	age_timer+=delta
	pet_attack_timer+=delta
	var move:=Vector2(Input.get_axis("move_left","move_right"),Input.get_axis("move_up","move_down")).normalized()
	var equipment:=combat_equipment()
	var speed:=180.0*(1.0+float(equipment.get("move_percent",0.0))/100.0)
	var current_map:Dictionary=TeleportSystemClass.MAPS.get(int(hero.get("map_id",0)),{})
	var min_x:float=365.0
	var min_y:float=120.0
	var max_x:float=min_x+float(current_map.get("width",1200))-1.0
	var max_y:float=min_y+float(current_map.get("height",700))-1.0
	hero["pos_x"]=clamp(float(hero["pos_x"])+move.x*speed*delta,min_x,max_x)
	hero["pos_y"]=clamp(float(hero["pos_y"])+move.y*speed*delta,min_y,max_y)
	update_pet_visual()
	if pet_attack_timer>=1.5:
		pet_attack_timer=0.0
		pet_auto_attack()
	if TeleportSystemClass.is_dungeon(int(hero.get("map_id",0))) and spawn_timer>=4.0 and monsters.size()<8:
		spawn_timer=0.0
		spawn_monster()
	if age_timer>=8.0:
		age_timer=0.0
		hero["online_days"]+=8.0/86400.0
		update_age()
	if save_timer>=8.0:
		save_timer=0.0
		save_game()
		update_ui()
	queue_redraw()

func _input(event:InputEvent)->void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE: attack()
			KEY_R: refine()
			KEY_T: refine_pet()
			KEY_Q: quest()
			KEY_C: craft()
			KEY_B: buy_material()

func execute_command(command:String)->void:
	var cmd:=command.strip_edges()
	var lower:=cmd.to_lower()
	if lower=="@autoloot" or lower.begins_with("@autoloot "):
		var argument:=lower.substr(9).strip_edges()
		if argument=="on":
			LootSystemClass.set_enabled(hero,true)
			log_message("AUTOLOOT ENABLED. Items, equipment, materials and cards are picked automatically.")
		elif argument=="off":
			LootSystemClass.set_enabled(hero,false)
			log_message("AUTOLOOT DISABLED. New drops stay on the ground.")
		elif argument=="status" or argument=="":
			log_message("AUTOLOOT: %s | Ground drops: %d" % ["ON" if LootSystemClass.is_enabled(hero) else "OFF",hero["ground_loot"].size()])
		else:
			log_message("Usage: @autoloot, @autoloot on, @autoloot off, @autoloot status")
		if LootSystemClass.is_enabled(hero):
			var collected:=LootSystemClass.collect_ground(hero)
			if collected.size()>0:
				log_message("Auto-loot collected: %s" % ", ".join(collected))
		save_game()
		update_ui()
		command_edit.clear()
		return
	if lower=="@loot":
		var gained:=LootSystemClass.collect_ground(hero)
		if gained.size()>0:
			log_message("Manual loot pickup: %s" % ", ".join(gained))
		else:
			log_message("Nothing collectible. Enable @autoloot to collect future drops automatically.")
		save_game()
		update_ui()
		command_edit.clear()
		return
	var result:=TeleportSystemClass.parse_go(cmd)
	if not result["ok"]:
		log_message(str(result["error"]))
		update_ui()
		return
	fast_travel(int(result["map_id"]),int(result["x"]),int(result["y"]))
	command_edit.clear()

func execute_command_from_button()->void:
	execute_command(command_edit.text)

func fast_travel(map_id:int,x:int,y:int)->void:
	if not TeleportSystemClass.MAPS.has(map_id):
		log_message("Unknown destination.")
		return
	hero["map_id"]=map_id
	hero["pos_x"]=365.0+float(x)
	hero["pos_y"]=120.0+float(y)
	monsters.clear()
	if TeleportSystemClass.is_dungeon(map_id):
		for i in 4:
			spawn_monster()
	log_message("Fast transmission to %s at X:%d Y:%d. Pet follows automatically.%s" % [TeleportSystemClass.map_name(map_id),x,y," Combat zone populated." if TeleportSystemClass.is_dungeon(map_id) else " Safe town: no monsters spawn here."])
	save_game()
	update_ui()

func spawn_monster()->void:
	if not TeleportSystemClass.is_dungeon(int(hero.get("map_id",0))):
		return
	var families:=GameDataClass.monster_families()
	var family:String=families[rng.randi_range(0,families.size()-1)]
	var zone:=max(1,int(hero["level"])/10+1)
	var level:=WorldSystem.monster_level_for_zone(zone,rng.randi_range(0,families.size()-1))
	var stats:Dictionary=WorldSystem.monster_stats(level)
	var map_data:Dictionary=TeleportSystemClass.MAPS.get(int(hero.get("map_id",10)),{})
	var min_x:float=365.0+80.0
	var min_y:float=120.0+80.0
	var max_x:float=365.0+float(map_data.get("width",1400))-80.0
	var max_y:float=120.0+float(map_data.get("height",900))-80.0
	monsters.append({"name":family,"level":level,"pos":Vector2(rng.randf_range(min_x,max_x),rng.randf_range(min_y,max_y)),"hp":stats["max_hp"],"max":stats["max_hp"],"attack":stats["attack"],"defense":stats["defense"],"exp":stats["exp"],"zmin":stats["zeny_min"],"zmax":stats["zeny_max"]})

func nearest_monster():
	var best=null
	var distance:=99999.0
	var position:=Vector2(float(hero["pos_x"]),float(hero["pos_y"]))
	for monster in monsters:
		var current_distance:float=position.distance_to(monster["pos"])
		if current_distance<distance:
			distance=current_distance
			best=monster
	return best if distance<90.0 else null

func attack()->void:
	var monster=nearest_monster()
	if monster==null:
		log_message("Move close to a monster, then press SPACE.")
		return
	var equipment:=combat_equipment()
	var damage:=skill_power()+rng.randi_range(0,9)
	damage=int(float(damage)*(1.0+float(equipment.get("damage_percent",0.0))/100.0))
	if bool(monster.get("mvp",false)):
		damage=int(float(damage)*(1.0+float(equipment.get("boss_damage_percent",0.0))/100.0))
	damage=max(1,damage-int(monster.get("defense",0)))
	monster["hp"]-=damage
	log_message("%s dealt %d damage to Lv.%d %s." % [CLASSES[hero["class"]]["skill"],damage,monster["level"],monster["name"]])
	pet_attack_target(monster)
	if monster["hp"]<=0:
		defeat_monster(monster)
	save_game()
	update_ui()

func use_skill(skill_id:String)->void:
	SkillSystemClass.ensure_state(hero)
	var now:float=Time.get_ticks_msec()/1000.0
	var result:Dictionary=SkillSystemClass.use(hero,skill_id,now)
	if not bool(result.get("ok",false)):
		var reason:String=str(result.get("reason","unavailable"))
		log_message("Skill unavailable: %s." % reason)
		return
	var skill:Dictionary=result.get("skill",{})
	var skill_name:String=str(skill.get("name",skill_id))
	var kind:String=str(skill.get("kind","active"))
	if kind=="passive":
		return

	var target=nearest_monster()
	var class_id:String=str(hero.get("class","Warrior"))
	var skill_power_value:int=int(result.get("power",0))
	var equipment:Dictionary=combat_equipment()

	# Support/healing skills restore the hero/pet. Seraphic Light and Heaven's Gate
	# also continue into the offensive path when a target is available.
	if class_id=="Acolyte" and skill_id in ["aco_sanctuary","aco_seraphic_light","aco_heaven_gate"]:
		var heal_ratio:float=0.10
		if skill_id=="aco_seraphic_light": heal_ratio=0.16
		elif skill_id=="aco_heaven_gate": heal_ratio=0.24
		var heal:int=max(1,int(float(hero.get("max_hp",100))*heal_ratio)+int(SkillSystemClass.combat_stats(hero).get("healing_bonus",0)))
		hero["hp"]=min(int(hero.get("max_hp",100)),int(hero.get("hp",0))+heal)
		hero["pet"]["hp"]=min(int(hero["pet"].get("max_hp",60)),int(hero["pet"].get("hp",0))+int(float(heal)*0.55))
		log_message("%s restores %d HP to hero and strengthens the bonded pet." % [skill_name,heal])
		if has_method("play_combat_effect"):
			call("play_combat_effect","heal",Vector2(float(hero.get("pos_x",595.0)),float(hero.get("pos_y",340.0))),str(heal),false)
		if skill_id=="aco_sanctuary" or target==null:
			save_game()
			update_ui()
			return

	if target==null:
		hero["sp"]=min(int(hero.get("max_sp",100)),int(hero.get("sp",0))+int(result.get("sp_cost",0)))
		hero["skill_cooldowns"][skill_id]=now
		log_message("%s needs a target." % skill_name)
		return

	var skill_stats:Dictionary=SkillSystemClass.combat_stats(hero)
	var branch_bonus:Dictionary=ClassTreeSystemClass.branch_bonus(hero)
	var raw:int=skill_power_value+int(hero.get("level",1))
	raw=int(round(float(raw)*(1.0+float(branch_bonus.get("damage",0.0)))))
	raw=int(round(float(raw)*float(skill_stats.get("damage_multiplier",1.0))))
	raw=int(round(float(raw)*(1.0+float(equipment.get("damage_percent",0.0))/100.0)))

	var affected:Array=[]
	affected.append(target)
	if int(skill.get("tier",1))>=2 or kind=="ultimate":
		var radius:float=95.0 if kind=="ultimate" else 62.0
		for candidate in monsters:
			if candidate==target or not candidate is Dictionary or int(candidate.get("hp",0))<=0:
				continue
			if target.get("pos",Vector2.ZERO).distance_to(candidate.get("pos",Vector2.ZERO))<=radius:
				affected.append(candidate)

	var total_damage:int=0
	for affected_monster in affected:
		var dealt:int=raw
		if affected_monster!=target:
			dealt=int(round(float(dealt)*0.72))
		if bool(affected_monster.get("mvp",false)):
			dealt=int(round(float(dealt)*(1.0+float(equipment.get("boss_damage_percent",0.0))/100.0)))
		var elemental_multiplier:float=MonsterDetailsSystemClass.skill_damage_multiplier(class_id,skill_id,affected_monster)
		dealt=int(round(float(dealt)*elemental_multiplier))
		if class_id=="Thief" and skill_id=="thief_execution":
			var ratio:float=float(affected_monster.get("hp",0))/float(max(1,int(affected_monster.get("max",affected_monster.get("hp",1)))))
			if ratio<=0.45:
				dealt=int(round(float(dealt)*1.75))
		if class_id=="Thief" and skill_id=="thief_eternal_assassin":
			dealt=int(round(float(dealt)*1.30))
		dealt=max(1,dealt-int(affected_monster.get("defense",0))/2)
		affected_monster["hp"]=int(affected_monster.get("hp",0))-dealt
		affected_monster["hit_flash"]=0.30
		total_damage+=dealt
		if skill_id=="mage_frost_prison":
			affected_monster["slow_until"]=max(float(affected_monster.get("slow_until",0.0)),now+4.0)
			affected_monster["root_until"]=max(float(affected_monster.get("root_until",0.0)),now+1.6)
		if skill_id=="mage_comet" or skill_id=="mage_meteor_surge" or skill_id=="mer_magma_forge":
			affected_monster["burn_until"]=max(float(affected_monster.get("burn_until",0.0)),now+5.0)
			affected_monster["burn_damage"]=max(int(affected_monster.get("burn_damage",0)),int(float(dealt)*0.18))
			affected_monster["burn_tick"]=now+1.0
		if skill_id=="arch_trap":
			affected_monster["root_until"]=max(float(affected_monster.get("root_until",0.0)),now+3.0)
			affected_monster["slow_until"]=max(float(affected_monster.get("slow_until",0.0)),now+5.0)
		if skill_id in ["war_earthbreaker","war_emperors_judgment","war_immortal_arsenal","mage_void_lance","mage_arcane_overload","arch_skybreaker"]:
			var break_percent:float=0.25
			var break_duration:float=5.0
			if skill_id=="war_emperors_judgment":
				break_percent=0.35
				break_duration=7.0
			elif skill_id=="war_immortal_arsenal":
				break_percent=0.50
				break_duration=10.0
			elif skill_id=="mage_void_lance":
				break_percent=0.45
				break_duration=6.0
			elif skill_id=="mage_arcane_overload":
				break_percent=0.30
				break_duration=7.0
			elif skill_id=="arch_skybreaker":
				break_percent=0.40
				break_duration=6.0
			affected_monster["defense_break_until"]=max(float(affected_monster.get("defense_break_until",0.0)),now+break_duration)
			affected_monster["defense_break_percent"]=max(float(affected_monster.get("defense_break_percent",0.0)),break_percent)
		if class_id=="Thief" and skill_id in ["thief_shadow_strike","thief_blade_flurry","thief_shadow_requiem","thief_eternal_assassin"]:
			MonsterDetailsSystemClass.apply_poison(affected_monster,dealt,6.0)
		if int(affected_monster["hp"])<=0:
			defeat_monster(affected_monster)

	if skill_id=="war_guardian_roar":
		hero["temporary_defense_until"]=now+6.0
		if hero.get("pet",{}) is Dictionary:
			hero["pet"]["guard_until"]=now+6.0
	elif skill_id=="thief_smoke":
		hero["temporary_evasion_until"]=now+6.0
	elif skill_id=="mer_fortify":
		hero["temporary_defense_until"]=now+7.0
	elif skill_id=="mer_arsenal_overlord":
		hero["temporary_power_until"]=now+8.0
		hero["pet"]["combo_power_bonus"]=min(0.35,float(hero["pet"].get("combo_power_bonus",0.0))+0.08)

	log_message("%s hits %d target(s) for %d total damage. SP -%d." % [skill_name,affected.size(),total_damage,int(result.get("sp_cost",0))])
	if has_method("play_combat_effect"):
		call("play_combat_effect","skill",target["pos"],skill_name,false)
	save_game()
	update_ui()

func pet_auto_attack()->void:
	if monsters.is_empty():
		return
	var monster=nearest_monster()
	if monster==null:
		return
	pet_attack_target(monster)
	if monster["hp"]<=0:
		defeat_monster(monster)

func pet_attack_target(monster:Dictionary)->void:
	ensure_pet_state()
	var pet:Dictionary=hero["pet"]
	var damage:=PetSystemClass.power(pet)+rng.randi_range(0,7)
	pet["skill_uses"]=int(pet.get("skill_uses",0))+1
	var used_skill:=int(pet["skill_uses"])%5==0
	if used_skill:
		damage+=PetSystemClass.skill_power(pet)
		if str(pet["role"])=="Healer":
			hero["hp"]=min(int(hero["max_hp"]),int(hero["hp"])+PetSystemClass.heal_power(pet))
		log_message("%s uses %s Lv.%d!" % [pet["name"],pet["skills"][0],pet["skill_level"]])
	if pet_visual:
		pet_visual.trigger_attack()
	monster["hp"]-=damage

func defeat_monster(monster:Dictionary)->void:
	if not monsters.has(monster):
		return
	hero["kills"]=int(hero.get("kills",0))+1
	hero["pet"]["kills"]=int(hero["pet"].get("kills",0))+1
	var zeny:=rng.randi_range(int(monster["zmin"]),int(monster["zmax"]))
	var equipment:=combat_equipment()
	zeny=int(float(zeny)*(1.0+float(equipment.get("all_rewards_percent",0.0))/100.0))
	hero["zeny"]+=zeny
	var exp_gain:=int(float(monster["exp"])*(1.0+float(equipment.get("xp_percent",0.0))/100.0))
	add_exp(exp_gain)
	var pet_exp:=max(1,int(exp_gain*2/3))
	var pet_leveled:=PetSystemClass.add_exp(hero["pet"],pet_exp)
	if pet_leveled:
		log_message("%s reached Pet Lv.%d and gained a skill point." % [hero["pet"]["name"],hero["pet"]["level"]])
	var gained:=LootSystemClass.on_monster_defeated(hero,monster,rng)
	if LootSystemClass.is_enabled(hero):
		if gained.size()>0:
			log_message("AUTOLOOT: %s" % ", ".join(gained))
	else:
		log_message("Drops are on the ground. Use @loot or @autoloot on to collect them.")
	log_message("Defeated Lv.%d %s! Hero +%d EXP, Pet +%d EXP, +%d Zeny." % [monster["level"],monster["name"],exp_gain,pet_exp,zeny])
	monsters.erase(monster)
	save_game()

func add_exp(amount:int)->void:
	if int(hero["level"])>=GameDataClass.MAX_HERO_LEVEL:
		hero["exp"]=0
		return
	hero["exp"]+=amount
	while int(hero["level"])<GameDataClass.MAX_HERO_LEVEL and int(hero["exp"])>=GameDataClass.exp_to_next(int(hero["level"])):
		hero["exp"]-=GameDataClass.exp_to_next(int(hero["level"]))
		hero["level"]+=1
		hero["max_hp"]+=8
		hero["hp"]=hero["max_hp"]
	hero["class_tier"]=max(int(hero.get("class_tier",0)),GameDataClass.class_tier_for_level(int(hero["level"])))

func refine()->void:
	var level:=int(hero.get("refine",0))
	if level>=15:
		log_message("Hero refinement cap +15.")
		return
	var material:="Phracon" if level<4 else ("Emveretarcon" if level<8 else "Oridecon")
	if int(hero["materials"].get(material,0))<=0:
		log_message("You need %s." % material)
		return
	hero["materials"][material]-=1
	if rng.randf()*100.0<refine_chance():
		hero["refine"]=level+1
		hero["equipment"]["weapon"]=CLASSES[hero["class"]]["weapon"]+" +"+str(hero["refine"])
		log_message("Hero refinement succeeded: +%d." % hero["refine"])
	else:
		log_message("Hero refinement failed; equipment protected.")
	save_game()
	update_ui()

func refine_pet()->void:
	ensure_pet_state()
	var pet:Dictionary=hero["pet"]
	var level:=int(pet.get("refine",0))
	if level>=15:
		log_message("Pet refinement cap +15.")
		return
	var material:=PetSystemClass.refine_material(level)
	if int(pet["materials"].get(material,0))<=0:
		if int(pet["inventory"].get("Pet Refine Item",0))>0:
			pet["inventory"]["Pet Refine Item"]-=1
		else:
			log_message("Pet needs %s or a Pet Refine Item." % material)
			return
	else:
		pet["materials"][material]-=1
	var chance:=max(35,refine_chance()-5-level*2)
	if rng.randf()*100.0<chance:
		pet["refine"]=level+1
		pet["equipment"]["weapon"]=str(pet["species"])+" Claw +"+str(pet["refine"])
		log_message("%s refinement succeeded: +%d." % [pet["name"],pet["refine"]])
	else:
		log_message("%s refinement failed; equipment protected." % pet["name"])
	save_game()
	update_ui()

func quest()->void:
	hero["quest"]=int(hero.get("quest",0))+1
	hero["quests_completed"].append("hunt_%d" % hero["quest"])
	hero["zeny"]+=100+int(hero["quest"])*25
	hero["materials"]["Phracon"]+=1
	hero["pet"]["materials"]["Phracon"]=int(hero["pet"]["materials"].get("Phracon",0))+1
	add_exp(50)
	PetSystemClass.add_exp(hero["pet"],25)
	log_message("Quest %d completed. Hero + Pet rewards delivered." % hero["quest"])
	save_game()
	update_ui()

func craft()->void:
	if int(hero["materials"].get("Phracon",0))<2 or int(hero["zeny"])<80:
		log_message("Crafting requires 2 Phracon and 80 Zeny.")
		return
	hero["materials"]["Phracon"]-=2
	hero["zeny"]-=80
	var item:String=CLASSES[hero["class"]]["weapon"]+" Core"
	hero["inventory"][item]=int(hero["inventory"].get(item,0))+1
	log_message("Crafted %s." % item)
	save_game()
	update_ui()

func buy_material()->void:
	var discount:=int(WorldSystem.age_discount(int(hero["age"]))*100.0)
	var price:=int(100.0*(100.0-discount)/100.0)
	if int(hero["zeny"])<price:
		log_message("Not enough Zeny.")
		return
	hero["zeny"]-=price
	hero["materials"]["Phracon"]+=1
	hero["pet"]["materials"]["Phracon"]=int(hero["pet"]["materials"].get("Phracon",0))+1
	log_message("Bought Phracon for %d Zeny." % price)
	save_game()
	update_ui()

func update_ui()->void:
	if not profile:
		return
	ensure_pet_state()
	EquipmentSystemClass.ensure_state(hero)
	LootSystemClass.ensure_state(hero)
	var materials:Dictionary=hero["materials"]
	var pet:Dictionary=hero["pet"]
	var map_name:=TeleportSystemClass.map_name(int(hero["map_id"]))
	var map_x:=int(hero["pos_x"]-365.0)
	var map_y:=int(hero["pos_y"]-120.0)
	var equipment:=combat_equipment()
	profile.text="Name: %s\nClass: %s\nLevel: %d/%d EXP:%d/%d\nAge:%d HP:%d/%d Zeny:%d Refine:+%d\n\nPET: %s (%s)\nPet Level:%d/%d HP:%d/%d Skill:%d Refine:+%d\n\nEquipment:\n%s\n\nCards:%d Inventory:%d\nAutoLoot:%s Ground Drops:%d\nPhracon:%d Emveretarcon:%d Oridecon:%d" % [str(hero["name"]),str(GameDataClass.class_title(hero)),int(hero["level"]),int(GameDataClass.MAX_HERO_LEVEL),int(hero["exp"]),int(GameDataClass.exp_to_next(int(hero["level"]))),int(hero["age"]),int(hero["hp"]),int(hero["max_hp"]),int(hero["zeny"]),int(hero.get("refine",0)),str(pet["name"]),str(pet["role"]),int(pet["level"]),int(PetSystemClass.MAX_PET_LEVEL),int(pet["hp"]),int(pet["max_hp"]),int(pet["skill_level"]),int(pet["refine"]),str(EquipmentSystemClass.summary(hero)),int(hero["cards"].size()),int(hero["inventory"].size()),"ON" if LootSystemClass.is_enabled(hero) else "OFF",int(hero["ground_loot"].size()),int(materials["Phracon"]),int(materials["Emveretarcon"]),int(materials["Oridecon"])]
	status.text="%s | MAP %d: %s | X:%d Y:%d | Power:%d | ATK:%d DEF:%d HP+%d | Cards:%d | AutoLoot:%s | Monsters:%d" % [str("Dungeon" if TeleportSystemClass.is_dungeon(int(hero["map_id"])) else "Field/Town"),int(hero["map_id"]),str(map_name),int(map_x),int(map_y),int(skill_power()),int(equipment.get("attack",0)),int(equipment.get("defense",0)),int(equipment.get("hp",0)),int(hero["cards"].size()),str("ON" if LootSystemClass.is_enabled(hero) else "OFF"),int(monsters.size())]
	log_label.text="\n".join(logs)

func log_message(message:String)->void:
	logs.push_front(message)
	if logs.size()>6:
		logs.pop_back()
	if log_label:
		log_label.text="\n".join(logs)

func save_game()->void:
	SaveSystemClass.save_game(hero)

func _draw()->void:
	draw_rect(Rect2(340,95,792,525),Color("#0d233c"))
	draw_rect(Rect2(365,120,742,300),Color("#163d3b"))
	for x in range(365,1110,45):
		draw_line(Vector2(x,120),Vector2(x,420),Color("#2d6c60"))
	for y in range(120,421,45):
		draw_line(Vector2(365,y),Vector2(1110,y),Color("#2d6c60"))
	var position:=Vector2(float(hero["pos_x"]),float(hero["pos_y"]))
	var class_data:Dictionary=CLASSES[hero["class"]]
	draw_circle(position,18,class_data["color"])
	draw_string(ThemeDB.fallback_font,Vector2(position.x-28,position.y-28),str(hero["name"]),HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color.WHITE)
	for monster in monsters:
		var is_mvp:=bool(monster.get("mvp",false))
		var radius:=24.0 if is_mvp else 16.0
		var monster_color:=Color("#f4c95d") if is_mvp else Color("#e05f72")
		draw_circle(monster["pos"],radius,monster_color)
		var label:="MVP Lv.%d %s" % [monster["level"],monster["name"]] if is_mvp else "Lv.%d %s" % [monster["level"],monster["name"]]
		draw_string(ThemeDB.fallback_font,Vector2(monster["pos"].x-45,monster["pos"].y-30),label,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color.WHITE)
		draw_rect(Rect2(monster["pos"].x-28,monster["pos"].y+25,56,5),Color("#222222"))
		draw_rect(Rect2(monster["pos"].x-28,monster["pos"].y+25,56*max(0.0,float(monster["hp"])/float(monster["max"])),5),Color("#ff7373"))
