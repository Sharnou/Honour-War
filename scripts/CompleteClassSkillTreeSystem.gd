extends RefCounted

## Honour War — Complete six-class skill-tree contract, Tiers 1→5.
## Tiers 1–4 use the live SkillSystem skills. Tier 5 uses the profession-rooted
## FifthTierClassTreeSystem skills. This adapter is intentionally read-only so
## it cannot desynchronize combat skill execution from the existing systems.

const SkillSystemClass = preload("res://scripts/SkillSystem.gd")
const FifthTierClassTreeSystem = preload("res://scripts/FifthTierClassTreeSystem.gd")

const CLASSES:Array[String] = ["Warrior","Mage","Archer","Thief","Acolyte","Merchant"]
const TIER_LEVELS:Dictionary = {1:1,2:25,3:50,4:150,5:200}
const TIER_NAMES:Dictionary = {1:"Foundation",2:"Specialization",3:"Advanced",4:"Mastery",5:"Transcendence"}

const TIER_ROLE:Dictionary = {
    1:"Core profession identity",
    2:"Specialization branch",
    3:"Advanced combat mastery",
    4:"Mastery capstone",
    5:"Transcendent profession-rooted evolution"
}

static func classes()->Array[String]:
    return CLASSES.duplicate()

static func tier_level(tier:int)->int:
    return int(TIER_LEVELS.get(tier,999))

static func tier_name(tier:int)->String:
    return str(TIER_NAMES.get(tier,"Unknown"))

static func skills_for_tier(class_id:String,tier:int)->Array:
    if tier == 5:
        return FifthTierClassTreeSystem.fifth_tier_skills(class_id)
    var result:Array = []
    for skill in SkillSystemClass.all_skills(class_id):
        if int(skill.get("tier",0)) == tier:
            result.append(skill.duplicate(true))
    return result

static func all_tiers(class_id:String)->Dictionary:
    var result:Dictionary = {}
    for tier in range(1,6):
        result[tier] = skills_for_tier(class_id,tier)
    return result

static func skill_tree(class_id:String)->Dictionary:
    if class_id not in CLASSES:
        return {}
    var tiers := all_tiers(class_id)
    var nodes:Array = []
    for tier in range(1,6):
        for skill in tiers[tier]:
            var node:Dictionary = skill.duplicate(true)
            node["class_id"] = class_id
            node["tier"] = tier
            node["tier_name"] = tier_name(tier)
            node["unlock_level"] = tier_level(tier)
            node["tier_role"] = TIER_ROLE[tier]
            nodes.append(node)
    return {
        "class_id":class_id,
        "max_tier":5,
        "tier_levels":TIER_LEVELS.duplicate(),
        "tiers":tiers,
        "nodes":nodes,
        "fifth_tier_identity":FifthTierClassTreeSystem.natural_fifth_tier_profile(class_id)
    }

static func branch_summary(class_id:String)->Dictionary:
    var profile:Dictionary = ClassTreeSystemProfileFallback.profile(class_id)
    return {
        "class_id":class_id,
        "branches":profile.get("branches",[]),
        "branch_descriptions":profile.get("branch_descriptions",{})
    }

static func progression(hero:Dictionary)->Dictionary:
    var class_id := str(hero.get("class_id",hero.get("class","Warrior")))
    var level := int(hero.get("level",1))
    var unlocked := 1
    for tier in range(1,6):
        if level >= tier_level(tier):
            unlocked = tier
    return {"class_id":class_id,"level":level,"unlocked_tier":unlocked,"next_tier":min(5,unlocked+1)}

static func validate()->Array[String]:
    var failures:Array[String] = []
    for class_id in CLASSES:
        var tree_data := skill_tree(class_id)
        for tier in range(1,6):
            var skills:Array = tree_data["tiers"][tier]
            if skills.is_empty():
                failures.append("%s tier %d has no skills" % [class_id,tier])
            for skill in skills:
                if str(skill.get("id","")).is_empty():
                    failures.append("%s tier %d has skill without id" % [class_id,tier])
                if tier == 5:
                    var profile:Dictionary = FifthTierClassTreeSystem.natural_fifth_tier_profile(class_id)
                    var weapon := str(skill.get("weapon",""))
                    if weapon != str(profile.get("primary_weapon","")) and weapon != str(profile.get("secondary_weapon","")):
                        failures.append("%s Fifth Tier skill is not profession-weapon rooted" % class_id)
    return failures


class ClassTreeSystemProfileFallback:
    static func profile(class_id:String)->Dictionary:
        match class_id:
            "Warrior": return {"branches":["Warlord","Guardian","Berserker","Dragoon"],"branch_descriptions":{"Warlord":"Weapon damage and execution.","Guardian":"Defense and survivability.","Berserker":"Critical burst.","Dragoon":"Reach and anti-MVP pressure."}}
            "Mage": return {"branches":["Elementalist","Voidcaller","Astral Sage","Chronomancer"],"branch_descriptions":{"Elementalist":"Elemental damage.","Voidcaller":"Void control and burst.","Astral Sage":"Mana and party utility.","Chronomancer":"Tempo and cooldown control."}}
            "Archer": return {"branches":["Sniper","Falconer","Trapper","Ballista"],"branch_descriptions":{"Sniper":"Range and precision.","Falconer":"Pet synergy.","Trapper":"Control fields.","Ballista":"Heavy ranged power."}}
            "Thief": return {"branches":["Assassin","Phantom","Venomblade","Shadow Dancer"],"branch_descriptions":{"Assassin":"Critical execution.","Phantom":"Stealth and mobility.","Venomblade":"Poison pressure.","Shadow Dancer":"Combo mobility."}}
            "Acolyte": return {"branches":["Priest","Saint","Exorcist","Oracle"],"branch_descriptions":{"Priest":"Healing and sustain.","Saint":"Holy power.","Exorcist":"Holy damage and purification.","Oracle":"Foresight and barriers."}}
            "Merchant": return {"branches":["Blacksmith","Alchemist","Arsenal Lord","Tactician"],"branch_descriptions":{"Blacksmith":"Weapons and refinement.","Alchemist":"Consumables and elemental pressure.","Arsenal Lord":"Equipment and pet synergy.","Tactician":"Battlefield utility."}}
            _: return {}
