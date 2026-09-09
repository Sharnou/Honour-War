class_name HDCombatNumberFilter
extends RefCounted

## Sanitizes combat-number text so debug/build/status strings cannot leak into damage UI.

static func clean_damage_text(value:String)->String:
    var text:=value.strip_edges()
    if text.is_empty():
        return ""
    var pieces:=text.split(" ", false)
    var numeric:=[]
    for piece in pieces:
        var token:=piece.replace(",", "").replace(".", "")
        if token.is_valid_int():
            numeric.append(piece)
    if numeric.size() > 0:
        return numeric[0]
    return ""

static func make_damage_label(amount:int)->String:
    return str(maxi(0, amount))
