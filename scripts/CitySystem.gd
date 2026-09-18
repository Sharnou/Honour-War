class_name CitySystem
extends RefCounted

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
