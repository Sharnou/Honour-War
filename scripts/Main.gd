extends Node2D

const CLASSES := {"Warrior":{"weapon":"Sword","base":18,"color":Color("#e8a34b"),"skill":"Power Slash"},"Mage":{"weapon":"Staff","base":23,"color":Color("#b88cff"),"skill":"Arcane Spark"},"Archer":{"weapon":"Bow","base":20,"color":Color("#8fe08f"),"skill":"Celestial Arrow"},"Thief":{"weapon":"Dagger","base":19,"color":Color("#ff7eb6"),"skill":"Shadow Strike"},"Acolyte":{"weapon":"Mace","base":15,"color":Color("#fff0a3"),"skill":"Holy Pulse"},"Merchant":{"weapon":"Hammer","base":17,"color":Color("#7ed7ff"),"skill":"Forge Smash"}}
var hero:Dictionary=GameData.new_hero()
var monsters:Array=[]
var logs:Array[String]=[]
var rng:=RandomNumberGenerator.new()
var spawn_timer:=0.0
var save_timer:=0.0
var age_timer:=0.0
var pet_attack_timer:=0.0
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
	for i in 5: spawn_monster()
	log_message("Welcome to Honour War. Your class pet is bonded automatically and never needs feeding.")
	queue_redraw()

func ensure_state()->void:
	if not hero.has("pos_x"): hero["pos_x"]=595.0
	if not hero.has("pos_y"): hero["pos_y"]=340.0
	if not hero.has("map_id"): hero["map_id"]=0
	if not hero.has("materials"): hero["materials"]={"Phracon":5,"Emveretarcon":2,"Oridecon":0}
	if not hero.has("inventory"): hero["inventory"]={}
	if not hero.has("equipment"): hero["equipment"]={"weapon":"Novice Weapon","armor":"Novice Armor"}
	if not hero.has("cards"): hero["cards"]=[]
	if not hero.has("quests_completed"): hero["quests_completed"]=[]
	if not hero.has("city_building"): hero["city_building"]={"Prontera":CitySystem.new_city()}
	if not hero.has("pet") or not hero["pet"] is Dictionary:
		hero["pet"]=PetSystem.new_pet(str(hero.get("class","Warrior")))
	ensure_pet_state()
	hero["age"]=GameData.STARTING_AGE+int(float(hero.get("online_days",0.0))/GameData.AGE_DAYS_PER_YEAR)
	hero["class_tier"]=max(int(hero.get("class_tier",0)),GameData.class_tier_for_level(int(hero.get("level",1))))
	var parsed:=TeleportSystem.parse_go("@go %d %d:%d" % [int(hero["map_id"]),int(hero["pos_x"])-365,int(hero["pos_y"])-120])
	if not parsed["ok"]: hero["map_id"]=0; hero["pos_x"]=595.0; hero["pos_y"]=340.0

func ensure_pet_state()->void:
	var p:Dictionary=hero["pet"]
	var class_name:=str(hero.get("class","Warrior"))
	var d:Dictionary=PetSystem.definition(class_name)
	p["owner_class"]=class_name
	p["name"]=str(p.get("name",d["name"]))
	p["role"]=str(p.get("role",d["role"]))
	p["species"]=str(p.get("species",d["species"]))
	p["level"]=clamp(int(p.get("level",1)),1,PetSystem.MAX_PET_LEVEL)
	p["exp"]=int(p.get("exp",0))
	p["max_hp"]=int(p.get("max_hp",60)); p["hp"]=clamp(int(p.get("hp",p["max_hp"])),0,int(p["max_hp"]))
	p["max_sp"]=int(p.get("max_sp",30)); p["sp"]=clamp(int(p.get("sp",p["max_sp"])),0,int(p["max_sp"]))
	p["skills"]=p.get("skills",[d["skill"]]); p["skill_level"]=max(1,int(p.get("skill_level",1)))
	p["skill_points"]=int(p.get("skill_points",0)); p["skill_uses"]=int(p.get("skill_uses",0)); p["refine"]=clamp(int(p.get("refine",0)),0,15)
	p["inventory"]=p.get("inventory",{}); p["materials"]=p.get("materials",{"Phracon":3,"Emveretarcon":1,"Oridecon":0})
	p["equipment"]=p.get("equipment",{"weapon":d["species"]+" Claw","armor":"Pet Guard Harness"}); p["kills"]=int(p.get("kills",0))
	hero["pet"]=p

