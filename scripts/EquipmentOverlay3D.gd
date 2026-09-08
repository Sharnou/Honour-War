class_name EquipmentOverlay3D
extends CanvasLayer

var legacy:Node
var panel:Panel
var equipment_list:VBoxContainer
var inventory_list:VBoxContainer
var title_label:Label
var visible_state:bool=false

func _ready()->void:
	legacy=get_parent().get_node_or_null("LegacyGame")
	call_deferred("_build")

func _unhandled_input(event:InputEvent)->void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_I:
		_toggle()

func _process(_delta:float)->void:
	if visible_state and legacy!=null and panel!=null:
		_refresh()

func _toggle()->void:
	visible_state=not visible_state
	if panel!=null:
		panel.visible=visible_state
	if visible_state:
		_refresh()

func _build()->void:
	if legacy==null:
		return
	panel=Panel.new()
	panel.position=Vector2(640,70)
	panel.size=Vector2(560,650)
	panel.visible=false
	add_child(panel)
	var root:=VBoxContainer.new()
	root.position=Vector2(18,14)
	root.size=Vector2(524,620)
	panel.add_child(root)
	title_label=Label.new()
	title_label.text="EQUIPMENT + INVENTORY"
	title_label.add_theme_font_size_override("font_size",24)
	root.add_child(title_label)
	var hint:=Label.new()
	hint.text="Press I to close • Equip loot directly • 4-slot gear remains supported"
	hint.add_theme_color_override("font_color",Color("#9eb8d2"))
	root.add_child(hint)
	var equipment_heading:=Label.new()
	equipment_heading.text="EQUIPPED"
	equipment_heading.add_theme_font_size_override("font_size",18)
	root.add_child(equipment_heading)
	equipment_list=VBoxContainer.new()
	equipment_list.custom_minimum_size=Vector2(520,220)
	root.add_child(equipment_list)
	var inventory_heading:=Label.new()
	inventory_heading.text="EQUIPMENT IN INVENTORY"
	inventory_heading.add_theme_font_size_override("font_size",18)
	root.add_child(inventory_heading)
	inventory_list=VBoxContainer.new()
	inventory_list.custom_minimum_size=Vector2(520,300)
	root.add_child(inventory_list)
	_refresh()

func _clear(container:VBoxContainer)->void:
	for child in container.get_children():
		child.queue_free()

func _refresh()->void:
	if legacy==null or equipment_list==null or inventory_list==null:
		return
	var hero_value:Variant=legacy.get("hero")
	if not hero_value is Dictionary:
		return
	var hero:Dictionary=hero_value
	EquipmentSystem.ensure_state(hero)
	_clear(equipment_list)
	for slot in EquipmentSystem.SLOTS:
		var row:=HBoxContainer.new()
		row.custom_minimum_size=Vector2(515,30)
		var item:=str(hero["equipment"].get(slot,""))
		if item=="": item="Empty"
		var cards:Array=hero["equipment_cards"].get(slot,[])
		var label:=Label.new()
		label.text="%s: %s  [%d/%d]" % [EquipmentSystem.SLOT_LABELS[slot],item,cards.size(),EquipmentSystem.item_card_slots(item)]
		label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		row.add_child(label)
		if item!="Empty" and not (slot=="weapon" and item=="Novice Sword"):
			var unequip:=Button.new()
			unequip.text="Unequip"
			unequip.pressed.connect(_unequip.bind(slot))
			row.add_child(unequip)
		equipment_list.add_child(row)
	_clear(inventory_list)
	var inventory_value:Variant=hero.get("inventory",{})
	if not inventory_value is Dictionary:
		return
	var inventory:Dictionary=inventory_value
	var count:int=0
	for item_name in inventory.keys():
		var item:=str(item_name)
		var amount:=int(inventory[item_name])
		if amount<=0 or not ItemDatabase.all().has(EquipmentSystem.base_item_name(item)):
			continue
		if EquipmentSystem.item_slot(item)=="":
			continue
		var row:=HBoxContainer.new()
		row.custom_minimum_size=Vector2(515,30)
		var label:=Label.new()
		label.text="%s  x%d  • %s" % [item,amount,EquipmentSystem.SLOT_LABELS.get(EquipmentSystem.item_slot(item),EquipmentSystem.item_slot(item))]
		label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var equip:=Button.new()
		equip.text="EQUIP"
		equip.pressed.connect(_equip.bind(item))
		row.add_child(equip)
		inventory_list.add_child(row)
		count+=1
	if count==0:
		var empty:=Label.new()
		empty.text="No equippable equipment in inventory yet. Defeat monsters/MVPs for gear."
		empty.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		inventory_list.add_child(empty)

func _equip(item_name:String)->void:
	if legacy==null:
		return
	var hero_value:Variant=legacy.get("hero")
	if not hero_value is Dictionary:
		return
	var result:Dictionary=EquipmentSystem.equip_from_inventory(hero_value,item_name)
	if bool(result.get("ok",false)):
		legacy.call("log_message","Equipped %s in %s. The 3D character visual will update automatically." % [result["item"],EquipmentSystem.SLOT_LABELS[result["slot"]]])
		legacy.call("save_game")
		legacy.call("update_ui")
		_refresh()
	else:
		legacy.call("log_message",str(result.get("error","Unable to equip item.")))

func _unequip(slot:String)->void:
	if legacy==null:
		return
	var hero_value:Variant=legacy.get("hero")
	if not hero_value is Dictionary:
		return
	var result:Dictionary=EquipmentSystem.unequip_to_inventory(hero_value,slot)
	if bool(result.get("ok",false)):
		legacy.call("log_message","Unequipped %s. It was returned to inventory." % result["item"])
		legacy.call("save_game")
		legacy.call("update_ui")
		_refresh()
	else:
		legacy.call("log_message",str(result.get("error","Unable to unequip item.")))
