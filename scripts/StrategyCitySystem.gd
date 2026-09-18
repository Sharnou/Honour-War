class_name StrategyCitySystem
extends RefCounted

## Persistent city/army layer for Honour War.
## A city produces soldiers, upgrades the hero, mixes cards, and controls banks.
## Banks only pay after their guarding monster has been defeated.

const MAX_SOLDIER_LEVEL:int = 50
const RESPAWN_BATCH:int = 5
const MAX_CITY_LEVEL:int = 10
const BANK_BASE_INCOME:int = 250

static func ensure_state(hero:Dictionary) -> void:
    if not hero.has("cities") or not hero["cities"] is Dictionary:
        hero["cities"] = {}
    if not hero.has("soldier_roster") or not hero["soldier_roster"] is Array:
        hero["soldier_roster"] = []
    if not hero.has("soldier_deaths") or not hero["soldier_deaths"] is int:
        hero["soldier_deaths"] = 0
    if not hero.has("bank_state") or not hero["bank_state"] is Dictionary:
        hero["bank_state"] = {}
    if not hero.has("tower_defense") or not hero["tower_defense"] is Dictionary:
        hero["tower_defense"] = {"level":0,"waves_cleared":0}
    if not hero.has("city_upgrade_state") or not hero["city_upgrade_state"] is Dictionary:
        hero["city_upgrade_state"] = {"card_mix":0,"weapon_upgrade":0,"skill_upgrade":0,"minimap_overlay":false}

static func build_city(hero:Dictionary, city_name:String, map_id:int=0) -> bool:
    ensure_state(hero)
    var key:String = city_name.strip_edges()
    if key.is_empty() or hero["cities"].has(key):
        return false
    hero["cities"][key] = {"name":key,"map_id":map_id,"level":1,"production":0,"hero_skill_level":1}
    return true

static func upgrade_city(hero:Dictionary, city_name:String) -> bool:
    ensure_state(hero)
    if not hero["cities"].has(city_name):
        return false
    var city:Dictionary = hero["cities"][city_name]
    var level:int = int(city.get("level",1))
    if level >= MAX_CITY_LEVEL:
        return false
    city["level"] = level + 1
    hero["cities"][city_name] = city
    return true

static func produce_soldier(hero:Dictionary, city_name:String, class_id:String) -> Dictionary:
    ensure_state(hero)
    if not hero["cities"].has(city_name):
        return {}
    var city:Dictionary = hero["cities"][city_name]
    var level:int = clampi(int(city.get("level",1)),1,MAX_CITY_LEVEL)
    var soldier:Dictionary = {
        "id":"soldier-%06d" % (hero["soldier_roster"].size()+1),
        "class":class_id,
        "level":1,
        "max_level":MAX_SOLDIER_LEVEL,
        "city":city_name,
        "map_id":int(city.get("map_id",0)),
        "alive":true,
        "bank_id":"",
        "skills":["Auto Skill I","Auto Skill II"]
    }
    hero["soldier_roster"].append(soldier)
    city["production"] = int(city.get("production",0)) + 1
    hero["cities"][city_name] = city
    return soldier

static func assign_soldier_to_bank(hero:Dictionary, soldier_id:String, bank_id:String) -> bool:
    ensure_state(hero)
    var bank:Dictionary = hero["bank_state"].get(bank_id,{})
    if not bool(bank.get("guard_defeated",false)):
        return false
    for soldier in hero["soldier_roster"]:
        if soldier is Dictionary and str(soldier.get("id","")) == soldier_id and bool(soldier.get("alive",false)):
            soldier["bank_id"] = bank_id
            return true
    return false

static func defeat_bank_guard(hero:Dictionary, bank_id:String, monster_name:String) -> bool:
    ensure_state(hero)
    hero["bank_state"][bank_id] = {"guard_defeated":true,"guard":monster_name,"income":BANK_BASE_INCOME,"claimed":0}
    return true

static func claim_bank_income(hero:Dictionary, bank_id:String) -> int:
    ensure_state(hero)
    var bank:Dictionary = hero["bank_state"].get(bank_id,{})
    if not bool(bank.get("guard_defeated",false)):
        return 0
    var soldiers:int = 0
    for soldier in hero["soldier_roster"]:
        if soldier is Dictionary and bool(soldier.get("alive",false)) and str(soldier.get("bank_id","")) == bank_id:
            soldiers += 1
    if soldiers <= 0:
        return 0
    var amount:int = int(bank.get("income",BANK_BASE_INCOME)) * soldiers
    hero["zeny"] = int(hero.get("zeny",0)) + amount
    bank["claimed"] = int(bank.get("claimed",0)) + amount
    hero["bank_state"][bank_id] = bank
    return amount

