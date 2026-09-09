class_name GameplaySystemsRuntime
extends CanvasLayer

const AGE=preload("res://scripts/OnlineAgeSystem.gd")
const INV=preload("res://scripts/EventInventorySystem.gd")
const CODEX=preload("res://scripts/MonsterDetailsSystem.gd")
const CHARACTER_INV=preload("res://scripts/CharacterInventorySystem.gd")
const CHARACTER=preload("res://scripts/CharacterProgressionSystem.gd")
const EQUIPMENT=preload("res://scripts/EquipmentProgressionSystem.gd")
const ITEMS=preload("res://scripts/ItemDatabase.gd")

var game:Node3D
var legacy:Node
var panel:PanelContainer
var body:Control
var tabs:HBoxContainer
var mode:String="character"
var timer:float=0.0
var hero:Dictionary={}
var selected_item:String=""
var selected_slot:String=""
var selected_card:String=""
var status_label:Label

func _ready()->void:
	game=get_parent() as Node3D
	call_deferred("_bind")

func _bind()->void:
	if game==null: return
	legacy=game.get_node_or_null("LegacyGame")
	_build_ui()
	_wire_toolbar()

func _process(delta:float)->void:
	timer+=delta
	if timer<0.5: return
	timer=0.0
	if legacy==null: return
	var hero_value:Variant=legacy.get("hero")
	if hero_value is Dictionary:
		hero=hero_value
		CHARACTER_INV.ensure_state(hero)
		_refresh(hero)

func _build_ui()->void:
	panel=PanelContainer.new()
	panel.name="GameplayInteractionPanel"
	panel.position=Vector2(1260,85)
	panel.size=Vector2(620,735)
	add_child(panel)
	var root:=VBoxContainer.new()
	root.add_theme_constant_override("separation",6)
	panel.add_child(root)
	var title:=Label.new()
	title.text="HONOUR WAR  •  CHARACTER SYSTEM"
	title.add_theme_font_size_override("font_size",16)
	root.add_child(title)
	tabs=HBoxContainer.new()
	root.add_child(tabs)
	for entry in [["character","CHARACTER"],["inventory","INVENTORY"],["equipment","EQUIPMENT"],["refine","REFINE"],["events","EVENTS"],["monster","MONSTER"]]:
		var button:=Button.new()
		button.text=str(entry[1])
		button.pressed.connect(_set_mode.bind(str(entry[0])))
		tabs.add_child(button)
	var scroll:=ScrollContainer.new()
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	body=VBoxContainer.new()
	body.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",6)
	scroll.add_child(body)
	status_label=Label.new()
	status_label.text=""
	status_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	root.add_child(status_label)
	var hint:=Label.new()
	hint.text="I Inventory  C Character  E Events  M Monster  •  All character actions save automatically"
	root.add_child(hint)

func _wire_toolbar()->void:
	var ui:=game.get_node_or_null("HDUIStyleDirector")
	if ui==null: return
	var toolbar:Variant=ui.get("toolbar")
	if not toolbar is HBoxContainer: return
	var buttons:Array=toolbar.get_children()
	if buttons.size()<7: return
	for i in buttons.size():
		var button:Variant=buttons[i]
		if button is BaseButton:
			button.pressed.connect(_toolbar_action.bind(i))

func _toolbar_action(index:int)->void:
	match index:
		0: _set_mode("character")
		1: _set_mode("character")
		2: _set_mode("character")
		3: _set_mode("inventory")
		4: _set_mode("equipment")
		5: _set_mode("refine")
		6: _set_mode("character")

func _set_mode(next:String)->void:
	mode=next
	selected_item=""
	selected_slot=""
	selected_card=""
	timer=1.0

func _unhandled_key_input(event:InputEvent)->void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	match event.keycode:
		KEY_I: _set_mode("inventory")
		KEY_E: _set_mode("events")
		KEY_M: _set_mode("monster")
		KEY_C: _set_mode("character")

func _clear_body()->void:
	for child in body.get_children(): child.queue_free()

func _add_heading(text:String)->void:
	var label:=Label.new()
	label.text=text
	label.add_theme_font_size_override("font_size",15)
	body.add_child(label)

func _add_button(text:String,action:Callable)->Button:
	var button:=Button.new()
	button.text=text
	button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	button.pressed.connect(action)
	body.add_child(button)
	return button

func _refresh(current:Dictionary)->void:
	AGE.normalize(current)
	INV.ensure_inventory(current)
	if mode=="character": _character(current)
	elif mode=="inventory": _inventory(current)
	elif mode=="equipment": _equipment(current)
	elif mode=="refine": _refine(current)
	elif mode=="events": _events(current)
	else: _monster(current)

