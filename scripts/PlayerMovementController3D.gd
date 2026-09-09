class_name PlayerMovementController3D
extends Node

const WORLD_SCALE:float = 0.055
const ORIGIN_X:float = 365.0
const ORIGIN_Y:float = 120.0
const MOVE_SPEED:float = 180.0
const STOP_DISTANCE:float = 5.0
const ATTACK_DISTANCE:float = 88.0

var game:Node3D
var legacy:Node2D
var camera:Camera3D
var target_map:Vector2 = Vector2.ZERO
var mouse_moving:bool = false
var target_monster:Dictionary = {}
var marker:MeshInstance3D
var _last_hero_position:Vector2 = Vector2.INF

func _ready()->void:
	game = get_parent() as Node3D
	legacy = game.get_node_or_null("LegacyGame") as Node2D
	camera = game.get_node_or_null("Camera3D") as Camera3D
	call_deferred("_setup")

func _setup()->void:
	marker = MeshInstance3D.new()
	marker.name = "MouseMoveMarker"
	var ring:TorusMesh = TorusMesh.new()
	ring.inner_radius = 0.20
	ring.outer_radius = 0.29
	marker.mesh = ring
	marker.rotation_degrees.x = 90.0
	var material:StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color("#f6cf67")
	material.emission_enabled = true
	material.emission = Color("#f6cf67")
	material.emission_energy_multiplier = 2.0
	marker.material_override = material
	marker.visible = false
	game.add_child(marker)

func _process(delta:float)->void:
	if legacy == null or camera == null or not camera.is_inside_tree():
		return
	var hero_value:Variant = legacy.get("hero")
	if not hero_value is Dictionary:
		return
	var hero:Dictionary = hero_value
	_apply_keyboard_fallback(hero,delta)
	_apply_mouse_movement(hero,delta)
	_handle_mouse_attack(hero)

func _apply_keyboard_fallback(hero:Dictionary,delta:float)->void:
	# Main.gd owns the normal action-map movement. This is only a physical-key
	# fallback for machines where imported project input actions miss A/D.
	var mapped:Vector2 = Input.get_vector("move_left","move_right","move_up","move_down")
	var direct:Vector2 = Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A): direct.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D): direct.x += 1.0
	if Input.is_physical_key_pressed(KEY_W): direct.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S): direct.y += 1.0
	if mapped.length_squared() > 0.0001 or direct.length_squared() <= 0.0001:
		return
	_move_hero(hero,direct.normalized(),delta)

func _apply_mouse_movement(hero:Dictionary,delta:float)->void:
	if not mouse_moving:
		return
	var position:Vector2 = Vector2(float(hero.get("pos_x",595.0)),float(hero.get("pos_y",340.0)))
	var distance:float = position.distance_to(target_map)
	if distance <= STOP_DISTANCE:
		hero["pos_x"] = target_map.x
		hero["pos_y"] = target_map.y
		mouse_moving = false
		if marker != null: marker.visible = false
		return
	_move_hero(hero,position.direction_to(target_map),delta)
	if marker != null:
		marker.visible = true
		marker.position = _map_to_world(target_map) + Vector3(0.0,0.06,0.0)

func _move_hero(hero:Dictionary,direction:Vector2,delta:float)->void:
	if direction.length_squared() <= 0.0001:
		return
	var equipment_value:Variant = hero.get("equipment",{})
	var move_percent:float = 0.0
	if equipment_value is Dictionary:
		move_percent = float((equipment_value as Dictionary).get("move_percent",0.0))
	var speed:float = MOVE_SPEED*(1.0+move_percent/100.0)
	var map_data:Dictionary = TeleportSystem.MAPS.get(int(hero.get("map_id",0)),{})
	var min_x:float = ORIGIN_X
	var min_y:float = ORIGIN_Y
	var max_x:float = ORIGIN_X+float(map_data.get("width",1200))-1.0
	var max_y:float = ORIGIN_Y+float(map_data.get("height",700))-1.0
	hero["pos_x"] = clamp(float(hero.get("pos_x",595.0))+direction.x*speed*delta,min_x,max_x)
	hero["pos_y"] = clamp(float(hero.get("pos_y",340.0))+direction.y*speed*delta,min_y,max_y)

