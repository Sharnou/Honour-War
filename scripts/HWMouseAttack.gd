extends Node

## Mouse-first target controller for the Main3D scene.
## A left-click on a monster selects it and uses the shared movement controller
## to stop at that class's authored engagement distance. CombatRuntime then owns
## the actual attack cadence/damage calculation, preventing the legacy SPACE
## attack path from producing a second, conflicting damage event.
const CombatRules = preload("res://scripts/CombatRules.gd")

var game:Node
var legacy:Node
var mover:Node
var combat:Node
var target:Dictionary={}

func _ready()->void:
	process_priority=2000
	set_process_unhandled_input(true)
	call_deferred("_setup")

func _setup()->void:
	game=get_tree().current_scene
	if game==null: return
	legacy=game.get("legacy") as Node
	mover=game.get_node_or_null("MovementStabilityFix")
	combat=game.get_node_or_null("LegacyGame/CombatRuntime")

func _unhandled_input(event:InputEvent)->void:
	if not event is InputEventMouseButton: return
	var click:=event as InputEventMouseButton
	if not click.pressed or click.button_index!=MOUSE_BUTTON_LEFT: return
	if legacy==null or mover==null or combat==null: _setup()
	if legacy==null or mover==null or combat==null: return
	var picked:Variant=mover.call("_pick_monster",click.position)
	if not picked is Dictionary or picked.is_empty(): return
	target=picked
	mover.call("_handle_world_click",click.position)
	combat.set("target",target)
	get_viewport().set_input_as_handled()

func _process(_delta:float)->void:
	if target.is_empty() or legacy==null or combat==null:
		return
	var mobs:Variant=legacy.get("monsters")
	if not mobs is Array or not (mobs as Array).has(target):
		target={}
		return
	if int(target.get("hp",0))<=0:
		target={}
		return
	# CombatRuntime owns the class-specific engagement range and attack cadence.
	# Re-assert the mouse-selected target every frame so nearest-monster
	# acquisition cannot steal the target while the hero is approaching it.
	combat.set("target",target)