func _character(current:Dictionary)->void:
	_clear_body()
	_add_heading("CHARACTER / LIVE STATS")
	var growth:Dictionary=AGE.strength_bonus(current)
	var stats:Dictionary=CHARACTER.stats(current)
	var pet:Dictionary=current.get("pet",{}) if current.get("pet",{}) is Dictionary else {}
	var label:=Label.new()
	label.text="Level %d / 250   •   %s\nAge %d • %s • %.2f online days\nZeny: %d\n\nATK %d  MATK %d\nDEF %d  MDEF %d\nHP %d / %d   SP %d / %d\nCRIT %d  HIT %d  FLEE %d\nHealing %d\n\nAGE BONUS\nATK +%d  MATK +%d  DEF +%d  MDEF +%d\nHP +%d  SP +%d  CRIT +%d  HIT +%d  FLEE +%d\n\nPET\n%s  Lv.%d  XP %d" % [int(current.get("level",1)),str(current.get("class","Warrior")),int(current.get("age",18)),AGE.title(int(current.get("age",18))),float(current.get("online_days",0.0)),int(current.get("zeny",0)),int(stats.get("atk",0)),int(stats.get("matk",0)),int(stats.get("def",0)),int(stats.get("mdef",0)),int(current.get("hp",stats.get("max_hp",0))),int(stats.get("max_hp",0)),int(current.get("sp",stats.get("max_sp",0))),int(stats.get("max_sp",0)),int(stats.get("crit",0)),int(stats.get("hit",0)),int(stats.get("flee",0)),int(stats.get("healing",0)),int(growth["atk"]),int(growth["matk"]),int(growth["def"]),int(growth["mdef"]),int(growth["hp"]),int(growth["sp"]),int(growth["crit"]),int(growth["hit"]),int(growth["flee"]),str(pet.get("name","None")),int(pet.get("level",1)),int(pet.get("xp",0))]
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	body.add_child(label)
	_add_button("OPEN INVENTORY",Callable(self,"_set_mode").bind("inventory"))
	_add_button("OPEN EQUIPMENT",Callable(self,"_set_mode").bind("equipment"))

func _inventory(current:Dictionary)->void:
	_clear_body()
	_add_heading("INVENTORY • SELECT AN ITEM")
	var stats:Dictionary=CHARACTER.stats(current)
	var economy:=Label.new()
	economy.text="Zeny: %d   •   HP %d/%d   •   SP %d/%d" % [int(current.get("zeny",0)),int(current.get("hp",0)),int(stats.get("max_hp",0)),int(current.get("sp",0)),int(stats.get("max_sp",0))]
	body.add_child(economy)
	var inv_value:Variant=current.get("inventory",{})
	var inv:Dictionary=inv_value if inv_value is Dictionary else {}
	if inv.is_empty():
		var empty:=Label.new(); empty.text="Inventory is empty."; body.add_child(empty); return
	for item_id in inv.keys():
		var id:String=str(item_id)
		var amount:int=int(inv[item_id].get("amount",0)) if inv[item_id] is Dictionary else int(inv[item_id])
		if amount<=0: continue
		var row:=HBoxContainer.new(); row.size_flags_horizontal=Control.SIZE_EXPAND_FILL; body.add_child(row)
		var info:=Button.new(); info.text="%s  x%d" % [id,amount]; info.size_flags_horizontal=Control.SIZE_EXPAND_FILL; info.pressed.connect(_select_item.bind(id)); row.add_child(info)
		var data:Dictionary=ITEMS.all().get(id,{})
		if str(data.get("type",""))=="Consumable":
			var use:=Button.new(); use.text="USE"; use.pressed.connect(_use_item.bind(id)); row.add_child(use)
		elif str(data.get("type","")) in ["Weapon","Armor","Accessory"]:
			var equip:=Button.new(); equip.text="EQUIP"; equip.pressed.connect(_equip_item.bind(id)); row.add_child(equip)
	if selected_item!="":
		_add_heading("SELECTED: "+selected_item)
		var data:Dictionary=ITEMS.all().get(selected_item,{})
		var detail:=Label.new(); detail.text="Type: %s\nRarity: %s\nValue: %d\nAttack: %d  Magic: %d  Defense: %d\nSlots: %d\nEffect: %s" % [str(data.get("type","Unknown")),str(data.get("rarity","Common")),int(data.get("value",0)),int(data.get("attack",0)),int(data.get("magic",0)),int(data.get("defense",0)),int(data.get("card_slots",0)),str(data.get("effect",""))]; detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; body.add_child(detail)

