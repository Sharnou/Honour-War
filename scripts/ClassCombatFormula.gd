class_name ClassCombatFormula
extends RefCounted

## Single-source class combat modifiers used by the CombatRuntime subclass facade.
## These formulas consume live CharacterProgressionSystem stats and never create a second combat loop.

const Character=preload("res://scripts/CharacterProgressionSystem.gd")
const Equipment=preload("res://scripts/EquipmentProgressionSystem.gd")
const SkillSystem=preload("res://scripts/SkillSystem.gd")

static func class_id(hero:Dictionary)->String:
    return str(hero.get("class","Warrior"))

static func attack_speed_percent(hero:Dictionary)->float:
    var agi:int=int(hero.get("stats",{}).get("agi",1))
    var dex:int=int(hero.get("stats",{}).get("dex",1))
    var equipment:Dictionary=Equipment.total_stats(hero.get("equipment",{}))
    var result:float=float(agi)*0.55+float(dex)*0.18+float(equipment.get("attack_speed_percent",0.0))
    match class_id(hero):
        "Thief": result+=10.0
        "Archer": result+=7.0
        "Ranger": result+=9.0
        "Warrior": result+=2.0
        "Mage": result+=1.0
        "Acolyte": result+=1.0
        "Merchant": result+=0.0
    return clamp(result,0.0,65.0)

static func attack_interval(hero:Dictionary,base:float=0.72)->float:
    return max(0.28,base/(1.0+attack_speed_percent(hero)/100.0))

static func physical_power(hero:Dictionary)->int:
    var s:Dictionary=Character.stats(hero)
    var value:int=int(s.get("atk",0))
    match class_id(hero):
        "Archer", "Ranger": value+=int(hero.get("stats",{}).get("dex",1))*2
        "Thief": value+=int(hero.get("stats",{}).get("agi",1))*2
        "Merchant": value+=int(hero.get("stats",{}).get("str",1))
        "Acolyte": value+=int(hero.get("stats",{}).get("int",1))
        "Mage": value+=int(hero.get("stats",{}).get("int",1))/2
    return max(1,value)

static func magic_power(hero:Dictionary)->int:
    var s:Dictionary=Character.stats(hero)
    var value:int=int(s.get("matk",0))
    if class_id(hero)=="Mage": value+=int(hero.get("stats",{}).get("int",1))*2
    elif class_id(hero)=="Acolyte": value+=int(hero.get("stats",{}).get("int",1))
    return max(1,value)

static func critical_chance(hero:Dictionary)->float:
    var s:Dictionary=Character.stats(hero)
    var result:float=float(s.get("crit",0))
    var luk:int=int(hero.get("stats",{}).get("luk",1))
    match class_id(hero):
        "Thief": result+=8.0+float(luk)*0.25
        "Archer", "Ranger": result+=5.0+float(luk)*0.15
        "Warrior": result+=float(luk)*0.08
        "Merchant": result+=float(luk)*0.05
    result+=float(SkillSystem.combat_stats(hero).get("crit_bonus",0))
    return clamp(result,0.0,75.0)

static func defense(hero:Dictionary)->int:
    var s:Dictionary=Character.stats(hero)
    var result:int=int(s.get("def",0))
    match class_id(hero):
        "Warrior": result+=12
        "Merchant": result+=8
        "Acolyte": result+=6
        "Thief": result-=2
        "Mage": result-=4
        "Archer", "Ranger": result-=1
    result+=int(SkillSystem.combat_stats(hero).get("defense_bonus",0))
    return max(0,result)

static func skill_damage(hero:Dictionary,power:int,magical:bool=false)->int:
    var base:int=magic_power(hero) if magical else physical_power(hero)
    var ratio:float=0.55 if magical else 0.65
    var result:int=int(round(float(base)*ratio))+power
    var skill_stats:Dictionary=SkillSystem.combat_stats(hero)
    result=int(round(float(result)*float(skill_stats.get("damage_multiplier",1.0))))
    var equipment:Dictionary=Equipment.total_stats(hero.get("equipment",{}))
    result=int(round(float(result)*(1.0+float(equipment.get("damage_percent",0.0))/100.0)))
    return max(1,result)
