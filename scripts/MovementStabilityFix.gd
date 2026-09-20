class_name MovementStabilityFix
extends Node

const CombatRules=preload("res://scripts/CombatRules.gd")
const TeleportSystem=preload("res://scripts/TeleportSystem.gd")

@export var legacy_path:NodePath = NodePath("../LegacyGame")
@export var camera_path:NodePath = NodePath("../Camera3D")
@export var zoom_min_distance:float = 10.0
@export var zoom_max_distance:float = 42.0
@export var zoom_step:float = 1.75
@export var zoom_smoothing:float = 10.0
@export var rotation_smoothing:float = 10.0
@export var rotation_step_degrees:float = 90.0
@export var keyboard_yaw_step_degrees:float = 12.0
@export var keyboard_pitch_step_degrees:float = 4.0
@export var mouse_orbit_yaw_sensitivity:float = 0.28
@export var mouse_orbit_pitch_sensitivity:float = 0.18
const ORIGIN_X:float = 365.0
const ORIGIN_Y:float = 120.0
const WORLD_SCALE:float = 0.055
const MOVE_SPEED:float = 235.0
const STOP_DISTANCE:float = 1.5
const CAMERA_DISTANCE:float = 24.0
const CAMERA_PITCH:float = -48.0
const MIN_CAMERA_PITCH:float = -62.0
const MAX_CAMERA_PITCH:float = -28.0
const CAMERA_FOV:float = 58.0
const ONLINE_SEND_INTERVAL:float = 0.05

var legacy:Node2D
var camera:Camera3D
var authority:Node
var destination:Vector2 = Vector2.INF
var marker:MeshInstance3D
var selected_monster:Dictionary = {}
var camera_distance:float = CAMERA_DISTANCE
var target_camera_distance:float = CAMERA_DISTANCE
var camera_yaw:float = 0.0
var target_camera_yaw:float = 0.0
var camera_pitch:float = CAMERA_PITCH
var target_camera_pitch:float = CAMERA_PITCH
var middle_dragging:bool = false
var last_middle_position:Vector2 = Vector2.ZERO
var online_send_elapsed:float = 0.0
var last_online_sent_position:Vector2 = Vector2.INF

func _ready()->void:
    process_priority=1000
    legacy=get_node_or_null(legacy_path) as Node2D
    camera=get_node_or_null(camera_path) as Camera3D
    authority=get_node_or_null("/root/HWOnlineAuthorityRuntime")
    set_process_unhandled_input(true)
    camera_distance=clamp(CAMERA_DISTANCE,zoom_min_distance,zoom_max_distance)
    target_camera_distance=camera_distance
    camera_pitch=clamp(CAMERA_PITCH,MIN_CAMERA_PITCH,MAX_CAMERA_PITCH)
    target_camera_pitch=camera_pitch
    call_deferred("_setup_camera")
    call_deferred("_setup_marker")

func _setup_camera()->void:
    if camera==null or not camera.is_inside_tree(): return
    camera.projection=Camera3D.PROJECTION_PERSPECTIVE
    camera.fov=CAMERA_FOV
    camera.near=0.08
    camera.far=700.0
    camera.current=true
    _apply_camera(1.0)

func _apply_camera(delta:float=1.0)->void:
    if camera==null or legacy==null: return
    var value:Variant=legacy.get("hero")
    var hero:Dictionary=value if value is Dictionary else {}
    var map_pos:Vector2=Vector2(float(hero.get("pos_x",595.0)),float(hero.get("pos_y",340.0)))
    var target:Vector3=_map_to_world(map_pos)+Vector3(0.0,1.0,0.0)
    var zoom_alpha:float=1.0-exp(-zoom_smoothing*max(delta,0.016))
    var rotation_alpha:float=1.0-exp(-rotation_smoothing*max(delta,0.016))
    camera_distance=lerp(camera_distance,target_camera_distance,zoom_alpha)
    camera_yaw=rad_to_deg(lerp_angle(deg_to_rad(camera_yaw),deg_to_rad(target_camera_yaw),rotation_alpha))
    camera_pitch=rad_to_deg(lerp_angle(deg_to_rad(camera_pitch),deg_to_rad(target_camera_pitch),rotation_alpha))
    camera_pitch=clamp(camera_pitch,MIN_CAMERA_PITCH,MAX_CAMERA_PITCH)
    camera_yaw=wrapf(camera_yaw,0.0,360.0)
    target_camera_yaw=wrapf(target_camera_yaw,0.0,360.0)
    var pitch:float=deg_to_rad(camera_pitch)
    var yaw:float=deg_to_rad(camera_yaw)
    var horizontal:float=cos(pitch)*camera_distance
    var vertical:float=-sin(pitch)*camera_distance
    var offset:=Vector3(sin(yaw)*horizontal,vertical,cos(yaw)*horizontal)
    var desired:Vector3=target+offset
    var camera_alpha:float=1.0-exp(-10.0*max(delta,0.016))
    camera.global_position=camera.global_position.lerp(desired,camera_alpha)
    camera.look_at(target,Vector3.UP)
    camera.current=true

