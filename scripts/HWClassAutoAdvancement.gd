extends Node

## Automatic class-rank advancement at the defined level milestones.
## The base class stays stable so its skill tree remains valid.

const SAVE=preload("res://scripts/SaveSystem.gd")
const DATA=preload("res://scripts/GameData.gd")

var scene_root:Node
var legacy:Node
var last_level:int=-1
var last_tier:int=-1

func _ready()->void:
    call_deferred("_bind")

func _process(_delta:float)->void:
    _bind()
    if legacy==null:
        return
    var value:Variant=legacy.get("hero")
    if not value is Dictionary:
        return
    _advance(value)

func _bind()->void:
    if scene_root==null or not is_instance_valid(scene_root):
        scene_root=get_tree().current_scene as Node
    if scene_root==null:
        return
    if legacy==null or not is_instance_valid(legacy):
        legacy=scene_root.get_node_or_null("LegacyGame")

func _advance(hero:Dictionary)->void:
    var level:int=clamp(int(hero.get("level",1)),1,250)
    var tier:int=DATA.class_tier_for_level(level)
    var class_id:String=str(hero.get("class","Warrior"))
    var rank:String=DATA.class_rank_for_level(level,class_id)
    var old_tier:int=int(hero.get("class_tier",0))
    var old_rank:String=str(hero.get("class_rank",""))
    var changed:bool=false
    if old_tier!=tier:
        hero["class_tier"]=tier
        hero["class_rank_tier"]=tier
        hero["class_rank"]=rank
        hero["class_mastery"]=max(int(hero.get("class_mastery",0)),tier)
        changed=true
    elif old_rank!=rank:
        hero["class_rank"]=rank
        hero["class_rank_tier"]=tier
        changed=true
    if last_level!=level or last_tier!=tier or changed:
        last_level=level
        last_tier=tier
        if changed:
            SAVE.save_game(hero)
            if legacy.has_method("log_message"):
                legacy.call("log_message","Class advancement: %s → %s (Tier %d)." % [class_id,rank,tier])
