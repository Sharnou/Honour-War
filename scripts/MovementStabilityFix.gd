class_name MovementStabilityFix
extends Node

@export var legacy_path:NodePath = NodePath("../LegacyGame")
@export var camera_path:NodePath = NodePath("../Camera3D")
const ORIGIN_X:float = 365.0
const ORIGIN_Y:float = 120.0
const WORLD_SCALE:float = 0.055
const MOVE_SPEED:float = 210.0
const STOP_DISTANCE:float = 7.0
const SWORDSMAN_STOP_RANGE:float = 44.0
const ARCHER_STOP_RANGE:float = 210.0
const CAMERA_POSITION:Vector3 = Vector3(12.925,10.5,26.15)
const CAMERA_TARGET:Vector3 = Vector3(12.925,0.0,12.65)

var legacy:Node2D
var camera:Camera3D
var destination:Vector2 = Vector2.INF
var marker:MeshInstance3D
var selected_monster:Dictionary = {}

func _ready() -> void:
	process_priority = 1000
	legacy = get_node_or_null(legacy_path) as Node2D
	camera = get_node_or_null(camera_path) as Camera3D
	set_process_unhandled_input(true)
	call_deferred("_setup_camera")
	call_deferred("_setup_marker")

func _setup_camera() -> void:
	if camera == null or not camera.is_inside_tree():
		return
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 16.0
	camera.global_position = CAMERA_POSITION
	camera.look_at(CAMERA_TARGET,Vector3.UP)
	camera.current = true

func _setup_marker() -> void:
	if marker != null or get_parent() == null:
		return
	marker = MeshInstance3D.new()
	marker.name = "StableMoveMarker"
	var ring:TorusMesh = TorusMesh.new()
	ring.inner_radius = 0.22
	ring.outer_radius = 0.30
	marker.mesh = ring
	ring.rotation_degrees.x = 90.0
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
		_handle_world_click(event.position)
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		destination = Vector2.INF
		selected_monster = {}

func _handle_world_click(screen_position:Vector2)->void:
	var clicked:=_pick_monster(screen_position)
	if not clicked.is_empty():
		selected_monster = clicked
		var hero_value:Variant = legacy.get("hero") if legacy else null
		if not hero_value is Dictionary:
			return
		var hero:Dictionary = hero_value
		var hero_pos:=Vector2(float(hero.get("pos_x",595.0)),float(hero.get("pos_y",340.0)))
		var monster_pos:Vector2 = clicked.get("pos",hero_pos)
		var distance:=hero_pos.distance_to(monster_pos)
		var desired:=_engagement_range(hero)
		if distance <= desired:
			destination = Vector2.INF
		else:
			var direction:=monster_pos.direction_to(hero_pos)
			destination = monster_pos + direction * desired
		return
	var map_point:Vector2 = _screen_to_map(screen_position)
	if map_point != Vector2.INF:
		selected_monster = {}
		destination = map_point

func _engagement_range(hero:Dictionary)->float:
	var class_id:=str(hero.get("class","Warrior")).to_lower()
	if class_id == "archer" or class_id == "ranger":
		return ARCHER_STOP_RANGE
	return SWORDSMAN_STOP_RANGE

func _pick_monster(screen_position:Vector2)->Dictionary:
	if legacy == null or camera == null:
		return {}
	var monsters_value:Variant = legacy.get("monsters")
	if not monsters_value is Array:
		return {}
	var best:Dictionary = {}
	var best_distance:float = 58.0
	for item in monsters_value as Array:
		if not item is Dictionary:
			continue
		var monster:Dictionary = item
		if int(monster.get("hp",0)) <= 0:
			continue
		var p:Variant = monster.get("pos",Vector2.ZERO)
		if not p is Vector2:
			continue
		var screen:Vector2 = camera.unproject_position(_map_to_world(p as Vector2)+Vector3(0.0,1.0,0.0))
		var distance:float = screen.distance_to(screen_position)
		if distance < best_distance:
			best_distance = distance
			best = monster
	return best

func _process(delta:float) -> void:
	if legacy == null or camera == null or not camera.is_inside_tree():
		return
	var hero_value:Variant = legacy.get("hero")
	if not hero_value is Dictionary:
		return
	var hero:Dictionary = hero_value
	var current:Vector2 = Vector2(float(hero.get("pos_x",595.0)),float(hero.get("pos_y",340.0)))
	if destination != Vector2.INF:
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
	camera.global_position = CAMERA_POSITION
	camera.look_at(CAMERA_TARGET,Vector3.UP)

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

func _ui_has_focus()->bool:
	var focus:Control = get_viewport().gui_get_focus_owner() as Control
	return focus != null and focus.visible and focus.is_inside_tree()
