extends Node
class_name HWSSRentRuntime

## SS (SUPER SHAMBION) rental companion.
## SS is not a selectable/createable player class; ownership only comes from Rent NPCs.

const RENT_PRICE_ZENY:int = 1000000
const SS_CLASS_NAME:String = "SS (SUPER SHAMBION)"
const SS_LEVEL:int = 0
const SS_MAX_LEVEL:int = 250
const SS_DEFAULT_SKILL:String = "Asura Strike"
const SS_RENT_NPC_NAME:String = "Rent"

var rented:bool = false
var owner_character_age:int = 18
var ss:Dictionary = {}

func rent(hero_age:int, zeny:int) -> Dictionary:
    if rented:
        return {"ok":false,"reason":"already_rented","ss":ss.duplicate(true)}
    if zeny < RENT_PRICE_ZENY:
        return {"ok":false,"reason":"insufficient_zeny","required":RENT_PRICE_ZENY}
    owner_character_age = maxi(18,hero_age)
    rented = true
    ss = _new_ss()
    return {"ok":true,"cost":RENT_PRICE_ZENY,"ss":ss.duplicate(true)}

func stop_renting() -> Dictionary:
    rented = false
    ss = {}
    return {"ok":true,"rented":false}

func is_rented() -> bool:
    return rented

func get_ss() -> Dictionary:
    return ss.duplicate(true)

func set_equipment(slot:String, item_id:String) -> bool:
    if not rented or ss.is_empty():
        return false
    var equipment:Dictionary = ss.get("equipment",{})
    equipment[slot] = item_id
    ss["equipment"] = equipment
    return true

func set_status_points(stats:Dictionary) -> bool:
    if not rented or ss.is_empty():
        return false
    ss["status_points"] = stats.duplicate(true)
    return true

func set_behavior(follow:bool=true, heal:bool=true, fight:bool=true) -> bool:
    if not rented or ss.is_empty():
        return false
    ss["behavior"] = {"follow":follow,"heal":heal,"fight":fight}
    return true

func _new_ss() -> Dictionary:
    return {
        "name":"SS",
        "class":SS_CLASS_NAME,
        "level":SS_LEVEL,
        "max_level":SS_MAX_LEVEL,
        "age":owner_character_age,
        "skill":SS_DEFAULT_SKILL,
        "behavior":{"follow":true,"heal":true,"fight":true},
        "equipment":{},
        "status_points":{},
        "rent_npc":SS_RENT_NPC_NAME
    }
