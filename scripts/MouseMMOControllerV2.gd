class_name MouseMMOControllerV2
extends Node

const WORLD_SCALE:float=0.055
const ORIGIN_X:float=365.0
const ORIGIN_Y:float=120.0
const MOVE_SPEED:float=320.0
const STOP_DISTANCE:float=6.0
const ATTACK_DISTANCE:float=88.0
var game:Node
var legacy:Node2D
var camera:Camera3D
var target_map:Vector2=Vector2.ZERO
var moving:bool=false
var target_monster:Dictionary={}
var marker:MeshInstance3D

func _ready()->void:
	game=get_parent()
	legacy=game.get_node_or_null("LegacyGame") as Node2D
	camera=game.get_node_or_null("Camera3D") as Camera3D
	call_deferred("_setup")

func _setup()->void:
	marker=MeshInstance3D.new()
	marker.name="MouseMoveMarker"
	var ring:TorusMesh=TorusMesh.new()
	ring.inner_radius=0.22
	ring.outer_radius=0.31
	marker.mesh=ring
	marker.rotation_degrees.x=90.0
	var mat:StandardMaterial3D=StandardMaterial3D.new()
	mat.albedo_color=Color("#f6cf67")
	mat.emission_enabled=true
	mat.emission=Color("#f6cf67")
	mat.emission_energy_multiplier=2.0
	marker.material_override=mat
	marker.visible=false
	game.add_child(marker)

func _process(delta:float)->void:
	if legacy==null or camera==null or not camera.is_inside_tree(): return
	var hero_value:Variant=legacy.get("hero")
	if not hero_value is Dictionary: return
	var hero:Dictionary=hero_value
	if moving:
		var pos:=Vector2(float(hero.get("pos_x",595.0)),float(hero.get("pos_y",340.0)))
		var distance:=pos.distance_to(target_map)
		if distance<=STOP_DISTANCE:
			hero["pos_x"]=target_map.x
			hero["pos_y"]=target_map.y
			moving=false
		else:
			var step:=min(distance,MOVE_SPEED*delta)
			var dir:=pos.direction_to(target_map)
			var map_data:Dictionary=TeleportSystem.MAPS.get(int(hero.get("map_id",0)),{})
			var min_x:=ORIGIN_X
			var min_y:=ORIGIN_Y
			var max_x:=ORIGIN_X+float(map_data.get("width",1200))-1.0
			var max_y:=ORIGIN_Y+float(map_data.get("height",700))-1.0
			hero["pos_x"]=clamp(float(hero["pos_x"])+dir.x*step,min_x,max_x)
			hero["pos_y"]=clamp(float(hero["pos_y"])+dir.y*step,min_y,max_y)
		if marker!=null:
			marker.visible=true
			marker.position=_map_to_world(target_map)+Vector3(0,0.06,0)
	if not target_monster.is_empty():
		var monsters_value:Variant=legacy.get("monsters")
		if monsters_value is Array and (monsters_value as Array).has(target_monster):
			var monster_pos:Variant=target_monster.get("pos",Vector2.ZERO)
			if monster_pos is Vector2:
				var pos:=Vector2(float(hero.get("pos_x",595.0)),float(hero.get("pos_y",340.0)))
				if pos.distance_to(monster_pos as Vector2)<=ATTACK_DISTANCE:
					moving=false
					if legacy.has_method("attack"): legacy.call("attack")
		else:
			target_monster={}

func _input(event:InputEvent)->void:
	if event is InputEventMouseButton and event.pressed and (event.button_index==MOUSE_BUTTON_LEFT or event.button_index==MOUSE_BUTTON_RIGHT):
		_handle_click(event.position)

func _handle_click(screen_pos:Vector2)->void:
	if camera==null or not camera.is_inside_tree(): return
	var monster:=_pick_monster(screen_pos)
	if not monster.is_empty():
		target_monster=monster
		var monster_pos:Vector2=monster.get("pos",Vector2.ZERO)
		var hero_value:Variant=legacy.get("hero")
		var hero:Dictionary=hero_value if hero_value is Dictionary else {}
		var hero_pos:=Vector2(float(hero.get("pos_x",595.0)),float(hero.get("pos_y",340.0)))
		var dir:=monster_pos.direction_to(hero_pos)
		target_map=monster_pos+dir*62.0
		moving=true
		return
	var point:=_screen_to_ground(screen_pos)
	if point==Vector3.INF: return
	target_monster={}
	target_map=_world_to_map(point)
	moving=true

func _pick_monster(screen_pos:Vector2)->Dictionary:
	var monsters_value:Variant=legacy.get("monsters")
	if not monsters_value is Array: return {}
	var best:Dictionary={}
	var best_d:=82.0
	for item in monsters_value as Array:
		if not item is Dictionary: continue
		var monster:Dictionary=item
		if int(monster.get("hp",0))<=0: continue
		var p:Variant=monster.get("pos",Vector2.ZERO)
		if not p is Vector2: continue
		var s:=camera.unproject_position(_map_to_world(p as Vector2)+Vector3(0,1.0,0))
		var d:=s.distance_to(screen_pos)
		if d<best_d:
			best_d=d
			best=monster
	return best

func _screen_to_ground(screen_pos:Vector2)->Vector3:
	var origin:=camera.project_ray_origin(screen_pos)
	var direction:=camera.project_ray_normal(screen_pos)
	if abs(direction.y)<0.00001: return Vector3.INF
	var t:float=-origin.y/direction.y
	if t<0.0: return Vector3.INF
	return origin+direction*t

func _map_to_world(p:Vector2)->Vector3:
	return Vector3((p.x-ORIGIN_X)*WORLD_SCALE,0.0,(p.y-ORIGIN_Y)*WORLD_SCALE)

func _world_to_map(p:Vector3)->Vector2:
	return Vector2(p.x/WORLD_SCALE+ORIGIN_X,p.z/WORLD_SCALE+ORIGIN_Y)
