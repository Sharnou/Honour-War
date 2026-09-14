extends Node

var game:Node
var legacy:Node
var mover:Node
var target:Dictionary={}
var attack_clock:float=0.0

func _ready()->void:
    set_process_unhandled_input(true)
    call_deferred("_setup")

func _setup()->void:
    game=get_tree().current_scene
    if game==null: return
    legacy=game.get("legacy") as Node
    mover=game.get_node_or_null("MovementStabilityFix")

func _unhandled_input(event:InputEvent)->void:
    if not event is InputEventMouseButton: return
    var click:=event as InputEventMouseButton
    if not click.pressed or click.button_index!=MOUSE_BUTTON_LEFT: return
    if legacy==null or mover==null: _setup()
    if legacy==null or mover==null: return
    var picked:Variant=mover.call("_pick_monster",click.position)
    if picked is Dictionary and not picked.is_empty():
        target=picked
        mover.call("_handle_world_click",click.position)
        get_viewport().set_input_as_handled()

func _process(delta:float)->void:
    if target.is_empty() or legacy==null: return
    var mobs:Variant=legacy.get("monsters")
    if not mobs is Array or not (mobs as Array).has(target):
        target={}
        return
    if int(target.get("hp",0))<=0:
        target={}
        return
    var value:Variant=legacy.get("hero")
    if not value is Dictionary: return
    var hero:Dictionary=value
    var hero_pos:=Vector2(float(hero.get("pos_x",595.0)),float(hero.get("pos_y",340.0)))
    var mob_pos:Vector2=target.get("pos",hero_pos)
    if hero_pos.distance_to(mob_pos)<=90.0:
        attack_clock+=delta
        if attack_clock>=0.72:
            attack_clock=0.0
            if legacy.has_method("attack"): legacy.call("attack")
