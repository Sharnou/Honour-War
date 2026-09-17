class_name TeleportSystem
extends RefCounted

const MAPS := {
    0:{"name":"Prontera","type":"town","width":1200,"height":700,"spawn_x":600,"spawn_y":350},
    1:{"name":"Payon","type":"town","width":1200,"height":700,"spawn_x":600,"spawn_y":350},
    2:{"name":"Geffen","type":"town","width":1200,"height":700,"spawn_x":600,"spawn_y":350},
    3:{"name":"Morroc","type":"town","width":1200,"height":700,"spawn_x":600,"spawn_y":350},
    4:{"name":"Izlude","type":"town","width":1200,"height":700,"spawn_x":600,"spawn_y":350},
    5:{"name":"Alberta","type":"town","width":1200,"height":700,"spawn_x":600,"spawn_y":350},
    6:{"name":"Comodo","type":"town","width":1200,"height":700,"spawn_x":600,"spawn_y":350},
    7:{"name":"Aldebaran","type":"town","width":1200,"height":700,"spawn_x":600,"spawn_y":350},
    8:{"name":"Lutie","type":"town","width":1200,"height":700,"spawn_x":600,"spawn_y":350},
    9:{"name":"Umbala","type":"town","width":1200,"height":700,"spawn_x":600,"spawn_y":350},
    10:{"name":"Prontera Sewer","type":"dungeon","width":1400,"height":900,"spawn_x":180,"spawn_y":450,"entrance":0},
    11:{"name":"Payon Cave","type":"dungeon","width":1400,"height":900,"spawn_x":180,"spawn_y":450,"entrance":1},
    12:{"name":"Geffen Tower","type":"dungeon","width":1400,"height":900,"spawn_x":180,"spawn_y":450,"entrance":2},
    13:{"name":"Morroc Ruins","type":"dungeon","width":1400,"height":900,"spawn_x":180,"spawn_y":450,"entrance":3},
    14:{"name":"Orc Dungeon","type":"dungeon","width":1400,"height":900,"spawn_x":180,"spawn_y":450,"entrance":5},
    15:{"name":"Ice Cave","type":"dungeon","width":1400,"height":900,"spawn_x":180,"spawn_y":450,"entrance":8},
    16:{"name":"Clock Tower","type":"dungeon","width":1400,"height":900,"spawn_x":180,"spawn_y":450,"entrance":7},
    17:{"name":"Sunken Ship","type":"dungeon","width":1400,"height":900,"spawn_x":180,"spawn_y":450,"entrance":6},
    18:{"name":"Hidden Forest","type":"dungeon","width":1400,"height":900,"spawn_x":180,"spawn_y":450,"entrance":9},
    19:{"name":"Ancient Catacombs","type":"dungeon","width":1400,"height":900,"spawn_x":180,"spawn_y":450,"entrance":4},
    20:{"name":"Prontera Field","type":"field","width":1600,"height":1000,"spawn_x":800,"spawn_y":500,"town":0},
    21:{"name":"Payon Forest","type":"field","width":1600,"height":1000,"spawn_x":800,"spawn_y":500,"town":1},
    22:{"name":"Geffen Plains","type":"field","width":1600,"height":1000,"spawn_x":800,"spawn_y":500,"town":2},
    23:{"name":"Morroc Desert","type":"field","width":1600,"height":1000,"spawn_x":800,"spawn_y":500,"town":3},
    24:{"name":"Izlude Coast","type":"field","width":1600,"height":1000,"spawn_x":800,"spawn_y":500,"town":4},
    25:{"name":"Alberta Coast","type":"field","width":1600,"height":1000,"spawn_x":800,"spawn_y":500,"town":5},
    26:{"name":"Comodo Jungle","type":"field","width":1600,"height":1000,"spawn_x":800,"spawn_y":500,"town":6},
    27:{"name":"Aldebaran Meadow","type":"field","width":1600,"height":1000,"spawn_x":800,"spawn_y":500,"town":7},
    28:{"name":"Lutie Snowfield","type":"field","width":1600,"height":1000,"spawn_x":800,"spawn_y":500,"town":8},
    29:{"name":"Umbala Wilds","type":"field","width":1600,"height":1000,"spawn_x":800,"spawn_y":500,"town":9}
}

