class_name GameplaySystemsRuntime
extends CanvasLayer

const AGE=preload("res://scripts/OnlineAgeSystem.gd")
const INV=preload("res://scripts/EventInventorySystem.gd")
const CODEX=preload("res://scripts/MonsterDetailsSystem.gd")

var game:Node3D
var legacy:Node
var panel:PanelContainer
var body:RichTextLabel
var tabs:HBoxContainer
var mode:String="character"
var timer:float=0.0

func _ready()->void:
	game=get_parent() as Node3D
	call_deferred("_bind")
func _bind()->void:
	if game==null: return
	legacy=game.get_node_or_null("LegacyGame")
	_build_ui()
func _process(delta:float)->void:
	timer+=delta
	if timer<0.5: return
	timer=0.0
	if legacy==null: return
	var hero_value:Variant=legacy.get("hero")
	if hero_value is Dictionary: _refresh(hero_value)
func _build_ui()->void:
	panel=PanelContainer.new(); panel.position=Vector2(1410,110); panel.size=Vector2(480,620); add_child(panel)
	var root:=VBoxContainer.new(); root.add_theme_constant_override("separation",8); panel.add_child(root)
	var title:=Label.new(); title.text="HONOUR WAR  •  CHARACTER / WORLD SYSTEMS"; title.add_theme_font_size_override("font_size",16); root.add_child(title)
	tabs=HBoxContainer.new(); root.add_child(tabs)
	for entry in [["character","CHARACTER"],["inventory","INVENTORY"],["events","EVENTS"],["monster","MONSTER"]]:
		var button:=Button.new(); button.text=str(entry[1]); button.pressed.connect(_set_mode.bind(str(entry[0]))); tabs.add_child(button)
	body=RichTextLabel.new(); body.bbcode_enabled=true; body.fit_content=false; body.scroll_active=true; body.size_flags_vertical=Control.SIZE_EXPAND_FILL; root.add_child(body)
	var hint:=Label.new(); hint.text="I = Inventory   E = Events   M = Monster details   C = Character"; root.add_child(hint)
func _set_mode(next:String)->void: mode=next; timer=1.0
func _unhandled_key_input(event:InputEvent)->void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	match event.keycode:
		KEY_I: mode="inventory"
		KEY_E: mode="events"
		KEY_M: mode="monster"
		KEY_C: mode="character"
func _refresh(hero:Dictionary)->void:
	AGE.normalize(hero); INV.ensure_inventory(hero)
	if mode=="character": _character(hero)
	elif mode=="inventory": _inventory(hero)
	elif mode=="events": _events(hero)
	else: _monster(hero)
func _character(hero:Dictionary)->void:
	var age:int=int(hero.get("age",18)); var growth:Dictionary=AGE.strength_bonus(hero); var pet:Dictionary=hero.get("pet",{}) if hero.get("pet",{}) is Dictionary else {}
	body.text="[b]AGE: %d years[/b]  •  %s\nOnline time: %.2f days\n\n[b]ECONOMY / PROGRESSION[/b]\nZeny: %d\nXP: %d / %d\nKills: %d\nPet: %s  Lv.%d  XP: %d / %d\n\n[b]UNLIMITED AGE GROWTH[/b]\nEvery 3 online days = +1 year. Age has no maximum.\n\nATK +%d   MATK +%d\nDEF +%d   MDEF +%d\nHP +%d    SP +%d\nCRIT +%d  HIT +%d  FLEE +%d\nHealing +%d\n\nLevel %d / 250\nClass: %s" % [age,AGE.title(age),int(hero.get("online_days",0)),int(hero.get("zeny",0)),int(hero.get("xp",0)),100+int(pow(float(hero.get("level",1)),1.55)*35.0),int(hero.get("kills",0)),str(pet.get("name","None")),int(pet.get("level",1)),int(pet.get("xp",0)),80+int(pet.get("level",1))*int(pet.get("level",1))*18+int(pet.get("level",1))*35,growth["atk"],growth["matk"],growth["def"],growth["mdef"],growth["hp"],growth["sp"],int(growth["crit"]),int(growth["hit"]),int(growth["flee"]),int(growth["healing"]),int(hero.get("level",1)),str(hero.get("class","Warrior"))]
func _inventory(hero:Dictionary)->void:
	var lines:Array[String]=["[b]INVENTORY / ECONOMY[/b]","","Zeny: %d" % int(hero.get("zeny",0)),"XP earned: %d  •  Pet XP: %d" % [int(hero.get("loot_stats",{}).get("xp",0)),int(hero.get("loot_stats",{}).get("pet_xp",0))],""]
	var inv_value:Variant=hero.get("inventory",{}); var inv:Dictionary=inv_value if inv_value is Dictionary else {}
	if inv.is_empty(): lines.append("Inventory is empty. Monster drops and event rewards will appear here.")
	else:
		for item_id in inv.keys():
			var value:Variant=inv[item_id]; var amount:int=int(value.get("amount",0)) if value is Dictionary else int(value); lines.append("• %s  x%d" % [str(item_id),amount])
	var cards_value:Variant=hero.get("cards",[]); var card_count:int=cards_value.size() if cards_value is Array else 0
	lines.append("\nCards: %d" % card_count); lines.append("Loot totals: %d items • %d equipment • %d materials • %d Zeny" % [int(hero.get("loot_stats",{}).get("items",0)),int(hero.get("loot_stats",{}).get("equipment",0)),int(hero.get("loot_stats",{}).get("materials",0)),int(hero.get("loot_stats",{}).get("zeny",0))]); body.text="\n".join(lines)
func _events(hero:Dictionary)->void:
	var lines:Array[String]=["[b]LIVE EVENT LIST[/b]",""]; var progress_value:Variant=hero.get("event_progress",{}); var progress_map:Dictionary=progress_value if progress_value is Dictionary else {}
	for event in INV.event_catalog():
		var id:String=str(event["id"]); var progress:int=int(progress_map.get(id,0)); var target:int=int(event.get("target",1)); lines.append("[b]%s[/b]  •  %dh\n%s\nReward: %s\nProgress: %d/%d\n" % [event["name"],int(event["duration_hours"]),event["objective"],event["reward"],progress,target])
	body.text="\n".join(lines)
func _monster(_hero:Dictionary)->void:
	var lines:Array[String]=["[b]MONSTER CODEX / DETAILS[/b]",""]; var monsters:Variant=legacy.get("monsters") if legacy!=null else []
	if monsters is Array:
		for monster in monsters:
			if monster is Dictionary:
				var d:Dictionary=CODEX.details(monster); lines.append("[b]%s[/b]  Lv.%d  Danger %d\nRole: %s  Element: %s\nStatus: %s (%.0f%%)  Poison Resist: %.0f%%\nHP: %d/%d  ATK: %d  DEF: %d\n%s\n" % [d["name"],d["level"],d["danger"],d["role"],d["element"],d["status"],float(d["status_chance"])*100.0,float(d["poison_resist"])*100.0,int(monster.get("hp",0)),int(monster.get("max",monster.get("hp",0))),int(monster.get("attack",0)),int(monster.get("defense",0)),d["description"]])
	body.text="\n".join(lines)
