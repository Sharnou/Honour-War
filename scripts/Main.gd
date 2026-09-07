extends Node2D

const CLASSES := {
	"Warrior":{"weapon":"Sword","base":18,"color":Color("#e8a34b"),"skill":"Power Slash"},
	"Mage":{"weapon":"Staff","base":23,"color":Color("#b88cff"),"skill":"Arcane Spark"},
	"Archer":{"weapon":"Bow","base":20,"color":Color("#8fe08f"),"skill":"Celestial Arrow"},
	"Thief":{"weapon":"Dagger","base":19,"color":Color("#ff7eb6"),"skill":"Shadow Strike"},
	"Acolyte":{"weapon":"Mace","base":15,"color":Color("#fff0a3"),"skill":"Holy Pulse"},
	"Merchant":{"weapon":"Hammer","base":17,"color":Color("#7ed7ff"),"skill":"Forge Smash"}
}

var hero:Dictionary=GameData.new_hero()
var monsters:Array=[]
var logs:Array[String]=[]
var rng:=RandomNumberGenerator.new()
var spawn_timer:=0.0
var save_timer:=0.0
var age_timer:=0.0
var pet_attack_timer:=0.0
var pet_visual:PetVisual
var profile:Label
var status:Label
var log_label:RichTextLabel
var name_edit:LineEdit
var class_box:OptionButton
var command_edit:LineEdit

func _ready()->void:
	rng.randomize()
	hero=SaveSystem.load_game(GameData.new_hero())
	ensure_state()
	build_ui()
	pet_visual=PetVisual.new()
	add_child(pet_visual)
	pet_visual.z_index=5
	update_pet_visual()
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
	if not hero.has("city_building"): hero["city_building"]={"Prontera":CitySystem.new_city()}
	if not hero.has("pet") or not hero["pet"] is Dictionary:
		hero["pet"]=PetSystem.new_pet(str(hero.get("class","Warrior")))
	EquipmentSystem.ensure_state(hero)
	LootSystem.ensure_state(hero)
	ensure_pet_state()
	hero["age"]=GameData.STARTING_AGE+int(float(hero.get("online_days",0.0))/GameData.AGE_DAYS_PER_YEAR)
	hero["class_tier"]=max(int(hero.get("class_tier",0)),GameData.class_tier_for_level(int(hero.get("level",1))))
	var parsed:=TeleportSystem.parse_go("@go %d %d:%d" % [int(hero["map_id"]),int(hero["pos_x"])-365,int(hero["pos_y"])-120])
	if not parsed["ok"]:
		hero["map_id"]=0
		hero["pos_x"]=595.0
		hero["pos_y"]=340.0

func ensure_pet_state()->void:
	var pet:Dictionary=hero["pet"]
	var class_id:=str(hero.get("class","Warrior"))
	var definition:Dictionary=PetSystem.definition(class_id)
	pet["owner_class"]=class_id
	pet["name"]=str(pet.get("name",definition["name"]))
	pet["role"]=str(pet.get("role",definition["role"]))
	pet["species"]=str(pet.get("species",definition["species"]))
	pet["level"]=clamp(int(pet.get("level",1)),1,PetSystem.MAX_PET_LEVEL)
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
	var city:=Button.new()
	city.text="Build Prontera"
	city.pressed.connect(build_city)
	box.add_child(city)
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
	hero["class_tier"]=GameData.class_tier_for_level(int(hero["level"]))
	hero["max_hp"]=100+int(hero["level"])*8
	hero["hp"]=hero["max_hp"]
	if old_class!=str(hero["class"]):
		hero["pet"]=PetSystem.new_pet(str(hero["class"]))
		log_message("Class changed to %s. New bonded pet: %s." % [hero["class"],hero["pet"]["name"]])
	ensure_pet_state()
	EquipmentSystem.ensure_state(hero)
	update_pet_visual()
	log_message("Hero updated: %s — %s. Pet: %s (%s)." % [hero["name"],GameData.class_title(hero),hero["pet"]["name"],hero["pet"]["role"]])
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
	hero["age"]=GameData.STARTING_AGE+int(float(hero["online_days"])/GameData.AGE_DAYS_PER_YEAR)

