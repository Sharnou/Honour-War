class_name HDDeathRecovery
extends Node

const Save=preload("res://scripts/SaveSystem.gd")
const Character=preload("res://scripts/CharacterProgressionSystem.gd")

var game:Node
var legacy:Node
var recovering:bool=false
var timer:float=0.0
var cooldown:float=0.0

func _ready()->void:
    game=get_parent()
    call_deferred("_bind")

func _bind()->void:
    if game==null: return
    legacy=game.get("legacy") as Node
    _install_visual_drivers()
    set_process(true)

func _install_visual_drivers()->void:
    if game==null: return
    _add_runtime_driver("res://scripts/HDProductionAnimationDriver.gd","HDProductionAnimationDriver")
    _add_runtime_driver("res://scripts/HDEquipmentVisualDriver.gd","HDEquipmentVisualDriver")

func _add_runtime_driver(path:String,node_name:String)->void:
    if game.get_node_or_null(node_name)!=null: return
    var script:GDScript=load(path) as GDScript
    if script==null: return
    var node:Node=script.new() as Node
    if node==null: return
    node.name=node_name
    game.add_child(node)

func _process(delta:float)->void:
    if cooldown>0.0:
        cooldown=max(0.0,cooldown-delta)
    if game==null or not is_instance_valid(game):
        game=get_parent()
        return
    if legacy==null or not is_instance_valid(legacy):
        legacy=game.get("legacy") as Node
    if legacy==null: return
    var value:Variant=legacy.get("hero")
    if not value is Dictionary: return
    var hero:Dictionary=value
    if recovering:
        timer-=delta
        if timer<=0.0:
            _recover(hero)
        return
    if cooldown<=0.0 and int(hero.get("hp",1))<=0:
        recovering=true
        timer=0.65

func _recover(hero:Dictionary)->void:
    recovering=false
    cooldown=1.5
    var stats:Dictionary=Character.stats(hero)
    var max_hp:int=max(1,int(stats.get("max_hp",100)))
    var max_sp:int=max(1,int(stats.get("max_sp",50)))
    hero["hp"]=max_hp
    hero["sp"]=max_sp
    hero["dead"]=false
    hero["respawn_pending"]=false
    hero["pos_x"]=595.0
    hero["pos_y"]=340.0
    hero["map_id"]=0
    hero["last_safe_city"]="Prontera"
    var pet_value:Variant=hero.get("pet",{})
    if pet_value is Dictionary:
        var pet:Dictionary=pet_value
        var pet_max:int=max(1,int(pet.get("max_hp",60)))
        pet["hp"]=pet_max
        pet["dead"]=false
        pet["respawn_pending"]=false
        hero["pet"]=pet
    var combat:Node=legacy.get_node_or_null("CombatRuntime")
    if combat!=null:
        _set_if_property(combat,"target",null)
        _set_if_property(combat,"hero_attack_timer",0.0)
        _set_if_property(combat,"pet_attack_timer",0.0)
        _set_if_property(combat,"monster_attack_timer",0.0)
        _set_if_property(combat,"mvp_skill_timer",0.0)
        if combat.has_method("clear_target"):
            combat.call("clear_target")
    game.set("last_hero_position",Vector2.ZERO)
    Save.save_game(hero)
    if game.has_method("log_message"):
        game.call("log_message","Hero returned to Prontera after defeat.")

func _set_if_property(object:Object,property_name:String,value:Variant)->void:
    for item in object.get_property_list():
        if str(item.get("name",""))==property_name:
            object.set(property_name,value)
            return
