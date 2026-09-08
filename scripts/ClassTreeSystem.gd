class_name ClassTreeSystem
extends RefCounted

const TIER_LEVELS:Dictionary={1:1,2:25,3:50,4:100,5:200}
const TIER_NAMES:Dictionary={1:"Foundation",2:"Specialization",3:"Advanced",4:"Mastery",5:"Transcendence"}

static func class_profile(class_id:String)->Dictionary:
    var profiles:Dictionary={
        "Warrior":{"title":"Iron Vanguard","identity":"Front-line weapon master","branches":["Warlord","Guardian","Berserker","Dragoon"],"primary":"STR","secondary":"VIT"},
        "Mage":{"title":"Astral Arcanist","identity":"Elemental and arcane caster","branches":["Elementalist","Voidcaller","Astral Sage","Chronomancer"],"primary":"INT","secondary":"SP"},
        "Archer":{"title":"Celestial Ranger","identity":"Precision ranged damage dealer","branches":["Sniper","Falconer","Trapper","Ballista"],"primary":"DEX","secondary":"CRIT"},
        "Thief":{"title":"Shadow Assassin","identity":"Critical burst and poison specialist","branches":["Assassin","Phantom","Venomblade","Shadow Dancer"],"primary":"AGI","secondary":"CRIT"},
        "Acolyte":{"title":"Divine Hierophant","identity":"Holy damage and party sustain","branches":["Priest","Saint","Exorcist","Oracle"],"primary":"INT","secondary":"VIT"},
        "Merchant":{"title":"Arsenal Master","identity":"Combat crafter and equipment specialist","branches":["Blacksmith","Alchemist","Arsenal Lord","Tactician"],"primary":"STR","secondary":"LUK"}
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

static func branch_descriptions(class_id:String)->Dictionary:
    var descriptions:Dictionary={
        "Warrior":{"Warlord":"Weapon damage, armor penetration and execution power.","Guardian":"Defense, taunt strength and survivability.","Berserker":"Critical burst and low-health damage.","Dragoon":"Reach, mounted-style momentum and anti-MVP burst."},
        "Mage":{"Elementalist":"Elemental area damage and burn/freeze pressure.","Voidcaller":"Defense penetration, control and burst magic.","Astral Sage":"Mana efficiency, ultimate power and party utility.","Chronomancer":"Cooldown control, tempo manipulation and sustained spell casting."},
        "Archer":{"Sniper":"Range, precision and critical damage.","Falconer":"Pet/Falcon synergy and sustained damage.","Trapper":"Control fields, slows and tactical area damage.","Ballista":"Heavy ranged power, armor-breaking shots and siege pressure."},
        "Thief":{"Assassin":"Critical burst and execution damage.","Phantom":"Evasion, stealth and mobility.","Venomblade":"Poison, damage-over-time and weakening effects.","Shadow Dancer":"Combo mobility, evasive burst and multi-target pressure."},
        "Acolyte":{"Priest":"Healing, defense and party sustain.","Saint":"Holy power, blessings and recovery.","Exorcist":"Holy damage, undead/MVP pressure and purification.","Oracle":"Foresight, barrier support and high-impact divine control."},
        "Merchant":{"Blacksmith":"Weapon power, defense and refinement.","Alchemist":"Consumable efficiency, elemental pressure and sustain.","Arsenal Lord":"Pet/equipment synergy and high-end combat power.","Tactician":"Battlefield control, team utility and resource efficiency."}
    }
    return descriptions.get(class_id,descriptions["Warrior"])

static func ensure_state(hero:Dictionary)->void:
    var class_id:=str(hero.get("class","Warrior"))
    var profile:=class_profile(class_id)
    if not hero.has("class_branch"): hero["class_branch"]=""
    if not hero.has("class_mastery"): hero["class_mastery"]=0
    if str(hero.get("class_branch",""))!="" and not profile["branches"].has(str(hero.get("class_branch"))):
        hero["class_branch"]=""
        hero["class_mastery"]=0

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

static func can_select_branch(hero:Dictionary,branch:String)->bool:
    ensure_state(hero)
    var profile:=class_profile(str(hero.get("class","Warrior")))
    if str(hero.get("class_branch",""))!="": return false
    return int(hero.get("level",1))>=25 and profile["branches"].has(branch)

static func select_branch(hero:Dictionary,branch:String)->bool:
    if not can_select_branch(hero,branch): return false
    hero["class_branch"]=branch
    hero["class_mastery"]=0
    return true

static func add_mastery(hero:Dictionary,amount:int)->void:
    ensure_state(hero)
    if str(hero.get("class_branch",""))=="": return
    hero["class_mastery"]=clamp(int(hero.get("class_mastery",0))+max(0,amount),0,100)

static func branch_bonus(hero:Dictionary)->Dictionary:
    ensure_state(hero)
    var class_id:=str(hero.get("class","Warrior"))
    var branch:=str(hero.get("class_branch",""))
    var mastery:float=float(hero.get("class_mastery",0))/100.0
    var bonus:Dictionary={"damage":0.0,"defense":0.0,"crit":0.0,"healing":0.0,"sp_efficiency":0.0,"pet_power":0.0,"range":0.0,"control":0.0}
    if branch=="": return bonus
    match class_id:
        "Warrior":
            if branch=="Warlord": bonus["damage"]=0.12+0.10*mastery
            elif branch=="Guardian": bonus["defense"]=0.15+0.12*mastery
            elif branch=="Berserker": bonus["damage"]=0.08+0.18*mastery; bonus["crit"]=8.0+12.0*mastery
            elif branch=="Dragoon": bonus["damage"]=0.10+0.16*mastery; bonus["range"]=12.0+8.0*mastery; bonus["crit"]=4.0+6.0*mastery
        "Mage":
            if branch=="Elementalist": bonus["damage"]=0.10+0.12*mastery; bonus["control"]=0.10+0.10*mastery
            elif branch=="Voidcaller": bonus["damage"]=0.14+0.14*mastery; bonus["control"]=0.15+0.10*mastery
            elif branch=="Astral Sage": bonus["sp_efficiency"]=0.12+0.13*mastery; bonus["damage"]=0.06+0.08*mastery
            elif branch=="Chronomancer": bonus["sp_efficiency"]=0.10+0.15*mastery; bonus["damage"]=0.08+0.10*mastery; bonus["control"]=0.10+0.12*mastery
        "Archer":
            if branch=="Sniper": bonus["damage"]=0.10+0.12*mastery; bonus["crit"]=7.0+13.0*mastery; bonus["range"]=10.0+10.0*mastery
            elif branch=="Falconer": bonus["pet_power"]=0.15+0.20*mastery; bonus["damage"]=0.06+0.08*mastery
            elif branch=="Trapper": bonus["control"]=0.20+0.15*mastery; bonus["damage"]=0.08+0.10*mastery
            elif branch=="Ballista": bonus["damage"]=0.14+0.18*mastery; bonus["crit"]=5.0+8.0*mastery; bonus["range"]=8.0+12.0*mastery
        "Thief":
            if branch=="Assassin": bonus["damage"]=0.12+0.15*mastery; bonus["crit"]=8.0+14.0*mastery
            elif branch=="Phantom": bonus["defense"]=0.08+0.12*mastery; bonus["control"]=0.08+0.12*mastery
            elif branch=="Venomblade": bonus["damage"]=0.10+0.14*mastery; bonus["control"]=0.18+0.12*mastery
            elif branch=="Shadow Dancer": bonus["damage"]=0.12+0.16*mastery; bonus["crit"]=6.0+10.0*mastery; bonus["range"]=4.0+6.0*mastery
        "Acolyte":
            if branch=="Priest": bonus["healing"]=0.18+0.17*mastery; bonus["defense"]=0.08+0.08*mastery
            elif branch=="Saint": bonus["healing"]=0.10+0.12*mastery; bonus["damage"]=0.12+0.14*mastery
            elif branch=="Exorcist": bonus["damage"]=0.16+0.18*mastery; bonus["control"]=0.10+0.10*mastery
            elif branch=="Oracle": bonus["healing"]=0.12+0.16*mastery; bonus["defense"]=0.10+0.10*mastery; bonus["control"]=0.12+0.10*mastery
        "Merchant":
            if branch=="Blacksmith": bonus["damage"]=0.10+0.12*mastery; bonus["defense"]=0.10+0.12*mastery
            elif branch=="Alchemist": bonus["healing"]=0.12+0.13*mastery; bonus["control"]=0.12+0.12*mastery
            elif branch=="Arsenal Lord": bonus["pet_power"]=0.14+0.20*mastery; bonus["damage"]=0.08+0.12*mastery
            elif branch=="Tactician": bonus["damage"]=0.08+0.12*mastery; bonus["defense"]=0.08+0.12*mastery; bonus["control"]=0.12+0.13*mastery; bonus["sp_efficiency"]=0.06+0.09*mastery
    return bonus

static func summary(hero:Dictionary)->Dictionary:
    ensure_state(hero)
    var class_id:=str(hero.get("class","Warrior"))
    var profile:=class_profile(class_id)
    var skills:Array=SkillSystem.all_skills(class_id)
    var learned:=0
    var total:=0
    for skill in skills:
        var level:=SkillSystem.skill_level(hero,str(skill["id"]))
        learned+=level
        total+=int(skill["max_level"])
    return {"class":class_id,"profile":profile,"available_tier":available_tier(hero),"capstone":capstone(class_id),"learned":learned,"total":total,"branch":str(hero.get("class_branch","")),"mastery":int(hero.get("class_mastery",0)),"branch_bonus":branch_bonus(hero)}
