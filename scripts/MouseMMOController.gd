class_name MouseMMOController
extends Node

const WORLD_SCALE:float=0.055
const ORIGIN_X:float=365.0
const ORIGIN_Y:float=120.0
const CLICK_RADIUS_PIXELS:float=70.0
const ATTACK_DISTANCE:float=105.0
const ATTACK_INTERVAL:float=0.74
const AUTO_ATTACK_SCAN_INTERVAL:float=0.35

var game:Node
var legacy:Node2D
var camera:Camera3D
var mouse_target:Vector3=Vector3.ZERO
var has_move_target:bool=false
var attack_target:Dictionary={}
var attack_timer:float=0.0
var auto_scan_timer:float=0.0
var auto_attack_enabled:bool=true
var cursor_marker:MeshInstance3D

func _ready()->void:
	game=get_parent()
	legacy=game.get_node_or_null("LegacyGame") as Node2D
	camera=game.get_node_or_null("Camera3D") as Camera3D
	call_deferred("_build_cursor_marker")

func _process(delta:float)->void:
	if legacy==null or camera==null: return
	attack_timer=max(0.0,attack_timer-delta)
	auto_scan_timer=max(0.0,auto_scan_timer-delta)
	var hero_value:Variant=legacy.get("hero")
	if not hero_value is Dictionary: return
	var hero:Dictionary=hero_value

	# Ragnarok-style default auto-combat: the hero continuously acquires the
	# nearest living monster when there is no explicit mouse-selected target.
	if auto_attack_enabled and attack_target.is_empty() and auto_scan_timer<=0.0:
		auto_scan_timer=AUTO_ATTACK_SCAN_INTERVAL
		var nearest:Dictionary=_find_nearest_monster(hero)
		if not nearest.is_empty():
			attack_target=nearest

	if has_move_target:
		var hero_pos:Vector2=Vector2(float(hero.get("pos_x",595.0)),float(hero.get("pos_y",340.0)))
		var target_2d:Vector2=_world_to_map(mouse_target)
		var distance:float=hero_pos.distance_to(target_2d)
		if distance>7.0:
			var step:float=min(distance,320.0*delta)
			var direction:Vector2=hero_pos.direction_to(target_2d)
			var map_data:Dictionary=TeleportSystem.MAPS.get(int(hero.get("map_id",0)),{})
			var min_x:float=ORIGIN_X
			var min_y:float=ORIGIN_Y
			var max_x:float=ORIGIN_X+float(map_data.get("width",1200))-1.0
			var max_y:float=ORIGIN_Y+float(map_data.get("height",700))-1.0
			var next_x:float=clamp(float(hero["pos_x"])+direction.x*step,min_x,max_x)
			var next_y:float=clamp(float(hero["pos_y"])+direction.y*step,min_y,max_y)
			hero["pos_x"]=next_x
			hero["pos_y"]=next_y
		else:
			hero["pos_x"]=target_2d.x
			hero["pos_y"]=target_2d.y
			has_move_target=false

	if not attack_target.is_empty():
		var target:Dictionary=attack_target
		var monsters_value:Variant=legacy.get("monsters")
		if not monsters_value is Array or not (monsters_value as Array).has(target):
			attack_target={}
		else:
			var target_pos:Vector2=target.get("pos",Vector2.ZERO)
			var current_pos:Vector2=Vector2(float(hero.get("pos_x",595.0)),float(hero.get("pos_y",340.0)))
			var dist:float=current_pos.distance_to(target_pos)
			if dist>ATTACK_DISTANCE:
				has_move_target=true
				mouse_target=_map_to_world(target_pos)
			elif attack_timer<=0.0:
				has_move_target=false
				attack_timer=ATTACK_INTERVAL
				if legacy.has_method("attack"): legacy.call("attack")
	_update_marker()

func _find_nearest_monster(hero:Dictionary)->Dictionary:
	var monsters_value:Variant=legacy.get("monsters")
	if not monsters_value is Array: return {}
	var hero_pos:=Vector2(float(hero.get("pos_x",595.0)),float(hero.get("pos_y",340.0)))
	var best:Dictionary={}
	var best_distance:float=INF
	for item in monsters_value as Array:
		if not item is Dictionary: continue
		var monster:Dictionary=item
		if int(monster.get("hp",1))<=0: continue
		var monster_pos:Variant=monster.get("pos",Vector2.ZERO)
		if not monster_pos is Vector2: continue
		var distance:float=hero_pos.distance_to(monster_pos as Vector2)
		if distance<best_distance:
			best_distance=distance
			best=monster
	return best