func build_city()->void:
	var city:Dictionary=hero["city_building"].get("Prontera",CitySystem.new_city())
	city["wood"]=int(city.get("wood",0))+60
	city["stone"]=int(city.get("stone",0))+60
	city["gold"]=int(city.get("gold",0))+650
	var built:=false
	for building in ["Blacksmith","Market","Barracks","Magic Tower"]:
		if CitySystem.can_build(city,building):
			city=CitySystem.build(city,building)
			log_message("Prontera expanded: %s built." % building)
			built=true
			break
	if not built:
		city=CitySystem.upgrade_city(city)
		log_message("Prontera advanced to city level %d." % city["level"])
	hero["city_building"]["Prontera"]=city
	save_game()
	update_ui()

func age_bonus()->int:
	return GameData.age_bonus(int(hero["age"]))

func combat_equipment()->Dictionary:
	return EquipmentSystem.combat_stats(hero)

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
	hero["pos_x"]=clamp(float(hero["pos_x"])+move.x*speed*delta,365.0,1107.0)
	hero["pos_y"]=clamp(float(hero["pos_y"])+move.y*speed*delta,120.0,420.0)
	update_pet_visual()
	if pet_attack_timer>=1.5:
		pet_attack_timer=0.0
		pet_auto_attack()
	if spawn_timer>=4.0 and monsters.size()<8:
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
			LootSystem.set_enabled(hero,true)
			log_message("AUTOLOOT ENABLED. Items, equipment, materials and cards are picked automatically.")
		elif argument=="off":
			LootSystem.set_enabled(hero,false)
			log_message("AUTOLOOT DISABLED. New drops stay on the ground.")
		elif argument=="status" or argument=="":
			log_message("AUTOLOOT: %s | Ground drops: %d" % ["ON" if LootSystem.is_enabled(hero) else "OFF",hero["ground_loot"].size()])
		else:
			log_message("Usage: @autoloot, @autoloot on, @autoloot off, @autoloot status")
		if LootSystem.is_enabled(hero):
			var collected:=LootSystem.collect_ground(hero)
			if collected.size()>0:
				log_message("Auto-loot collected: %s" % ", ".join(collected))
		save_game()
		update_ui()
		command_edit.clear()
		return
	if lower=="@loot":
		var gained:=LootSystem.collect_ground(hero)
		if gained.size()>0:
			log_message("Manual loot pickup: %s" % ", ".join(gained))
		else:
			log_message("Nothing collectible. Enable @autoloot to collect future drops automatically.")
		save_game()
		update_ui()
		command_edit.clear()
		return
	var result:=TeleportSystem.parse_go(cmd)
	if not result["ok"]:
		log_message(str(result["error"]))
		update_ui()
		return
	fast_travel(int(result["map_id"]),int(result["x"]),int(result["y"]))
	command_edit.clear()

func execute_command_from_button()->void:
	execute_command(command_edit.text)

func fast_travel(map_id:int,x:int,y:int)->void:
	if not TeleportSystem.MAPS.has(map_id):
		log_message("Unknown destination.")
		return
	hero["map_id"]=map_id
	hero["pos_x"]=365.0+float(x)
	hero["pos_y"]=120.0+float(y)
	monsters.clear()
	for i in 4:
		spawn_monster()
	log_message("Fast transmission to %s at X:%d Y:%d. Pet follows automatically." % [TeleportSystem.map_name(map_id),x,y])
	save_game()
	update_ui()

func spawn_monster()->void:
	var families:=GameData.monster_families()
	var family:String=families[rng.randi_range(0,families.size()-1)]
	var zone:=max(1,int(hero["level"])/10+1)
	var level:=WorldSystem.monster_level_for_zone(zone,rng.randi_range(0,families.size()-1))
	var stats:Dictionary=WorldSystem.monster_stats(level)
	monsters.append({"name":family,"level":level,"pos":Vector2(rng.randf_range(410.0,1080.0),rng.randf_range(175.0,405.0)),"hp":stats["max_hp"],"max":stats["max_hp"],"attack":stats["attack"],"defense":stats["defense"],"exp":stats["exp"],"zmin":stats["zeny_min"],"zmax":stats["zeny_max"]})

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
	var damage:=PetSystem.power(pet)+rng.randi_range(0,7)
	pet["skill_uses"]=int(pet.get("skill_uses",0))+1
	var used_skill:=int(pet["skill_uses"])%5==0
	if used_skill:
		damage+=PetSystem.skill_power(pet)
		if str(pet["role"])=="Healer":
			hero["hp"]=min(int(hero["max_hp"]),int(hero["hp"])+PetSystem.heal_power(pet))
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
	var pet_leveled:=PetSystem.add_exp(hero["pet"],pet_exp)
	if pet_leveled:
		log_message("%s reached Pet Lv.%d and gained a skill point." % [hero["pet"]["name"],hero["pet"]["level"]])
	var gained:=LootSystem.on_monster_defeated(hero,monster,rng)
	if LootSystem.is_enabled(hero):
		if gained.size()>0:
			log_message("AUTOLOOT: %s" % ", ".join(gained))
	else:
		log_message("Drops are on the ground. Use @loot or @autoloot on to collect them.")
	log_message("Defeated Lv.%d %s! Hero +%d EXP, Pet +%d EXP, +%d Zeny." % [monster["level"],monster["name"],exp_gain,pet_exp,zeny])
	monsters.erase(monster)
	save_game()