func _select_item(item_id:String)->void:
	selected_item=item_id
	timer=1.0

func _equip_item(item_id:String)->void:
	var result:Dictionary=CHARACTER_INV.equip(hero,item_id)
	_show_result(result,"Equipped "+item_id)
	if bool(result.get("ok",false)): selected_item=""
	timer=1.0

func _use_item(item_id:String)->void:
	var result:Dictionary=CHARACTER_INV.use_consumable(hero,item_id)
	_show_result(result,"Used "+item_id)
	timer=1.0

func _equipment(current:Dictionary)->void:
	_clear_body()
	_add_heading("EQUIPMENT • LIVE CHARACTER STATS")
	var stats:Dictionary=CHARACTER.stats(current)
	var stat_box:=Label.new(); stat_box.text="ATK %d   MATK %d   DEF %d   MDEF %d\nHP %d/%d   SP %d/%d   CRIT %d" % [int(stats.get("atk",0)),int(stats.get("matk",0)),int(stats.get("def",0)),int(stats.get("mdef",0)),int(current.get("hp",0)),int(stats.get("max_hp",0)),int(current.get("sp",0)),int(stats.get("max_sp",0)),int(stats.get("crit",0))]; body.add_child(stat_box)
	for slot in ["weapon","armor","head","head_middle","head_lower","garment","shoes","offhand","accessory_1","accessory_2"]:
		var equipped:Variant=current.get("equipment",{}).get(slot,null)
		var name:String="Empty"
		var refine:int=0
		if equipped is Dictionary:
			name=str(equipped.get("id",equipped.get("name","Unknown"))); refine=int(equipped.get("refine",current.get("equipment_refine",{}).get(slot,0)))
		elif equipped is String: name=str(equipped); refine=int(current.get("equipment_refine",{}).get(slot,0))
		var row:=HBoxContainer.new(); body.add_child(row)
		var choose:=Button.new(); choose.text="%s: %s  +%d" % [slot.to_upper(),name,refine]; choose.size_flags_horizontal=Control.SIZE_EXPAND_FILL; choose.pressed.connect(_select_slot.bind(slot)); row.add_child(choose)
		if name!="Empty":
			var remove:=Button.new(); remove.text="UNEQUIP"; remove.pressed.connect(_unequip_slot.bind(slot)); row.add_child(remove)
	if selected_slot!="":
		_add_heading("SELECTED SLOT: "+selected_slot.to_upper())
		_add_button("REFINE SELECTED SLOT",Callable(self,"_refine_selected"))
		_add_button("CHOOSE A CARD FOR THIS SLOT",Callable(self,"_show_card_picker"))
		if selected_card!="": _add_button("INSERT SELECTED CARD: "+selected_card,Callable(self,"_insert_selected_card"))

func _select_slot(slot:String)->void:
	selected_slot=slot
	selected_card=""
	timer=1.0

func _unequip_slot(slot:String)->void:
	var result:Dictionary=CHARACTER_INV.unequip(hero,slot)
	_show_result(result,"Unequipped "+slot)
	timer=1.0

func _refine(current:Dictionary)->void:
	_clear_body()
	_add_heading("REFINEMENT • AUTOMATIC SAVE")
	for slot in ["weapon","armor","head","head_middle","head_lower","garment","shoes","offhand","accessory_1","accessory_2"]:
		if not current.get("equipment",{}).has(slot): continue
		var item:Dictionary=current["equipment"][slot] if current["equipment"][slot] is Dictionary else {}
		var refine:int=int(item.get("refine",current.get("equipment_refine",{}).get(slot,0)))
		var chance:float=EQUIPMENT.refine_chance(refine)
		var material:String="Oridecon" if refine>=5 else "Phracon"
		var owned:int=int(current.get("inventory",{}).get(material,0))
		if current.get("inventory",{}).get(material,0) is Dictionary: owned=int(current["inventory"][material].get("amount",0))
		var row:=HBoxContainer.new(); body.add_child(row)
		var label:=Label.new(); label.text="%s  +%d → +%d  •  %.0f%%  •  %s x%d" % [str(item.get("id","Item")),refine,refine+1,chance*100.0,material,owned]; label.size_flags_horizontal=Control.SIZE_EXPAND_FILL; row.add_child(label)
		var button:=Button.new(); button.text="REFINE"; button.disabled=owned<=0; button.pressed.connect(_refine_slot.bind(slot)); row.add_child(button)
	_add_heading("Phracon: +0 to +4 • Oridecon: +5 onward • Failed high refinement can reduce the refine level.")

