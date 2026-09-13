class_name HeroPetCombatAnimationBridge
extends Node

var game:Node
var controller:Node
var target_visual:Node3D
var hero_visual:Node3D
var pet_visual:Node3D

func _ready()->void:
    game=get_parent()
    call_deferred("_bind")

func _bind()->void:
    if game==null: return
    controller=game.get_node_or_null("CombatAnimationController")

func _target_visual(target:Dictionary)->Node3D:
    if target.is_empty() or game==null: return null
    var visual_id:=str(target.get("visual_id",target.get("name","monster")))
    var visuals:Variant=game.get("monster_visuals")
    if visuals is Dictionary:
        var candidate:Variant=visuals.get(visual_id)
        if candidate is Node3D and is_instance_valid(candidate): return candidate
    return null

func _face_combatants()->void:
    if target_visual==null or not is_instance_valid(target_visual): return
    if _attack_visual_lock_active(): return
    if hero_visual and is_instance_valid(hero_visual): _face_node(hero_visual,target_visual)
    if pet_visual and is_instance_valid(pet_visual): _face_node(pet_visual,target_visual)

func _attack_visual_lock_active()->bool:
    if controller==null or not is_instance_valid(controller): return false
    var hero_lock:Variant=controller.get("hero_timeline_active")
    var pet_lock:Variant=controller.get("pet_timeline_active")
    return bool(hero_lock) or bool(pet_lock)

func _orient_to_target(actor:Node3D)->void:
    if actor==null or target_visual==null or not is_instance_valid(target_visual): return
    _face_node(actor,target_visual)

func _face_node(actor:Node3D,target:Node3D)->void:
    var direction:=target.global_position-actor.global_position
    direction.y=0.0
    if direction.length_squared()<0.0001: return
    actor.rotation.y=atan2(direction.x,direction.z)

func _trigger_attack(is_pet:bool)->void:
    if controller==null or not is_instance_valid(controller): return
    if controller.has_method("trigger_attack"):
        controller.call("trigger_attack",is_pet)