func _setup_marker()->void:
    if marker!=null or get_parent()==null: return
    marker=MeshInstance3D.new(); marker.name="StableMoveMarker"
    var ring:=TorusMesh.new(); ring.inner_radius=0.22; ring.outer_radius=0.31; ring.rings=32; ring.ring_segments=8; marker.mesh=ring; marker.rotation_degrees.x=90.0
    var material:=StandardMaterial3D.new(); material.albedo_color=Color("#f6cf67"); material.emission_enabled=true; material.emission=Color("#f6cf67"); material.emission_energy_multiplier=1.8; marker.material_override=material; marker.visible=false
    get_parent().add_child(marker)

func _unhandled_input(event:InputEvent)->void:
    if event is InputEventMouseButton:
        if event.button_index==MOUSE_BUTTON_WHEEL_UP and event.pressed:
            _change_zoom(-zoom_step)
            get_viewport().set_input_as_handled()
        elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
            _change_zoom(zoom_step)
            get_viewport().set_input_as_handled()
        elif event.button_index==MOUSE_BUTTON_MIDDLE:
            if event.pressed:
                middle_dragging=true
                last_middle_position=event.position
            else:
                middle_dragging=false
            get_viewport().set_input_as_handled()
        elif event.button_index==MOUSE_BUTTON_LEFT and event.pressed and not _ui_has_focus():
            _handle_world_click(event.position)
        elif event.button_index==MOUSE_BUTTON_RIGHT and event.pressed:
            selected_monster={}; destination=Vector2.INF
    elif event is InputEventMouseMotion and middle_dragging and not _ui_has_focus():
        var motion:InputEventMouseMotion=event as InputEventMouseMotion
        target_camera_yaw=wrapf(target_camera_yaw-motion.relative.x*mouse_orbit_yaw_sensitivity,0.0,360.0)
        target_camera_pitch=clamp(target_camera_pitch+motion.relative.y*mouse_orbit_pitch_sensitivity,MIN_CAMERA_PITCH,MAX_CAMERA_PITCH)
        last_middle_position=event.position
        get_viewport().set_input_as_handled()
    elif event is InputEventKey and event.pressed and not event.echo:
        match event.keycode:
            KEY_ESCAPE:
                destination=Vector2.INF; selected_monster={}; middle_dragging=false
                get_viewport().set_input_as_handled()
            KEY_Q:
                _rotate_keyboard_yaw(-1.0)
                get_viewport().set_input_as_handled()
            KEY_E:
                _rotate_keyboard_yaw(1.0)
                get_viewport().set_input_as_handled()

func _change_zoom(amount:float)->void:
    target_camera_distance=clamp(target_camera_distance+amount,zoom_min_distance,zoom_max_distance)

func _rotate_camera(step_sign:float)->void:
    target_camera_yaw=wrapf(target_camera_yaw+rotation_step_degrees*step_sign,0.0,360.0)

func _rotate_keyboard_yaw(step_sign:float)->void:
    target_camera_yaw=wrapf(target_camera_yaw+keyboard_yaw_step_degrees*step_sign,0.0,360.0)

func _rotate_keyboard_pitch(step_sign:float)->void:
    target_camera_pitch=clamp(target_camera_pitch+keyboard_pitch_step_degrees*step_sign,MIN_CAMERA_PITCH,MAX_CAMERA_PITCH)

func _handle_world_click(screen_position:Vector2)->void:
    var clicked:=_pick_monster(screen_position)
    if not clicked.is_empty():
        selected_monster=clicked
        var value:Variant=legacy.get("hero") if legacy else null
        if not value is Dictionary: return
        var hero:Dictionary=value
        var hero_pos:Vector2=Vector2(float(hero.get("pos_x",595.0)),float(hero.get("pos_y",340.0)))
        var monster_pos:Vector2=clicked.get("pos",hero_pos)
        var distance:float=hero_pos.distance_to(monster_pos)
        var desired:float=CombatRules.class_engagement_map(hero)
        if distance>desired: destination=CombatRules.snap_map_point(monster_pos+monster_pos.direction_to(hero_pos)*desired)
        else: destination=Vector2.INF
        return
    var map_point:=_screen_to_map(screen_position)
    if map_point!=Vector2.INF:
        selected_monster={}; destination=CombatRules.snap_map_point(map_point)

