class_name SkillOverlay3D
extends CanvasLayer

var legacy:Node2D
var bar:Panel
var detail:Panel
var slots:Array[Button]=[]
var title:Label
var open:bool=true

func _ready()->void:
	legacy=get_parent().get_node_or_null("LegacyGame")
	_build()
	_refresh()

func _process(_delta:float)->void:
	_refresh()

func _input(event:InputEvent)->void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode==KEY_K:
		open=not open
		if detail!=null: detail.visible=open
		return
	if event.keycode>=KEY_1 and event.keycode<=KEY_8:
		var index:int=int(event.keycode-KEY_1)
		_cast(index)

func _build()->void:
	bar=Panel.new()
	bar.position=Vector2(230,576)
	bar.size=Vector2(820,92)
	add_child(bar)
	var caption:Label=Label.new()
	caption.text="SKILL ARSENAL"
	caption.position=Vector2(14,8)
	caption.add_theme_font_size_override("font_size",13)
	bar.add_child(caption)
	for i in 8:
		var button:Button=Button.new()
		button.position=Vector2(12+i*99,30)
		button.size=Vector2(90,48)
		button.text=str(i+1)
		button.pressed.connect(_cast.bind(i))
		bar.add_child(button)
		slots.append(button)
	detail=Panel.new()
	detail.position=Vector2(760,118)
	detail.size=Vector2(360,430)
	add_child(detail)
	title=Label.new()
	title.position=Vector2(16,12)
	title.add_theme_font_size_override("font_size",18)
	detail.add_child(title)

func _refresh()->void:
	if legacy==null:
		return
	var hero_value:Variant=legacy.get("hero")
	if not hero_value is Dictionary:
		return
	var hero:Dictionary=hero_value
	var skills:Array=SkillSystem.all_skills(str(hero.get("class","Warrior")))
	for i in slots.size():
		if i>=skills.size():
			slots[i].disabled=true
			continue
		var skill:Dictionary=skills[i]
		var rank:int=SkillSystem.skill_level(hero,str(skill["id"]))
		var sp:int=SkillSystem.sp_cost(hero,str(skill["id"]))
		slots[i].disabled=str(skill["kind"])=="passive"
		slots[i].text="%d  %s\nR%d  SP%d" % [i+1,str(skill["name"]),rank,sp]
	if detail!=null:
		detail.visible=open
		if open:
			var lines:PackedStringArray=["%s — SKILLS" % str(hero.get("class","Warrior"))]
			for i in min(8,skills.size()):
				var skill:Dictionary=skills[i]
				lines.append("%d. %s [%s] Lv.%d" % [i+1,str(skill["name"]),str(skill["kind"]).to_upper(),SkillSystem.skill_level(hero,str(skill["id"]))])
			lines.append("")
			lines.append("Press 1–8 to cast. K toggles this panel.")
			title.text="\n".join(lines)

func _cast(index:int)->void:
	if legacy==null:
		return
	var hero_value:Variant=legacy.get("hero")
	if not hero_value is Dictionary:
		return
	var hero:Dictionary=hero_value
	var skills:Array=SkillSystem.all_skills(str(hero.get("class","Warrior")))
	if index<0 or index>=skills.size():
		return
	var skill:Dictionary=skills[index]
	if str(skill["kind"])=="passive":
		legacy.call("log_message",str(skill["name"])+" is passive and is always active.")
		return
	var skill_ui:Node=legacy.get_node_or_null("SkillUI")
	if skill_ui!=null and skill_ui.has_method("use_skill"):
		skill_ui.call("use_skill",str(skill["id"]))
