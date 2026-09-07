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
var combat_vfx:CombatVFX

func _ready()->void:
	game=get_parent()
	combat_vfx=CombatVFX.new()
	call_deferred("_add_combat_vfx")
	build()
	panel.visible=false
	call_deferred("refresh")

func _add_combat_vfx()->void:
	if combat_vfx==null or game==null:
		return
	if combat_vfx.get_parent()==null:
		game.add_child(combat_vfx)
	combat_vfx.setup(game)

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
	panel.visible=not panel.visible
	refresh()

func _input(event:InputEvent)->void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_K:
		toggle()
		return
	if not panel.visible: return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode>=KEY_1 and event.keycode<=KEY_8:
			var index:=int(event.keycode-KEY_1)
			var hero_value=game.get("hero")
			if not hero_value is Dictionary: return
			var hero:Dictionary=hero_value
			var ids:=SkillSystem.all_skills(str(hero.get("class","Warrior")))
			if index<ids.size():
				selected_skill_id=str(ids[index]["id"])
				if str(ids[index]["kind"])!="passive": use_skill(selected_skill_id)

func refresh()->void:
	if game==null or not game.get("hero") is Dictionary: return
	var hero:Dictionary=game.get("hero")
	SkillSystem.ensure_state(hero)
	if title_label==null or points_label==null or tree_box==null: return
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
		var rank:=SkillSystem.skill_level(hero,str(skill["id"]))
		button.text="%d. %s\nLv.%d/%d  •  %s" % [slot+1,str(skill["name"]),rank,int(skill["max_level"]),str(skill["kind"]).to_upper()]
		button.pressed.connect(select_skill.bind(str(skill["id"])))
		row.add_child(button)
		skill_buttons[str(skill["id"])]=button
		var learn:=Button.new()
		learn.text="UPGRADE"
		learn.custom_minimum_size=Vector2(110,58)
		learn.disabled=rank>=int(skill["max_level"])
		learn.pressed.connect(learn_skill.bind(str(skill["id"])))
		row.add_child(learn)
		slot+=1
	if selected_skill_id=="" and skills.size()>0: selected_skill_id=str(skills[0]["id"])
	update_detail()

func select_skill(skill_id:String)->void:
	selected_skill_id=skill_id
	update_detail()

func update_detail()->void:
	if game==null or selected_skill_id=="" or detail_label==null: return
	var hero_value=game.get("hero")
	if not hero_value is Dictionary: return
	var hero:Dictionary=hero_value
	var skills:=SkillSystem.skill_map(str(hero.get("class","Warrior")))
	if not skills.has(selected_skill_id): return
	var skill:Dictionary=skills[selected_skill_id]
	var level:=SkillSystem.skill_level(hero,selected_skill_id)
	var req_text:="None"
	if skill["requires"].size()>0: req_text=", ".join(skill["requires"])
	var stats:=SkillSystem.combat_stats(hero)
	var effect:=SkillSystem.effect_text(hero,selected_skill_id)
	detail_label.text="%s\n\nType: %s\nTier: %d\nRank: %d / %d\nRequired Hero Level: %d\nUpgrade Cost: %d SP\nSkill SP Cost: %d\nCooldown: %.1fs\nPower: %d\nPrerequisites: %s\n\nEffect: %s\n\nLIVE PASSIVE BONUSES\nPower +%d  Crit +%d%%\nDefense +%d  Healing +%d\nRefine +%d\n\n%s" % [skill["name"],str(skill["kind"]).to_upper(),skill["tier"],level,skill["max_level"],skill["required_level"],skill["cost"],SkillSystem.sp_cost(hero,selected_skill_id),skill["cooldown"],SkillSystem.power(hero,selected_skill_id),req_text,effect,stats["power_bonus"],stats["crit_bonus"],stats["defense_bonus"],stats["healing_bonus"],stats["refine_bonus"],skill["description"]]

