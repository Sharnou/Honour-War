class_name CharacterInventorySystem
extends RefCounted

const Equipment=preload("res://scripts/EquipmentProgressionSystem.gd")
const Character=preload("res://scripts/CharacterProgressionSystem.gd")
const Save=preload("res://scripts/SaveSystem.gd")

const EQUIPMENT_SLOTS:Array[String]=["weapon","armor","head","head_middle","head_lower","garment","shoes","offhand","accessory_1","accessory_2"]
const CONSUMABLE_TYPES:Array[String]=["Consumable"]

static func ensure_state(hero:Dictionary)->void:
	if not hero.has("inventory") or not hero["inventory"] is Dictionary: hero["inventory"]={}
	if not hero.has("equipment") or not hero["equipment"] is Dictionary: hero["equipment"]={}
	if not hero.has("equipment_refine") or not hero["equipment_refine"] is Dictionary: hero["equipment_refine"]={}
	if not hero.has("cards") or not hero["cards"] is Array: hero["cards"]=[]
	if not hero.has("hp"): hero["hp"]=100
	if not hero.has("sp"): hero["sp"]=40

static func _catalog()->Dictionary:
	return ItemDatabase.all()

static func _count(hero:Dictionary,item_id:String)->int:
	var value:Variant=hero["inventory"].get(item_id,0)
	return int(value.get("amount",0)) if value is Dictionary else int(value)

static func _set_count(hero:Dictionary,item_id:String,count:int)->void:
	if count<=0: hero["inventory"].erase(item_id)
	else: hero["inventory"][item_id]=count

static func _auto_save(hero:Dictionary)->void:
	Save.save_game(hero)

static func add_item(hero:Dictionary,item_id:String,amount:int=1)->bool:
	ensure_state(hero)
	if amount<=0 or not _catalog().has(item_id): return false
	_set_count(hero,item_id,_count(hero,item_id)+amount)
	return true

static func remove_item(hero:Dictionary,item_id:String,amount:int=1)->bool:
	ensure_state(hero)
	if amount<=0 or _count(hero,item_id)<amount: return false
	_set_count(hero,item_id,_count(hero,item_id)-amount)
	return true

static func equip(hero:Dictionary,item_id:String)->Dictionary:
	ensure_state(hero)
	if not _catalog().has(item_id): return {"ok":false,"reason":"unknown_item"}
	if _count(hero,item_id)<=0: return {"ok":false,"reason":"not_in_inventory"}
	var item:Dictionary=Equipment.normalize_item(_catalog()[item_id])
	var type:String=str(item.get("type","")); var slot:String=str(item.get("slot","")).to_lower()
	if type not in ["Weapon","Armor","Accessory"]: return {"ok":false,"reason":"not_equipment"}
	if slot=="":
		if type=="Weapon": slot="weapon"
		elif type=="Accessory": slot="accessory_1"
		else: slot="armor"
	var slot_map:Dictionary={"shield":"offhand","head_upper":"head","head_middle":"head_middle","head_lower":"head_lower","accessory_1":"accessory_1","accessory_2":"accessory_2"}
	if slot_map.has(slot): slot=str(slot_map[slot])
	if not EQUIPMENT_SLOTS.has(slot): return {"ok":false,"reason":"invalid_slot"}
	var old:Variant=hero["equipment"].get(slot,null)
	if old is Dictionary: add_item(hero,str(old.get("id",old.get("name",item_id))),1)
	elif old is String and str(old)!="": add_item(hero,str(old),1)
	remove_item(hero,item_id,1)
	item["id"]=item_id
	hero["equipment"][slot]=item
	hero["equipment_refine"][slot]=int(item.get("refine",0))
	Character.ensure_state(hero)
	var stats:Dictionary=Character.stats(hero)
	_auto_save(hero)
	return {"ok":true,"slot":slot,"item":item,"old":old,"stats":stats}

