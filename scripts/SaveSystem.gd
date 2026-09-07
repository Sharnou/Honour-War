class_name SaveSystem
extends RefCounted

const SAVE_PATH := "user://honour_war_save.json"
const SAVE_VERSION := 3

static func save_game(hero:Dictionary) -> bool:
	var data=hero.duplicate(true)
	data["save_version"]=SAVE_VERSION
	var file=FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data))
	file.close()
	return true

static func load_game(default_hero:Dictionary) -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return default_hero.duplicate(true)
	var file=FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return default_hero.duplicate(true)
	var parsed=JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return default_hero.duplicate(true)
	var result=default_hero.duplicate(true)
	for key in parsed.keys():
		result[key]=parsed[key]
	return migrate(result)

static func migrate(hero:Dictionary) -> Dictionary:
	if not hero.has("class_tier"): hero["class_tier"]=0
	if not hero.has("quest_progress"): hero["quest_progress"]={}
	if not hero.has("quests_completed"): hero["quests_completed"]=[]
	if not hero.has("inventory"): hero["inventory"]={}
	if not hero.has("equipment"): hero["equipment"]={"weapon":"Novice Weapon", "armor":"Novice Armor"}
	if not hero.has("cards"): hero["cards"]=[]
	if not hero.has("skills"): hero["skills"]=[]
	if not hero.has("skill_levels"): hero["skill_levels"]={}
	if not hero.has("skill_points"): hero["skill_points"]=max(0,int(hero.get("level",1))-1)
	if not hero.has("skill_cooldowns"): hero["skill_cooldowns"]={}
	if not hero.has("pet") or not hero["pet"] is Dictionary: hero["pet"]={}
	if not hero.has("city_building"): hero["city_building"]={"Prontera":{"level":1, "wood":0, "stone":0, "gold":0}}
	if not hero.has("last_safe_city"): hero["last_safe_city"]="Prontera"
	if not hero.has("pos_x"): hero["pos_x"]=270.0
	if not hero.has("pos_y"): hero["pos_y"]=330.0
	return hero
