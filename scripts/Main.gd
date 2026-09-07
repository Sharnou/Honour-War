extends Node2D

const CLASSES := {"Warrior":{"weapon":"Sword","base":18,"color":Color("#e8a34b"),"skill":"Power Slash"},"Mage":{"weapon":"Staff","base":23,"color":Color("#b88cff"),"skill":"Arcane Spark"},"Archer":{"weapon":"Bow","base":20,"color":Color("#8fe08f"),"skill":"Celestial Arrow"},"Thief":{"weapon":"Dagger","base":19,"color":Color("#ff7eb6"),"skill":"Shadow Strike"},"Acolyte":{"weapon":"Mace","base":15,"color":Color("#fff0a3"),"skill":"Holy Pulse"},"Merchant":{"weapon":"Hammer","base":17,"color":Color("#7ed7ff"),"skill":"Forge Smash"}}
var hero:Dictionary=GameData.new_hero()
var monsters:Array=[]
var logs:Array[String]=[]
var rng:=RandomNumberGenerator.new()
var spawn_timer:=0.0
var save_timer:=0.0
var age_timer:=0.0
var profile:Label
var status:Label
var log_label:RichTextLabel
var name_edit:LineEdit
var class_box:OptionButton

func _ready()->void:
	rng.randomize()
	hero=SaveSystem.load_game(GameData.new_hero())
	ensure_state()
	build_ui()
	for i in 5: spawn_monster()
	log_message("Welcome to Honour War. Progress saves automatically.")
	queue_redraw()

func ensure_state()->void:
	if not hero.has("pos_x"): hero["pos_x"]=500.0
	if not hero.has("pos_y"): hero["pos_y"]=280.0
	if not hero.has("materials"): hero["materials"]={"Phracon":5,"Emveretarcon":2,"Oridecon":0}
	if not hero.has("inventory"): hero["inventory"]={}
	if not hero.has("equipment"): hero["equipment"]={"weapon":"Novice Weapon","armor":"Novice Armor"}
	if not hero.has("cards"): hero["cards"]=[]
	if not hero.has("quests_completed"): hero["quests_completed"]=[]
	if not hero.has("city_building"): hero["city_building"]={"Prontera":CitySystem.new_city()}
	hero["age"]=GameData.STARTING_AGE+int(float(hero.get("online_days",0.0))/GameData.AGE_DAYS_PER_YEAR)
	hero["class_tier"]=max(int(hero.get("class_tier",0)),GameData.class_tier_for_level(int(hero.get("level",1))))

func build_ui()->void:
	var bg:=ColorRect.new(); bg.color=Color("#071426"); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(bg)
	var title:=Label.new(); title.text="HONOUR WAR"; title.position=Vector2(24,16); title.add_theme_font_size_override("font_size",32); title.add_theme_color_override("font_color",Color("#f4c95d")); add_child(title)
	var sub:=Label.new(); sub.text="Adventure • Class Evolution • Refinement • Crafting • Cities"; sub.position=Vector2(28,55); sub.add_theme_color_override("font_color",Color("#9eb8d2")); add_child(sub)
	var side:=Panel.new(); side.position=Vector2(20,95); side.size=Vector2(300,525); add_child(side)
	var box:=VBoxContainer.new(); box.position=Vector2(14,14); box.size=Vector2(272,495); side.add_child(box)
	var h:=Label.new(); h.text="HERO PROFILE"; h.add_theme_font_size_override("font_size",20); h.add_theme_color_override("font_color",Color("#f4c95d")); box.add_child(h)
	profile=Label.new(); profile.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; profile.custom_minimum_size=Vector2(270,280); box.add_child(profile)
	name_edit=LineEdit.new(); name_edit.placeholder_text="Hero name"; box.add_child(name_edit)
	class_box=OptionButton.new(); for c in CLASSES.keys(): class_box.add_item(c); box.add_child(class_box)
	var apply:=Button.new(); apply.text="Apply Hero"; apply.pressed.connect(apply_hero); box.add_child(apply)
	var rest:=Button.new(); rest.text="Rest (+1 simulated day)"; rest.pressed.connect(rest_hero); box.add_child(rest)
	var city:=Button.new(); city.text="Build Prontera"; city.pressed.connect(build_city); box.add_child(city)
	var save:=Button.new(); save.text="Save Now"; save.pressed.connect(save_game); box.add_child(save)
	var right:=Panel.new(); right.position=Vector2(340,95); right.size=Vector2(792,525); add_child(right)
	status=Label.new(); status.position=Vector2(18,15); right.add_child(status)
	var help:=Label.new(); help.text="WASD / Arrows: move   SPACE: attack   R: refine   Q: quest   C: craft   B: buy"; help.position=Vector2(18,42); help.add_theme_color_override("font_color",Color("#9eb8d2")); right.add_child(help)
	log_label=RichTextLabel.new(); log_label.position=Vector2(18,450); log_label.size=Vector2(756,58); right.add_child(log_label)
	name_edit.text=str(hero["name"]); class_box.select(max(0,CLASS_NAMES().find(str(hero["class"]))))
	update_ui()