static func unequip(hero:Dictionary,slot:String)->Dictionary:
	ensure_state(hero); slot=slot.to_lower()
	if not hero["equipment"].has(slot): return {"ok":false,"reason":"empty_slot"}
	var old:Variant=hero["equipment"][slot]
	var id:String=str(old.get("id",old.get("name",""))) if old is Dictionary else str(old)
	if id!="": add_item(hero,id,1)
	hero["equipment"].erase(slot); hero["equipment_refine"].erase(slot)
	var stats:Dictionary=Character.stats(hero)
	_auto_save(hero)
	return {"ok":true,"slot":slot,"item":old,"stats":stats}

static func use_consumable(hero:Dictionary,item_id:String)->Dictionary:
	ensure_state(hero)
	if not _catalog().has(item_id) or _count(hero,item_id)<=0: return {"ok":false,"reason":"not_available"}
	var item:Dictionary=_catalog()[item_id]
	if str(item.get("type","")) not in CONSUMABLE_TYPES: return {"ok":false,"reason":"not_consumable"}
	remove_item(hero,item_id,1)
	var max_stats:Dictionary=Character.stats(hero)
	var hp_gain:int=int(item.get("hp",item.get("healing",0))); var sp_gain:int=int(item.get("sp",0))
	hero["hp"]=min(int(max_stats["max_hp"]),int(hero.get("hp",max_stats["max_hp"]))+hp_gain)
	hero["sp"]=min(int(max_stats["max_sp"]),int(hero.get("sp",max_stats["max_sp"]))+sp_gain)
	_auto_save(hero)
	return {"ok":true,"item":item_id,"hp":int(hero["hp"]),"sp":int(hero["sp"]),"hp_gain":hp_gain,"sp_gain":sp_gain}

static func refine(hero:Dictionary,slot:String,roll:float)->Dictionary:
	ensure_state(hero); slot=slot.to_lower()
	if not hero["equipment"].has(slot): return {"ok":false,"reason":"empty_slot"}
	var item:Dictionary=hero["equipment"][slot]
	var current:int=int(item.get("refine",hero["equipment_refine"].get(slot,0)))
	var material:String="Oridecon" if current>=5 else "Phracon"
	if not _catalog().has(material): return {"ok":false,"reason":"no_refine_material_catalogue"}
	if _count(hero,material)<=0: return {"ok":false,"reason":"missing_material","material":material}
	var result:Dictionary=Equipment.attempt_refine(item,roll)
	if not bool(result.get("ok",false)): return result
	remove_item(hero,material,1)
	var refined:Dictionary=result["item"]
	hero["equipment"][slot]=refined; hero["equipment_refine"][slot]=int(refined["refine"])
	result["slot"]=slot; result["material"]=material; result["stats"]=Character.stats(hero)
	_auto_save(hero)
	return result

static func insert_card(hero:Dictionary,slot:String,card_id:String)->Dictionary:
	ensure_state(hero); slot=slot.to_lower()
	if not hero["equipment"].has(slot): return {"ok":false,"reason":"empty_slot"}
	if not hero["cards"].has(card_id): return {"ok":false,"reason":"card_not_owned"}
	var result:Dictionary=Equipment.insert_card(hero["equipment"][slot],card_id)
	if not bool(result.get("ok",false)): return result
	hero["equipment"][slot]=result["item"]; hero["cards"].erase(card_id)
	result["ok"]=true; result["slot"]=slot; result["card"]=card_id; result["stats"]=Character.stats(hero)
	_auto_save(hero)
	return result

static func snapshot(hero:Dictionary)->Dictionary:
	ensure_state(hero)
	return {"inventory":hero["inventory"].duplicate(true),"equipment":hero["equipment"].duplicate(true),"cards":hero["cards"].duplicate(true),"stats":Character.stats(hero),"hp":int(hero.get("hp",0)),"sp":int(hero.get("sp",0)),"zeny":int(hero.get("zeny",0))}

static func save(hero:Dictionary)->bool:
	ensure_state(hero); return Save.save_game(hero)