func _refine_slot(slot:String)->void:
	var result:Dictionary=CHARACTER_INV.refine(hero,slot,0.5)
	_show_result(result,"Refinement attempt complete")
	timer=1.0

func _refine_selected()->void:
	if selected_slot=="": return
	_refine_slot(selected_slot)

func _show_card_picker()->void:
	_clear_body()
	_add_heading("CARD SELECTOR • SELECT AN OWNED CARD")
	var cards_value:Variant=hero.get("cards",[])
	var cards:Array=cards_value if cards_value is Array else []
	if cards.is_empty():
		var empty:=Label.new(); empty.text="No cards owned."; body.add_child(empty); _add_button("BACK TO EQUIPMENT",Callable(self,"_set_mode").bind("equipment")); return
	for card_value in cards:
		var card_id:String=str(card_value)
		var button:=Button.new(); button.text=card_id; button.pressed.connect(_select_card.bind(card_id)); body.add_child(button)
	if selected_card!="":
		_add_heading("SELECTED CARD: "+selected_card)
		_add_button("INSERT INTO "+selected_slot.to_upper(),Callable(self,"_insert_selected_card"))
	_add_button("BACK TO EQUIPMENT",Callable(self,"_set_mode").bind("equipment"))

func _select_card(card_id:String)->void:
	selected_card=card_id
	_set_mode("equipment")
	timer=1.0

func _insert_selected_card()->void:
	if selected_slot=="" or selected_card=="": return
	var result:Dictionary=CHARACTER_INV.insert_card(hero,selected_slot,selected_card)
	_show_result(result,"Card inserted")
	if bool(result.get("ok",false)): selected_card=""
	timer=1.0

func _events(current:Dictionary)->void:
	_clear_body()
	_add_heading("LIVE EVENT LIST")
	var progress_value:Variant=current.get("event_progress",{})
	var progress_map:Dictionary=progress_value if progress_value is Dictionary else {}
	for event in INV.event_catalog():
		var id:String=str(event["id"]); var progress:int=int(progress_map.get(id,0)); var target:int=int(event.get("target",1))
		var label:=Label.new(); label.text="%s • %dh\n%s\nReward: %s\nProgress: %d/%d" % [event["name"],int(event["duration_hours"]),event["objective"],event["reward"],progress,target]; label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; body.add_child(label)

func _monster(_current:Dictionary)->void:
	_clear_body()
	_add_heading("MONSTER CODEX / DETAILS")
	var monsters:Variant=legacy.get("monsters") if legacy!=null else []
	if monsters is Array:
		for monster in monsters:
			if monster is Dictionary:
				var d:Dictionary=CODEX.details(monster)
				var label:=Label.new(); label.text="%s  Lv.%d  Danger %d\nRole: %s  Element: %s\nStatus: %s (%.0f%%)  Poison Resist: %.0f%%\nHP: %d/%d  ATK: %d  DEF: %d\n%s" % [d["name"],d["level"],d["danger"],d["role"],d["element"],d["status"],float(d["status_chance"])*100.0,float(d["poison_resist"])*100.0,int(monster.get("hp",0)),int(monster.get("max",monster.get("hp",0))),int(monster.get("attack",0)),int(monster.get("defense",0)),d["description"]]; label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; body.add_child(label)

func _show_result(result:Dictionary,success_text:String)->void:
	if bool(result.get("ok",false)):
		_set_status("✓ "+success_text+" — saved automatically.")
	else:
		var message:String="✕ "+_reason_text(str(result.get("reason","action_failed")))
		if result.has("material"): message+="  Material: "+str(result["material"])
		_set_status(message)

func _reason_text(reason:String)->String:
	match reason:
		"unknown_item": return "Unknown item."
		"not_in_inventory": return "You do not own that item."
		"not_equipment": return "That item cannot be equipped."
		"invalid_slot": return "That equipment slot is not supported."
		"empty_slot": return "That equipment slot is empty."
		"not_available": return "Item is not available."
		"not_consumable": return "That item cannot be used."
		"missing_material": return "Required refinement material is missing."
		"no_refine_material_catalogue": return "Refinement material catalogue is unavailable."
		"card_not_owned": return "Card is not owned."
		"no_slots": return "This equipment has no free card slots."
		"duplicate_card": return "That card is already inserted."
		"cap": return "This equipment has reached its refinement cap."
		return reason.replace("_"," ").capitalize()

func _set_status(text:String)->void:
	status_label.text=text
