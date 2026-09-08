class_name ClassTreeSystem
extends RefCounted

const TIER_LEVELS:Dictionary={1:1,2:25,3:50,4:100,5:200}
const TIER_NAMES:Dictionary={1:"Foundation",2:"Specialization",3:"Advanced",4:"Mastery",5:"Transcendence"}

static func class_profile(class_id:String)->Dictionary:
    var profiles:Dictionary={
        "Warrior":{"title":"Iron Vanguard","identity":"Front-line weapon master","branches":["Warlord","Guardian","Berserker"],"primary":"STR","secondary":"VIT"},
        "Mage":{"title":"Astral Arcanist","identity":"Elemental and arcane caster","branches":["Elementalist","Voidcaller","Astral Sage"],"primary":"INT","secondary":"SP"},
        "Archer":{"title":"Celestial Ranger","identity":"Precision ranged damage dealer","branches":["Sniper","Falconer","Trapper"],"primary":"DEX","secondary":"CRIT"},
        "Thief":{"title":"Shadow Assassin","identity":"Critical burst and poison specialist","branches":["Assassin","Phantom","Venomblade"],"primary":"AGI","secondary":"CRIT"},
        "Acolyte":{"title":"Divine Hierophant","identity":"Holy damage and party sustain","branches":["Priest","Saint","Exorcist"],"primary":"INT","secondary":"VIT"},
        "Merchant":{"title":"Arsenal Master","identity":"Combat crafter and equipment specialist","branches":["Blacksmith","Alchemist","Arsenal Lord"],"primary":"STR","secondary":"LUK"}
    }
    return profiles.get(class_id,profiles["Warrior"])

static func branch_for_skill(skill_id:String)->String:
    if skill_id.contains("guardian") or skill_id.contains("fortify") or skill_id.contains("sanctuary") or skill_id.contains("blessing") or skill_id.contains("mana_mastery"): return "Defense / Support"
    if skill_id.contains("berserker") or skill_id.contains("blood_fury") or skill_id.contains("execution") or skill_id.contains("overload") or skill_id.contains("deadeye") or skill_id.contains("instinct"): return "Burst / Mastery"
    if skill_id.contains("trap") or skill_id.contains("hawk") or skill_id.contains("cart") or skill_id.contains("forge"): return "Specialization"
    if skill_id.contains("holy") or skill_id.contains("divine") or skill_id.contains("seraphic") or skill_id.contains("judgment"): return "Holy / Support"
    if skill_id.contains("shadow") or skill_id.contains("poison") or skill_id.contains("blade") or skill_id.contains("smoke"): return "Assault / Control"
    if skill_id.contains("meteor") or skill_id.contains("comet") or skill_id.contains("void") or skill_id.contains("astral"): return "Arcane / Elemental"
    if skill_id.contains("arrow") or skill_id.contains("eagle") or skill_id.contains("skybreaker") or skill_id.contains("celestial"): return "Precision / Ranged"
    if skill_id.contains("magma") or skill_id.contains("titan") or skill_id.contains("arsenal"): return "Forge / Arsenal"
    if skill_id.contains("whirlwind") or skill_id.contains("earthbreaker") or skill_id.contains("emperor") or skill_id.contains("immortal"): return "Weapon / Warlord"
    return "Core"

static func tier_unlocked(hero:Dictionary,tier:int)->bool:
    return int(hero.get("level",1))>=int(TIER_LEVELS.get(tier,999))

static func tier_progress(hero:Dictionary,tier:int)->Dictionary:
    var required:int=int(TIER_LEVELS.get(tier,999))
    var level:int=int(hero.get("level",1))
    var previous:int=1 if tier==1 else int(TIER_LEVELS.get(tier-1,1))
    var ratio:float=clamp(float(level-previous)/max(1,required-previous),0.0,1.0)
    return {"required":required,"level":level,"ratio":ratio,"unlocked":level>=required}

static func available_tier(hero:Dictionary)->int:
    var result:=1
    for tier in range(1,6):
        if tier_unlocked(hero,tier): result=tier
    return result

static func capstone(class_id:String)->String:
    match class_id:
        "Warrior": return "Immortal Arsenal"
        "Mage": return "Astral Apocalypse"
        "Archer": return "Celestial Barrage"
        "Thief": return "Eternal Assassin"
        "Acolyte": return "Heaven's Gate"
        "Merchant": return "Arsenal Overlord"
        _: return "Immortal Arsenal"

static func summary(hero:Dictionary)->Dictionary:
    var class_id:=str(hero.get("class","Warrior"))
    var profile:=class_profile(class_id)
    var skills:Array=SkillSystem.all_skills(class_id)
    var learned:=0
    var total:=0
    for skill in skills:
        var level:=SkillSystem.skill_level(hero,str(skill["id"]))
        learned+=level
        total+=int(skill["max_level"])
    return {"class":class_id,"profile":profile,"available_tier":available_tier(hero),"capstone":capstone(class_id),"learned":learned,"total":total}
