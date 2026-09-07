class_name SkillUI
extends CanvasLayer

var game:Node
var panel:Panel
var tree_box:VBoxContainer
var title_label:Label
var points_label:Label
var detail_label:Label
var open_button:Button
var skill_buttons:Dictionary={}
var selected_skill_id:String=""

func _ready()->void:
	game=get_parent()
	build()
	visible=false
	refresh()

func build()->void:
	open_button=Button.new()
	open_button.text="SKILLS [K]"
	open_button.position=Vector2(340,58)
	open_button.size=Vector2(120,32)
	open_button.pressed.connect(toggle)
	add_child(open_button)
	panel=Panel.new()
	panel.position=Vector2(330,70)
	panel.size=Vector2(800,560)
	add_child(panel)
	var header:=HBoxContainer.new()
	header.position=Vector2(18,12)
	header.size=Vector2(760,38)
	panel.add_child(header)
	title_label=Label.new()
	title_label.add_theme_font_size_override("font_size",24)
	header.add_child(title_label)
	points_label=Label.new()
	points_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	points_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	header.add_child(points_label)
	var close:=Button.new()
	close.text="X"
	close.custom_minimum_size=Vector2(42,30)
	close.pressed.connect(toggle)
	header.add_child(close)
	var scroll:=ScrollContainer.new()
	scroll.position=Vector2(18,58)
	scroll.size=Vector2(470,480)
	panel.add_child(scroll)
	tree_box=VBoxContainer.new()
	tree_box.custom_minimum_size=Vector2(450,0)
	scroll.add_child(tree_box)
	var detail_panel:=Panel.new()
	detail_panel.position=Vector2(510,58)
	detail_panel.size=Vector2(265,480)
	panel.add_child(detail_panel)
	detail_label=Label.new()
	detail_label.position=Vector2(14,14)
	detail_label.size=Vector2(235,410)
	detail_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	detail_panel.add_child(detail_label)
	var use:=Button.new()
	use.text="USE SELECTED SKILL"
	use.position=Vector2(14,425)
	use.size=Vector2(235,38)
	use.pressed.connect(use_selected)
	detail_panel.add_child(use)

func toggle()->void:
	visible=not visible
	refresh()

func _input(event:InputEvent)->void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_K:
		toggle()
		return
	if not visible: return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode>=KEY_1 and event.keycode<=KEY_8:
			var index:=int(event.keycode-KEY_1)
			var ids:=SkillSystem.skill_map(str(game.get("hero").get("class","Warrior"))).keys()
			if index<ids.size():
				selected_skill_id=str(ids[index])
				use_skill(selected_skill_id)

func refresh()->void:
	if game==null or not game.get("hero") is Dictionary: return
	var hero:Dictionary=game.get("hero")
	SkillSystem.ensure_state(hero)
	title_label.text="HONOUR WAR — %s SKILL TREE" % str(hero.get("class","Warrior"))
	points_label.text="Skill Points: %d   |   Hero Lv.%d" % [int(hero.get("skill_points",0)),int(hero.get("level",1))]
	for child in tree_box.get_children(): child.queue_free()
	skill_buttons.clear()
	var skills:=SkillSystem.all_skills(str(hero.get("class","Warrior")))
	var current_tier:=0
	var slot:=0
	for skill in skills:
		var tier:=int(skill["tier"])
		if tier!=current_tier:
			current_tier=tier
			var tier_label:=Label.new()
			tier_label.text="TIER %d" % tier
			tier_label.add_theme_font_size_override("font_size",16)
			tier_label.add_theme_color_override("font_color",Color("#f4c95d"))
			tree_box.add_child(tier_label)
		var row:=HBoxContainer.new()
		row.custom_minimum_size=Vector2(450,64)
		tree_box.add_child(row)
		var button:=Button.new()
		button.custom_minimum_size=Vector2(310,58)
		button.text="%d. %s\nLv.%d/%d  •  %s" % [slot+1,str(skill["name"]),SkillSystem.skill_level(hero,str(skill["id"])),int(skill["max_level"]),str(skill["kind"]).to_upper()]
		button.pressed.connect(select_skill.bind(str(skill["id"])))
		row.add_child(button)
		skill_buttons[str(skill["id"])]=button
		var learn:=Button.new()
		learn.text="UPGRADE"
		learn.custom_minimum_size=Vector2(110,58)
		learn.pressed.connect(learn_skill.bind(str(skill["id"])))
		row.add_child(learn)
		slot+=1
	if selected_skill_id=="" and skills.size()>0: selected_skill_id=str(skills[0]["id"])
	update_detail()

func select_skill(skill_id:String)->void:
	selected_skill_id=skill_id
	update_detail()

func update_detail()->void:
	if game==null or selected_skill_id=="": return
	var hero:Dictionary=game.get("hero")
	var skills:=SkillSystem.skill_map(str(hero.get("class","Warrior")))
	if not skills.has(selected_skill_id): return
	var skill:Dictionary=skills[selected_skill_id]
	var level:=SkillSystem.skill_level(hero,selected_skill_id)
	var req_text:="None"
	if skill["requires"].size()>0: req_text=", ".join(skill["requires"])
	detail_label.text="%s\n\nType: %s\nTier: %d\nRank: %d / %d\nRequired Hero Level: %d\nUpgrade Cost: %d SP\nSkill SP Cost: %d\nCooldown: %.1fs\nPower: %d\nPrerequisites: %s\n\n%s" % [skill["name"],str(skill["kind"]).to_upper(),skill["tier"],level,skill["max_level"],skill["required_level"],skill["cost"],SkillSystem.sp_cost(hero,selected_skill_id),skill["cooldown"],SkillSystem.power(hero,selected_skill_id),req_text,skill["description"]]

func learn_skill(skill_id:String)->void:
	var hero:Dictionary=game.get("hero")
	if SkillSystem.learn(hero,skill_id):
		selected_skill_id=skill_id
		game.call("log_message","Skill upgraded: %s Lv.%d." % [SkillSystem.skill_map(str(hero["class"]))[skill_id]["name"],SkillSystem.skill_level(hero,skill_id)])
		game.call("save_game")
	else:
		game.call("log_message","Cannot upgrade this skill: level, prerequisite, max rank, or skill points requirement not met.")
	refresh()

func use_selected()->void:
	if selected_skill_id=="": return
	use_skill(selected_skill_id)

func use_skill(skill_id:String)->void:
	var hero:Dictionary=game.get("hero")
	var result:=SkillSystem.use(hero,skill_id,Time.get_ticks_msec()/1000.0)
	if not result["ok"]:
		game.call("log_message","Skill unavailable: %s." % str(result["reason"]))
		refresh()
		return
	var target=game.call("nearest_monster")
	if target==null:
		game.call("log_message","%s ready. Move near a monster to cast it." % result["skill"]["name"])
		refresh()
		return
	var damage:=int(result["power"])
	var kind:=str(result["skill"]["kind"])
	if kind=="ultimate": damage*=2
	target["hp"]-=damage
	game.call("log_message","%s Lv.%d unleashed for %d damage!" % [result["skill"]["name"],result["level"],damage])
	if target["hp"]<=0: game.call("defeat_monster",target)
	game.call("save_game")
	game.call("update_ui")
	refresh()
