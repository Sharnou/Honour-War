class_name EquipmentProgressionSystem
extends RefCounted

## Runtime adapter for the existing ItemDatabase.
## Adds deterministic equip/refine/card/enchant calculations without replacing
## the project's existing item catalogue.

const MAX_REFINE:int = 15

static func normalize_item(item:Dictionary)->Dictionary:
    var result:Dictionary = item.duplicate(true)
    result["refine"] = clamp(int(result.get("refine",0)),0,MAX_REFINE)
    result["cards"] = result.get("cards",[])
    if not result["cards"] is Array: result["cards"] = []
    return result

static func refined_bonus(item:Dictionary)->Dictionary:
    var result:Dictionary = {}
    var refine:int = clamp(int(item.get("refine",0)),0,MAX_REFINE)
    var kind:String = str(item.get("type",""))
    var base:int = int(item.get("attack",0)) if kind == "Weapon" else int(item.get("defense",0))
    var bonus:int = int(round(float(base) * 0.025 * refine)) + refine * 2
    if kind == "Weapon": result["attack"] = bonus
    else: result["defense"] = bonus
    result["refine"] = refine
    return result

static func total_stats(equipment:Dictionary)->Dictionary:
    var total:Dictionary = {"attack":0,"magic":0,"defense":0,"hp":0,"sp":0,"crit":0,"evasion":0,"healing":0}
    for slot in equipment.keys():
        var raw:Variant = equipment[slot]
        if not raw is Dictionary: continue
        var item:Dictionary = normalize_item(raw)
        for key in total.keys(): total[key] += int(item.get(key,0))
        var rb:Dictionary = refined_bonus(item)
        for key in rb.keys():
            if total.has(key): total[key] += int(rb[key])
    return total

static func refine_chance(current:int)->float:
    var target:int = current + 1
    if target <= 1: return 1.0
    if target <= 5: return 0.90 - float(target-2)*0.05
    if target <= 10: return 0.72 - float(target-6)*0.08
    if target <= 15: return 0.38 - float(target-11)*0.065
    return 0.0

static func attempt_refine(item:Dictionary,roll:float)->Dictionary:
    var normalized:Dictionary = normalize_item(item)
    var current:int = int(normalized["refine"])
    var cap:int = clamp(int(normalized.get("refine_cap",MAX_REFINE)),1,MAX_REFINE)
    if current >= cap: return {"ok":false,"success":false,"reason":"cap","refine":current,"chance":0.0}
    var chance:float = refine_chance(current)
    var success:bool = clamp(roll,0.0,0.999999) < chance
    if success:
        normalized["refine"] = current + 1
    else:
        normalized["refine"] = max(0,current - 1) if current >= 10 else current
    return {"ok":true,"success":success,"item":normalized,"refine":int(normalized["refine"]),"chance":chance}

static func card_capacity(item:Dictionary)->int:
    return max(0,int(item.get("card_slots",0)))

static func insert_card(item:Dictionary,card_id:String)->Dictionary:
    var normalized:Dictionary = normalize_item(item)
    var cards:Array = normalized["cards"]
    if cards.size() >= card_capacity(normalized):
        return {"ok":false,"reason":"no_slots","item":normalized}
    if cards.has(card_id):
        return {"ok":false,"reason":"duplicate_card","item":normalized}
    cards.append(card_id)
    normalized["cards"] = cards
    return {"ok":true,"item":normalized}
