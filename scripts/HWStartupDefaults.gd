extends Node

## Honour War startup defaults.
## Enables automatic loot collection and RO-style no-control combat mode by default.

const SAVE=preload("res://scripts/SaveSystem.gd")
const LOOT=preload("res://scripts/LootSystem.gd")

const LOOT_DEFAULT_KEY:String="autoloot_default_applied"
const NOCTRL_KEY:String="noctrl_enabled"

var scene_root:Node
var legacy:Node
var applied:bool=false

func _ready()->void:
    call_deferred("_bind")

func _process(_delta:float)->void:
    if applied:
        return
    _bind()

func _bind()->void:
    if scene_root==null or not is_instance_valid(scene_root):
        scene_root=get_tree().current_scene as Node
    if scene_root==null:
        return
    if legacy==null or not is_instance_valid(legacy):
        legacy=scene_root.get_node_or_null("LegacyGame")
    if legacy==null:
        return
    var value:Variant=legacy.get("hero")
    if not value is Dictionary:
        return
    var hero:Dictionary=value
    _apply_defaults(hero)
    applied=true

func _apply_defaults(hero:Dictionary)->void:
    if not hero.has("loot_rules") or not hero["loot_rules"] is Dictionary:
        hero["loot_rules"]={}
    var rules:Dictionary=hero["loot_rules"]
    rules["enabled"]=true
    rules["auto_pick_items"]=true
    rules["auto_pick_cards"]=true
    rules["auto_pick_materials"]=true
    rules["auto_pick_equipment"]=true
    hero["loot_rules"]=rules
    hero[NOCTRL_KEY]=true
    hero["default_commands"]=["@autoloot on","/nc"]
    hero[LOOT_DEFAULT_KEY]=true
    LOOT.set_enabled(hero,true)
    SAVE.save_game(hero)

func is_noctrl_enabled(hero:Dictionary)->bool:
    return bool(hero.get(NOCTRL_KEY,true))

func set_noctrl_enabled(hero:Dictionary,enabled:bool)->void:
    hero[NOCTRL_KEY]=enabled
    SAVE.save_game(hero)
