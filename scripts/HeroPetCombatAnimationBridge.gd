class_name HeroPetCombatAnimationBridge
extends Node

var game:Node3D
var events:Node
var controller:Node
var hero_visual:Node3D
var pet_visual:Node3D
var target_visual:Node3D

func _ready()->void:
    game=get_parent() as Node3D
    call_deferred("_bind")

func _bind()->void:
    if game==null:
        return
    events=game.get_node_or_null("CombatEventBus")
    controller=game.get_node_or_null("CombatAnimationController")
    _refresh_visuals()
    if events:
        if events.has_signal("hero_attack_landed"):
            events.hero_attack_landed.connect(_on_hero_attack)
        if events.has_signal("pet_attack_landed"):
            events.pet_attack_landed.connect(_on_pet_attack)
        if events.has_signal("monster_attack_landed"):
            events.monster_attack_landed.connect(_on_monster_attack)
        if events.has_signal("target_changed"):
            events.target_changed.connect(_on_target_changed)

func _refresh_visuals()->void:
    hero_visual=game.get("hero_visual") as Node3D
    pet_visual=game.get("pet_visual") as Node3D

func _process(_delta:float)->void:
    if not is_instance_valid(hero_visual) or not is_instance_valid(pet_visual):
        _refresh_visuals()
    _face_combatants()

func _on_hero_attack(target:Dictionary,_damage:int,_critical:bool)->void:
    _refresh_visuals()
    _trigger_attack(false)
    _set_target_from_dictionary(target)

func _on_pet_attack(target:Dictionary,_damage:int,_special:bool)->void:
    _refresh_visuals()
    _trigger_attack(true)
    _set_target_from_dictionary(target)

func _on_monster_attack(_target_kind:String,_damage:int)->void:
    if controller and controller.has_method("_set_hero_state"):
        controller.call("_set_hero_state","hit")
    if controller and controller.has_method("_set_pet_state"):
        controller.call("_set_pet_state","hit")

func _on_target_changed(target:Dictionary)->void:
    _set_target_from_dictionary(target)

func _set_target_from_dictionary(target:Dictionary)->void:
    target_visual=null
    if target.is_empty() or game==null:
        return
    var visual_id:=str(target.get("visual_id",target.get("name","monster")))
    var visuals:Variant=game.get("monster_visuals")
    if visuals is Dictionary:
        var candidate:Variant=visuals.get(visual_id)
        if candidate is Node3D and is_instance_valid(candidate):
            target_visual=candidate

func _face_combatants()->void:
    if target_visual==null or not is_instance_valid(target_visual):
        return
    if hero_visual and is_instance_valid(hero_visual):
        _face_node(hero_visual,target_visual)
    if pet_visual and is_instance_valid(pet_visual):
        _face_node(pet_visual,target_visual)

func _face_node(actor:Node3D,target:Node3D)->void:
    var direction:=target.global_position-actor.global_position
    direction.y=0.0
    if direction.length_squared()<0.0001:
        return
    actor.rotation.y=lerp_angle(actor.rotation.y,atan2(direction.x,direction.z),0.22)

func _trigger_attack(is_pet:bool)->void:
    if controller==null:
        return
    if is_pet:
        if controller.has_method("play_pet_attack"):
            controller.call("play_pet_attack")
        elif controller.has_method("_set_pet_state"):
            controller.call("_set_pet_state","attack")
    else:
        if controller.has_method("play_hero_attack"):
            controller.call("play_hero_attack")
        elif controller.has_method("_set_hero_state"):
            controller.call("_set_hero_state","attack")
