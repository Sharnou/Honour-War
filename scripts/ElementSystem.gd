class_name ElementSystem
extends RefCounted

## Honour War elemental combat and crafting contract.
## Only the ten documented elements and the explicitly named catalysts are valid.
## No fallback or unknown material is ever created.

const ELEMENTS:Array[String]=["Neutral","Fire","Water","Earth","Wind","Holy","Shadow","Undead","Poison","Ghost"]
const CONVERTER_DURATION:float=1200.0

static func material_catalogue()->Dictionary:
	return {
		"Fire":{"catalyst":"Flame Heart","alternate":"Red Blood","converter":"Fire Converter"},
		"Water":{"catalyst":"Mystic Frozen","alternate":"Crystal Blue","converter":"Water Converter"},
		"Earth":{"catalyst":"Great Nature","alternate":"Green Live","converter":"Earth Converter"},
		"Wind":{"catalyst":"Rough Wind","alternate":"Wind of Verdure","converter":"Wind Converter"},
		"Holy":{"catalyst":"Holy Water","alternate":"Aqua Benedicta","converter":"Holy Converter"},
		"Shadow":{"catalyst":"Cursed Water","alternate":"Cursed Water","converter":"Shadow Converter"}
	}

static func is_valid(element:String)->bool:
	return ELEMENTS.has(element)

static func normalize(element:String)->String:
	return element if is_valid(element) else "Neutral"

static func weakness(element:String)->String:
	match normalize(element):
		"Fire": return "Water"
		"Water": return "Wind"
		"Earth": return "Fire"
		"Wind": return "Earth"
		"Holy": return "Shadow"
		"Shadow": return "Holy"
		"Undead": return "Holy"
		"Poison": return "Fire"
		"Ghost": return "Ghost"
		_: return "Neutral"

static func attack_multiplier(attack_element:String,defense_element:String)->float:
	var attack:String=normalize(attack_element)
	var defense:String=normalize(defense_element)
	if attack=="Neutral" or defense=="Neutral": return 1.0
	if attack==defense:
		return 0.90
	if weakness(defense)==attack:
		return 1.25
	if defense=="Ghost" and attack=="Neutral": return 0.0
	if defense=="Undead" and attack=="Holy": return 1.40
	if attack=="Shadow" and defense=="Holy": return 1.30
	return 1.0

static func skill_element(class_id:String,skill_id:String)->String:
	var skill:String=skill_id.to_lower()
	if class_id=="Mage":
		if skill.contains("frost") or skill.contains("ice"): return "Water"
		if skill.contains("meteor") or skill.contains("comet") or skill.contains("fire"): return "Fire"
		if skill.contains("thunder") or skill.contains("lightning"): return "Wind"
		if skill.contains("void") or skill.contains("dark"): return "Shadow"
		return "Neutral"
	if class_id=="Archer":
		if skill.contains("holy") or skill.contains("silver"): return "Holy"
		if skill.contains("trap") or skill.contains("storm"): return "Wind"
		return "Neutral"
	if class_id=="Thief": return "Shadow"
	if class_id=="Acolyte": return "Holy"
	if class_id=="Merchant":
		if skill.contains("magma") or skill.contains("fire"): return "Fire"
		return "Neutral"
	return "Neutral"

static func weapon_element(hero:Dictionary)->String:
	var explicit:String=str(hero.get("weapon_element","Neutral"))
	if is_valid(explicit): return explicit
	var equipment:Variant=hero.get("equipment",{})
	if equipment is Dictionary:
		var weapon:Variant=equipment.get("weapon",{})
		if weapon is Dictionary:
			return normalize(str(weapon.get("element","Neutral")))
	return "Neutral"

static func set_weapon_element(hero:Dictionary,element:String,duration:float=CONVERTER_DURATION)->Dictionary:
	if not is_valid(element) or element in ["Poison","Ghost","Undead"]:
		return {"ok":false,"reason":"invalid_converter_element","element":element}
	hero["weapon_element"]=element
	hero["weapon_element_until"]=float(Time.get_ticks_msec())/1000.0+duration
	return {"ok":true,"element":element,"expires_in":duration}

static func active_weapon_element(hero:Dictionary)->String:
	var now:float=float(Time.get_ticks_msec())/1000.0
	var element:String=weapon_element(hero)
	if element!="Neutral" and float(hero.get("weapon_element_until",0.0))>now: return element
	if element!="Neutral" and not hero.has("weapon_element_until"): return element
	return "Neutral"

static func converter_item(element:String)->String:
	var data:Dictionary=material_catalogue().get(element,{})
	return str(data.get("converter",""))

static func catalyst_for(element:String)->String:
	var data:Dictionary=material_catalogue().get(element,{})
	return str(data.get("catalyst",""))

static func validate_material(material:String)->bool:
	for element in material_catalogue().keys():
		var data:Dictionary=material_catalogue()[element]
		if material==str(data.get("catalyst","")) or material==str(data.get("alternate","")): return true
	return material in ["Holy Water","Cursed Water"]

static func craft_converter(hero:Dictionary,element:String,quantity:int=1)->Dictionary:
	if quantity<=0 or not material_catalogue().has(element):
		return {"ok":false,"reason":"unknown_element"}
	var catalyst:String=catalyst_for(element)
	if catalyst=="" or not validate_material(catalyst):
		return {"ok":false,"reason":"unknown_material"}
	if not hero.has("inventory") or not hero["inventory"] is Dictionary: hero["inventory"]={}
	var inventory:Dictionary=hero["inventory"]
	var available:int=int(inventory.get(catalyst,0))
	if available<quantity:
		return {"ok":false,"reason":"missing_catalyst","material":catalyst,"required":quantity,"available":available}
	inventory[catalyst]=available-quantity
	var converter:String=converter_item(element)
	inventory[converter]=int(inventory.get(converter,0))+quantity
	return {"ok":true,"element":element,"material":catalyst,"converter":converter,"quantity":quantity,"duration_seconds":CONVERTER_DURATION}

static func apply_converter(hero:Dictionary,element:String)->Dictionary:
	var converter:String=converter_item(element)
	if converter=="": return {"ok":false,"reason":"unknown_element"}
	if not hero.has("inventory") or not hero["inventory"] is Dictionary: return {"ok":false,"reason":"no_inventory"}
	var inventory:Dictionary=hero["inventory"]
	if int(inventory.get(converter,0))<=0: return {"ok":false,"reason":"converter_not_owned","converter":converter}
	inventory[converter]=int(inventory[converter])-1
	return set_weapon_element(hero,element)

static func damage(hero:Dictionary,monster:Dictionary,base_damage:int,skill_id:String="")->Dictionary:
	var class_id:String=str(hero.get("class","Warrior"))
	var attack_element:String=weapon_element(hero)
	if skill_id!="":
		var skill_element_id:String=skill_element(class_id,skill_id)
		if skill_element_id!="Neutral": attack_element=skill_element_id
	var defense_element:String=normalize(str(monster.get("element","Neutral")))
	var multiplier:float=attack_multiplier(attack_element,defense_element)
	return {"damage":max(0,int(round(float(base_damage)*multiplier))),"attack_element":attack_element,"defense_element":defense_element,"multiplier":multiplier}
