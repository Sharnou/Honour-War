class_name EquipmentProgressionSystem
extends RefCounted

## Runtime adapter for the existing ItemDatabase.
## Keeps the existing catalogue intact while normalizing its attack/magic/
## defense schema into the live character stat model.

const MAX_REFINE:int = 15

static func normalize_item(item:Dictionary)->Dictionary:
    var result:Dictionary = item.duplicate(true)
    result["refine"] = clamp(int(result.get("refine",0)),0,MAX_REFINE)
    result["cards"] = result.get("cards",[])
    if not result["cards"] is Array: result["cards"] = []
    return result

static func refined_bonus(item:Dictionary)->Dictionary:
    var result:Dictionary = {"atk":0,"matk":0,"def":0}
    var refine:int = clamp(int(item.get("refine",0)),0,MAX_REFINE)
    var kind:String = str(item.get("type",""))
    if kind=="Weapon":
        var attack:int=int(item.get("attack",0))
        var magic:int=int(item.get("magic",0))
        result["atk"] = int(round(float(attack)*0.025*refine))+refine*2
        result["matk"] = int(round(float(magic)*0.025*refine))+refine*2
    elif kind in ["Armor","Accessory"]:
        var defense:int=int(item.get("defense",0))
        result["def"] = int(round(float(defense)*0.025*refine))+refine
    return result

static func total_stats(equipment:Dictionary)->Dictionary:
    var total:Dictionary={
        "atk":0,"matk":0,"def":0,"mdef":0,"hp":0,"sp":0,
        "crit":0,"evasion":0,"hit":0,"flee":0,"healing":0,
        "move_percent":0.0,"fire_percent":0.0,"wind_percent":0.0,
        "dark_percent":0.0,"ice_resist_percent":0.0,"boss_damage_percent":0.0,
        "all_rewards_percent":0.0,"carry":0
    }
    for slot in equipment.keys():
        var raw:Variant=equipment[slot]
        if not raw is Dictionary: continue
        var item:Dictionary=normalize_item(raw)
        total["atk"]+=int(item.get("attack",0))
        total["matk"]+=int(item.get("magic",0))
        total["def"]+=int(item.get("defense",0))
        for key in ["hp","sp","crit","evasion","hit","flee","healing","carry"]:
            total[key]+=int(item.get(key,0))
        for key in ["move_percent","fire_percent","wind_percent","dark_percent","ice_resist_percent","boss_damage_percent","all_rewards_percent"]:
            total[key]+=float(item.get(key,0.0))
        var rb:Dictionary=refined_bonus(item)
        total["atk"]+=int(rb["atk"]); total["matk"]+=int(rb["matk"]); total["def"]+=int(rb["def"])
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
    return max(0,int(item.get("card_slots",0)))

static func insert_card(item:Dictionary,card_id:String)->Dictionary:
    var normalized:Dictionary=normalize_item(item)
    var cards:Array=normalized["cards"]
    if cards.size()>=card_capacity(normalized): return {"ok":false,"reason":"no_slots","item":normalized}
    if cards.has(card_id): return {"ok":false,"reason":"duplicate_card","item":normalized}
    cards.append(card_id); normalized["cards"]=cards
    return {"ok":true,"item":normalized}
