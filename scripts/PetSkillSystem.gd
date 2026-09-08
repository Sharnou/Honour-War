class_name PetSkillSystem
extends RefCounted

const MAX_SKILL_LEVEL:int = 10
const MAX_SKILL_POINTS:int = 250

static func trees()->Dictionary:
    return {
        "Falcon": [
            p("pet_falcon_gust","Gale Talon",1,1,10,1,[],"active",38,0,2.0,"A rapid diving strike."),
            p("pet_falcon_eye","Hunter's Eye",1,1,10,10,[],"passive",12,0,0.0,"Raises pet critical chance."),
            p("pet_falcon_storm","Sky Gust",2,2,10,25,["pet_falcon_gust"],"active",82,0,5.0,"Creates a focused wind burst."),
            p("pet_falcon_mark","Predator Mark",2,2,10,30,["pet_falcon_eye"],"active",55,0,7.0,"Marks the target for increased party damage."),
            p("pet_falcon_barrage","Feather Barrage",3,3,10,50,["pet_falcon_storm"],"active",145,0,8.0,"Launches a storm of razor feathers."),
            p("pet_falcon_raptor","Raptor Instinct",3,3,10,70,["pet_falcon_eye"],"passive",24,0,0.0,"Improves burst damage and movement."),
            p("pet_falcon_tempest","Celestial Tempest",4,4,10,100,["pet_falcon_barrage","pet_falcon_raptor"],"active",280,0,14.0,"Aerial storm centered on the target."),
            p("pet_falcon_sky_requiem","Sky Requiem",5,5,10,200,["pet_falcon_tempest"],"ultimate",620,0,38.0,"Ultimate falcon dive that tears through defenses.")
        ],
        "Wolf": [
            p("pet_wolf_bite","Savage Bite",1,1,10,1,[],"active",42,0,2.0,"Heavy close-range bite."),
            p("pet_wolf_pack","Pack Instinct",1,1,10,10,[],"passive",14,0,0.0,"Raises attack power while near its owner."),
            p("pet_wolf_howl","War Howl",2,2,10,25,["pet_wolf_bite"],"active",70,0,5.0,"Damages enemies and empowers allies."),
            p("pet_wolf_guard","Iron Fang",2,2,10,30,["pet_wolf_pack"],"passive",18,0,0.0,"Improves pet defense and threat."),
            p("pet_wolf_rend","Rending Rush",3,3,10,50,["pet_wolf_howl"],"active",150,0,7.0,"A chained leap with armor penetration."),
            p("pet_wolf_fury","Blood Howl",3,3,10,70,["pet_wolf_pack"],"active",105,0,9.0,"Enters a high-damage combat state."),
            p("pet_wolf_apex","Apex Maul",4,4,10,100,["pet_wolf_rend","pet_wolf_fury"],"active",310,0,15.0,"A crushing execution attack."),
            p("pet_wolf_alpha","Alpha Ascension",5,5,10,200,["pet_wolf_apex"],"ultimate",650,0,40.0,"Ultimate alpha strike with massive threat.")
        ],
        "Dragon": [
            p("pet_dragon_flame","Ember Breath",1,1,10,1,[],"active",50,0,2.5,"Breathes concentrated flame."),
            p("pet_dragon_scale","Dragon Scales",1,1,10,10,[],"passive",16,0,0.0,"Raises elemental resistance and defense."),
            p("pet_dragon_wing","Inferno Wing",2,2,10,25,["pet_dragon_flame"],"active",95,0,6.0,"Sweeps enemies with burning wings."),
            p("pet_dragon_roar","Dread Roar",2,2,10,30,["pet_dragon_scale"],"active",75,0,7.0,"Disrupts nearby enemies and reduces their power."),
            p("pet_dragon_meteor","Dragon Meteor",3,3,10,50,["pet_dragon_wing"],"active",180,0,9.0,"Calls a blazing meteor onto the target."),
            p("pet_dragon_core","Ancient Core",3,3,10,70,["pet_dragon_scale"],"passive",28,0,0.0,"Improves pet maximum HP and skill power."),
            p("pet_dragon_apocalypse","Draconic Apocalypse",4,4,10,100,["pet_dragon_meteor","pet_dragon_core"],"active",360,0,16.0,"Massive elemental devastation."),
            p("pet_dragon_eternity","Eternal Dragon",5,5,10,200,["pet_dragon_apocalypse"],"ultimate",760,0,42.0,"Ultimate dragon technique that scorches a huge area.")
        ],
        "Wolf Cub": [
            p("pet_wolfcub_pounce","Little Pounce",1,1,10,1,[],"active",30,0,2.0,"Fast playful strike."),
            p("pet_wolfcub_courage","Growing Courage",1,1,10,10,[],"passive",10,0,0.0,"Raises pet damage as it levels."),
            p("pet_wolfcub_howl","Young Howl",2,2,10,25,["pet_wolfcub_pounce"],"active",58,0,5.0,"Weakens nearby enemies."),
            p("pet_wolfcub_guard","Brave Guard",2,2,10,30,["pet_wolfcub_courage"],"passive",14,0,0.0,"Improves defensive support."),
            p("pet_wolfcub_rush","Pack Rush",3,3,10,50,["pet_wolfcub_howl"],"active",110,0,7.0,"Charges through the target."),
            p("pet_wolfcub_bond","Loyal Bond",3,3,10,70,["pet_wolfcub_courage"],"passive",20,0,0.0,"Improves owner and pet recovery."),
            p("pet_wolfcub_heart","Guardian Heart",4,4,10,100,["pet_wolfcub_rush","pet_wolfcub_bond"],"active",230,0,14.0,"Protective shockwave around the owner."),
            p("pet_wolfcub_legend","Legendary Companion",5,5,10,200,["pet_wolfcub_heart"],"ultimate",500,0,36.0,"Ultimate bonded strike that protects the party.")
        ]
    }

