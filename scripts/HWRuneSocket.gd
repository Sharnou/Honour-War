class_name HWRuneSocket
extends RefCounted

## Honour War Rune Socket service. Treat all mutation methods as server-side only.

const MAX_SOCKETS:int=4

static func validate_item_socket_state(item:Dictionary)->Dictionary:
	var sockets:int=int(item.get("sockets",item.get("card_slots",0)))
	var inserted:Variant=item.get("socketed_runes",[])
	if sockets<0 or sockets>MAX_SOCKETS: return {"ok":false,"reason":"invalid_socket_count"}
	if not inserted is Array: return {"ok":false,"reason":"invalid_socket_state"}
	if (inserted as Array).size()>sockets: return {"ok":false,"reason":"socket_overflow"}
	for rune in inserted:
		if not rune is Dictionary: return {"ok":false,"reason":"invalid_rune_record"}
		if not str(rune.get("id","")) or not str(rune.get("checksum","")):
			return {"ok":false,"reason":"unsigned_rune_record"}
	return {"ok":true,"sockets":sockets,"occupied":(inserted as Array).size()}

static func can_insert(item:Dictionary,rune:Dictionary)->Dictionary:
	var state:Dictionary=validate_item_socket_state(item)
	if not bool(state.get("ok",false)): return state
	var runes:Array=item.get("socketed_runes",[])
	if runes.size()>=int(state["sockets"]): return {"ok":false,"reason":"no_empty_socket"}
	if str(rune.get("id",""))=="": return {"ok":false,"reason":"invalid_rune"}
	if str(rune.get("checksum",""))=="": return {"ok":false,"reason":"unsigned_rune"}
	return {"ok":true,"slot_index":runes.size()}

static func insert(item:Dictionary,rune:Dictionary)->Dictionary:
	var check:Dictionary=can_insert(item,rune)
	if not bool(check.get("ok",false)): return check
	var result:Dictionary=item.duplicate(true)
	var runes:Array=result.get("socketed_runes",[]).duplicate(true)
	runes.append(rune.duplicate(true))
	result["socketed_runes"]=runes
	return {"ok":true,"item":result,"slot_index":runes.size()-1}

static func remove(item:Dictionary,index:int)->Dictionary:
	var check:Dictionary=validate_item_socket_state(item)
	if not bool(check.get("ok",false)): return check
	var runes:Array=item.get("socketed_runes",[]).duplicate(true)
	if index<0 or index>=runes.size(): return {"ok":false,"reason":"invalid_socket_index"}
	var removed:Dictionary=runes[index]
	runes.remove_at(index)
	var result:Dictionary=item.duplicate(true)
	result["socketed_runes"]=runes
	return {"ok":true,"item":result,"removed":removed}
