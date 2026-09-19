extends Node

## Rental-only Super Champion service. Never part of character creation.
const SkillSystemClass = preload("res://scripts/SkillSystem.gd")
const PetSystemClass = preload("res://scripts/PetSystem.gd")
const RENT_PRICE_ZENY:int = 1000000
const SS_CLASS_NAME:String = "Super Champion (Rental Only)"
const SS_LEVEL:int = 250
const SS_MAX_LEVEL:int = 250
const SS_DEFAULT_SKILL:String = "Champion's Asura"
const SS_RENT_NPC_NAME:String = "Rent"
const COLLECTION_ITEM_LIMIT:int = 50
const COLLECTION_CARD_LIMIT:int = 20
const RENT_UI_CONTRACT:String = '{"go_button":"GO"}'

var rented:bool = false
var ss:Dictionary = {}
var rent_panel_open:bool = false

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS

func is_rented() -> bool:
    return rented

func get_ss() -> Dictionary:
    return ss.duplicate(true)

func rent(hero:Dictionary) -> Dictionary:
    if rented:
        return {"ok":false,"reason":"already_rented"}
    var zeny:int = int(hero.get("zeny",0))
    if zeny < RENT_PRICE_ZENY:
        return {"ok":false,"reason":"insufficient_zeny","required":RENT_PRICE_ZENY}
    hero["zeny"] = zeny - RENT_PRICE_ZENY
    ss = _new_ss(hero)
    rented = true
    return {"ok":true,"ss":ss.duplicate(true)}

func release() -> void:
    rented = false
    ss = {}
    rent_panel_open = false

func set_rental_state(value:bool,data:Dictionary={}) -> void:
    rented = value
    ss = data.duplicate(true) if value else {}

func open_rent_panel() -> void:
    rent_panel_open = true

func close_rent_panel() -> void:
    rent_panel_open = false

func can_create_as_character_class(class_id:String) -> bool:
    var normalized:String = class_id.strip_edges().to_upper()
    if normalized != "SS":
        return true
    return false

func all_fifth_job_skills(class_id:String) -> Array:
    var normalized:String = class_id.strip_edges()
    var skills:Array = SkillSystemClass.all_skills(normalized)
    var result:Array = []
    for skill in skills:
        if int(skill.get("tier",0)) >= 5:
            result.append(skill.duplicate(true))
    return result

func fifth_job_equipment_classes() -> Dictionary:
    return {
        "Warrior":"War Emperor",
        "Mage":"Arcane Sovereign",
        "Archer":"Celestial Ranger",
        "Thief":"Shadow Emperor",
        "Acolyte":"Divine Saint",
        "Merchant":"Forge Overlord"
    }

func rental_profile() -> Dictionary:
    return {
        "name":"Champion's Asura",
        "class":SS_CLASS_NAME,
        "rental_only":true,
        "level":SS_LEVEL,
        "max_level":SS_MAX_LEVEL,
        "price_zeny":RENT_PRICE_ZENY,
        "default_skill":SS_DEFAULT_SKILL,
        "collection_item_limit":COLLECTION_ITEM_LIMIT,
        "collection_card_limit":COLLECTION_CARD_LIMIT,
        "behavior":{"follow":true,"heal":true,"fight":true},
        "ui": {"go_button":"GO"}
    }

func _new_ss(hero:Dictionary) -> Dictionary:
    var pet:Dictionary = PetSystemClass.new_pet("Warrior")
    return {
        "name":"Champion's Asura",
        "class":SS_CLASS_NAME,
        "rental_only":true,
        "level":SS_LEVEL,
        "max_level":SS_MAX_LEVEL,
        "hp":25000,
        "max_hp":25000,
        "sp":5000,
        "max_sp":5000,
        "refine":15,
        "age":maxi(18,int(hero.get("age",18))),
        "status_points":{"STR":150,"AGI":120,"VIT":180,"INT":100,"DEX":140,"LUK":100},
        "skills":[SS_DEFAULT_SKILL],
        "skill_runtime":SkillSystemClass.all_skills("Warrior"),
        "fifth_job_skills":all_fifth_job_skills("Warrior"),
        "fifth_job_equipment_class":fifth_job_equipment_classes()["Warrior"],
        "pet":pet,
        "behavior":{"follow":true,"heal":true,"fight":true},
        "inventory":{},
        "cards":[]
    }