func CLASS_NAMES()->Array: return CLASSES.keys()

func apply_hero()->void:
	if name_edit.text.strip_edges()!="": hero["name"]=name_edit.text.strip_edges()
	hero["class"]=class_box.get_item_text(class_box.selected)
	hero["class_tier"]=GameData.class_tier_for_level(int(hero["level"]))
	hero["max_hp"]=100+int(hero["level"])*8; hero["hp"]=hero["max_hp"]
	log_message("Hero updated: %s — %s." % [hero["name"],GameData.class_title(hero)]); save_game(); update_ui()

func rest_hero()->void:
	hero["online_days"]=float(hero["online_days"])+1.0; update_age(); hero["hp"]=hero["max_hp"]
	log_message("One simulated online day passed. Age: %d." % hero["age"]); save_game(); update_ui()

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
	spawn_timer+=delta; save_timer+=delta; age_timer+=delta
	var move:=Vector2(Input.get_axis("move_left","move_right"),Input.get_axis("move_up","move_down")).normalized()
	hero["pos_x"]=clamp(float(hero["pos_x"])+move.x*180.0*delta,365.0,1110.0); hero["pos_y"]=clamp(float(hero["pos_y"])+move.y*180.0*delta,150.0,420.0)
	if spawn_timer>=4.0 and monsters.size()<8: spawn_timer=0.0; spawn_monster()
	if age_timer>=8.0: age_timer=0.0; hero["online_days"]+=8.0/86400.0; update_age()
	if save_timer>=8.0: save_timer=0.0; save_game(); update_ui()
	queue_redraw()

func _input(event:InputEvent)->void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE: attack()
			KEY_R: refine()
			KEY_Q: quest()
			KEY_C: craft()
			KEY_B: buy_material()

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
	var damage:=skill_power()+rng.randi_range(0,9); m["hp"]-=damage; log_message("%s dealt %d damage to Lv.%d %s." % [CLASSES[hero["class"]]["skill"],damage,m["level"],m["name"]])
	if m["hp"]<=0: defeat_monster(m)
	save_game(); update_ui()

func defeat_monster(m:Dictionary)->void:
	hero["kills"]=int(hero.get("kills",0))+1; var z:=rng.randi_range(int(m["zmin"]),int(m["zmax"])); hero["zeny"]+=z; add_exp(int(m["exp"]))
	var drops:=WorldSystem.roll_drops(str(m["name"]),rng)
	for item in drops:
		if item.ends_with(" Card"):
			if item not in hero["cards"]: hero["cards"].append(item)
		else: hero["inventory"][item]=int(hero["inventory"].get(item,0))+1
	log_message("Defeated Lv.%d %s! +%d EXP +%d Zeny. Drops: %s" % [m["level"],m["name"],m["exp"],z,", ".join(drops) if drops.size()>0 else "none"]); monsters.erase(m)

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

func quest()->void:
	hero["quest"]=int(hero.get("quest",0))+1; hero["quests_completed"].append("hunt_%d" % hero["quest"]); hero["zeny"]+=100+int(hero["quest"])*25; hero["materials"]["Phracon"]+=1; add_exp(50); log_message("Quest %d completed. Rewards delivered." % hero["quest"]); save_game(); update_ui()

