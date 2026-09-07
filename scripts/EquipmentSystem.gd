class_name EquipmentSystem
extends RefCounted

const MAX_CARD_SLOTS := 4
const SLOTS := [
	"weapon",
	"shield",
	"head_upper",
	"head_middle",
	"head_lower",
	"armor",
	"garment",
	"shoes",
	"accessory_1",
	"accessory_2"
]

const SLOT_LABELS := {
	"weapon":"Weapon",
	"shield":"Shield",
	"head_upper":"Upper Headgear",
	"head_middle":"Middle Headgear",
	"head_lower":"Lower Headgear",
	"armor":"Armor",
	"garment":"Garment",
	"shoes":"Shoes",
	"accessory_1":"Accessory 1",
	"accessory_2":"Accessory 2"
}

static func ensure_state(hero:Dictionary)->void:
	if not hero.has("equipment") or not hero["equipment"] is Dictionary:
		hero["equipment"]={}
	var equipment:Dictionary=hero["equipment"]
	if not equipment.has("weapon"): equipment["weapon"]="Novice Sword"
	if not equipment.has("armor"): equipment["armor"]="Novice Armor"
	for slot in ["shield","head_upper","head_middle","head_lower","garment","shoes","accessory_1","accessory_2"]:
		if not equipment.has(slot): equipment[slot]=""
	hero["equipment"]=equipment
	if not hero.has("equipment_cards") or not hero["equipment_cards"] is Dictionary:
		hero["equipment_cards"]={}
	var cards:Dictionary=hero["equipment_cards"]
	for slot in SLOTS:
		if not cards.has(slot): cards[slot]=[]
	hero["equipment_cards"]=cards

static func item_slot(item_name:String)->String:
	var data:Dictionary=ItemDatabase.all().get(item_name,{})
	return str(data.get("slot",""))

static func item_card_slots(item_name:String)->int:
	var data:Dictionary=ItemDatabase.all().get(item_name,{})
	return clamp(int(data.get("card_slots",0)),0,MAX_CARD_SLOTS)

static func can_equip(item_name:String,slot:String)->bool:
	if item_name=="" or not ItemDatabase.all().has(item_name): return false
	return item_slot(item_name)==slot

static func equip(hero:Dictionary,item_name:String)->bool:
	ensure_state(hero)
	if not ItemDatabase.all().has(item_name): return false
	var slot:=item_slot(item_name)
	if slot=="" or not SLOTS.has(slot): return false
	hero["equipment"][slot]=item_name
	return true

static func add_card_to_slot(hero:Dictionary,slot:String,card_name:String)->bool:
	ensure_state(hero)
	if not SLOTS.has(slot) or not CardDatabase.all().has(card_name): return false
	var item_name:=str(hero["equipment"].get(slot,""))
	var capacity:=item_card_slots(item_name)
	if capacity<=0: return false
	var cards:Array=hero["equipment_cards"].get(slot,[])
	if cards.size()>=capacity or cards.has(card_name): return false
	var allowed_slot:=str(CardDatabase.all()[card_name].get("slot",""))
	if allowed_slot!="" and allowed_slot!=slot_family(slot): return false
	cards.append(card_name)
	hero["equipment_cards"][slot]=cards
	return true

static func slot_family(slot:String)->String:
	match slot:
		"weapon": return "Weapon"
		"armor","garment","shoes","shield": return "Armor"
		"head_upper","head_middle","head_lower": return "Headgear"
		"accessory_1","accessory_2": return "Accessory"
	return ""

static func combat_stats(hero:Dictionary)->Dictionary:
	ensure_state(hero)
	var result:Dictionary={"attack":0,"magic":0,"defense":0,"hp":0,"sp":0,"crit":0,"evasion":0,"healing":0,"damage_percent":0.0,"boss_damage_percent":0.0,"item_drop_percent":0.0,"xp_percent":0.0,"move_percent":0.0,"fire_percent":0.0,"ice_resist_percent":0.0,"wind_percent":0.0,"dark_percent":0.0,"all_rewards_percent":0.0,"poison_resist":0}
	for slot in SLOTS:
		var item_name:=str(hero["equipment"].get(slot,""))
		if item_name=="": continue
		var data:Dictionary=ItemDatabase.all().get(item_name,{})
		for key in ["attack","magic","defense","hp","sp","crit","evasion","healing"]:
			result[key]+=int(data.get(key,0))
		result["damage_percent"]+=float(data.get("damage_percent",0.0))
		result["boss_damage_percent"]+=float(data.get("boss_damage_percent",0.0))
		result["item_drop_percent"]+=float(data.get("item_drop_percent",0.0))
		result["xp_percent"]+=float(data.get("xp_percent",0.0))
		result["move_percent"]+=float(data.get("move_percent",0.0))
		result["fire_percent"]+=float(data.get("fire_percent",0.0))
		result["ice_resist_percent"]+=float(data.get("ice_resist_percent",0.0))
		result["wind_percent"]+=float(data.get("wind_percent",0.0))
		result["dark_percent"]+=float(data.get("dark_percent",0.0))
		result["all_rewards_percent"]+=float(data.get("all_rewards_percent",0.0))
		result["poison_resist"]+=int(data.get("poison_resist",0))
		var refine:=int(hero.get("refine",0)) if slot=="weapon" else 0
		result["attack"]+=refine*3
		result["defense"]+=refine*2 if slot!="weapon" else 0
		for card_name in hero["equipment_cards"].get(slot,[]):
			CardDatabase.apply_effect(result,str(card_name),hero,slot)
	return result

static func summary(hero:Dictionary)->String:
	ensure_state(hero)
	var lines:Array[String]=[]
	for slot in SLOTS:
		var item:=str(hero["equipment"].get(slot,""))
		if item=="": item="Empty"
		var capacity:=item_card_slots(item)
		var count:=hero["equipment_cards"].get(slot,[]).size()
		lines.append("%s: %s [%d/%d cards]" % [SLOT_LABELS[slot],item,count,capacity])
	return "\n".join(lines)
