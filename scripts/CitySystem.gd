class_name CitySystem
extends RefCounted

const BUILDINGS := {
	"Town Hall":{"wood":50,"stone":50,"gold":500},
	"Blacksmith":{"wood":30,"stone":20,"gold":300},
	"Market":{"wood":40,"stone":20,"gold":350},
	"Barracks":{"wood":60,"stone":60,"gold":600},
	"Magic Tower":{"wood":40,"stone":70,"gold":700}
}

static func new_city() -> Dictionary:
	return {"level":1, "wood":0, "stone":0, "gold":0, "buildings":{}}

static func upgrade_city(city:Dictionary) -> Dictionary:
	var result=city.duplicate(true)
	result["level"]=int(result.get("level", 1))+1
	return result

static func can_build(city:Dictionary, building:String) -> bool:
	if not BUILDINGS.has(building): return false
	var cost:Dictionary=BUILDINGS[building]
	return int(city.get("wood",0)) >= int(cost["wood"]) and int(city.get("stone",0)) >= int(cost["stone"]) and int(city.get("gold",0)) >= int(cost["gold"])

static func build(city:Dictionary, building:String) -> Dictionary:
	var result=city.duplicate(true)
	if not can_build(result, building): return result
	var cost:Dictionary=BUILDINGS[building]
	result["wood"]=int(result.get("wood",0))-int(cost["wood"])
	result["stone"]=int(result.get("stone",0))-int(cost["stone"])
	result["gold"]=int(result.get("gold",0))-int(cost["gold"])
	if not result.has("buildings"): result["buildings"]={}
	result["buildings"][building]=int(result["buildings"].get(building,0))+1
	return result
