class_name MovementStabilityFix
extends Node

@export var legacy_path: NodePath = NodePath("../LegacyGame")
@export var camera_path: NodePath = NodePath("../Camera3D")
var legacy: Node
var camera: Camera3D
var mouse_target: Vector2
var mouse_active := false

func _ready() -> void:
	legacy = get_node_or_null(legacy_path)
	camera = get_node_or_null(camera_path) as Camera3D
	set_process_unhandled_input(true)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		mouse_active = event.pressed
		if event.pressed:
			mouse_target = event.position
	elif event is InputEventMouseMotion and mouse_active:
		mouse_target = event.position

func _process(_delta: float) -> void:
	if legacy == null or not legacy.has_method("set_mouse_move_target"):
		return
	if mouse_active:
		legacy.call("set_mouse_move_target", mouse_target)
	else:
		legacy.call("clear_mouse_move_target")