func build_ui()->void:
	var bg:=ColorRect.new(); bg.color=Color("#071426"); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(bg)
	var title:=Label.new(); title.text="HONOUR WAR"; title.position=Vector2(24,16); title.add_theme_font_size_override("font_size",32); title.add_theme_color_override("font_color",Color("#f4c95d")); add_child(title)
	var sub:=Label.new(); sub.text="Adventure • Class Evolution • Automatic Battle Pets • Refinement • Crafting • Cities • Fast Travel"; sub.position=Vector2(28,55); sub.add_theme_color_override("font_color",Color("#9eb8d2")); add_child(sub)
	var side:=Panel.new(); side.position=Vector2(20,95); side.size=Vector2(300,525); add_child(side)
	var box:=VBoxContainer.new(); box.position=Vector2(14,14); box.size=Vector2(272,495); side.add_child(box)
	var h:=Label.new(); h.text="HERO + PET PROFILE"; h.add_theme_font_size_override("font_size",20); h.add_theme_color_override("font_color",Color("#f4c95d")); box.add_child(h)
	profile=Label.new(); profile.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; profile.custom_minimum_size=Vector2(270,300); box.add_child(profile)
	name_edit=LineEdit.new(); name_edit.placeholder_text="Hero name"; box.add_child(name_edit)
	class_box=OptionButton.new(); for c in CLASSES.keys(): class_box.add_item(c); box.add_child(class_box)
	var apply:=Button.new(); apply.text="Apply Hero / Rebond Pet"; apply.pressed.connect(apply_hero); box.add_child(apply)
	var rest:=Button.new(); rest.text="Rest (+1 simulated day)"; rest.pressed.connect(rest_hero); box.add_child(rest)
	var city:=Button.new(); city.text="Build Prontera"; city.pressed.connect(build_city); box.add_child(city)
	var save:=Button.new(); save.text="Save Now"; save.pressed.connect(save_game); box.add_child(save)
	var right:=Panel.new(); right.position=Vector2(340,95); right.size=Vector2(792,525); add_child(right)
	status=Label.new(); status.position=Vector2(18,15); right.add_child(status)
	var help:=Label.new(); help.text="WASD / Arrows: move   SPACE: hero + pet attack   R: hero refine   T: pet refine   Q: quest   C: craft   B: buy"; help.position=Vector2(18,42); help.add_theme_color_override("font_color",Color("#9eb8d2")); right.add_child(help)
	command_edit=LineEdit.new(); command_edit.position=Vector2(18,395); command_edit.size=Vector2(650,36); command_edit.placeholder_text="Fast travel: @go 0 230:220   |   @go 10 300:180"; command_edit.text_submitted.connect(execute_command); right.add_child(command_edit)
	var go_button:=Button.new(); go_button.text="GO"; go_button.position=Vector2(678,395); go_button.size=Vector2(96,36); go_button.pressed.connect(execute_command_from_button); right.add_child(go_button)
	log_label=RichTextLabel.new(); log_label.position=Vector2(18,450); log_label.size=Vector2(756,58); right.add_child(log_label)
	name_edit.text=str(hero["name"]); class_box.select(max(0,CLASS_NAMES().find(str(hero["class"]))))
	update_ui()

func CLASS_NAMES()->Array: return CLASSES.keys()

