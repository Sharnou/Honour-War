class_name SkillTreeUI
extends CanvasLayer

var game
var panel:Panel
var title:Label
var points_label:Label
var scroll:ScrollContainer
var list:VBoxContainer
var notice:Label
var visible_state:=false

func _ready()->void:
	layer=30
	call_deferred("setup")

func setup()->void:
	game=get_parent()
	build()
	hide_tree()

func build()->void:
	panel=Panel.new()
	panel.position=Vector2(300,55)
	panel.size=Vector2(820,570)
	add_child(panel)
	var header:=HBoxContainer.new()
	header.position=Vector2(18,14)
	header.size=Vector2(784,42)
	panel.add_child(header)
	title=Label.new()
	title.text="SKILL MASTERY"
	title.add_theme_font_size_override("font_size",24)
	header.add_child(title)
	var spacer:=Control.new()
	spacer.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	points_label=Label.new()
	points_label.add_theme_font_size_override("font_size",18)
	header.add_child(points_label)
	var close:=Button.new()
	close.text="CLOSE [F]"
	close.pressed.connect(hide_tree)
	header.add_child(close)
	var line:=HSeparator.new()
	line.position=Vector2(18,62)
	line.size=Vector2(784,2)
	panel.add_child(line)
	scroll=ScrollContainer.new()
	scroll.position=Vector2(18,76)
	scroll.size=Vector2(784,430)
	panel.add_child(scroll)
	list=VBoxContainer.new()
	list.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation",8)
	scroll.add_child(list)
	notice=Label.new()
	notice.position=Vector2(18,518)
	notice.size=Vector2(784,36)
	notice.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(notice)

func _unhandled_input(event:InputEvent)->void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_F:
		toggle_tree()

func toggle_tree()->void:
	if visible_state: hide_tree()
	else: show_tree()

func show_tree()->void:
	if game==null: return
	visible_state=true
	panel.visible=true
	refresh()
	get_viewport().set_input_as_handled()

func hide_tree()->void:
	visible_state=false
	if panel: panel.visible=false

func refresh()->void:
	if game==null or list==null: return
	SkillSystem.ensure_state(game.hero)
	points_label.text="Skill Points: %d" % int(game.hero.get("skill_points",0))
	title.text="%s • SKILL MASTERY" % str(game.hero.get("class","Warrior"))
	for child in list.get_children(): child.queue_free()
	var skills:=SkillSystem.all_skills(str(game.hero.get("class","Warrior")))
	var current_tier:=0
	for skill in skills:
		if int(skill["tier"])!=current_tier:
		current_tier=int(skill["tier"])
		var tier_label:=Label.new()
		tier_label.text="TIER %d  •  %s" % [current_tier, tier_name(current_tier)]
		tier_label.add_theme_font_size_override("font_size",17)
		list.add_child(tier_label)
		var divider:=HSeparator.new()
		list.add_child(divider)
		var row:=PanelContainer.new()
		row.custom_minimum_size=Vector2(760,72)
		list.add_child(row)
		var hb:=HBoxContainer.new()
		hb.add_theme_constant_override("separation",10)
		row.add_child(hb)
		var info:=Label.new()
		var lvl:=SkillSystem.skill_level(game.hero,str(skill["id"]))
		var state:="LOCKED"
		if lvl>0: state="Lv.%d/%d" % [lvl,int(skill["max_level"])]
		info.text="%s  [%s]\n%s\nReq Lv.%d • Cost %d SP • Power %d • Cooldown %.1fs" % [skill["name"],state,skill["description"],int(skill["required_level"]),int(skill["cost"]),SkillSystem.power(game.hero,skill["id"]),float(skill["cooldown"])]
		info.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		hb.add_child(info)
		var button:=Button.new()
		if lvl<=0: button.text="LEARN"
		else: button.text="UPGRADE"
		button.custom_minimum_size=Vector2(105,48)
		button.disabled=not SkillSystem.can_learn(game.hero,str(skill["id"]))
		button.pressed.connect(learn_skill.bind(str(skill["id"])))
		hb.add_child(button)
	notice.text="F: toggle • Skills scale with level and skill rank. Ultimates require Lv.200 and their prerequisite chain."

func tier_name(tier:int)->String:
	return ["Foundation","Specialization","Advanced","Mastery","Ultimate"][clamp(tier-1,0,4)]

func learn_skill(skill_id:String)->void:
	if SkillSystem.learn(game.hero,skill_id):
		notice.text="Skill upgraded successfully. Combat power updated."
		game.log_message("Learned %s Lv.%d." % [SkillSystem.skill_map(str(game.hero.get("class","Warrior")))[skill_id]["name"],SkillSystem.skill_level(game.hero,skill_id)])
		game.save_game()
		game.update_ui()
		refresh()
	else:
		notice.text="Cannot learn: check level, prerequisites, maximum rank, or skill points."
