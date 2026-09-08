class_name TeleportSystem
extends RefCounted

const MAPS := {
	0: {"name":"Prontera", "type":"town", "width":1200, "height":700, "spawn_x":600, "spawn_y":350},
	1: {"name":"Payon", "type":"town", "width":1200, "height":700, "spawn_x":600, "spawn_y":350},
	2: {"name":"Geffen", "type":"town", "width":1200, "height":700, "spawn_x":600, "spawn_y":350},
	3: {"name":"Morroc", "type":"town", "width":1200, "height":700, "spawn_x":600, "spawn_y":350},
	4: {"name":"Izlude", "type":"town", "width":1200, "height":700, "spawn_x":600, "spawn_y":350},
	5: {"name":"Alberta", "type":"town", "width":1200, "height":700, "spawn_x":600, "spawn_y":350},
	6: {"name":"Comodo", "type":"town", "width":1200, "height":700, "spawn_x":600, "spawn_y":350},
	7: {"name":"Aldebaran", "type":"town", "width":1200, "height":700, "spawn_x":600, "spawn_y":350},
	8: {"name":"Lutie", "type":"town", "width":1200, "height":700, "spawn_x":600, "spawn_y":350},
	9: {"name":"Umbala", "type":"town", "width":1200, "height":700, "spawn_x":600, "spawn_y":350},
	10: {"name":"Prontera Sewer", "type":"dungeon", "width":1400, "height":900, "spawn_x":180, "spawn_y":450, "entrance":0},
	11: {"name":"Payon Cave", "type":"dungeon", "width":1400, "height":900, "spawn_x":180, "spawn_y":450, "entrance":1},
	12: {"name":"Geffen Tower", "type":"dungeon", "width":1400, "height":900, "spawn_x":180, "spawn_y":450, "entrance":2},
	13: {"name":"Morroc Ruins", "type":"dungeon", "width":1400, "height":900, "spawn_x":180, "spawn_y":450, "entrance":3},
	14: {"name":"Orc Dungeon", "type":"dungeon", "width":1400, "height":900, "spawn_x":180, "spawn_y":450, "entrance":5},
	15: {"name":"Ice Cave", "type":"dungeon", "width":1400, "height":900, "spawn_x":180, "spawn_y":450, "entrance":8},
	16: {"name":"Clock Tower", "type":"dungeon", "width":1400, "height":900, "spawn_x":180, "spawn_y":450, "entrance":7},
	17: {"name":"Sunken Ship", "type":"dungeon", "width":1400, "height":900, "spawn_x":180, "spawn_y":450, "entrance":6},
	18: {"name":"Hidden Forest", "type":"dungeon", "width":1400, "height":900, "spawn_x":180, "spawn_y":450, "entrance":9},
	19: {"name":"Ancient Catacombs", "type":"dungeon", "width":1400, "height":900, "spawn_x":180, "spawn_y":450, "entrance":4}
}

const ALIASES := {
	"prontera":0,
	"payon":1,
	"geffen":2,
	"morroc":3,
	"izlude":4,
	"alberta":5,
	"comodo":6,
	"aldebaran":7,
	"lutie":8,
	"umbala":9,
	"prontera sewer":10,
	"payon cave":11,
	"geffen tower":12,
	"morroc ruins":13,
	"orc dungeon":14,
	"ice cave":15,
	"clock tower":16,
	"sunken ship":17,
	"hidden forest":18,
	"ancient catacombs":19,
	"prt":0,
	"pay":1,
	"gef":2,
	"moc":3,
	"izl":4,
	"alb":5,
	"com":6,
	"alde":7,
	"lut":8,
	"umb":9
}

static func default_point(map_id:int)->Vector2:
	var data:Dictionary=MAPS.get(map_id,{"spawn_x":600,"spawn_y":350})
	return Vector2(float(data.get("spawn_x",600)),float(data.get("spawn_y",350)))

static func resolve_map(value:String)->int:
	var token:String=value.strip_edges().to_lower()
	if token.is_valid_int():
		var numeric:int=int(token)
		return numeric if MAPS.has(numeric) else -1
	return int(ALIASES.get(token,-1))

static func parse_coordinates(value:String)->Dictionary:
	var coords:PackedStringArray=value.strip_edges().split(":",false)
	if coords.size()!=2 or not coords[0].is_valid_int() or not coords[1].is_valid_int():
		return {"ok":false,"error":"Coordinates must use X:Y, for example 600:350."}
	return {"ok":true,"x":int(coords[0]),"y":int(coords[1])}

static func parse_go(command:String)->Dictionary:
	var text:String=command.strip_edges()
	if text.begins_with("@"): text=text.substr(1).strip_edges()
	var parts:PackedStringArray=text.split(" ",false)
	if parts.is_empty() or parts[0].to_lower()!="go":
		return {"ok":false,"error":"Usage: @go <city|map_id> [x:y]. Examples: @go 3, @go 5, @go Morroc, @go 3 600:350."}
	if parts.size()<2:
		return {"ok":false,"error":"Choose a destination. Try @go 3 or @go 5."}
	if parts[1].to_lower()=="list":
		return {"ok":false,"error":"Destinations: %s" % destination_list()}
	var coordinate_index:int=-1
	for i in range(2,parts.size()):
		if parts[i].contains(":"):
			coordinate_index=i
			break
	var destination_end:int=coordinate_index if coordinate_index>=0 else parts.size()
	var destination:String=" ".join(parts.slice(1,destination_end))
	var map_id:int=resolve_map(destination)
	if map_id<0:
		return {"ok":false,"error":"Unknown destination '%s'. Use @go list to see destinations." % destination}
	var point:Vector2=default_point(map_id)
	if coordinate_index>=0:
		if coordinate_index+1!=parts.size():
			return {"ok":false,"error":"Too many arguments. Use @go 3 600:350."}
		var parsed:Dictionary=parse_coordinates(parts[coordinate_index])
		if not bool(parsed.get("ok",false)): return parsed
		point=Vector2(float(parsed["x"]),float(parsed["y"]))
	var map_data:Dictionary=MAPS[map_id]
	var x:int=int(point.x)
	var y:int=int(point.y)
	if x<0 or x>=int(map_data["width"]) or y<0 or y>=int(map_data["height"]):
		return {"ok":false,"error":"Coordinates outside %s bounds: 0-%d:0-%d." % [map_data["name"],int(map_data["width"])-1,int(map_data["height"])-1]}
	return {"ok":true,"map_id":map_id,"x":x,"y":y,"name":map_data["name"],"type":map_data["type"],"shortcut":coordinate_index<0}

static func destination_list()->String:
	var names:PackedStringArray=[]
	for map_id in MAPS.keys():
		names.append("%d=%s" % [int(map_id),str(MAPS[map_id]["name"])])
	return ", ".join(names)

static func map_name(map_id:int)->String:
	return str(MAPS.get(map_id,{"name":"Unknown"})["name"])

static func is_dungeon(map_id:int)->bool:
	return str(MAPS.get(map_id,{"type":""})["type"])=="dungeon"

static func coordinate(map_id:int,x:float,y:float)->String:
	return "@go %d %d:%d" % [map_id,int(x),int(y)]