func apply_hero()->void:
	if name_edit.text.strip_edges()!="": hero["name"]=name_edit.text.strip_edges()
	var old_class:=str(hero.get("class","Warrior"))
	hero["class"]=class_box.get_item_text(class_box.selected)
	hero["class_tier"]=GameData.class_tier_for_level(int(hero["level"]))
	hero["max_hp"]=100+int(hero["level"])*8; hero["hp"]=hero["max_hp"]
	if old_class!=str(hero["class"]):
		hero["pet"]=PetSystem.new_pet(str(hero["class"]))
		log_message("Class changed to %s. A new bonded %s pet joined automatically." % [hero["class"],hero["pet"]["name"]])
	ensure_pet_state()
	log_message("Hero updated: %s — %s. Pet: %s (%s)." % [hero["name"],GameData.class_title(hero),hero["pet"]["name"],hero["pet"]["role"]]); save_game(); update_ui()

func rest_hero()->void:
	hero["online_days"]=float(hero["online_days"])+1.0; update_age(); hero["hp"]=hero["max_hp"]; hero["pet"]["hp"]=hero["pet"]["max_hp"]
	log_message("One simulated online day passed. Age: %d. Pet restored automatically." % hero["age"]); save_game(); update_ui()

func update_age()->void: hero["age"]=GameData.STARTING_AGE+int(float(hero["online_days"])/GameData.AGE_DAYS_PER_YEAR)

func build_city()->void:
	var city:Dictionary=hero["city_building"].get("Prontera",CitySystem.new_city())
	city["wood"]=int(city.get("wood",0))+60; city["stone"]=int(city.get("stone",0))+60; city["gold"]=int(city.get("gold",0))+650
	var built:=false
	for b in ["Blacksmith","Market","Barracks","Magic Tower"]:
		if CitySystem.can_build(city,b): city=CitySystem.build(city,b); log_message("Prontera expanded: %s built." % b); built=true; break
	if not built: city=CitySystem.upgrade_city(city); log_message("Prontera advanced to city level %d." % city["level"])
	hero["city_building"]["Prontera"]=city; save_game(); update_ui()

func age_bonus()->int: return GameData.age_bonus(int(hero["age"]))
func skill_power()->int:
	var d:Dictionary=CLASSES[str(hero["class"])]
	return int(d["base"])+int(hero["level"])*2+int(age_bonus()/3)+int(hero.get("refine",0))*2
func refine_chance()->int: return int(WorldSystem.refinement_chance(int(hero["age"]),int(hero["level"]),int(hero.get("refine",0)))*100.0)

func _process(delta:float)->void:
	spawn_timer+=delta; save_timer+=delta; age_timer+=delta; pet_attack_timer+=delta
	var move:=Vector2(Input.get_axis("move_left","move_right"),Input.get_axis("move_up","move_down")).normalized()
	hero["pos_x"]=clamp(float(hero["pos_x"])+move.x*180.0*delta,365.0,1107.0); hero["pos_y"]=clamp(float(hero["pos_y"])+move.y*180.0*delta,120.0,420.0)
	if pet_attack_timer>=1.5: pet_attack_timer=0.0; pet_auto_attack()
	if spawn_timer>=4.0 and monsters.size()<8: spawn_timer=0.0; spawn_monster()
	if age_timer>=8.0: age_timer=0.0; hero["online_days"]+=8.0/86400.0; update_age()
	if save_timer>=8.0: save_timer=0.0; save_game(); update_ui()
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
	var result:=TeleportSystem.parse_go(command)
	if not result["ok"]: log_message(str(result["error"])); update_ui(); return
	fast_travel(int(result["map_id"]),int(result["x"]),int(result["y"]))
	command_edit.clear()

func execute_command_from_button()->void: execute_command(command_edit.text)

func fast_travel(map_id:int,x:int,y:int)->void:
	if not TeleportSystem.MAPS.has(map_id): log_message("Unknown destination."); return
	var old_map:=int(hero["map_id"]); hero["map_id"]=map_id; hero["pos_x"]=365.0+float(x); hero["pos_y"]=120.0+float(y); monsters.clear()
	for i in 4: spawn_monster()
	var kind:="Dungeon" if TeleportSystem.is_dungeon(map_id) else "Town"
	log_message("Fast transmission: %s -> %s (%d:%d)." % ["same map" if old_map==map_id else TeleportSystem.map_name(old_map),TeleportSystem.map_name(map_id),x,y])
	log_message("Arrived in %s %s at X:%d Y:%d. Pet follows automatically." % [kind,TeleportSystem.map_name(map_id),x,y]); save_game(); update_ui()

