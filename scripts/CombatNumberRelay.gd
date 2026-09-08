class_name CombatNumberRelay
extends Node

var legacy:Node
var bridge:Node
var vfx:Node
var seen_hits:=0
var seen_heals:=0

func _ready()->void:
    legacy=get_parent()
    bridge=legacy.get_node_or_null("Combat3DBridge")
    vfx=legacy.get_node_or_null("CombatVFX")
    set_process(true)

func _process(_delta:float)->void:
    if bridge==null or vfx==null:
        return
    var effects_value:Variant=vfx.get("effects")
    if not effects_value is Array:
        return
    var effects:Array=effects_value
    var hits:=0
    var heals:=0
    for effect in effects:
        if not effect is Dictionary:
            continue
        var kind:=str(effect.get("kind",""))
        if kind=="hit" or kind=="critical":
            hits+=1
        elif kind=="heal":
            heals+=1
    if hits>seen_hits:
        _relay_latest(effects,"hit")
    if heals>seen_heals:
        _relay_latest(effects,"heal")
    seen_hits=hits
    seen_heals=heals

func _relay_latest(effects:Array,kind:String)->void:
    for i in range(effects.size()-1,-1,-1):
        var effect=effects[i]
        if not effect is Dictionary:
            continue
        var effect_kind:=str(effect.get("kind",""))
        if kind=="hit" and effect_kind!="hit" and effect_kind!="critical":
            continue
        if kind=="heal" and effect_kind!="heal":
            continue
        var position_value:Variant=effect.get("pos",Vector2.ZERO)
        if not position_value is Vector2:
            return
        var amount:=int(str(effect.get("text","0")))
        var critical:=effect_kind=="critical"
        bridge.show_number(position_value,amount,critical,"heal" if kind=="heal" else "enemy")
        return
