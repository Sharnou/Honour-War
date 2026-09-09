class_name CharacterProgressionSystem
extends RefCounted

const MAX_LEVEL:int = 250
const STAT_CAP:int = 99
const STAT_NAMES:Array[String] = ["str", "agi", "vit", "int", "dex", "luk"]
const Age=preload("res://scripts/OnlineAgeSystem.gd")
const Equipment=preload("res://scripts/EquipmentProgressionSystem.gd")

static func ensure_state(hero:Dictionary)->void:
	hero["level"] = clamp(int(hero.get("level",1)),1,MAX_LEVEL)
	hero["stat_points"] = max(0,int(hero.get("stat_points",0)))
	if not hero.has("xp"): hero["xp"]=0
	if not hero.has("stats") or not hero["stats"] is Dictionary: hero["stats"] = {}
	for stat in STAT_NAMES: hero["stats"][stat] = clamp(int(hero["stats"].get(stat,1)),1,STAT_CAP)
	if not hero.has("equipment") or not hero["equipment"] is Dictionary: hero["equipment"] = {}
	Age.normalize(hero)

static func allocate(hero:Dictionary,stat:String,amount:int=1)->bool:
	ensure_state(hero)
	if not STAT_NAMES.has(stat) or amount<=0: return false
	var current:int=int(hero["stats"].get(stat,1)); var spend:int=min(amount,STAT_CAP-current,int(hero.get("stat_points",0)))
	if spend<=0: return false
	hero["stats"][stat]=current+spend; hero["stat_points"]-=spend; return true
static func reset_stats(hero:Dictionary)->int:
	ensure_state(hero); var refund:int=0
	for stat in STAT_NAMES: refund+=max(0,int(hero["stats"].get(stat,1))-1); hero["stats"][stat]=1
	hero["stat_points"]+=refund; return refund

static func equipment_bonus(hero:Dictionary)->Dictionary:
	ensure_state(hero)
	var raw:Dictionary=Equipment.total_stats(hero["equipment"])
	return {"atk":int(raw["atk"]),"matk":int(raw["matk"]),"def":int(raw["def"]),"mdef":int(raw.get("mdef",0)),"hit":int(raw.get("hit",0)),"flee":int(raw.get("flee",raw.get("evasion",0))),"crit":int(raw["crit"]),"hp":int(raw["hp"]),"sp":int(raw["sp"]),"healing":int(raw["healing"]),"move_percent":float(raw.get("move_percent",0.0)),"fire_percent":float(raw.get("fire_percent",0.0)),"wind_percent":float(raw.get("wind_percent",0.0)),"dark_percent":float(raw.get("dark_percent",0.0)),"ice_resist_percent":float(raw.get("ice_resist_percent",0.0)),"boss_damage_percent":float(raw.get("boss_damage_percent",0.0)),"all_rewards_percent":float(raw.get("all_rewards_percent",0.0)),"carry":int(raw.get("carry",0))}

static func stats(hero:Dictionary)->Dictionary:
	ensure_state(hero); var s:Dictionary=hero["stats"]; var e:Dictionary=equipment_bonus(hero); var age:Dictionary=Age.strength_bonus(hero); var level:int=int(hero["level"])
	var hp:int=100+level*28+int(s["vit"])*24+int(e["hp"])+int(age["hp"])
	var sp:int=40+level*9+int(s["int"])*10+int(e["sp"])+int(age["sp"])
	var atk:int=8+level*2+int(s["str"])*3+int(s["dex"])+int(e["atk"])+int(age["atk"])
	var matk:int=8+level*2+int(s["int"])*4+int(s["dex"])+int(e["matk"])+int(age["matk"])
	var defense:int=int(s["vit"])*2+level+int(e["def"])+int(age["def"])
	var mdef:int=int(s["int"])+int(s["vit"])+level/2+int(e["mdef"])+int(age["mdef"])
	var hit:int=level+int(s["dex"])*2+int(e["hit"])+int(age["hit"]); var flee:int=level+int(s["agi"])*2+int(e["flee"])+int(age["flee"])
	var crit:float=float(s["luk"])/2.0+float(e["crit"])+float(age["crit"])
	return {"max_hp":hp,"max_sp":sp,"atk":atk,"matk":matk,"def":defense,"mdef":mdef,"hit":hit,"flee":flee,"crit":crit,"healing":int(age["healing"])+int(e["healing"]),"move_percent":float(e["move_percent"]),"fire_percent":float(e["fire_percent"]),"wind_percent":float(e["wind_percent"]),"dark_percent":float(e["dark_percent"]),"ice_resist_percent":float(e["ice_resist_percent"]),"boss_damage_percent":float(e["boss_damage_percent"]),"all_rewards_percent":float(e["all_rewards_percent"]),"carry":int(e["carry"])}

static func level_up(hero:Dictionary,new_level:int)->int:
	ensure_state(hero); var target:int=clamp(new_level,1,MAX_LEVEL)
	if target<=int(hero["level"]): return 0
	var gained:int=0
	for level in range(int(hero["level"])+1,target+1): gained+=3+int(level/10)
	hero["level"]=target; hero["stat_points"]+=gained; return gained
static func xp_to_next(level:int)->int:
	var l:int=clamp(level,1,MAX_LEVEL); return 100+int(pow(float(l),1.55)*35.0)
static func grant_xp(hero:Dictionary,xp:int)->Dictionary:
	ensure_state(hero); var current:int=int(hero.get("xp",0))+max(0,xp); var gained_levels:int=0
	while int(hero["level"])<MAX_LEVEL and current>=xp_to_next(int(hero["level"])):
		current-=xp_to_next(int(hero["level"])); level_up(hero,int(hero["level"])+1); gained_levels+=1
	hero["xp"]=current
	return {"xp":current,"levels":gained_levels,"level":int(hero["level"])}
