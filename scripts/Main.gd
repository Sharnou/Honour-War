extends Node2D

const SAVE_PATH := "user://honour_war_save.json"
const CLASSES := {
	"Warrior": {"weapon":"Sword", "base":18, "color":Color("#e8a34b"), "skill":"Power Slash"},
	"Mage": {"weapon":"Staff", "base":23, "color":Color("#b88cff"), "skill":"Arcane Spark"},
	"Archer": {"weapon":"Bow", "base":20, "color":Color("#8fe08f"), "skill":"Celestial Arrow"},
	"Thief": {"weapon":"Dagger", "base":19, "color":Color("#ff7eb6"), "skill":"Shadow Strike"},
	"Acolyte": {"weapon":"Mace", "base":15, "color":Color("#fff0a3"), "skill":"Holy Pulse"},
	"Merchant": {"weapon":"Hammer", "base":17, "color":Color("#7ed7ff"), "skill":"Forge Smash"}
}
var hero := {
	"name":"Aldric", "class":"Warrior", "level":1, "exp":0, "age":18,
	"online_days":0.0, "hp":100, "max_hp":100, "zeny":500,
	"materials":{"Phracon":5, "Emveretarcon":2, "Oridecon":0},
	"refine":0, "quest":0, "kills":0, "pos":Vector2(270,330)
}
var monsters:Array = []
var log_lines:Array[String] = []
var elapsed := 0.0
var spawn_timer := 0.0
var autosave_timer := 0.0
var name_edit:LineEdit
var class_box:OptionButton
var profile:Label
var log_label:RichTextLabel
var status_label:Label

func _ready() -> void:
	load_game()
	build_ui()
	for i in 4: spawn_monster()
	log_message("Welcome to Honour War. Progress saves automatically.")
	queue_redraw()

func build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#071426")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var title := Label.new()
	title.text = "HONOUR WAR"
	title.position = Vector2(24,16)
	title.add_theme_font_size_override("font_size",32)
	title.add_theme_color_override("font_color",Color("#f4c95d"))
	add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Age • Class Evolution • Refinement • Adventure"
	subtitle.position = Vector2(28,55)
	subtitle.add_theme_color_override("font_color",Color("#9eb8d2"))
	add_child(subtitle)

	var side := Panel.new()
	side.position=Vector2(20,95); side.size=Vector2(300,525)
	add_child(side)
	var side_box:=VBoxContainer.new()
	side_box.position=Vector2(14,14); side_box.size=Vector2(272,495)
	side.add_child(side_box)
	var h:=Label.new(); h.text="HERO PROFILE"; h.add_theme_color_override("font_color",Color("#f4c95d")); h.add_theme_font_size_override("font_size",20); side_box.add_child(h)
	profile=Label.new(); profile.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; profile.custom_minimum_size=Vector2(270,250); side_box.add_child(profile)
	name_edit=LineEdit.new(); name_edit.placeholder_text="Hero name"; side_box.add_child(name_edit)
	class_box=OptionButton.new()
	for c in CLASSES.keys(): class_box.add_item(c)
	side_box.add_child(class_box)
	var apply:=Button.new(); apply.text="Create / Apply Hero"; apply.pressed.connect(apply_hero); side_box.add_child(apply)
	var rest:=Button.new(); rest.text="Rest (+1 simulated online day)"; rest.pressed.connect(rest_hero); side_box.add_child(rest)
	var save:=Button.new(); save.text="Save Now"; save.pressed.connect(save_game); side_box.add_child(save)

	var right:=Panel.new(); right.position=Vector2(340,95); right.size=Vector2(792,525); add_child(right)
	status_label=Label.new(); status_label.position=Vector2(18,15); right.add_child(status_label)
	var help:=Label.new(); help.text="WASD / Arrow Keys: move    SPACE: basic attack    R: refine    Q: quest    C: craft    B: buy material"; help.position=Vector2(18,42); help.add_theme_color_override("font_color",Color("#9eb8d2")); right.add_child(help)
	log_label=RichTextLabel.new(); log_label.position=Vector2(18,450); log_label.size=Vector2(756,58); log_label.bbcode_enabled=true; right.add_child(log_label)
	name_edit.text=str(hero["name"]); class_box.select(CLASS_NAMES().find(str(hero["class"])))
	update_ui()