func craft()->void:
	if int(hero["materials"].get("Phracon",0))<2 or int(hero["zeny"])<80: log_message("Crafting requires 2 Phracon and 80 Zeny."); return
	hero["materials"]["Phracon"]-=2; hero["zeny"]-=80; var item:=CLASSES[hero["class"]]["weapon"]+" Core"; hero["inventory"][item]=int(hero["inventory"].get(item,0))+1; log_message("Crafted %s and added it to inventory." % item); save_game(); update_ui()

func buy_material()->void:
	var discount:=int(WorldSystem.age_discount(int(hero["age"]))*100.0); var price:=int(100.0*(100.0-discount)/100.0)
	if int(hero["zeny"])<price: log_message("Not enough Zeny."); return
	hero["zeny"]-=price; hero["materials"]["Phracon"]+=1; log_message("Bought Phracon for %d Zeny (%d%% age discount)." % [price,discount]); save_game(); update_ui()

func update_ui()->void:
	if not profile: return
	var m:Dictionary=hero["materials"]; var city:Dictionary=hero["city_building"].get("Prontera",CitySystem.new_city())
	profile.text="Name: %s\nClass: %s\nLevel: %d/%d\nEXP: %d/%d\nAge: %d\nOnline: %.4f days\nHP: %d/%d\nZeny: %d\n\nPhracon: %d  Emveretarcon: %d  Oridecon: %d\nAge skill bonus: +%d%%\nRefine chance: %d%%\nPrice discount: -%d%%\nWeapon: %s\nCards: %d  Inventory: %d\nProntera Lv.%d" % [hero["name"],GameData.class_title(hero),hero["level"],GameData.MAX_HERO_LEVEL,hero["exp"],GameData.exp_to_next(int(hero["level"])),hero["age"],hero["online_days"],hero["hp"],hero["max_hp"],hero["zeny"],m["Phracon"],m["Emveretarcon"],m["Oridecon"],age_bonus(),refine_chance(),int(WorldSystem.age_discount(int(hero["age"]))*100.0),hero["equipment"]["weapon"],hero["cards"].size(),hero["inventory"].size(),city.get("level",1)]
	status.text="FIELD | %s | %s | Basic Power: %d | Monsters: %d | Kills: %d" % [hero["last_safe_city"],GameData.class_title(hero),skill_power(),monsters.size(),hero.get("kills",0)]
	log_label.text="\n".join(logs)

func log_message(message:String)->void:
	logs.push_front(message); if logs.size()>6: logs.pop_back(); if log_label: log_label.text="\n".join(logs)

func save_game()->void: SaveSystem.save_game(hero)

func _draw()->void:
	draw_rect(Rect2(340,95,792,525),Color("#0d233c")); draw_rect(Rect2(365,120,742,300),Color("#163d3b"))
	for x in range(365,1110,45): draw_line(Vector2(x,120),Vector2(x,420),Color("#2d6c60"))
	for y in range(120,421,45): draw_line(Vector2(365,y),Vector2(1110,y),Color("#2d6c60"))
	var p:=Vector2(float(hero["pos_x"]),float(hero["pos_y"])); var data:Dictionary=CLASSES[hero["class"]]; draw_circle(p,18,data["color"]); draw_string(ThemeDB.fallback_font,Vector2(p.x-28,p.y-28),str(hero["name"]),HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color.WHITE)
	for m in monsters:
		draw_circle(m["pos"],16,Color("#d96b76")); draw_string(ThemeDB.fallback_font,Vector2(m["pos"].x-28,m["pos"].y-24),"Lv.%d %s" % [m["level"],m["name"]],HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color.WHITE); draw_rect(Rect2(m["pos"].x-22,m["pos"].y+20,44,4),Color("#222222")); draw_rect(Rect2(m["pos"].x-22,m["pos"].y+20,44*max(0.0,float(m["hp"])/float(m["max"])),4),Color("#ff7373"))
