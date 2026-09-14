class_name OnlineAgeRuntime
extends Node

## Live online-age controller. One accumulated online day is represented by
## online_days; every 3 online days grants one permanent character year.
const Save = preload("res://scripts/SaveSystem.gd")
const Age = preload("res://scripts/OnlineAgeSystem.gd")
const Character = preload("res://scripts/CharacterProgressionSystem.gd")
const AUTOSAVE_SECONDS:float = 15.0

var legacy:Node
var autosave_timer:float = 0.0
var age_check_timer:float = 0.0
var dirty:bool = false
var last_age:int = -1

func _ready()->void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("_bind")

func _bind()->void:
    var scene:Node = get_tree().current_scene
    if scene == null:
        call_deferred("_bind")
        return
    legacy = scene.get_node_or_null("LegacyGame")
    if legacy == null:
        legacy = scene.get_node_or_null("LegacyGame/CombatRuntime")
    _sync_age(true)

func _process(delta:float)->void:
    if legacy == null or not is_instance_valid(legacy):
        _bind()
        return
    var value:Variant = legacy.get("hero")
    if not value is Dictionary:
        return
    var hero:Dictionary = value
    var old_days:float = max(0.0,float(hero.get("online_days",0.0)))
    var new_days:float = old_days + max(0.0,delta) / 86400.0
    if new_days != old_days:
        hero["online_days"] = new_days
        dirty = true
    age_check_timer += delta
    if age_check_timer >= 1.0:
        age_check_timer = 0.0
        _sync_age(false)
    autosave_timer += delta
    if dirty and autosave_timer >= AUTOSAVE_SECONDS:
        autosave_timer = 0.0
        if Save.save_game(hero):
            dirty = false

func _sync_age(force:bool)->void:
    if legacy == null or not is_instance_valid(legacy):
        return
    var value:Variant = legacy.get("hero")
    if not value is Dictionary:
        return
    var hero:Dictionary = value
    Age.normalize(hero)
    var current_age:int = int(hero.get("age",Age.STARTING_AGE))
    if not force and current_age == last_age:
        return
    last_age = current_age
    var stats:Dictionary = Character.stats(hero)
    hero["hp"] = clamp(int(hero.get("hp",stats["max_hp"])),1,int(stats["max_hp"]))
    hero["sp"] = clamp(int(hero.get("sp",stats["max_sp"])),0,int(stats["max_sp"]))
    dirty = true
    Save.save_game(hero)
    dirty = false

func _notification(what:int)->void:
    if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_EXIT_TREE:
        _save_now()

func _save_now()->void:
    if legacy == null or not is_instance_valid(legacy):
        return
    var value:Variant = legacy.get("hero")
    if value is Dictionary:
        var hero:Dictionary = value
        Age.normalize(hero)
        Save.save_game(hero)
        dirty = false