func CLASS_NAMES() -> Array:
	return CLASSES.keys()

func apply_hero() -> void:
	hero["name"]=name_edit.text if name_edit.text.strip_edges()!="" else hero["name"]
	hero["class"]=class_box.get_item_text(class_box.selected)
	hero["max_hp"]=100+int(hero["level"])*8
	hero["hp"]=min(int(hero["hp"]),int(hero["max_hp"]))
	log_message("Hero profile updated: %s, %s." % [hero["name"],hero["class"]])
	save_game(); update_ui()

func rest_hero() -> void:
	hero["online_days"]=float(hero["online_days"])+1.0
	hero["age"]=18+int(float(hero["online_days"])/3.0)
	hero["hp"]=hero["max_hp"]
	log_message("One simulated online day passed. Age is now %d." % hero["age"])
	save_game(); update_ui()

func age_bonus() -> int:
	return min(35,int((int(hero["age"])-18)/4))

func skill_power() -> int:
	var data=CLASSES[hero["class"]]
	return int(data["base"])+int(hero["level"])*2+int(age_bonus()/3)

func refine_chance() -> int:
	return min(92,45+age_bonus()+int(hero["refine"])*3+int(hero["level"]))

func _process(delta:float) -> void:
	elapsed+=delta; spawn_timer+=delta; autosave_timer+=delta
	var movement=Vector2(Input.get_axis("move_left","move_right"),Input.get_axis("move_up","move_down")).normalized()
	hero["pos"]=Vector2(hero["pos"])+movement*180.0*delta
	hero["pos"].x=clamp(float(hero["pos"].x),365.0,1110.0); hero["pos"].y=clamp(float(hero["pos"].y),150.0,420.0)
	if spawn_timer>4.0 and monsters.size()<7: spawn_timer=0; spawn_monster()
	if autosave_timer>8.0:
		autosave_timer=0
		hero["online_days"]=float(hero["online_days"])+delta/86400.0
		hero["age"]=18+int(float(hero["online_days"])/3.0)
		save_game(); update_ui()
	queue_redraw()

