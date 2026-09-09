class_name CharacterProgressionSystem
extends RefCounted

## Authoritative character progression facade.
## Keeps level/stat allocation and equipment-derived combat stats deterministic.

const MAX_LEVEL:int = 250
const STAT_CAP:int = 99
const STAT_NAMES:Array[String] = ["str", "agi", "vit", "int", "dex", "luk"]

static func ensure_state(hero:Dictionary)->void:
    hero["level"] = clamp(int(hero.get("level",1)),1,MAX_LEVEL)
    hero["stat_points"] = max(0,int(hero.get("stat_points",0)))
    if not hero.has("stats") or not hero["stats"] is Dictionary:
        hero["stats"] = {}
    for stat in STAT_NAMES:
        hero["stats"][stat] = clamp(int(hero["stats"].get(stat,1)),1,STAT_CAP)
    if not hero.has("equipment") or not hero["equipment"] is Dictionary:
        hero["equipment"] = {}
    if not hero.has("equipment_refine") or not hero["equipment_refine"] is Dictionary:
        hero["equipment_refine"] = {}

static func allocate(hero:Dictionary,stat:String,amount:int=1)->bool:
    ensure_state(hero)
    if not STAT_NAMES.has(stat) or amount <= 0: return false
    var current:int = int(hero["stats"].get(stat,1))
    var spend:int = min(amount,STAT_CAP-current)
    spend = min(spend,int(hero.get("stat_points",0)))
    if spend <= 0: return false
    hero["stats"][stat] = current + spend
    hero["stat_points"] -= spend
    return true

static func reset_stats(hero:Dictionary)->int:
    ensure_state(hero)
    var refund:int = 0
    for stat in STAT_NAMES:
        refund += max(0,int(hero["stats"].get(stat,1))-1)
        hero["stats"][stat] = 1
    hero["stat_points"] += refund
    return refund

static func equipment_bonus(hero:Dictionary)->Dictionary:
    ensure_state(hero)
    var result:Dictionary = {"atk":0,"matk":0,"def":0,"mdef":0,"hit":0,"flee":0,"crit":0,"hp":0,"sp":0}
    for slot in hero["equipment"].keys():
        var item:Variant = hero["equipment"][slot]
        if not item is Dictionary: continue
        var item_dict:Dictionary = item
        for key in result.keys():
            result[key] += int(item_dict.get(key,0))
        var refine:int = int(hero["equipment_refine"].get(slot,0))
        result["atk"] += refine * int(item_dict.get("refine_atk",2))
        result["matk"] += refine * int(item_dict.get("refine_matk",2))
        result["def"] += refine * int(item_dict.get("refine_def",1))
    return result

static func stats(hero:Dictionary)->Dictionary:
    ensure_state(hero)
    var s:Dictionary = hero["stats"]
    var e:Dictionary = equipment_bonus(hero)
    var level:int = int(hero["level"])
    var hp:int = 100 + level * 28 + int(s["vit"]) * 24 + int(e["hp"])
    var sp:int = 40 + level * 9 + int(s["int"]) * 10 + int(e["sp"])
    var atk:int = 8 + level * 2 + int(s["str"]) * 3 + int(s["dex"]) + int(e["atk"])
    var matk:int = 8 + level * 2 + int(s["int"]) * 4 + int(s["dex"]) + int(e["matk"])
    var defense:int = int(s["vit"]) * 2 + level + int(e["def"])
    var mdef:int = int(s["int"]) + int(s["vit"]) + level / 2 + int(e["mdef"])
    return {"max_hp":hp,"max_sp":sp,"atk":atk,"matk":matk,"def":defense,"mdef":mdef,"hit":level+int(s["dex"])*2+int(e["hit"]),"flee":level+int(s["agi"])*2+int(e["flee"]),"crit":int(s["luk"])/2+int(e["crit"])}

static func level_up(hero:Dictionary,new_level:int)->int:
    ensure_state(hero)
    var target:int = clamp(new_level,1,MAX_LEVEL)
    if target <= int(hero["level"]): return 0
    var gained:int = 0
    for level in range(int(hero["level"])+1,target+1):
        gained += 3 + int(level / 10)
    hero["level"] = target
    hero["stat_points"] += gained
    return gained