func spawn_monster()->void:
	var families:=GameData.monster_families(); var family:String=families[rng.randi_range(0,families.size()-1)]; var zone:=max(1,int(hero["level"])/10+1); var level:=WorldSystem.monster_level_for_zone(zone,rng.randi_range(0,families.size()-1)); var s:Dictionary=WorldSystem.monster_stats(level)
	monsters.append({"name":family,"level":level,"pos":Vector2(rng.randf_range(410.0,1080.0),rng.randf_range(175.0,405.0)),"hp":s["max_hp"],"max":s["max_hp"],"exp":s["exp"],"zmin":s["zeny_min"],"zmax":s["zeny_max"]})

func nearest_monster():
	var best=null; var distance:=99999.0; var p:=Vector2(float(hero["pos_x"]),float(hero["pos_y"]))
	for m in monsters:
		var d:float=p.distance_to(m["pos"])
		if d<distance: distance=d; best=m
	return best if distance<90.0 else null

func attack()->void:
	var m=nearest_monster()
	if m==null: log_message("Move close to a monster, then press SPACE."); return
	var damage:=skill_power()+rng.randi_range(0,9); m["hp"]-=damage
	log_message("%s dealt %d damage to Lv.%d %s." % [CLASSES[hero["class"]]["skill"],damage,m["level"],m["name"]])
	pet_attack_target(m)
	if m["hp"]<=0: defeat_monster(m)
	save_game(); update_ui()

func pet_auto_attack()->void:
	if monsters.size()==0: return
	var m=nearest_monster()
	if m==null: return
	pet_attack_target(m)
	if m["hp"]<=0: defeat_monster(m)

func pet_attack_target(m:Dictionary)->void:
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
	m["hp"]-=damage
	if not used_skill: log_message("%s attacks for %d damage." % [pet["name"],damage])

func defeat_monster(m:Dictionary)->void:
	hero["kills"]=int(hero.get("kills",0))+1; hero["pet"]["kills"]=int(hero["pet"].get("kills",0))+1
	var z:=rng.randi_range(int(m["zmin"]),int(m["zmax"])); hero["zeny"]+=z; add_exp(int(m["exp"]))
	var pet_exp:=max(1,int(m["exp"])*2/3); var pet_leveled:=PetSystem.add_exp(hero["pet"],pet_exp)
	if pet_leveled: log_message("%s reached Pet Lv.%d and gained a skill point." % [hero["pet"]["name"],hero["pet"]["level"]])
	var drops:=WorldSystem.roll_drops(str(m["name"]),rng)
	for item in drops:
		if item.ends_with(" Card"):
			if item not in hero["cards"]: hero["cards"].append(item)
		else: hero["inventory"][item]=int(hero["inventory"].get(item,0))+1
	if rng.randf()<0.12: hero["pet"]["inventory"]["Pet Skill Item"]=int(hero["pet"]["inventory"].get("Pet Skill Item",0))+1
	if rng.randf()<0.10: hero["pet"]["inventory"]["Pet Refine Item"]=int(hero["pet"]["inventory"].get("Pet Refine Item",0))+1
	log_message("Defeated Lv.%d %s! +%d EXP +%d Pet EXP +%d Zeny. Drops: %s" % [m["level"],m["name"],m["exp"],pet_exp,z,", ".join(drops) if drops.size()>0 else "none"]); monsters.erase(m)

