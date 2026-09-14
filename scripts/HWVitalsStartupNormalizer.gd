extends Node

## One-time migration for the authoritative CharacterProgressionSystem vitals.
## New profiles start at full HP/SP. Existing saves without this marker are
## normalized once; later combat damage is preserved across launches.

const CHARACTER=preload("res://scripts/CharacterProgressionSystem.gd")
const SAVE=preload("res://scripts/SaveSystem.gd")

var done:bool=false

func _ready()->void:
    call_deferred("_bind")

func _process(_delta:float)->void:
    if not done:
        _bind()

func _bind()->void:
    var scene:Node=get_tree().current_scene
    if scene==null:
        return
    var legacy:Node=scene.get_node_or_null("LegacyGame")
    if legacy==null:
        return
    var value:Variant=legacy.get("hero")
    if not value is Dictionary:
        return
    var hero:Dictionary=value
    if bool(hero.get("_hw_vitals_initialized",false)):
        done=true
        return
    CHARACTER.ensure_state(hero)
    var live:Dictionary=CHARACTER.stats(hero)
    hero["max_hp"]=int(live["max_hp"])
    hero["max_sp"]=int(live["max_sp"])
    hero["hp"]=int(live["max_hp"])
    hero["sp"]=int(live["max_sp"])
    hero["_hw_vitals_initialized"]=true
    SAVE.save_game(hero)
    done=true
