extends RefCounted

const City = preload("res://scripts/StrategyCitySystem.gd")
const Loot = preload("res://scripts/LootProgressionSystem.gd")

static func run() -> void:
    var hero:Dictionary = {"level":50,"age":18,"zeny":0,"cards":["A","B"],"equipment":{}}
    City.ensure_state(hero)
    assert(City.build_city(hero,"Prontera Base",0))
    assert(City.produce_soldier(hero,"Prontera Base","Warrior").size()>0)
    assert(City.defeat_bank_guard(hero,"bank-0","Orc Guard"))
    var soldier:Dictionary = hero["soldier_roster"][0]
    assert(City.assign_soldier_to_bank(hero,str(soldier["id"]),"bank-0"))
    assert(City.claim_bank_income(hero,"bank-0")>0)
    for i in range(5):
        var id:String = str(hero["soldier_roster"][0]["id"])
        hero["soldier_roster"][0]["alive"] = true
        City.soldier_died(hero,id)
    assert(int(hero["soldier_deaths"])==5)
    assert(bool(hero["soldier_roster"][0].get("alive",false)))
    assert(City.upgrade_weapon(hero,"weapon"))
    assert(City.upgrade_hero_skill_building(hero,"Prontera Base"))
    City.enable_minimap_overlay(hero)
    assert(bool(hero["city_upgrade_state"]["minimap_overlay"]))
    assert(Loot.clamp_equipment_drop_count(9)==2)
    assert(Loot.clamp_card_drop_count(9)==2)