func _input(event:InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE: attack()
			KEY_R: refine()
			KEY_Q: quest()
			KEY_C: craft()
			KEY_B: buy_material()

func spawn_monster() -> void:
	var names=["Poring","Goblin","Wolf","Skeleton","Orc"]
	var n=names[randi()%names.size()]
	monsters.append({"name":n,"pos":Vector2(randf_range(410,1080),randf_range(175,405)),"hp":35+int(hero["level"])*4,"max":35+int(hero["level"])*4})

func nearest_monster():
	var best=null; var dist=99999.0
	for m in monsters:
		var d=Vector2(hero["pos"]).distance_to(m["pos"])
		if d<dist: dist=d; best=m
	return best if dist<90 else null

func attack() -> void:
	var m=nearest_monster()
	if m==null: log_message("Move close to a monster, then press SPACE."); return
	var damage=skill_power()+randi_range(0,9); m["hp"]-=damage
	log_message("%s dealt %d damage." % [CLASSES[hero["class"]]["skill"],damage])
	if m["hp"]<=0:
		hero["kills"]+=1; hero["zeny"]+=randi_range(30,70); add_exp(35); monsters.erase(m)
		log_message("Monster defeated! +35 EXP and Zeny.")
	save_game(); update_ui()

func add_exp(amount:int) -> void:
	hero["exp"]+=amount
	while int(hero["exp"])>=int(hero["level"])*100:
		hero["exp"]-=int(hero["level"])*100; hero["level"]+=1; hero["max_hp"]+=8; hero["hp"]=hero["max_hp"]
		log_message("Level up! You reached level %d." % hero["level"])

func refine() -> void:
	var material="Phracon" if int(hero["refine"])<4 else ("Emveretarcon" if int(hero["refine"])<8 else "Oridecon")
	var mats=hero["materials"]
	if int(mats[material])<=0: log_message("You need %s to refine." % material); return
	mats[material]-=1
	if randf()*100.0<refine_chance(): hero["refine"]+=1; log_message("Refinement succeeded! Equipment +%d." % hero["refine"])
	else: log_message("Refinement failed; equipment was protected.")
	save_game(); update_ui()

func quest() -> void:
	hero["quest"]+=1; hero["zeny"]+=100+int(hero["quest"])*25; hero["materials"]["Phracon"]+=1; add_exp(50)
	log_message("Quest completed! +EXP, Zeny, and Phracon.")
	save_game(); update_ui()

func craft() -> void:
	if int(hero["materials"]["Phracon"])<2 or int(hero["zeny"])<80: log_message("Crafting requires 2 Phracon and 80 Zeny."); return
	hero["materials"]["Phracon"]-=2; hero["zeny"]-=80; hero["refine"]+=1
	log_message("Crafted a %s upgrade." % CLASSES[hero["class"]]["weapon"]); save_game(); update_ui()

func buy_material() -> void:
	var discount=min(30,age_bonus()); var price=int(100*(100-discount)/100)
	if int(hero["zeny"])<price: log_message("Not enough Zeny."); return
	hero["zeny"]-=price; hero["materials"]["Phracon"]+=1
	log_message("Bought Phracon for %d Zeny (%d%% age discount)." % [price,discount]); save_game(); update_ui()

func update_ui() -> void:
	if not profile: return
	var mats=hero["materials"]
	profile.text="Name: %s\nClass: %s\nLevel: %d  EXP: %d/%d\nAge: %d years\nOnline: %.2f days\nHP: %d/%d\nZeny: %d\n\nMaterials\nPhracon: %d\nEmveretarcon: %d\nOridecon: %d\n\nAge bonus: +%d%% basic skills\nRefine chance: %d%%\nPrice discount: -%d%%\nRefinement: +%d" % [hero["name"],hero["class"],hero["level"],hero["exp"],int(hero["level"])*100,hero["age"],hero["online_days"],hero["hp"],hero["max_hp"],hero["zeny"],mats["Phracon"],mats["Emveretarcon"],mats["Oridecon"],age_bonus(),refine_chance(),min(30,age_bonus()),hero["refine"]]
	status_label.text="FIELD: %s   |   Weapon: %s   |   Basic Power: %d   |   Monsters: %d" % [hero["class"],CLASSES[hero["class"]]["weapon"],skill_power(),monsters.size()]
	log_label.text="\n".join(log_lines)

func log_message(message:String) -> void:
	log_lines.push_front(message)
	if log_lines.size()>6: log_lines.pop_back()
	if log_label: log_label.text="\n".join(log_lines)

func save_game() -> void:
	var data=hero.duplicate(true)
	data["pos_x"]=float(hero["pos"].x); data["pos_y"]=float(hero["pos"].y); data.erase("pos")
	var file=FileAccess.open(SAVE_PATH,FileAccess.WRITE)
	if file: file.store_string(JSON.stringify(data)); file.close()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH): return
	var file=FileAccess.open(SAVE_PATH,FileAccess.READ)
	var parsed=JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		for key in parsed: hero[key]=parsed[key]
		hero["pos"]=Vector2(float(parsed.get("pos_x",270)),float(parsed.get("pos_y",330)))
		file.close()

func _draw() -> void:
	draw_rect(Rect2(340,95,792,525),Color("#0d233c"))
	draw_rect(Rect2(365,120,742,300),Color("#163d3b"))
	for x in range(365,1110,45): draw_line(Vector2(x,120),Vector2(x,420),Color("#2d6c60"))
	for y in range(120,421,45): draw_line(Vector2(365,y),Vector2(1110,y),Color("#2d6c60"))
	draw_string(ThemeDB.fallback_font,Vector2(385,145),"HONOUR WAR FIELD",HORIZONTAL_ALIGNMENT_LEFT,300,18,Color("#f4c95d"))
	var data=CLASSES[hero["class"]]
	draw_circle(hero["pos"],18,data["color"])
	draw_string(ThemeDB.fallback_font,Vector2(hero["pos"].x-28,hero["pos"].y-28),str(hero["name"]),HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color.WHITE)
	for m in monsters:
		draw_circle(m["pos"],16,Color("#d96b76"))
		draw_string(ThemeDB.fallback_font,Vector2(m["pos"].x-24,m["pos"].y-24),str(m["name"]),HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color.WHITE)
		draw_rect(Rect2(m["pos"].x-22,m["pos"].y+20,44,4),Color("#222222"))
		draw_rect(Rect2(m["pos"].x-22,m["pos"].y+20,44*max(0.0,float(m["hp"])/float(m["max"])),4),Color("#ff7373"))
