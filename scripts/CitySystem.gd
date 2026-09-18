class_name CitySystem
extends RefCounted

const STRATEGY = preload("res://scripts/StrategyCitySystem.gd")

## MMORPG/ARPG city registry.
## Cities are permanent social/service hubs only. They have no progression,
## resource inventories, production queues, territory ownership, army, bank,
## barracks, or tower-defense mechanics.

const CITIES:Array = [
	"Prontera",
	"Morroc",
	"Payon",
	"Geffen",
	"Juno",
	"Alberta",
	"Izlude"
]

# Kept as an empty compatibility registry because older QA/integration code
# probes this symbol. It intentionally contains NO buildable gameplay systems.
const BUILDINGS:Array = []

const SERVICES:Dictionary = {
	"healing": {"name":"Healing / Inn", "npc":"Innkeeper / Healer", "description":"Restore HP and SP and provide a safe respawn point."},
	"shop": {"name":"General Shop", "npc":"Merchant", "description":"Buy and sell normal consumables and utility items."},
	"equipment": {"name":"Equipment Shop", "npc":"Equipment Merchant", "description":"Browse weapons, armor and accessories."},
	"refinement": {"name":"Blacksmith / Refinement", "npc":"Blacksmith", "description":"Refine equipment using Zeny and Phracon, Emveretarcon or Oridecon."},
	"cards": {"name":"Card Service", "npc":"Card Expert", "description":"View, manage and apply character card collection services."},
	"market": {"name":"Player Market", "npc":"Market Clerk", "description":"Access player-to-player buying and selling services."},
	"magic": {"name":"Magic Tower", "npc":"Mage Guild", "description":"Magic, skill and class-related city services."},
	"quests": {"name":"Quest Board", "npc":"Quest Master", "description":"Accept and turn in quests and view progression."},
	"warp": {"name":"Warp Gate", "npc":"Warp Keeper", "description":"Fast travel between unlocked towns, fields and dungeons."},
	"rent": {"name":"Rent NPC", "npc":"Rent NPC", "description":"Rent the SS (SUPER SHAMBION) companion for 1,000,000 Zeny."},
	"social": {"name":"Social Hub", "npc":"Town Guide", "description":"Chat, party formation, player interaction and local information."}
}

static func city_ids() -> Array:
	return CITIES.duplicate()

static func is_city(city_id:String) -> bool:
	return CITIES.has(city_id)

static func new_city(city_id:String="Prontera") -> Dictionary:
	var normalized:String = city_id if is_city(city_id) else "Prontera"
	return {
		"id": normalized,
		"name": normalized,
		"services": SERVICES.keys()
	}

static func available_services(_city:Dictionary={}) -> Array:
	return SERVICES.keys()

static func has_service(_city:Dictionary, service_id:String) -> bool:
	return SERVICES.has(service_id)

static func service(service_id:String) -> Dictionary:
	var value:Variant = SERVICES.get(service_id,{})
	return value.duplicate(true) if value is Dictionary else {}

static func city_snapshot(city_id:String="Prontera") -> Dictionary:
	var city:Dictionary = new_city(city_id)
	var service_list:Array = []
	for service_id in SERVICES.keys():
		service_list.append(service(str(service_id)))
	city["service_list"] = service_list
	return city

# Compatibility shims for the legacy prototype caller in Main.gd.
# These functions deliberately perform no city progression, spending, building,
# production, territory, bank or defense action.
static func can_build(_city:Dictionary, building:String) -> bool:
    return building in ["soldier_production","card_mixing","weapon_upgrade","skill_upgrade","tower_defense","minimap_overlay"]

static func build(city:Dictionary, building:String) -> Dictionary:
    var result:Dictionary=city.duplicate(true)
    var hero:Dictionary=result.get("hero_state",{})
    STRATEGY.ensure_state(hero)
    if building=="soldier_production":
        result["production_enabled"]=true
    elif building=="card_mixing":
        result["card_mixing_enabled"]=true
    elif building=="weapon_upgrade":
        result["weapon_upgrade_enabled"]=true
    elif building=="skill_upgrade":
        result["skill_upgrade_enabled"]=true
    elif building=="tower_defense":
        result["tower_defense_enabled"]=true
    elif building=="minimap_overlay":
        STRATEGY.enable_minimap_overlay(hero)
    result["hero_state"]=hero
    return result

static func upgrade_city(city:Dictionary) -> Dictionary:
    var result:Dictionary=city.duplicate(true)
    result["level"]=min(10,int(result.get("level",1))+1)
    return result

static func build_player_city(hero:Dictionary,city_name:String,map_id:int=0)->bool:
    return STRATEGY.build_city(hero,city_name,map_id)

static func produce_soldier(hero:Dictionary,city_name:String,class_id:String)->Dictionary:
    return STRATEGY.produce_soldier(hero,city_name,class_id)

static func defeat_bank_guard(hero:Dictionary,bank_id:String,monster_name:String)->bool:
    return STRATEGY.defeat_bank_guard(hero,bank_id,monster_name)

static func assign_soldier_to_bank(hero:Dictionary,soldier_id:String,bank_id:String)->bool:
    return STRATEGY.assign_soldier_to_bank(hero,soldier_id,bank_id)

static func claim_bank_income(hero:Dictionary,bank_id:String)->int:
    return STRATEGY.claim_bank_income(hero,bank_id)

static func soldier_died(hero:Dictionary,soldier_id:String)->Dictionary:
    return STRATEGY.soldier_died(hero,soldier_id)

static func upgrade_tower(hero:Dictionary)->bool:
    return STRATEGY.upgrade_tower(hero)

static func clear_tower_wave(hero:Dictionary)->bool:
    return STRATEGY.clear_tower_wave(hero)

static func mix_cards(hero:Dictionary,card_a:String,card_b:String)->Dictionary:
    return STRATEGY.mix_cards(hero,card_a,card_b)

static func upgrade_weapon(hero:Dictionary,slot:String)->bool:
    return STRATEGY.upgrade_weapon(hero,slot)

static func upgrade_hero_skill_building(hero:Dictionary,city_name:String)->bool:
    return STRATEGY.upgrade_hero_skill_building(hero,city_name)

static func enable_minimap_overlay(hero:Dictionary)->void:
    STRATEGY.enable_minimap_overlay(hero)
