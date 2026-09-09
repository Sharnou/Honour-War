class_name SaveSystem
extends RefCounted

const SAVE_PATH := "user://honour_war_save.json"
const SAVE_VERSION := 5

static func save_game(hero:Dictionary) -> bool:
	var data=hero.duplicate(true)
	data["save_version"]=SAVE_VERSION
	var file=FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify(data)); file.close(); return true

static func load_game(default_hero:Dictionary) -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH): return migrate(default_hero.duplicate(true))
	var file=FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null: return migrate(default_hero.duplicate(true))
	var parsed=JSON.parse_string(file.get_as_text()); file.close()
	if typeof(parsed) != TYPE_DICTIONARY: return migrate(default_hero.duplicate(true))
	var result=default_hero.duplicate(true)
	for key in parsed.keys(): result[key]=parsed[key]
	return migrate(result)

static func migrate(hero:Dictionary) -> Dictionary:
	if not hero.has("save_version"): hero["save_version"]=1
	if not hero.has("class_tier"): hero["class_tier"]=0
	if not hero.has("quest_progress"): hero["quest_progress"]={}
	if not hero.has("quests_completed"): hero["quests_completed"]=[]
	if not hero.has("inventory") or not hero["inventory"] is Dictionary: hero["inventory"]={}
	if not hero.has("equipment") or not hero["equipment"] is Dictionary: hero["equipment"]={}
	if not hero.has("equipment_refine") or not hero["equipment_refine"] is Dictionary: hero["equipment_refine"]={}
	if not hero.has("cards") or not hero["cards"] is Array: hero["cards"]=[]
	if not hero.has("skills") or not hero["skills"] is Array: hero["skills"]=[]
	if not hero.has("skill_levels") or not hero["skill_levels"] is Dictionary: hero["skill_levels"]={}
	if not hero.has("skill_points"): hero["skill_points"]=max(0,int(hero.get("level",1))-1)
	if not hero.has("skill_cooldowns") or not hero["skill_cooldowns"] is Dictionary: hero["skill_cooldowns"]={}
	if not hero.has("pet") or not hero["pet"] is Dictionary: hero["pet"]={}
	if not hero.has("city_building") or not hero["city_building"] is Dictionary: hero["city_building"]={"Prontera":{"level":1,"wood":0,"stone":0,"gold":0}}
	if not hero.has("last_safe_city"): hero["last_safe_city"]="Prontera"
	if not hero.has("pos_x"): hero["pos_x"]=270.0
	if not hero.has("pos_y"): hero["pos_y"]=330.0
	if not hero.has("age"): hero["age"]=18
	if not hero.has("online_days"): hero["online_days"]=0.0
	if not hero.has("xp"): hero["xp"]=0
	if not hero.has("zeny"): hero["zeny"]=0
	if not hero.has("hp"): hero["hp"]=100
	if not hero.has("sp"): hero["sp"]=40
	if not hero.has("event_inventory") or not hero["event_inventory"] is Dictionary: hero["event_inventory"]={}
	if not hero.has("event_progress") or not hero["event_progress"] is Dictionary: hero["event_progress"]={}
	if not hero.has("event_claimed") or not hero["event_claimed"] is Dictionary: hero["event_claimed"]={}
	if not hero.has("monster_codex") or not hero["monster_codex"] is Dictionary: hero["monster_codex"]={}
	if not hero.has("loot_rules") or not hero["loot_rules"] is Dictionary: hero["loot_rules"]={"enabled":true,"auto_pick_items":true,"auto_pick_cards":true,"auto_pick_materials":true,"auto_pick_equipment":true}
	if not hero.has("loot_stats") or not hero["loot_stats"] is Dictionary: hero["loot_stats"]={"items":0,"cards":0,"equipment":0,"materials":0,"zeny":0,"xp":0,"pet_xp":0}
	return hero