const ALIASES := {
    "prontera":0,"payon":1,"geffen":2,"morroc":3,"izlude":4,"alberta":5,"comodo":6,"aldebaran":7,"lutie":8,"umbala":9,
    "prontera sewer":10,"payon cave":11,"geffen tower":12,"morroc ruins":13,"orc dungeon":14,"ice cave":15,"clock tower":16,"sunken ship":17,"hidden forest":18,"ancient catacombs":19,
    "prontera field":20,"payon forest":21,"geffen plains":22,"morroc desert":23,"izlude coast":24,"alberta coast":25,"comodo jungle":26,"aldebaran meadow":27,"lutie snowfield":28,"umbala wilds":29,
    "prt":0,"pay":1,"gef":2,"moc":3,"izl":4,"alb":5,"com":6,"alde":7,"lut":8,"umb":9
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

static func parse_coordinates(token:String)->Dictionary:
    var text:String=token.strip_edges()
    if text.begins_with("(") and text.ends_with(")"):
        text=text.substr(1,text.length()-2).strip_edges()
    var pieces:PackedStringArray=text.split(":",false)
    if pieces.size()!=2 or not pieces[0].is_valid_float() or not pieces[1].is_valid_float():
        return {"ok":false}
    var x:float=float(pieces[0]); var y:float=float(pieces[1])
    if not is_finite(x) or not is_finite(y): return {"ok":false}
    return {"ok":true,"x":x,"y":y}

static func parse_go(command:String)->Dictionary:
    var text:String=command.strip_edges()
    if text.begins_with("@"): text=text.substr(1).strip_edges()
    var parts:PackedStringArray=text.split(" ",false)
    if parts.is_empty() or parts[0].to_lower()!="go":
        return {"ok":false,"error":"Usage: @go <town|field|dungeon> [x:y]. Example: @go Morroc or @go 0 230:220."}
    if parts.size()<2:
        return {"ok":false,"error":"Choose a destination. Use @go list to see towns, fields and dungeons."}
    if parts[1].to_lower()=="list":
        return {"ok":false,"error":"Destinations: %s" % destination_list()}

    var map_id:int=resolve_map(parts[1])
    if map_id<0:
        return {"ok":false,"error":"Unknown destination '%s'. Use @go list to see destinations." % parts[1]}

    var point:Vector2=default_point(map_id)
    if parts.size()>2:
        var coordinate_text:String=" ".join(parts.slice(2,parts.size())).strip_edges()
        var coordinate:Dictionary=parse_coordinates(coordinate_text)
        if not bool(coordinate.get("ok",false)):
            return {"ok":false,"error":"Invalid coordinates '%s'. Use x:y, for example 230:220." % coordinate_text}
        point=Vector2(float(coordinate["x"]),float(coordinate["y"]))
        var data:Dictionary=MAPS[map_id]
        point.x=clamp(point.x,0.0,float(data.get("width",1200))-1.0)
        point.y=clamp(point.y,0.0,float(data.get("height",700))-1.0)

    var map_data:Dictionary=MAPS[map_id]
    return {"ok":true,"map_id":map_id,"x":int(point.x),"y":int(point.y),"name":map_data["name"],"type":map_data["type"],"shortcut":true,"coordinate_specified":parts.size()>2}

static func destination_list()->String:
    var names:PackedStringArray=[]
    for map_id in MAPS.keys():
        names.append(str(MAPS[map_id]["name"]))
    return ", ".join(names)

static func map_name(map_id:int)->String:
    return str(MAPS.get(map_id,{"name":"Unknown"})["name"])

static func is_dungeon(map_id:int)->bool:
    return str(MAPS.get(map_id,{"type":""})["type"])=="dungeon"

static func town_for_dungeon(map_id:int)->int:
    return int(MAPS.get(map_id,{"entrance":-1}).get("entrance",-1))

static func town_for_field(map_id:int)->int:
    return int(MAPS.get(map_id,{"town":-1}).get("town",-1))

static func coordinate(map_id:int,x:float=0.0,y:float=0.0)->String:
    return "@go "+str(map_id)+" "+str(int(x))+":"+str(int(y))