func _input(event:InputEvent)->void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT:
			if _is_pointer_over_ui(event.position):
				return
			_set_mouse_destination(event.position)

func _set_mouse_destination(screen_position:Vector2)->void:
	if camera == null or not camera.is_inside_tree() or legacy == null:
		return
	var monster:Dictionary = _pick_monster(screen_position)
	if not monster.is_empty():
		target_monster = monster
		var monster_pos:Variant = monster.get("pos",Vector2.ZERO)
		if monster_pos is Vector2:
			var hero_value:Variant = legacy.get("hero")
			var hero:Dictionary = hero_value if hero_value is Dictionary else {}
			var hero_pos:Vector2 = Vector2(float(hero.get("pos_x",595.0)),float(hero.get("pos_y",340.0)))
			target_map = (monster_pos as Vector2)+((monster_pos as Vector2).direction_to(hero_pos))*62.0
			mouse_moving = true
			return
	var ground:Vector3 = _screen_to_ground(screen_position)
	if ground == Vector3.INF:
		return
	target_monster = {}
	target_map = _world_to_map(ground)
	mouse_moving = true

func _handle_mouse_attack(hero:Dictionary)->void:
	if target_monster.is_empty():
		return
	var monster_pos_value:Variant = target_monster.get("pos",Vector2.ZERO)
	if not monster_pos_value is Vector2:
		target_monster = {}
		return
	var hero_pos:Vector2 = Vector2(float(hero.get("pos_x",595.0)),float(hero.get("pos_y",340.0)))
	if hero_pos.distance_to(monster_pos_value as Vector2) <= ATTACK_DISTANCE:
		mouse_moving = false
		if legacy.has_method("attack"):
			legacy.call("attack")

func _pick_monster(screen_position:Vector2)->Dictionary:
	var monsters_value:Variant = legacy.get("monsters")
	if not monsters_value is Array:
		return {}
	var best:Dictionary = {}
	var best_distance:float = 76.0
	for item in monsters_value as Array:
		if not item is Dictionary:
			continue
		var monster:Dictionary = item
		if int(monster.get("hp",0)) <= 0:
			continue
		var position_value:Variant = monster.get("pos",Vector2.ZERO)
		if not position_value is Vector2:
			continue
		var projected:Vector2 = camera.unproject_position(_map_to_world(position_value as Vector2)+Vector3(0.0,1.0,0.0))
		var distance:float = projected.distance_to(screen_position)
		if distance < best_distance:
			best_distance = distance
			best = monster
	return best

func _screen_to_ground(screen_position:Vector2)->Vector3:
	var origin:Vector3 = camera.project_ray_origin(screen_position)
	var direction:Vector3 = camera.project_ray_normal(screen_position)
	if abs(direction.y) < 0.00001:
		return Vector3.INF
	var t:float = -origin.y/direction.y
	if t < 0.0:
		return Vector3.INF
	return origin+direction*t

func _map_to_world(position:Vector2)->Vector3:
	return Vector3((position.x-ORIGIN_X)*WORLD_SCALE,0.0,(position.y-ORIGIN_Y)*WORLD_SCALE)

func _world_to_map(position:Vector3)->Vector2:
	return Vector2(position.x/WORLD_SCALE+ORIGIN_X,position.z/WORLD_SCALE+ORIGIN_Y)

func _is_pointer_over_ui(screen_position:Vector2)->bool:
	var focused:Control = get_viewport().gui_get_focus_owner()
	if focused != null and focused.global_rect.has_point(screen_position):
		return true
	return false
