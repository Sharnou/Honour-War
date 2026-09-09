class_name MovementStabilityFix
extends Node

@export var legacy_path:NodePath = NodePath("../LegacyGame")
@export var camera_path:NodePath = NodePath("../Camera3D")
const ORIGIN_X:float = 365.0
const ORIGIN_Y:float = 120.0
const WORLD_SCALE:float = 0.055
const MOVE_SPEED:float = 210.0
const STOP_DISTANCE:float = 7.0
const CAMERA_HEIGHT:float = 10.5
const CAMERA_DISTANCE:float = 13.5

var legacy:Node2D
var camera:Camera3D
var destination:Vector2 = Vector2.INF
var marker:MeshInstance3D

func _ready() -> void:
	process_priority = 1000
	legacy = get_node_or_null(legacy_path) as Node2D
	camera = get_node_or_null(camera_path) as Camera3D
	set_process_unhandled_input(true)
	call_deferred("_setup_marker")

func _setup_marker() -> void:
	if marker != null or get_parent() == null:
		return
	marker = MeshInstance3D.new()
	marker.name = "StableMoveMarker"
	var ring:TorusMesh = TorusMesh.new()
	ring.inner_radius = 0.22
	ring.outer_radius = 0.30
	marker.mesh = ring
	marker.rotation_degrees.x = 90.0
	var material:StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color("#f6cf67")
	material.emission_enabled = true
	material.emission = Color("#f6cf67")
	material.emission_energy_multiplier = 1.8
	marker.material_override = material
	marker.visible = false
	get_parent().add_child(marker)

func _unhandled_input(event:InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if _ui_has_focus():
			return
		var map_point:Vector2 = _screen_to_map(event.position)
		if map_point != Vector2.INF:
			destination = map_point
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		destination = Vector2.INF

func _process(delta:float) -> void:
	if legacy == null or camera == null or not camera.is_inside_tree():
		return
	var hero_value:Variant = legacy.get("hero")
	if not hero_value is Dictionary:
		return
	var hero:Dictionary = hero_value
	var current:Vector2 = Vector2(float(hero.get("pos_x",595.0)),float(hero.get("pos_y",340.0)))
	var keyboard:Vector2 = _physical_keyboard_direction()
	if keyboard.length_squared() > 0.0:
		destination = Vector2.INF
		current += keyboard * MOVE_SPEED * delta
	elif destination != Vector2.INF:
		var distance:float = current.distance_to(destination)
		if distance <= STOP_DISTANCE:
			current = destination
			destination = Vector2.INF
		else:
			current += current.direction_to(destination) * min(distance,MOVE_SPEED * delta)
	current = _clamp_to_map(current,hero)
	hero["pos_x"] = current.x
	hero["pos_y"] = current.y
	if marker != null:
		marker.visible = destination != Vector2.INF
		if marker.visible:
			marker.position = _map_to_world(destination) + Vector3(0.0,0.06,0.0)
	_stabilize_camera(hero,delta)

func _physical_keyboard_direction() -> Vector2:
	var x:float = 0.0
	var y:float = 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): y += 1.0
	var direction:Vector2 = Vector2(x,y)
	return direction.normalized() if direction.length_squared() > 0.0 else Vector2.ZERO

func _screen_to_map(screen_position:Vector2)->Vector2:
	var origin:Vector3 = camera.project_ray_origin(screen_position)
	var direction:Vector3 = camera.project_ray_normal(screen_position)
	if abs(direction.y) < 0.00001:
		return Vector2.INF
	var distance:float = -origin.y / direction.y
	if distance < 0.0:
		return Vector2.INF
	var point:Vector3 = origin + direction * distance
	return Vector2(point.x / WORLD_SCALE + ORIGIN_X,point.z / WORLD_SCALE + ORIGIN_Y)

func _map_to_world(map_position:Vector2)->Vector3:
	return Vector3((map_position.x - ORIGIN_X) * WORLD_SCALE,0.0,(map_position.y - ORIGIN_Y) * WORLD_SCALE)

func _clamp_to_map(point:Vector2,hero:Dictionary)->Vector2:
	var map_data:Dictionary = TeleportSystem.MAPS.get(int(hero.get("map_id",0)),{})
	var max_x:float = ORIGIN_X + float(map_data.get("width",1200)) - 1.0
	var max_y:float = ORIGIN_Y + float(map_data.get("height",700)) - 1.0
	return Vector2(clamp(point.x,ORIGIN_X,max_x),clamp(point.y,ORIGIN_Y,max_y))

func _stabilize_camera(hero:Dictionary,delta:float)->void:
	var target:Vector3 = _map_to_world(Vector2(float(hero.get("pos_x",595.0)),float(hero.get("pos_y",340.0))))
	var desired:Vector3 = target + Vector3(0.0,CAMERA_HEIGHT,CAMERA_DISTANCE)
	var blend:float = clamp(1.0 - exp(-12.0 * max(delta,0.001)),0.0,1.0)
	camera.global_position = camera.global_position.lerp(desired,blend)
	camera.look_at(target + Vector3(0.0,0.8,0.0),Vector3.UP)

func _ui_has_focus()->bool:
	var focus:Control = get_viewport().gui_get_focus_owner() as Control
	return focus != null and focus.visible and focus.is_inside_tree()
