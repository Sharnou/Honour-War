class_name TeleportSystem
extends RefCounted

const MAPS := {
	0: {"name":"Prontera", "type":"town", "width":1152, "height":648},
	1: {"name":"Payon", "type":"town", "width":1152, "height":648},
	2: {"name":"Geffen", "type":"town", "width":1152, "height":648},
	3: {"name":"Morroc", "type":"town", "width":1152, "height":648},
	4: {"name":"Izlude", "type":"town", "width":1152, "height":648},
	10: {"name":"Prontera Sewer", "type":"dungeon", "width":1152, "height":648},
	11: {"name":"Payon Cave", "type":"dungeon", "width":1152, "height":648},
	12: {"name":"Geffen Tower", "type":"dungeon", "width":1152, "height":648},
	13: {"name":"Morroc Ruins", "type":"dungeon", "width":1152, "height":648}
}

static func parse_go(command:String) -> Dictionary:
	var text:=command.strip_edges()
	if text.begins_with("@"): text=text.substr(1)
	var parts:=text.split(" ", false)
	if parts.size()<3 or parts[0].to_lower()!="go":
		return {"ok":false,"error":"Usage: @go <map_id> <x>:<y>  e.g. @go 0 230:220"}
	var map_id:=int(parts[1])
	if not MAPS.has(map_id): return {"ok":false,"error":"Unknown map ID %d." % map_id}
	var coords:=parts[2].split(":", false)
	if coords.size()!=2: return {"ok":false,"error":"Coordinates must use X:Y, e.g. 230:220."}
	var x:=int(coords[0]); var y:=int(coords[1])
	var map:Dictionary=MAPS[map_id]
	if x<0 or x>=int(map["width"]) or y<0 or y>=int(map["height"]):
		return {"ok":false,"error":"Coordinates outside %s bounds." % map["name"]}
	return {"ok":true,"map_id":map_id,"x":x,"y":y,"name":map["name"],"type":map["type"]}

static func map_name(map_id:int)->String:
	return str(MAPS.get(map_id,{"name":"Unknown"})["name"])

static func is_dungeon(map_id:int)->bool:
	return str(MAPS.get(map_id,{"type":""})["type"])=="dungeon"

static func coordinate(map_id:int,x:float,y:float)->String:
	return "@go %d %d:%d" % [map_id,int(x),int(y)]
