extends Node

const Save = preload("res://scripts/SaveSystem.gd")
const Age = preload("res://scripts/OnlineAgeSystem.gd")
const Character = preload("res://scripts/CharacterProgressionSystem.gd")
const AUTOSAVE_SECONDS:float = 15.0
const BIND_RETRY_SECONDS:float = 0.50

var legacy:Node
var autosave_timer:float = 0.0
var age_check_timer:float = 0.0
var bind_retry_timer:float = 0.0
var dirty:bool = false
var last_age:int = -1
var last_age_multiplier:float = 1.0
var bind_queued:bool = false

func _ready()->void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _queue_bind()

func _queue_bind()->void:
    if bind_queued:
        return
    bind_queued = true
    call_deferred("_attempt_bind")

func _attempt_bind()->void:
    bind_queued = false
    var scene:Node = get_tree().current_scene
    if scene == null:
        bind_retry_timer = 0.0
        return
    var candidate:Node = scene.get_node_or_null("LegacyGame")
    if candidate == null:
        candidate = scene.get_node_or_null("LegacyGame/CombatRuntime")
    if candidate == null or not is_instance_valid(candidate):
        bind_retry_timer = 0.0
        return
    legacy = candidate
    bind_retry_timer = 0.0
    _sync_age(true)

func _process(delta:float)->void:
    if legacy == null or not is_instance_valid(legacy):
        bind_retry_timer += max(0.0,delta)
        if bind_retry_timer >= BIND_RETRY_SECONDS:
            bind_retry_timer = 0.0
            _queue_bind()
        return
    var value:Variant = legacy.get("hero")
    if not value is Dictionary: return
    var hero:Dictionary = value
    var old_days:float = max(0.0,float(hero.get("online_days",0.0)))
    var new_days:float = old_days + max(0.0,delta)/86400.0
    if new_days != old_days:
        hero["online_days"] = new_days
        dirty = true
    age_check_timer += max(0.0,delta)
    if age_check_timer >= 1.0:
        age_check_timer = 0.0
        _sync_age(false)
    autosave_timer += max(0.0,delta)
    if dirty and autosave_timer >= AUTOSAVE_SECONDS:
        autosave_timer = 0.0
        if Save.save_game(hero): dirty = false

func _sync_age(force:bool)->void:
    if legacy == null or not is_instance_valid(legacy): return
    var value:Variant = legacy.get("hero")
    if not value is Dictionary: return
    var hero:Dictionary = value
    Age.normalize(hero)
    var current_age:int = int(hero.get("age",Age.DEFAULT_STARTING_AGE))
    var multiplier:float = Age.stat_growth_multiplier(hero)
    hero["age_stat_growth_percent"] = Age.stat_growth_percent(hero)
    hero["age_refine_success_bonus"] = Age.refine_success_bonus(hero)
    hero["age_refine_success_bonus_percent"] = Age.refine_success_bonus_percent(hero)
    hero["age_top_100_drop_bonus"] = Age.top_100_drop_bonus(hero)
    hero["age_top_100_drop_bonus_percent"] = Age.top_100_drop_bonus_percent(hero)
    hero["age_years_earned"] = Age.years_earned(hero)
    hero["age_next_year_days"] = Age.progress_to_next_year(hero).get("days_remaining",Age.DAYS_PER_YEAR)

    var equipment_value:Variant = hero.get("equipment",{})
    if equipment_value is Dictionary:
        var equipment:Dictionary = equipment_value
        for slot in equipment.keys():
            if equipment[slot] is Dictionary:
                equipment[slot]["age_refine_success_bonus"] = Age.refine_success_bonus(hero)
        hero["equipment"] = equipment

    if force or current_age != last_age:
        var stats_value:Variant = hero.get("stats",{})
        if stats_value is Dictionary:
            var stats:Dictionary = stats_value
            var previous:float = max(0.0001,last_age_multiplier)
            for key in ["str","agi","vit","int","dex","luk"]:
                if stats.has(key):
                    var base_value:float = float(stats[key])/previous
                    stats[key] = clampi(roundi(base_value*multiplier),1,99)
            hero["stats"] = stats
        last_age = current_age
        last_age_multiplier = multiplier
        var computed:Dictionary = Character.stats(hero)
        hero["hp"] = clamp(int(hero.get("hp",computed["max_hp"])),1,int(computed["max_hp"]))
        hero["sp"] = clamp(int(hero.get("sp",computed["max_sp"])),0,int(computed["max_sp"]))
        dirty = true
        if Save.save_game(hero):
            dirty = false

func _notification(what:int)->void:
    if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_EXIT_TREE: _save_now()

func _save_now()->void:
    if legacy == null or not is_instance_valid(legacy): return
    var value:Variant = legacy.get("hero")
    if value is Dictionary:
        var hero:Dictionary = value
        Age.normalize(hero)
        Save.save_game(hero)
        dirty = false
