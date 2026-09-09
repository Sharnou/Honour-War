class_name PetProgressionSystem
extends RefCounted

const MAX_LEVEL:int = 250

static func ensure_state(pet:Dictionary)->void:
    pet["level"] = clamp(int(pet.get("level",1)),1,MAX_LEVEL)
    pet["xp"] = max(0,int(pet.get("xp",0)))
    pet["loyalty"] = clamp(int(pet.get("loyalty",100)),0,100)
    pet["refine"] = clamp(int(pet.get("refine",0)),0,15)
    PetSkillSystem.ensure_state(pet)

static func xp_to_next(level:int)->int:
    var l:int = clamp(level,1,MAX_LEVEL)
    return 80 + l*l*18 + l*35

static func grant_xp(pet:Dictionary,amount:int)->Dictionary:
    ensure_state(pet)
    var gained:int = max(0,amount)
    pet["xp"] += gained
    var levels:int = 0
    while int(pet["level"]) < MAX_LEVEL and int(pet["xp"]) >= xp_to_next(int(pet["level"])):
        pet["xp"] -= xp_to_next(int(pet["level"]))
        pet["level"] += 1
        pet["skill_points"] = min(PetSkillSystem.MAX_SKILL_POINTS,int(pet.get("skill_points",0))+1)
        levels += 1
    if int(pet["level"]) >= MAX_LEVEL: pet["xp"] = 0
    return {"xp":gained,"levels":levels,"level":int(pet["level"]),"skill_points":int(pet.get("skill_points",0))}

static func combat_stats(pet:Dictionary)->Dictionary:
    ensure_state(pet)
    var role:String = str(pet.get("role",pet.get("species","Wolf")))
    var level:int = int(pet["level"])
    var base:Dictionary = {"attack":10+level*3,"magic":8+level*2,"defense":level*2,"hp":80+level*25,"crit":0,"range":2.6}
    match role:
        "ranged": base["range"] = 9.0
        "caster": base["range"] = 6.0
        "support": base["range"] = 5.0
        "assassin": base["range"] = 3.0
    var skills:Dictionary = PetSkillSystem.combat_stats(pet)
    base["attack"] = int(round(float(base["attack"])*float(skills["damage_multiplier"])))
    base["defense"] += int(skills["defense_bonus"])
    base["crit"] += int(skills["crit_bonus"])
    base["attack"] += int(pet["refine"])*3
    return base

static func refine(pet:Dictionary,roll:float)->Dictionary:
    ensure_state(pet)
    var current:int = int(pet["refine"])
    if current >= 15: return {"ok":false,"success":false,"reason":"cap","refine":current}
    var chance:float = max(0.10,1.0-float(current)*0.055)
    var success:bool = clamp(roll,0.0,0.999999) < chance
    if success: pet["refine"] = current+1
    elif current >= 10: pet["refine"] = current-1
    return {"ok":true,"success":success,"refine":int(pet["refine"]),"chance":chance}
