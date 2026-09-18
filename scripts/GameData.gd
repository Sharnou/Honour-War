class_name GameData
extends RefCounted

const PetSystemClass = preload("res://scripts/PetSystem.gd")

const MAX_HERO_LEVEL:int = 250
const MAX_MONSTER_LEVEL:int = 300
const STARTING_AGE:int = 18
const AGE_DAYS_PER_YEAR:float = 3.0

# Honour War class progression:
# Lv 1  = Foundation
# Lv 25 = Specialization
# Lv 50 = Advanced
# Lv 100 = Mastery
# Lv 200 = Transcendence
# Lv 250 = level cap
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
	return ["Poring", "Goblin", "Wolf", "Skeleton", "Zombie", "Orc", "Mantis", "Golem", "Evil Druid", "Dragon", "Bloody Knight"]

static func material_definitions() -> Dictionary:
	return {
		"Phracon": {"cost":100, "min_refine":0, "max_refine":4},
		"Emveretarcon": {"cost":350, "min_refine":5, "max_refine":8},
		"Oridecon": {"cost":1000, "min_refine":9, "max_refine":15}
	}

static func new_hero() -> Dictionary:
	var hero_class:String = "Warrior"
	return {
		"name":"Aldric", "class":hero_class, "class_tier":0, "class_branch":"", "class_mastery":0, "level":1, "exp":0,
		"age":18, "online_days":0.0, "hp":100, "max_hp":100, "sp":50, "max_sp":50,
		"zeny":500, "refine":0, "kills":0, "quest_progress":{}, "quests_completed":[],
		"inventory":{"Novice Sword":1,"Novice Armor":1}, "materials":{"Phracon":5, "Emveretarcon":2, "Oridecon":0},
		"equipment":{"weapon":"Novice Sword", "armor":"Novice Armor"},
		"cards":[], "skills":[], "pet":PetSystemClass.new_pet(hero_class),
		"last_safe_city":"Prontera", "pos_x":595.0, "pos_y":340.0, "map_id":0,
		"event_inventory":{}, "event_progress":{}, "monster_codex":{}
	}

static func exp_to_next(level:int) -> int:
	return max(100, level * 100)

static func age_bonus(age:int) -> int:
	# Unlimited age: no artificial maximum. Every four years grants one bonus tier.
	return max(0, int((age - STARTING_AGE) / 4))

static func age_strength_bonus(age:int)->Dictionary:
	var years:int=max(0,age-STARTING_AGE)
	return {"atk":years*2,"matk":years*2,"def":years,"mdef":years,"hp":years*18,"sp":years*4,"crit":years/10,"hit":years/8,"flee":years/8,"healing":years/5}

const FOURTH_JOB_CLASSES:Dictionary = {
	"Warrior":"Transcendent Knight",
	"Mage":"Transcendent Wizard",
	"Archer":"Transcendent Ranger",
	"Thief":"Transcendent Assassin",
	"Acolyte":"Transcendent Saint",
	"Merchant":"Transcendent Forge Master"
}

const SPECIAL_FOURTH_JOB_CLASSES:Dictionary = {
	"Acolyte:Saint":"Super Champion"
}

static func fourth_job_class(class_id:String, branch:String="")->String:
	var special_key:String = class_id + ":" + branch
	if SPECIAL_FOURTH_JOB_CLASSES.has(special_key):
		return str(SPECIAL_FOURTH_JOB_CLASSES[special_key])
	return str(FOURTH_JOB_CLASSES.get(class_id, FOURTH_JOB_CLASSES["Warrior"]))

static func class_rank_for_hero(hero:Dictionary)->String:
	var class_id:String = str(hero.get("class","Warrior"))
	var branch:String = str(hero.get("class_branch",""))
	var level:int = int(hero.get("level",1))
	if level >= 100 and SPECIAL_FOURTH_JOB_CLASSES.has(class_id + ":" + branch):
		return fourth_job_class(class_id,branch)
	return class_rank_for_level(level,class_id)

static func class_tier_for_level(level:int) -> int:
	if level >= 200: return 4
	if level >= 100: return 3
	if level >= 50: return 2
	if level >= 25: return 1
	return 0

static func class_rank_for_level(level:int, class_id:String="Warrior") -> String:
	var defs:=class_definitions()
	var profile:Dictionary=defs.get(class_id,defs["Warrior"])
	var tree:Array=profile["tree"]
	var tier:=class_tier_for_level(level)
	return str(tree[min(tier,tree.size()-1)])

static func class_rank_title(hero:Dictionary)->String:
	return class_rank_for_level(int(hero.get("level",1)),str(hero.get("class","Warrior")))

static func class_title(hero:Dictionary) -> String:
	return class_rank_title(hero)