static func p(id:String,name:String,tier:int,cost:int,max_level:int,required_level:int,requires:Array,kind:String,power:int,sp_cost:int,cooldown:float,description:String)->Dictionary:
    return {"id":id,"name":name,"tier":tier,"cost":cost,"max_level":max_level,"required_level":required_level,"requires":requires,"kind":kind,"power":power,"sp_cost":sp_cost,"cooldown":cooldown,"description":description}

static func all_skills(species:String)->Array:
    return trees().get(species,trees()["Wolf Cub"])

static func skill_map(species:String)->Dictionary:
    var result:Dictionary = {}
    for skill in all_skills(species):
        result[skill["id"]] = skill
    return result

static func ensure_state(pet:Dictionary)->void:
    if not pet.has("skill_levels"): pet["skill_levels"] = {}
    if not pet.has("skill_points"): pet["skill_points"] = max(0,int(pet.get("level",1))-1)
    if not pet.has("skill_points_level"): pet["skill_points_level"] = int(pet.get("level",1))
    if not pet.has("skill_cooldowns"): pet["skill_cooldowns"] = {}
    var level:int = int(pet.get("level",1))
    var recorded:int = int(pet.get("skill_points_level",level))
    if level > recorded:
        pet["skill_points"] = min(MAX_SKILL_POINTS,int(pet.get("skill_points",0)) + level - recorded)
        pet["skill_points_level"] = level
    var valid:Dictionary = skill_map(str(pet.get("species","Wolf Cub")))
    for id in valid.keys():
        if not pet["skill_levels"].has(id): pet["skill_levels"][id] = 0
    var basic:String = str(valid.keys()[0])
    if int(pet["skill_levels"].get(basic,0)) < 1: pet["skill_levels"][basic] = 1

static func skill_level(pet:Dictionary,skill_id:String)->int:
    ensure_state(pet)
    return int(pet["skill_levels"].get(skill_id,0))

static func can_learn(pet:Dictionary,skill_id:String)->bool:
    ensure_state(pet)
    var skills:Dictionary = skill_map(str(pet.get("species","Wolf Cub")))
    if not skills.has(skill_id): return false
    var skill:Dictionary = skills[skill_id]
    if skill_level(pet,skill_id) >= int(skill["max_level"]): return false
    if int(pet.get("level",1)) < int(skill["required_level"]): return false
    if int(pet.get("skill_points",0)) < int(skill["cost"]): return false
    for req in skill["requires"]:
        if skill_level(pet,str(req)) < 1: return false
    return true

static func learn(pet:Dictionary,skill_id:String)->bool:
    if not can_learn(pet,skill_id): return false
    var skill:Dictionary = skill_map(str(pet.get("species","Wolf Cub")))[skill_id]
    pet["skill_points"] -= int(skill["cost"])
    pet["skill_levels"][skill_id] = skill_level(pet,skill_id) + 1
    return true

static func power(pet:Dictionary,skill_id:String)->int:
    var skills:Dictionary = skill_map(str(pet.get("species","Wolf Cub")))
    if not skills.has(skill_id): return 0
    var skill:Dictionary = skills[skill_id]
    var level:int = skill_level(pet,skill_id)
    var value:int = int(skill["power"]) + max(0,level - 1) * int(skill["power"]) / 3
    var passive_bonus:int = 0
    for other in all_skills(str(pet.get("species","Wolf Cub"))):
        if other["kind"] == "passive": passive_bonus += skill_level(pet,str(other["id"])) * int(other["power"]) / 8
    if skill["kind"] != "passive": value += passive_bonus
    return value

static func is_ready(pet:Dictionary,skill_id:String,now:float)->bool:
    ensure_state(pet)
    return float(pet["skill_cooldowns"].get(skill_id,0.0)) <= now

static func use(pet:Dictionary,skill_id:String,now:float)->Dictionary:
    ensure_state(pet)
    var skills:Dictionary = skill_map(str(pet.get("species","Wolf Cub")))
    if not skills.has(skill_id) or skill_level(pet,skill_id) <= 0: return {"ok":false,"reason":"locked"}
    var skill:Dictionary = skills[skill_id]
    if skill["kind"] == "passive": return {"ok":false,"reason":"passive"}
    if not is_ready(pet,skill_id,now): return {"ok":false,"reason":"cooldown"}
    pet["skill_cooldowns"][skill_id] = now + float(skill["cooldown"])
    return {"ok":true,"skill":skill,"level":skill_level(pet,skill_id),"power":power(pet,skill_id)}

static func combat_stats(pet:Dictionary)->Dictionary:
    ensure_state(pet)
    var crit:int = 0
    var defense:int = 0
    var damage:float = 1.0
    for skill in all_skills(str(pet.get("species","Wolf Cub"))):
        var level:int = skill_level(pet,str(skill["id"]))
        if level <= 0 or skill["kind"] != "passive": continue
        damage += float(level * int(skill["power"])) / 700.0
        if str(skill["id"]).find("eye") >= 0: crit += level * 2
        defense += level
    return {"damage_multiplier":damage,"crit_bonus":crit,"defense_bonus":defense}