func add_exp(amount:int)->void:
	if int(hero["level"])>=GameData.MAX_HERO_LEVEL: hero["exp"]=0; return
	hero["exp"]+=amount
	while int(hero["level"])<GameData.MAX_HERO_LEVEL and int(hero["exp"])>=GameData.exp_to_next(int(hero["level"])):
		hero["exp"]-=GameData.exp_to_next(int(hero["level"])); hero["level"]+=1; hero["max_hp"]+=8; hero["hp"]=hero["max_hp"]
	hero["class_tier"]=max(int(hero.get("class_tier",0)),GameData.class_tier_for_level(int(hero["level"])))
	if int(hero["level"])%50==0: log_message("Major class tier reached: %s." % GameData.class_title(hero))

func refine()->void:
	var level:=int(hero.get("refine",0)); if level>=15: log_message("Prototype refinement cap reached: +15."); return
	var material:="Phracon" if level<4 else ("Emveretarcon" if level<8 else "Oridecon")
	if int(hero["materials"].get(material,0))<=0: log_message("You need %s to refine." % material); return
	hero["materials"][material]-=1
	if rng.randf()*100.0<refine_chance(): hero["refine"]=level+1; hero["equipment"]["weapon"]=CLASSES[hero["class"]]["weapon"]+" +"+str(hero["refine"]); log_message("Refinement succeeded! Weapon +%d." % hero["refine"])
	else: log_message("Refinement failed; equipment was protected.")
	save_game(); update_ui()

func refine_pet()->void:
	ensure_pet_state(); var pet:Dictionary=hero["pet"]; var level:=int(pet.get("refine",0))
	if level>=15: log_message("Pet refinement cap reached: +15."); return
	var material:=PetSystem.refine_material(level)
	if int(pet["materials"].get(material,0))<=0:
		if int(pet["inventory"].get("Pet Refine Item",0))>0:
			pet["inventory"]["Pet Refine Item"]-=1
		else: log_message("Pet needs %s or a Pet Refine Item." % material); return
	else: pet["materials"][material]-=1
	var chance:=max(35,refine_chance()-5-level*2)
	if rng.randf()*100.0<chance:
		pet["refine"]=level+1; pet["equipment"]["weapon"]=str(pet["species"])+" Claw +"+str(pet["refine"]); log_message("%s refinement succeeded! Pet weapon +%d." % [pet["name"],pet["refine"]])
	else: log_message("%s refinement failed; pet equipment was protected." % pet["name"])
	save_game(); update_ui()

func quest()->void:
	hero["quest"]=int(hero.get("quest",0))+1; hero["quests_completed"].append("hunt_%d" % hero["quest"]); hero["zeny"]+=100+int(hero["quest"])*25; hero["materials"]["Phracon"]+=1; hero["pet"]["materials"]["Phracon"]=int(hero["pet"]["materials"].get("Phracon",0))+1; add_exp(50); PetSystem.add_exp(hero["pet"],25); log_message("Quest %d completed. Hero + Pet rewards delivered." % hero["quest"]); save_game(); update_ui()

func craft()->void:
	if int(hero["materials"].get("Phracon",0))<2 or int(hero["zeny"])<80: log_message("Crafting requires 2 Phracon and 80 Zeny."); return
	hero["materials"]["Phracon"]-=2; hero["zeny"]-=80; var item:=CLASSES[hero["class"]]["weapon"]+" Core"; hero["inventory"][item]=int(hero["inventory"].get(item,0))+1; log_message("Crafted %s and added it to inventory." % item); save_game(); update_ui()

func buy_material()->void:
	var discount:=int(WorldSystem.age_discount(int(hero["age"]))*100.0); var price:=int(100.0*(100.0-discount)/100.0)
	if int(hero["zeny"])<price: log_message("Not enough Zeny."); return
	hero["zeny"]-=price; hero["materials"]["Phracon"]+=1; hero["pet"]["materials"]["Phracon"]=int(hero["pet"]["materials"].get("Phracon",0))+1; log_message("Bought Phracon for %d Zeny (%d%% age discount). Hero and pet crafting stores supplied." % [price,discount]); save_game(); update_ui()

