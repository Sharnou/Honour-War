extends Node

## Mouse-first target controller for Main3D.
## Selection is intentionally passive: CombatRuntime owns damage and cadence.
const CombatRules = preload("res://scripts/CombatRules.gd")

var game:Node
var legacy:Node
var mover:Node
var combat:Node
var target:Dictionary = {}

func _ready() -> void:
	process_priority = 2000
	set_process_unhandled_input(true)
	call_deferred("_setup")

func _setup() -> void:
	game = get_tree().current_scene
	if game != null:
		legacy = game.get("legacy") as Node
		mover = game.get_node_or_null("MovementStabilityFix")
		combat = game.get_node_or_null("LegacyGame/CombatRuntime")

func _unhandled_input(event:InputEvent) -> void:
	var valid_click:bool = event is InputEventMouseButton
	if valid_click:
		var click:InputEventMouseButton = event as InputEventMouseButton
		valid_click = click.pressed and click.button_index == MOUSE_BUTTON_LEFT
	if valid_click:
		if legacy == null or mover == null or combat == null:
			_setup()
		if legacy != null and mover != null and combat != null:
			var click:InputEventMouseButton = event as InputEventMouseButton
			var picked:Variant = mover.call("_pick_monster",click.position)
			if picked is Dictionary:
				var picked_dict:Dictionary = picked
				if not picked_dict.is_empty():
					target = picked_dict
					mover.call("_handle_world_click",click.position)
					combat.set("target",target)
					get_viewport().set_input_as_handled()

func _process(_delta:float) -> void:
	if not target.is_empty() and legacy != null and combat != null:
		var mobs:Variant = legacy.get("monsters")
		if mobs is Array:
			var monster_array:Array = mobs
			if monster_array.has(target) and int(target.get("hp",0)) > 0:
				combat.set("target",target)
			else:
				target = {}