func add_exp(amount:int)->void:
	if int(hero["level"])>=GameData.MAX_HERO_LEVEL:
		hero["exp"]=0
		return
	hero["exp"]+=amount
	while int(hero["level"])<GameData.MAX_HERO_LEVEL and int(hero["exp"])>=GameData.exp_to_next(int(hero["level"])):
		hero["exp"]-=GameData.exp_to_next(int(hero["level"]))
		hero["level"]+=1
		hero["max_hp"]+=8
		hero["hp"]=hero["max_hp"]
	hero["class_tier"]=max(int(hero.get("class_tier",0)),GameData.class_tier_for_level(int(hero["level"])))

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
	var material:=PetSystem.refine_material(level)
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
	PetSystem.add_exp(hero["pet"],25)
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
	EquipmentSystem.ensure_state(hero)
	LootSystem.ensure_state(hero)
	var materials:Dictionary=hero["materials"]
	var pet:Dictionary=hero["pet"]
	var city:Dictionary=hero["city_building"].get("Prontera",CitySystem.new_city())
	var map_name:=TeleportSystem.map_name(int(hero["map_id"]))
	var map_x:=int(hero["pos_x"]-365.0)
	var map_y:=int(hero["pos_y"]-120.0)
	var equipment:=combat_equipment()
	profile.text="Name: %s\nClass: %s\nLevel: %d/%d EXP:%d/%d\nAge:%d HP:%d/%d Zeny:%d Refine:+%d\n\nPET: %s (%s)\nPet Level:%d/%d HP:%d/%d Skill:%d Refine:+%d\n\nEquipment:\n%s\n\nCards:%d Inventory:%d\nAutoLoot:%s Ground Drops:%d\nPhracon:%d Emveretarcon:%d Oridecon:%d\nProntera Lv.%d" % [hero["name"],GameData.class_title(hero),hero["level"],GameData.MAX_HERO_LEVEL,hero["exp"],GameData.exp_to_next(int(hero["level"])),hero["age"],hero["hp"],hero["max_hp"],hero["zeny"],hero.get("refine",0),pet["name"],pet["role"],pet["level"],PetSystem.MAX_PET_LEVEL,pet["hp"],pet["max_hp"],pet["skill_level"],pet["refine"],EquipmentSystem.summary(hero),hero["cards"].size(),hero["inventory"].size(),"ON" if LootSystem.is_enabled(hero) else "OFF",hero["ground_loot"].size(),materials["Phracon"],materials["Emveretarcon"],materials["Oridecon"],city.get("level",1)]
	status.text="%s | MAP %d: %s | X:%d Y:%d | Power:%d | ATK:%d DEF:%d HP+%d | Cards:%d | AutoLoot:%s | Monsters:%d" % ["Dungeon" if TeleportSystem.is_dungeon(int(hero["map_id"])) else "Town",int(hero["map_id"]),map_name,map_x,map_y,skill_power(),equipment.get("attack",0),equipment.get("defense",0),equipment.get("hp",0),hero["cards"].size(),"ON" if LootSystem.is_enabled(hero) else "OFF",monsters.size()]
	log_label.text="\n".join(logs)

func log_message(message:String)->void:
	logs.push_front(message)
	if logs.size()>6:
		logs.pop_back()
	if log_label:
		log_label.text="\n".join(logs)

func save_game()->void:
	SaveSystem.save_game(hero)

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
