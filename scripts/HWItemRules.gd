class_name HWItemRules
extends RefCounted

## Canonical Honour War itemization rules.
## Server-authoritative validation must call these rules before applying state changes.

const RARITIES:Array[String]=["Common","Uncommon","Rare","Epic","Legendary","Mythic"]
const SOCKET_MIN:int=0
const SOCKET_MAX:int=4
const REFINE_MIN:int=0
const REFINE_MAX:int=15
const FOUR_SOCKET_BASE_MULTIPLIER:float=0.72
const THREE_SOCKET_BASE_MULTIPLIER:float=0.84
const TWO_SOCKET_BASE_MULTIPLIER:float=0.94

static func normalize_rarity(value:String)->String:
	var rarity:String=value.strip_edges().capitalize()
	return rarity if rarity in RARITIES else "Common"

static func socket_base_multiplier(socket_count:int)->float:
	match clamp(socket_count,SOCKET_MIN,SOCKET_MAX):
		4: return FOUR_SOCKET_BASE_MULTIPLIER
		3: return THREE_SOCKET_BASE_MULTIPLIER
		2: return TWO_SOCKET_BASE_MULTIPLIER
		_: return 1.0

static func validate_socket_count(item:Dictionary)->Dictionary:
	var sockets:int=int(item.get("sockets",item.get("card_slots",0)))
	if sockets<SOCKET_MIN or sockets>SOCKET_MAX:
		return {"ok":false,"reason":"invalid_socket_count"}
	return {"ok":true,"sockets":sockets,"base_multiplier":socket_base_multiplier(sockets)}

static func validate_refine(level:int)->Dictionary:
	if level<REFINE_MIN or level>REFINE_MAX:
		return {"ok":false,"reason":"invalid_refine_level"}
	return {"ok":true,"refine":level}

static func validate_item(item:Dictionary)->Dictionary:
	if item.is_empty(): return {"ok":false,"reason":"empty_item"}
	var rarity:String=normalize_rarity(str(item.get("rarity","Common")))
	var sockets:int=int(item.get("sockets",item.get("card_slots",0)))
	var refine:int=int(item.get("refine",0))
	if sockets<0 or sockets>4: return {"ok":false,"reason":"invalid_socket_count"}
	if refine<0 or refine>15: return {"ok":false,"reason":"invalid_refine_level"}
	var cards:Variant=item.get("socketed_cards",item.get("cards",[]))
	if not cards is Array: return {"ok":false,"reason":"invalid_card_container"}
	if (cards as Array).size()>sockets: return {"ok":false,"reason":"card_count_exceeds_sockets"}
	return {"ok":true,"rarity":rarity,"sockets":sockets,"refine":refine,"base_multiplier":socket_base_multiplier(sockets)}

static func affixes()->Dictionary:
	return {
		"Might":"flat_stat",
		"Finesse":"flat_stat",
		"Resolve":"flat_stat",
		"Insight":"flat_stat",
		"Spirit":"flat_stat",
		"Fortune":"flat_stat",
		"Health":"flat_secondary",
		"Mana":"flat_secondary",
		"Stamina":"flat_secondary",
		"Physical Power":"flat_secondary",
		"Spell Power":"flat_secondary",
		"Weapon Damage":"percent_damage",
		"Armor":"flat_secondary",
		"Guard":"flat_secondary",
		"Ward":"flat_secondary",
		"Accuracy":"flat_secondary",
		"Evasion":"flat_secondary",
		"Critical Chance":"percent_chance",
		"Critical Severity":"percent_multiplier",
		"Attack Speed":"percent_speed",
		"Cast Speed":"percent_speed",
		"Move Speed":"percent_speed",
		"Cooldown Recovery":"percent_recovery",
		"Healing Power":"percent_healing",
		"Barrier Power":"percent_barrier",
		"Life on Hit":"flat_proc",
		"Mana on Hit":"flat_proc",
		"Threat":"percent_threat",
		"Loot Fortune":"percent_loot",
		"Status Potency":"percent_status",
		"Status Resistance":"percent_status_resist",
		"Fire Resistance":"percent_resistance",
		"Frost Resistance":"percent_resistance",
		"Storm Resistance":"percent_resistance",
		"Earth Resistance":"percent_resistance",
		"Shadow Resistance":"percent_resistance",
		"Poison Resistance":"percent_resistance",
		"Bleed Resistance":"percent_resistance",
		"Control Resistance":"percent_resistance",
		"Boss Damage":"percent_damage",
		"Elite Damage":"percent_damage",
		"Damage Reduction":"percent_reduction",
		"Tenacity":"percent_status_resist",
		"Resource Efficiency":"percent_resource"
	}

static func affix_count()->int:
	return affixes().size()

static func is_valid_affix(name:String)->bool:
	return affixes().has(name)

static func pvp_multiplier_for_affix(name:String)->float:
	# PvP never inherits unrestricted PvE boss/elite scaling.
	if name in ["Boss Damage","Elite Damage","Loot Fortune","Threat"]:
		return 0.0
	return 1.0

static func validate_affix_value(name:String,value:float)->Dictionary:
	if not is_valid_affix(name): return {"ok":false,"reason":"unknown_affix"}
	if not is_finite(value): return {"ok":false,"reason":"non_finite_affix_value"}
	return {"ok":true,"name":name,"value":value,"pvp_multiplier":pvp_multiplier_for_affix(name)}