static func soldier_died(hero:Dictionary, soldier_id:String) -> Dictionary:
    ensure_state(hero)
    for soldier in hero["soldier_roster"]:
        if soldier is Dictionary and str(soldier.get("id","")) == soldier_id:
            if not bool(soldier.get("alive",true)):
                return {"respawned":false,"id":soldier_id}
            soldier["alive"] = false
            soldier["bank_id"] = ""
            hero["soldier_deaths"] = int(hero.get("soldier_deaths",0)) + 1
            var respawned:bool = false
            if int(hero["soldier_deaths"]) % RESPAWN_BATCH == 0:
                for replacement in hero["soldier_roster"]:
                    if replacement is Dictionary and not bool(replacement.get("alive",true)):
                        replacement["alive"] = true
                        replacement["level"] = 1
                        replacement["bank_id"] = ""
                        replacement["respawn_city"] = replacement.get("city","")
                        respawned = true
            return {"respawned":respawned,"id":soldier_id,"deaths":hero["soldier_deaths"]}
    return {}

static func upgrade_hero_skill_building(hero:Dictionary, city_name:String) -> bool:
    ensure_state(hero)
    if not hero["cities"].has(city_name):
        return false
    var city:Dictionary = hero["cities"][city_name]
    city["hero_skill_level"] = int(city.get("hero_skill_level",1)) + 1
    hero["cities"][city_name] = city
    hero["city_upgrade_state"]["skill_upgrade"] = int(hero["city_upgrade_state"].get("skill_upgrade",0)) + 1
    return true

static func mix_cards(hero:Dictionary, card_a:String, card_b:String) -> Dictionary:
    ensure_state(hero)
    if card_a == card_b or not hero.get("cards",[]).has(card_a) or not hero.get("cards",[]).has(card_b):
        return {"ok":false,"reason":"two distinct owned cards are required"}
    hero["cards"].erase(card_a)
    hero["cards"].erase(card_b)
    var mixed:String = "Mixed "+card_a+" + "+card_b+" Card"
    hero["cards"].append(mixed)
    hero["city_upgrade_state"]["card_mix"] = int(hero["city_upgrade_state"].get("card_mix",0)) + 1
    return {"ok":true,"card":mixed}

static func upgrade_weapon(hero:Dictionary, slot:String) -> bool:
    ensure_state(hero)
    if not hero.has("equipment_refine") or not hero["equipment_refine"] is Dictionary:
        hero["equipment_refine"] = {}
    var current:int = int(hero["equipment_refine"].get(slot,0))
    if current >= 15:
        return false
    hero["equipment_refine"][slot] = current + 1
    hero["city_upgrade_state"]["weapon_upgrade"] = int(hero["city_upgrade_state"].get("weapon_upgrade",0)) + 1
    return true

static func upgrade_tower(hero:Dictionary) -> bool:
    ensure_state(hero)
    var tower:Dictionary = hero["tower_defense"]
    tower["level"] = min(50,int(tower.get("level",0))+1)
    hero["tower_defense"] = tower
    return true

static func clear_tower_wave(hero:Dictionary) -> bool:
    ensure_state(hero)
    var tower:Dictionary = hero["tower_defense"]
    tower["waves_cleared"] = int(tower.get("waves_cleared",0)) + 1
    hero["tower_defense"] = tower
    return true

static func enable_minimap_overlay(hero:Dictionary) -> void:
    ensure_state(hero)
    hero["city_upgrade_state"]["minimap_overlay"] = true

static func city_summary(hero:Dictionary) -> Dictionary:
    ensure_state(hero)
    return {"cities":hero["cities"].size(),"soldiers":hero["soldier_roster"].size(),"deaths":int(hero["soldier_deaths"]),"banks":hero["bank_state"].size(),"tower_level":int(hero["tower_defense"].get("level",0)),"minimap_overlay":bool(hero["city_upgrade_state"].get("minimap_overlay",false))}