func _pick_monster(screen_position:Vector2)->Dictionary:
    if legacy==null or camera==null: return {}
    var monsters_value:Variant=legacy.get("monsters")
    if not monsters_value is Array: return {}
    var best:Dictionary={}; var best_distance:float=58.0
    for item in monsters_value as Array:
        if not item is Dictionary: continue
        var monster:Dictionary=item
        if int(monster.get("hp",0))<=0: continue
        var p:Variant=monster.get("pos",Vector2.ZERO)
        if not p is Vector2: continue
        var screen:=camera.unproject_position(_map_to_world(p as Vector2)+Vector3(0.0,1.0,0.0))
        var distance:float=screen.distance_to(screen_position)
        if distance<best_distance: best_distance=distance; best=monster
    return best

func _process(delta:float)->void:
    if legacy==null or camera==null or not camera.is_inside_tree(): return
    if authority==null or not is_instance_valid(authority):
        authority=get_node_or_null("/root/HWOnlineAuthorityRuntime")
    if Input.is_action_just_pressed("camera_rotate_left"):
        _rotate_camera(-1.0)
    if Input.is_action_just_pressed("camera_rotate_right"):
        _rotate_camera(1.0)
    var value:Variant=legacy.get("hero")
    if not value is Dictionary: return
    var hero:Dictionary=value
    var current:Vector2=Vector2(float(hero.get("pos_x",595.0)),float(hero.get("pos_y",340.0)))
    var keyboard_direction:=Vector2(
        Input.get_action_strength("move_right")-Input.get_action_strength("move_left"),
        Input.get_action_strength("move_down")-Input.get_action_strength("move_up")
    )
    if keyboard_direction.length()>0.01:
        keyboard_direction=keyboard_direction.normalized()
        current+=keyboard_direction*MOVE_SPEED*delta
        destination=Vector2.INF
    elif destination!=Vector2.INF:
        var distance:float=current.distance_to(destination)
        if distance<=STOP_DISTANCE:
            current=destination
            destination=Vector2.INF
        else:
            current+=current.direction_to(destination)*min(distance,MOVE_SPEED*delta)
    current=_clamp_to_map(current,hero)
    hero["pos_x"]=current.x
    hero["pos_y"]=current.y
    online_send_elapsed+=delta
    if _online_authenticated() and online_send_elapsed>=ONLINE_SEND_INTERVAL:
        online_send_elapsed=0.0
        if last_online_sent_position==Vector2.INF or last_online_sent_position.distance_to(current)>=0.25:
            authority.request_action("move",{"absolute":true,"x":current.x,"y":current.y})
            last_online_sent_position=current
    elif not _online_authenticated():
        last_online_sent_position=Vector2.INF
    _apply_camera(delta)
    if marker!=null:
        marker.visible=destination!=Vector2.INF
        if marker.visible: marker.position=_map_to_world(destination)+Vector3(0.0,0.06,0.0)

func _online_authenticated()->bool:
    return authority!=null and is_instance_valid(authority) and not authority.is_authority() and authority.is_peer_authenticated(multiplayer.get_unique_id())

func _screen_to_map(screen_position:Vector2)->Vector2:
    var origin:=camera.project_ray_origin(screen_position)
    var direction:=camera.project_ray_normal(screen_position)
    if abs(direction.y)<0.00001: return Vector2.INF
    var distance:float=-origin.y/direction.y
    if distance<0.0: return Vector2.INF
    var point:=origin+direction*distance
    return CombatRules.snap_map_point(Vector2(point.x/WORLD_SCALE+ORIGIN_X,point.z/WORLD_SCALE+ORIGIN_Y))

func _map_to_world(map_position:Vector2)->Vector3:
    return Vector3((map_position.x-ORIGIN_X)*WORLD_SCALE,0.0,(map_position.y-ORIGIN_Y)*WORLD_SCALE)

func _clamp_to_map(point:Vector2,hero:Dictionary)->Vector2:
    var map_data:Dictionary=TeleportSystem.MAPS.get(int(hero.get("map_id",0)),{})
    var max_x:float=ORIGIN_X+float(map_data.get("width",1200))-1.0
    var max_y:float=ORIGIN_Y+float(map_data.get("height",700))-1.0
    return Vector2(clamp(point.x,ORIGIN_X,max_x),clamp(point.y,ORIGIN_Y,max_y))

func _ui_has_focus()->bool:
    var focus:Control=get_viewport().gui_get_focus_owner() as Control
    return focus!=null and focus.visible and focus.is_inside_tree()
