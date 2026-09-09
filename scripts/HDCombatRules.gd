class_name HDCombatRules
extends RefCounted

## Shared combat rules for class-specific engagement distances.

const SWORDSMAN_MELEE_RANGE:float = 2.4
const ARCHER_ATTACK_RANGE:float = 12.0
const ARCHER_MIN_RANGE:float = 2.5
const MONSTER_MELEE_RANGE:float = 2.2

static func attack_range_for_class(class_name:String)->float:
    var normalized:=class_name.to_lower()
    if normalized == "archer" or normalized == "ranger":
        return ARCHER_ATTACK_RANGE
    return SWORDSMAN_MELEE_RANGE

static func monster_melee_range()->float:
    return MONSTER_MELEE_RANGE

static func is_in_attack_range(class_name:String, distance:float)->bool:
    return distance <= attack_range_for_class(class_name)