func learn_skill(skill_id:String)->void:
	var hero:Dictionary=game.get("hero")
	if SkillSystem.learn(hero,skill_id):
		selected_skill_id=skill_id
		game.call("log_message","Skill upgraded: %s Lv.%d. Passive effects are now active." % [SkillSystem.skill_map(str(hero["class"]))[skill_id]["name"],SkillSystem.skill_level(hero,skill_id)])
		game.call("save_game")
	else:
		game.call("log_message","Cannot upgrade this skill: level, prerequisite, max rank, or skill points requirement not met.")
	refresh()

func use_selected()->void:
	if selected_skill_id=="": return
	use_skill(selected_skill_id)

func use_skill(skill_id:String)->void:
	var hero:Dictionary=game.get("hero")
	var target=game.call("nearest_monster")
	var sid:=str(skill_id)
	var skill_map:=SkillSystem.skill_map(str(hero.get("class","Warrior")))
	if not skill_map.has(sid): return
	var skill_def:Dictionary=skill_map[sid]
	var targetless_heal:=sid=="aco_heaven_gate" or sid=="aco_sanctuary" or sid=="aco_seraphic_light"
	if target==null and not targetless_heal:
		game.call("log_message","%s requires a nearby monster target." % str(skill_def["name"]))
		refresh()
		return
	var result:=SkillSystem.use(hero,skill_id,Time.get_ticks_msec()/1000.0)
	if not result["ok"]:
		game.call("log_message","Skill unavailable: %s." % str(result["reason"]))
		refresh()
		return
	var damage:=int(result["power"])
	var ultimate:=str(result["skill"]["kind"])=="ultimate"
	if ultimate: damage*=2
	var hero_pos:=Vector2(float(hero.get("pos_x",0.0)),float(hero.get("pos_y",0.0)))
	if combat_vfx!=null:
		combat_vfx.skill_cast(target["pos"] if target!=null else hero_pos,str(result["skill"]["name"]),ultimate)
	if target==null:
		heal_hero(hero,damage)
		if combat_vfx!=null: combat_vfx.heal(hero_pos,damage)
		game.call("log_message","%s restored %d HP." % [result["skill"]["name"],damage])
	else:
		target["hp"]-=damage
		var critical:=int(result["power"])>=SkillSystem.power(hero,skill_id)*2
		if combat_vfx!=null: combat_vfx.hit(target["pos"],damage,critical)
		if sid=="aco_heaven_gate" or sid=="aco_sanctuary" or sid=="aco_seraphic_light":
			heal_hero(hero,max(1,int(damage/2)))
			if combat_vfx!=null: combat_vfx.heal(hero_pos,max(1,int(damage/2)))
		if sid=="mer_arsenal_overlord":
			heal_pet(hero,max(1,int(damage/4)))
			hero["temporary_power_until"]=Time.get_ticks_msec()/1000.0+10.0
		if sid=="war_guardian_roar" or sid=="mer_fortify": hero["temporary_defense_until"]=Time.get_ticks_msec()/1000.0+8.0
		if sid=="thief_smoke": hero["temporary_evasion_until"]=Time.get_ticks_msec()/1000.0+6.0
		game.call("log_message","%s Lv.%d unleashed for %d damage!" % [result["skill"]["name"],result["level"],damage])
		if target["hp"]<=0:
			if combat_vfx!=null: combat_vfx.monster_death(target["pos"])
			game.call("defeat_monster",target)
	game.call("save_game")
	game.call("update_ui")
	refresh()

func heal_hero(hero:Dictionary,amount:int)->void:
	var stats:=SkillSystem.combat_stats(hero)
	var final_amount:=amount+int(stats["healing_bonus"])
	hero["hp"]=min(int(hero.get("max_hp",1)),int(hero.get("hp",0))+final_amount)

func heal_pet(hero:Dictionary,amount:int)->void:
	if not hero.get("pet",{}) is Dictionary: return
	var pet:Dictionary=hero["pet"]
	pet["hp"]=min(int(pet.get("max_hp",1)),int(pet.get("hp",0))+amount)
	hero["pet"]=pet
