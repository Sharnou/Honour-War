class_name GameData
extends RefCounted

const MAX_HERO_LEVEL := 250
const MAX_MONSTER_LEVEL := 300
const STARTING_AGE := 18
const AGE_DAYS_PER_YEAR := 3.0

static func class_definitions() -> Dictionary:
	return {
		"Warrior": {"weapon":"Sword", "basic_skill":"Power Slash", "base_power":18, "tree":["Swordsman", "Knight", "Lord Knight", "Transcendent Knight", "War Emperor"]},
		"Mage": {"weapon":"Staff", "basic_skill":"Arcane Spark", "base_power":23, "tree":["Mage", "Wizard", "High Wizard", "Transcendent Wizard", "Arcane Sovereign"]},
		"Archer": {"weapon":"Bow", "basic_skill":"Celestial Arrow", "base_power":20, "tree":["Archer", "Hunter", "Sniper", "Transcendent Ranger", "Celestial Ranger"]},
		"Thief": {"weapon":"Dagger", "basic_skill":"Shadow Strike", "base_power":19, "tree":["Thief", "Assassin", "Assassin Cross", "Transcendent Assassin", "Shadow Emperor"]},
		"Acolyte": {"weapon":"Mace", "basic_skill":"Holy Pulse", "base_power":15, "tree":["Acolyte", "Priest", "High Priest", "Transcendent Saint", "Divine Saint"]},
		"Merchant": {"weapon":"Hammer", "basic_skill":"Forge Smash", "base_power":17, "tree":["Merchant", "Blacksmith", "Mastersmith", "Transcendent Forge Master", "Forge Overlord"]}
	}

static func cities() -> Array:
	return ["Prontera", "Morroc", "Payon", "Geffen", "Juno", "Alberta", "Izlude"]

static func monster_families() -> Array:
	return ["Poring", "Goblin", "Wolf", "Skeleton", "Zombie", "Orc", "Mantis", "Golem", "Evil Druid", "Dragon"]

static func material_definitions() -> Dictionary:
	return {
		"Phracon": {"cost":100, "min_refine":0, "max_refine":4},
		"Emveretarcon": {"cost":350, "min_refine":5, "max_refine":8},
		"Oridecon": {"cost":1000, "min_refine":9, "max_refine":15}
	}

static func new_hero() -> Dictionary:
	return {
		"name":"Aldric", "class":"Warrior", "class_tier":0, "level":1, "exp":0,
		"age":18, "online_days":0.0, "hp":100, "max_hp":100, "sp":50, "max_sp":50,
		"zeny":500, "refine":0, "kills":0, "quest_progress":{}, "quests_completed":[],
		"inventory":{}, "materials":{"Phracon":5, "Emveretarcon":2, "Oridecon":0},
		"equipment":{"weapon":"Novice Weapon", "armor":"Novice Armor"},
		"cards":[], "skills":[], "city_building":{"Prontera":{"level":1, "wood":0, "stone":0, "gold":0}},
		"last_safe_city":"Prontera", "pos_x":270.0, "pos_y":330.0
	}

static func exp_to_next(level:int) -> int:
	return max(100, level * 100)

static func age_bonus(age:int) -> int:
	return min(35, max(0, int((age - STARTING_AGE) / 4)))

static func class_tier_for_level(level:int) -> int:
	if level >= 200: return 4
	if level >= 150: return 3
	if level >= 100: return 2
	if level >= 50: return 1
	return 0

static func class_title(hero:Dictionary) -> String:
	var defs=class_definitions()
	var class_name=str(hero.get("class", "Warrior"))
	var tree:Array=defs[class_name]["tree"]
	return tree[min(int(hero.get("class_tier", 0)), tree.size() - 1)]
