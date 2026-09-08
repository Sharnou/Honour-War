class_name HeroPetCombatAnimationBridge
extends Node

var game:Node3D
var events:Node
var controller:Node
var feedback:Node
var hero_visual:Node3D
var pet_visual:Node3D
var target_visual:Node3D
var pending_hero:Dictionary={}
var pending_pet:Dictionary={}

func _ready()->void:
    game=get_parent() as Node3D
    call_deferred("_bind")

func _bind()->void:
    if game==null: return
    events=game.get_node_or_null("CombatEventBus")
    controller=game.get_node_or_null("CombatAnimationController")
    feedback=game.get_node_or_null("HDCombatFeedback")
    _refresh_visuals()
    if events:
        if events.has_signal("hero_attack_landed"): events.hero_attack_landed.connect(_on_hero_attack)
        if events.has_signal("pet_attack_landed"): events.pet_attack_landed.connect(_on_pet_attack)
        if events.has_signal("monster_attack_landed"): events.monster_attack_landed.connect(_on_monster_attack)
        if events.has_signal("target_changed"): events.target_changed.connect(_on_target_changed)
    if controller:
        if controller.has_signal("hero_attack_started"): controller.hero_attack_started.connect(_on_hero_attack_started)
        if controller.has_signal("hero_attack_impact"): controller.hero_attack_impact.connect(_on_hero_attack_impact)
        if controller.has_signal("hero_attack_completed"): controller.hero_attack_completed.connect(_on_hero_attack_completed)
        if controller.has_signal("pet_attack_started"): controller.pet_attack_started.connect(_on_pet_attack_started)
        if controller.has_signal("pet_attack_impact"): controller.pet_attack_impact.connect(_on_pet_attack_impact)
        if controller.has_signal("pet_attack_completed"): controller.pet_attack_completed.connect(_on_pet_attack_completed)

func _refresh_visuals()->void:
    hero_visual=game.get("hero_visual") as Node3D
    pet_visual=game.get("pet_visual") as Node3D

func _process(_delta:float)->void:
    if not is_instance_valid(hero_visual) or not is_instance_valid(pet_visual): _refresh_visuals()
    _face_combatants()

func _on_hero_attack(target:Dictionary,damage:int,critical:bool)->void:
    _refresh_visuals()
    pending_hero={"target":target,"damage":damage,"critical":critical}
    _set_target_from_dictionary(target)
    _trigger_attack(false)

func _on_pet_attack(target:Dictionary,damage:int,special:bool)->void:
    _refresh_visuals()
    pending_pet={"target":target,"damage":damage,"special":special}
    _set_target_from_dictionary(target)
    _trigger_attack(true)

func _on_hero_attack_started()->void:
    _orient_to_target(hero_visual)

func _on_hero_attack_impact()->void:
    if pending_hero.is_empty(): return
    _emit_impact(pending_hero,true)
    pending_hero={}

func _on_hero_attack_completed()->void:
    pending_hero={}

func _on_pet_attack_started()->void:
    _orient_to_target(pet_visual)

func _on_pet_attack_impact()->void:
    if pending_pet.is_empty(): return
    _emit_impact(pending_pet,false)
    pending_pet={}

func _on_pet_attack_completed()->void:
    pending_pet={}

func _emit_impact(payload:Dictionary,is_hero:bool)->void:
    var target:Dictionary=payload.get("target",{})
    var visual:=_target_visual(target)
    if visual==null: return
    var pos:=visual.global_position+Vector3(0.0,0.8,0.0)
    var amount:=int(payload.get("damage",0))
    var critical:=bool(payload.get("critical",false))
    if feedback and feedback.has_method("show_damage"):
        feedback.show_damage(amount,pos,critical)
    if feedback and feedback.has_method("play_skill_effect"):
        feedback.play_skill_effect("hero_impact" if is_hero else "pet_impact",pos)

func _on_monster_attack(_target_kind:String,_damage:int)->void:
    if controller and controller.has_method("_set_hero_state"): controller.call("_set_hero_state","hit")
    if controller and controller.has_method("_set_pet_state"): controller.call("_set_pet_state","hit")

func _on_target_changed(target:Dictionary)->void:
    _set_target_from_dictionary(target)

func _set_target_from_dictionary(target:Dictionary)->void:
    target_visual=_target_visual(target)

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
    if hero_visual and is_instance_valid(hero_visual): _face_node(hero_visual,target_visual)
    if pet_visual and is_instance_valid(pet_visual): _face_node(pet_visual,target_visual)

func _orient_to_target(actor:Node3D)->void:
    if actor==null or target_visual==null or not is_instance_valid(target_visual): return
    _face_node(actor,target_visual)

func _face_node(actor:Node3D,target:Node3D)->void:
    var direction:=target.global_position-actor.global_position
    direction.y=0.0
    if direction.length_squared()<0.0001: return
    actor.rotation.y=atan2(direction.x,direction.z)

func _trigger_attack(is_pet:bool)->void:
    if controller==null: return
    if is_pet:
        if controller.has_method("play_pet_attack"): controller.call("play_pet_attack")
        elif controller.has_method("_set_pet_state"): controller.call("_set_pet_state","attack")
    else:
        if controller.has_method("play_hero_attack"): controller.call("play_hero_attack")
        elif controller.has_method("_set_hero_state"): controller.call("_set_hero_state","attack")
