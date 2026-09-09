class_name EquipmentProgressionSystem
extends RefCounted

## Runtime adapter for the existing ItemDatabase.
## Equipment remains fully data-driven and card sockets contribute live stats.

const MAX_REFINE:int = 15
const MAX_CARD_SLOTS:int = 4
const CARD_DATABASE=preload("res://scripts/CardDatabase.gd")

static func normalize_item(item:Dictionary)->Dictionary:
	var result:Dictionary=item.duplicate(true)
	result["refine"]=clamp(int(result.get("refine",0)),0,MAX_REFINE)
	result["cards"]=result.get("cards",[])
	if not result["cards"] is Array: result["cards"]=[]
	return result

static func refined_bonus(item:Dictionary)->Dictionary:
	var result:Dictionary={"atk":0,"matk":0,"def":0}
	var refine:int=clamp(int(item.get("refine",0)),0,MAX_REFINE)
	var kind:String=str(item.get("type",""))
	if kind=="Weapon":
		var attack:int=int(item.get("attack",0)); var magic:int=int(item.get("magic",0))
		result["atk"]=int(round(float(attack)*0.025*refine))+refine*2
		result["matk"]=int(round(float(magic)*0.025*refine))+refine*2
	elif kind in ["Armor","Accessory"]:
		var defense:int=int(item.get("defense",0))
		result["def"]=int(round(float(defense)*0.025*refine))+refine
	return result

static func _card_effect(card_id:String)->Dictionary:
	return CARD_DATABASE.all().get(card_id,{})

static func _apply_card(total:Dictionary,card_id:String)->void:
	var data:Dictionary=_card_effect(card_id)
	total["hp"]+=int(data.get("hp",0))
	total["def"]+=int(data.get("defense",0))
	total["crit"]+=int(data.get("crit",0))
	total["evasion"]+=int(data.get("evasion",0))
	total["healing"]+=int(data.get("healing",0))
	for key in ["move_percent","fire_percent","wind_percent","dark_percent","ice_resist_percent","boss_damage_percent","all_rewards_percent","damage_percent","xp_percent","item_drop_percent","attack_speed_percent","magic_resist_percent","crit_damage_percent"]:
		total[key]+=float(data.get(key,0.0))
	total["poison_resist"]+=int(data.get("poison_resist",0))
	total["power_bonus"]+=int(data.get("power",0))

static func total_stats(equipment:Dictionary)->Dictionary:
	var total:Dictionary={"atk":0,"matk":0,"def":0,"mdef":0,"hp":0,"sp":0,"crit":0,"evasion":0,"hit":0,"flee":0,"healing":0,"move_percent":0.0,"fire_percent":0.0,"wind_percent":0.0,"dark_percent":0.0,"ice_resist_percent":0.0,"boss_damage_percent":0.0,"all_rewards_percent":0.0,"damage_percent":0.0,"xp_percent":0.0,"item_drop_percent":0.0,"attack_speed_percent":0.0,"magic_resist_percent":0.0,"crit_damage_percent":0.0,"poison_resist":0,"power_bonus":0}
	for slot in equipment.keys():
		var raw:Variant=equipment[slot]
		if not raw is Dictionary: continue
		var item:Dictionary=normalize_item(raw)
		total["atk"]+=int(item.get("attack",0)); total["matk"]+=int(item.get("magic",0)); total["def"]+=int(item.get("defense",0))
		for key in ["hp","sp","crit","evasion","hit","flee","healing"]: total[key]+=int(item.get(key,0))
		for key in ["move_percent","fire_percent","wind_percent","dark_percent","ice_resist_percent","boss_damage_percent","all_rewards_percent","damage_percent","xp_percent","item_drop_percent","attack_speed_percent","magic_resist_percent","crit_damage_percent"]: total[key]+=float(item.get(key,0.0))
		var rb:Dictionary=refined_bonus(item)
		total["atk"]+=int(rb["atk"]); total["matk"]+=int(rb["matk"]); total["def"]+=int(rb["def"])
		for card_id in item["cards"]:
			_apply_card(total,str(card_id))
	return total

static func refine_chance(current:int)->float:
	var target:int=current+1
	if target<=1: return 1.0
	if target<=5: return 0.90-float(target-2)*0.05
	if target<=10: return 0.72-float(target-6)*0.08
	if target<=15: return 0.38-float(target-11)*0.065
	return 0.0

static func attempt_refine(item:Dictionary,roll:float)->Dictionary:
	var normalized:Dictionary=normalize_item(item)
	var current:int=int(normalized["refine"])
	var cap:int=clamp(int(normalized.get("refine_cap",MAX_REFINE)),1,MAX_REFINE)
	if current>=cap: return {"ok":false,"success":false,"reason":"cap","refine":current,"chance":0.0}
	var chance:float=refine_chance(current)
	var success:bool=clamp(roll,0.0,0.999999)<chance
	if success: normalized["refine"]=current+1
	elif current>=10: normalized["refine"]=max(0,current-1)
	return {"ok":true,"success":success,"item":normalized,"refine":int(normalized["refine"]),"chance":chance}

static func card_capacity(item:Dictionary)->int:
	return clamp(int(item.get("card_slots",0)),0,MAX_CARD_SLOTS)

static func _card_compatible(item:Dictionary,card_id:String)->bool:
	var card:Dictionary=_card_effect(card_id)
	var required:String=str(card.get("slot",""))
	if required=="": return true
	var type:String=str(item.get("type",""))
	var slot:String=str(item.get("slot",""))
	if required=="Weapon": return type=="Weapon"
	if required=="Accessory": return type=="Accessory" or slot in ["accessory_1","accessory_2"]
	if required=="Armor": return type=="Armor" and slot not in ["head_upper","head_middle","head_lower"]
	if required=="Headgear": return slot in ["head_upper","head_middle","head_lower"]
	return true

static func insert_card(item:Dictionary,card_id:String)->Dictionary:
	var normalized:Dictionary=normalize_item(item)
	if not CARD_DATABASE.all().has(card_id): return {"ok":false,"reason":"unknown_card","item":normalized}
	if not _card_compatible(normalized,card_id): return {"ok":false,"reason":"incompatible_card","item":normalized}
	var cards:Array=normalized["cards"]
	if cards.size()>=card_capacity(normalized): return {"ok":false,"reason":"no_slots","item":normalized}
	if cards.has(card_id): return {"ok":false,"reason":"duplicate_card","item":normalized}
	cards.append(card_id); normalized["cards"]=cards
	return {"ok":true,"item":normalized,"card":card_id}