func _unhandled_input(event:InputEvent)->void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index==MOUSE_BUTTON_LEFT or event.button_index==MOUSE_BUTTON_RIGHT:
			_handle_mouse_click(event.position)

func _handle_mouse_click(screen_position:Vector2)->void:
	var gate:Node=_pick_warp_gate(screen_position)
	if gate!=null:
		if gate.has_method("activate"): gate.call("activate")
		attack_target={}
		has_move_target=false
		return
	var monster:Dictionary=_pick_monster(screen_position)
	if not monster.is_empty():
		attack_target=monster
		has_move_target=true
		mouse_target=_map_to_world(monster.get("pos",Vector2.ZERO))
		return
	var world_point:Vector3=_screen_to_ground(screen_position)
	if world_point==Vector3.INF: return
	attack_target={}
	mouse_target=world_point
	has_move_target=true
	attack_timer=0.0

func _pick_monster(screen_position:Vector2)->Dictionary:
	if legacy==null: return {}
	var monsters_value:Variant=legacy.get("monsters")
	if not monsters_value is Array: return {}
	var best:Dictionary={}
	var best_distance:float=CLICK_RADIUS_PIXELS
	for item in monsters_value as Array:
		if not item is Dictionary: continue
		var monster:Dictionary=item
		var pos_value:Variant=monster.get("pos",Vector2.ZERO)
		if not pos_value is Vector2: continue
		var world:Vector3=_map_to_world(pos_value as Vector2)
		var screen:Vector2=camera.unproject_position(world+Vector3(0.0,0.8,0.0))
		var distance:float=screen.distance_to(screen_position)
		if distance<best_distance:
			best_distance=distance
			best=monster
	return best

func _pick_warp_gate(screen_position:Vector2)->Node:
	var best:Node=null
	var best_distance:float=CLICK_RADIUS_PIXELS
	for item in get_tree().get_nodes_in_group("warp_gate"):
		var gate:Node3D=item as Node3D
		if gate==null or not gate.is_visible_in_tree(): continue
		var screen:Vector2=camera.unproject_position(gate.global_position+Vector3(0.0,1.1,0.0))
		var distance:float=screen.distance_to(screen_position)
		if distance<best_distance:
			best_distance=distance
			best=gate
	return best

func _screen_to_ground(screen_position:Vector2)->Vector3:
	var origin:Vector3=camera.project_ray_origin(screen_position)
	var direction:Vector3=camera.project_ray_normal(screen_position)
	if abs(direction.y)<0.0001: return Vector3.INF
	var distance:float=-origin.y/direction.y
	if distance<0.0: return Vector3.INF
	return origin+direction*distance

func _map_to_world(pos:Vector2)->Vector3:
	return Vector3((pos.x-ORIGIN_X)*WORLD_SCALE,0.0,(pos.y-ORIGIN_Y)*WORLD_SCALE)

func _world_to_map(pos:Vector3)->Vector2:
	return Vector2(pos.x/WORLD_SCALE+ORIGIN_X,pos.z/WORLD_SCALE+ORIGIN_Y)

func _build_cursor_marker()->void:
	cursor_marker=MeshInstance3D.new()
	var ring:TorusMesh=TorusMesh.new()
	ring.inner_radius=0.20
	ring.outer_radius=0.27
	cursor_marker.mesh=ring
	var material:StandardMaterial3D=StandardMaterial3D.new()
	material.albedo_color=Color("#f5d06f")
	material.emission_enabled=true
	material.emission=Color("#f5d06f")
	material.emission_energy_multiplier=2.4
	cursor_marker.material_override=material
	cursor_marker.rotation_degrees.x=90.0
	cursor_marker.visible=false
	game.add_child(cursor_marker)

func _update_marker()->void:
	if cursor_marker==null: return
	cursor_marker.visible=has_move_target
	if has_move_target:
		cursor_marker.position=mouse_target+Vector3(0.0,0.045,0.0)
		cursor_marker.scale=Vector3.ONE*(1.0+sin(Time.get_ticks_msec()*0.008)*0.08)
