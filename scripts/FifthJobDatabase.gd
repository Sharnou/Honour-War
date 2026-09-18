class_name FifthJobDatabase
extends RefCounted

## Canonical Lv200 Fifth Job content.
## These are difficult endgame drops from Lv280-300 top monsters/MVPs.

const FIFTH_JOBS:Dictionary={
	"Warrior":{"job":"War Emperor","identity":"Supreme weapon master","weapon":"War Emperor Blade"},
	"Mage":{"job":"Arcane Sovereign","identity":"Supreme arcane caster","weapon":"Astral Sovereign Staff"},
	"Archer":{"job":"Celestial Ranger","identity":"Supreme precision ranger","weapon":"Celestial Longbow"},
	"Thief":{"job":"Shadow Emperor","identity":"Supreme assassin","weapon":"Eternal Assassin Blade"},
	"Acolyte":{"job":"Divine Saint","identity":"Supreme holy champion","weapon":"Heaven Gate Mace"},
	"Merchant":{"job":"Forge Overlord","identity":"Supreme arsenal master","weapon":"Arsenal Overlord Hammer"}
}

static func profile(class_id:String)->Dictionary:
	return FIFTH_JOBS.get(class_id,FIFTH_JOBS["Warrior"])

static func all_profiles()->Dictionary:
	return FIFTH_JOBS.duplicate(true)

static func equipment(class_id:String)->Dictionary:
	var p:Dictionary=profile(class_id)
	var job:String=str(p["job"])
	var weapon:String=str(p["weapon"])
	var root:String=job.replace(" ","")
	var weapon_stats:Dictionary={"attack":420,"magic":0,"crit":18,"healing":0,"defense":0,"boss_damage_percent":20.0,"damage_percent":12.0}
	match class_id:
		"Warrior": weapon_stats={"attack":480,"magic":0,"crit":20,"healing":0,"defense":20,"boss_damage_percent":24.0,"damage_percent":16.0}
		"Mage": weapon_stats={"attack":300,"magic":520,"crit":12,"healing":0,"defense":0,"boss_damage_percent":24.0,"damage_percent":14.0}
		"Archer": weapon_stats={"attack":450,"magic":0,"crit":38,"healing":0,"defense":0,"boss_damage_percent":26.0,"damage_percent":15.0}
		"Thief": weapon_stats={"attack":500,"magic":0,"crit":48,"healing":0,"defense":0,"boss_damage_percent":28.0,"damage_percent":20.0}
		"Acolyte": weapon_stats={"attack":340,"magic":300,"crit":10,"healing":150,"defense":20,"boss_damage_percent":24.0,"damage_percent":14.0}
		"Merchant": weapon_stats={"attack":430,"magic":0,"crit":16,"healing":0,"defense":70,"boss_damage_percent":25.0,"damage_percent":15.0}
	return {
		"weapon":{"name":weapon,"slot":"weapon","rarity":"Mythic","attack":int(weapon_stats["attack"]),"magic":int(weapon_stats["magic"]),"crit":int(weapon_stats["crit"]),"healing":int(weapon_stats["healing"]),"defense":int(weapon_stats["defense"]),"boss_damage_percent":float(weapon_stats["boss_damage_percent"]),"damage_percent":float(weapon_stats["damage_percent"]),"card_slots":4,"refine_cap":15,"drop_rate_percent":0.025},
		"shield":{"name":root+" Aegis","slot":"shield","rarity":"Mythic","defense":260,"hp":1200,"card_slots":4,"refine_cap":15,"drop_rate_percent":0.020},
		"head_upper":{"name":root+" Crown","slot":"head_upper","rarity":"Mythic","defense":120,"hp":700,"card_slots":4,"refine_cap":15,"drop_rate_percent":0.018},
		"head_middle":{"name":root+" Vision","slot":"head_middle","rarity":"Mythic","defense":55,"crit":12,"card_slots":4,"refine_cap":15,"drop_rate_percent":0.016},
		"head_lower":{"name":root+" Mantle Seal","slot":"head_lower","rarity":"Mythic","defense":30,"hp":350,"card_slots":4,"refine_cap":15,"drop_rate_percent":0.016},
		"armor":{"name":root+" Armor","slot":"armor","rarity":"Mythic","defense":340,"hp":1100,"card_slots":4,"refine_cap":15,"drop_rate_percent":0.020},
		"garment":{"name":root+" Garment","slot":"garment","rarity":"Mythic","defense":150,"hp":850,"move_percent":14.0,"card_slots":4,"refine_cap":15,"drop_rate_percent":0.018},
		"shoes":{"name":root+" Greaves","slot":"shoes","rarity":"Mythic","defense":85,"hp":500,"move_percent":12.0,"card_slots":4,"refine_cap":15,"drop_rate_percent":0.018},
		"accessory_1":{"name":root+" Seal Ring","slot":"accessory_1","rarity":"Mythic","crit":12,"hp":450,"card_slots":4,"refine_cap":15,"drop_rate_percent":0.014},
		"accessory_2":{"name":root+" Sovereign Charm","slot":"accessory_2","rarity":"Mythic","damage_percent":12.0,"boss_damage_percent":15.0,"card_slots":4,"refine_cap":15,"drop_rate_percent":0.012}
	}

static func top_cards(class_id:String)->Array:
	var p:Dictionary=profile(class_id)
	var job:String=str(p["job"])
	return [
		{"name":job+" Card","job":job,"rarity":"Mythic","slot":"Weapon","power":180,"damage_percent":25.0,"boss_damage_percent":20.0,"drop_rate_percent":0.008},
		{"name":job+" Sovereign Card","job":job,"rarity":"Mythic","slot":"Armor","power":160,"hp_percent":25.0,"defense":60,"drop_rate_percent":0.005},
		{"name":job+" Emperor Card","job":job,"rarity":"Mythic","slot":"Accessory","power":220,"damage_percent":30.0,"boss_damage_percent":30.0,"all_rewards_percent":8.0,"drop_rate_percent":0.0025}
	]

static func all_equipment()->Array:
	var result:Array=[]
	for class_id in FIFTH_JOBS.keys():
		for item in equipment(str(class_id)).values():
			var entry:Dictionary=item.duplicate(true)
			entry["class"]=str(class_id)
			result.append(entry)
	return result

static func all_cards()->Array:
	var result:Array=[]
	for class_id in FIFTH_JOBS.keys():
		result.append_array(top_cards(str(class_id)))
	return result

static func is_top_monster(monster:Dictionary)->bool:
	return bool(monster.get("mvp",false)) or int(monster.get("level",1))>=280

static func drop_table(monster:Dictionary,class_id:String)->Dictionary:
	if not is_top_monster(monster):
		return {"eligible":false,"class":class_id,"job":str(profile(class_id)["job"]),"items":[],"cards":[]}
	var items:Array=[]
	for item in equipment(class_id).values():
		items.append({"name":item["name"],"slot":item["slot"],"drop_rate_percent":float(item["drop_rate_percent"])})
	var cards:Array=[]
	for card in top_cards(class_id):
		cards.append({"name":card["name"],"slot":card["slot"],"drop_rate_percent":float(card["drop_rate_percent"])})
	return {"eligible":true,"class":class_id,"job":str(profile(class_id)["job"]),"items":items,"cards":cards,"note":"Extremely rare Lv280-300/MVP endgame loot."}