func update_ui()->void:
	if not profile: return
	ensure_pet_state()
	var m:Dictionary=hero["materials"]; var p:Dictionary=hero["pet"]; var city:Dictionary=hero["city_building"].get("Prontera",CitySystem.new_city())
	var map_name:=TeleportSystem.map_name(int(hero["map_id"])); var map_kind:="Dungeon" if TeleportSystem.is_dungeon(int(hero["map_id"])) else "Town"; var map_x:=int(hero["pos_x"]-365.0); var map_y:=int(hero["pos_y"]-120.0)
	profile.text="Name: %s\nClass: %s\nLevel: %d/%d  EXP: %d/%d\nAge: %d  HP: %d/%d\nZeny: %d  Refine: +%d\n\nPET: %s\nRole: %s\nPet Level: %d/%d  EXP: %d/%d\nPet HP: %d/%d  Skill Lv.%d\nPet Refine: +%d  Pet Kills: %d\n\nPhracon: %d  Emveretarcon: %d  Oridecon: %d\nAge bonus: +%d%%  Hero refine: %d%%\nWeapon: %s\nCards: %d  Inventory: %d\nProntera Lv.%d" % [hero["name"],GameData.class_title(hero),hero["level"],GameData.MAX_HERO_LEVEL,hero["exp"],GameData.exp_to_next(int(hero["level"])),hero["age"],hero["hp"],hero["max_hp"],hero["zeny"],hero.get("refine",0),p["name"],p["role"],p["level"],PetSystem.MAX_PET_LEVEL,p["exp"],PetSystem.exp_to_next(int(p["level"])),p["hp"],p["max_hp"],p["skill_level"],p["refine"],p["kills"],m["Phracon"],m["Emveretarcon"],m["Oridecon"],age_bonus(),refine_chance(),hero["equipment"]["weapon"],hero["cards"].size(),hero["inventory"].size(),city.get("level",1)]
	status.text="%s | %s | MAP %d: %s | X:%d Y:%d | Hero Power: %d | Pet: %s [%s] Power:%d | Monsters:%d | Kills:%d" % [map_kind,map_name,int(hero["map_id"]),GameData.class_title(hero),map_x,map_y,skill_power(),p["name"],p["role"],PetSystem.power(p),monsters.size(),hero.get("kills",0)]
	log_label.text="\n".join(logs)

func log_message(message:String)->void:
	logs.push_front(message); if logs.size()>6: logs.pop_back(); if log_label: log_label.text="\n".join(logs)
func save_game()->void: SaveSystem.save_game(hero)

func _draw()->void:
	draw_rect(Rect2(340,95,792,525),Color("#0d233c")); draw_rect(Rect2(365,120,742,300),Color("#163d3b"))
	for x in range(365,1110,45): draw_line(Vector2(x,120),Vector2(x,420),Color("#2d6c60"))
	for y in range(120,421,45): draw_line(Vector2(365,y),Vector2(1110,y),Color("#2d6c60"))
	var p:=Vector2(float(hero["pos_x"]),float(hero["pos_y"])); var data:Dictionary=CLASSES[hero["class"]]; draw_circle(p,18,data["color"]); draw_string(ThemeDB.fallback_font,Vector2(p.x-28,p.y-28),str(hero["name"]),HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color.WHITE)
	var pet:Dictionary=hero["pet"]; var pet_pos:=p+Vector2(-34,34); var pet_def:Dictionary=PetSystem.definition(str(hero["class"])); draw_circle(pet_pos,12,Color(str(pet_def["color"]))); draw_string(ThemeDB.fallback_font,Vector2(pet_pos.x-30,pet_pos.y+27),str(pet["name"]),HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color.WHITE)
	for m in monsters:
		draw_circle(m["pos"],16,Color("#d96b76")); draw_string(ThemeDB.fallback_font,Vector2(m["pos"].x-28,m["pos"].y-24),"Lv.%d %s" % [m["level"],m["name"]],HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color.WHITE); draw_rect(Rect2(m["pos"].x-22,m["pos"].y+20,44,4),Color("#222222")); draw_rect(Rect2(m["pos"].x-22,m["pos"].y+20,44*max(0.0,float(m["hp"])/float(m["max"])),4),Color("#ff7373"))
