extends Node

## Honour War 3D input policy for the Ragnarok-style main scene.
##
## The legacy simulation still owns the hero Dictionary and remains useful for
## gameplay state, but Main3D.tscn must be mouse-first. In the 3D shell this
## policy removes WASD/arrow events from the legacy movement actions so they
## cannot fight the mouse movement controller or move the camera indirectly.
## Q/E remain dedicated camera-rotation controls in MovementStabilityFix.

const MOVEMENT_ACTIONS:Array[String] = ["move_up", "move_down", "move_left", "move_right"]
const CONTROL_HINT:String = "Left click: move / target   •   Mouse wheel: zoom   •   Q/E: rotate camera   •   1–8: skills   •   F9: graphics"

var applied:bool = false
var hint_applied:bool = false

func _ready() -> void:
	call_deferred("_apply_when_main_scene_ready")

func _process(_delta:float) -> void:
	_apply_when_main_scene_ready()
	if applied and hint_applied:
		set_process(false)

func _apply_when_main_scene_ready() -> void:
	var scene:Node = get_tree().current_scene
	if scene == null:
		return
	var movement:Node = scene.get_node_or_null("MovementStabilityFix")
	if movement == null:
		return
	for action in MOVEMENT_ACTIONS:
		if InputMap.has_action(action) and InputMap.action_get_events(action).size() > 0:
			InputMap.action_erase_events(action)
	applied = true

	var hud:Node = scene.get_node_or_null("HUD3D")
	if hud != null:
		hint_applied = _rewrite_control_hints(hud)

func _rewrite_control_hints(node:Node) -> bool:
	var changed:bool = false
	for child in node.get_children():
		if child is Label:
			var label:Label = child
			if label.text.contains("WASD") or label.text.contains("Arrows") or label.text.contains("Move"):
				label.text = CONTROL_HINT
				changed = true
		if _rewrite_control_hints(child):
			changed = true
	return changed
