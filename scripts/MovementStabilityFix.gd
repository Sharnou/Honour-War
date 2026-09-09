class_name MovementStabilityFix
extends Node

@export var legacy_path: NodePath = NodePath("../LegacyGame")
@export var camera_path: NodePath = NodePath("../Camera3D")

const MOVE_SPEED: float = 155.0
const STOP_DISTANCE: float = 7.0
const MIN_X: float = 40.0
const MAX_X: float = 1150.0
const MIN_Y: float = 40.0
const MAX_Y: float = 650.0

var legacy: Node
var camera: Camera3D
var mouse_target: Vector2 = Vector2.ZERO
var mouse_active := false
var destination: Vector2 = Vector2.ZERO

func _ready() -> void:
	legacy = get_node_or_null(legacy_path)
	camera = get_node_or_null(camera_path) as Camera3D
	set_process_unhandled_input(true)
	set_process(true)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			mouse_active = true
			mouse_target = event.position
			var world_point := _screen_to_map(event.position)
			if world_point != Vector2.INF:
				destination = world_point
		else:
			mouse_active = false
	elif event is InputEventMouseMotion and mouse_active:
		mouse_target = event.position

func _process(delta: float) -> void:
	if legacy == null:
		return
	var hero_value: Variant = legacy.get("hero")
	if not hero_value is Dictionary:
		return
	var hero: Dictionary = hero_value
	var keyboard := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	if keyboard.length_squared() > 0.001:
		mouse_active = false
		destination = Vector2.INF
		var direction := keyboard.normalized()
		hero["pos_x"] = clamp(float(hero.get("pos_x", 595.0)) + direction.x * MOVE_SPEED * delta, MIN_X, MAX_X)
		hero["pos_y"] = clamp(float(hero.get("pos_y", 340.0)) + direction.y * MOVE_SPEED * delta, MIN_Y, MAX_Y)
		return
	if destination == Vector2.INF:
		return
	var current := Vector2(float(hero.get("pos_x", 595.0)), float(hero.get("pos_y", 340.0)))
	var offset := destination - current
	if offset.length() <= STOP_DISTANCE:
		destination = Vector2.INF
		return
	var direction := offset.normalized()
	hero["pos_x"] = clamp(current.x + direction.x * MOVE_SPEED * delta, MIN_X, MAX_X)
	hero["pos_y"] = clamp(current.y + direction.y * MOVE_SPEED * delta, MIN_Y, MAX_Y)

func _screen_to_map(screen_position: Vector2) -> Vector2:
	if camera == null:
		return Vector2.INF
	var origin := camera.project_ray_origin(screen_position)
	var direction := camera.project_ray_normal(screen_position)
	if abs(direction.y) < 0.0001:
		return Vector2.INF
	var distance := -origin.y / direction.y
	if distance < 0.0:
		return Vector2.INF
	var point := origin + direction * distance
	return Vector2(point.x / 0.055, -point.z / 0.055)
