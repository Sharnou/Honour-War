class_name MovementStabilityFix
extends Node

@export var legacy_path:NodePath = NodePath("../LegacyGame")
@export var camera_path:NodePath = NodePath("../Camera3D")
const ORIGIN_X:float = 365.0
const ORIGIN_Y:float = 120.0
const WORLD_SCALE:float = 0.055
const MOVE_SPEED:float = 210.0
const STOP_DISTANCE:float = 1.5
const CAMERA_DISTANCE:float = 18.5
const CAMERA_YAW_SPEED:float = 1.65
const CAMERA_PITCH_SPEED:float = 0.95
const CAMERA_PITCH_MIN:float = -56.0
const CAMERA_PITCH_MAX:float = -28.0
const CAMERA_POSITION_TARGET:Vector3 = Vector3(12.925,0.0,12.65)

var legacy:Node2D
var camera:Camera3D
var destination:Vector2 = Vector2.INF
var marker:MeshInstance3D
var selected_monster:Dictionary = {}
var camera_yaw:float = 0.0
var camera_pitch:float = -38.0
var middle_dragging:bool = false
var last_mouse:Vector2 = Vector2.ZERO

func _ready() -> void:
    process_priority = 1000
    legacy = get_node_or_null(legacy_path) as Node2D
    camera = get_node_or_null(camera_path) as Camera3D
    set_process_unhandled_input(true)
    call_deferred("_setup_camera")
    call_deferred("_setup_marker")
    call_deferred("_ensure_visual_safety")
    call_deferred("_ensure_visual_safety")

func _setup_camera() -> void:
    if camera == null or not camera.is_inside_tree(): return
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 16.0
    camera.near = 0.05
    camera.far = 500.0
    camera.current = true
    _apply_camera()

func _apply_camera() -> void:
    if camera == null: return
    var target:Vector3 = CAMERA_POSITION_TARGET
    var pitch:float = deg_to_rad(camera_pitch)
    var yaw:float = deg_to_rad(camera_yaw)
    var offset:Vector3 = Vector3(sin(yaw)*cos(pitch),-sin(pitch),cos(yaw)*cos(pitch))*CAMERA_DISTANCE
    camera.global_position = target+offset
    camera.look_at(target,Vector3.UP)
    camera.current = true

func _ensure_visual_safety() -> void:
    var root:Node = get_parent()
    if root == null or not root is Node3D: return
    var root_3d:Node3D = root as Node3D
    if root_3d.get_node_or_null("HDVisualSafetyStage") != null: return
    var stage:Node3D = Node3D.new()
    stage.name = "HDVisualSafetyStage"
    root_3d.add_child(stage)

    var environment:WorldEnvironment = WorldEnvironment.new()
    environment.name = "SafetyEnvironment"
    var env:Environment = Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color("#081521")
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color("#d8e5ef")
    env.ambient_light_energy = 0.9
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    environment.environment = env
    stage.add_child(environment)

    var sun:DirectionalLight3D = DirectionalLight3D.new()
    sun.name = "SafetySun"
    sun.rotation_degrees = Vector3(-52.0,-32.0,0.0)
    sun.light_energy = 1.8
    sun.shadow_enabled = true
    stage.add_child(sun)

    var floor:MeshInstance3D = MeshInstance3D.new()
    floor.name = "SafetyFloor"
    var floor_mesh:BoxMesh = BoxMesh.new()
    floor_mesh.size = Vector3(70.0,0.25,43.0)
    floor.mesh = floor_mesh
    floor.position = CAMERA_POSITION_TARGET + Vector3(0.0,-0.18,0.0)
    floor.material_override = _safety_material(Color("#294734"),0.9)
    stage.add_child(floor)

    var road:MeshInstance3D = MeshInstance3D.new()
    road.name = "SafetyRoad"
    var road_mesh:BoxMesh = BoxMesh.new()
    road_mesh.size = Vector3(9.0,0.10,43.0)
    road.mesh = road_mesh
    road.position = CAMERA_POSITION_TARGET + Vector3(0.0,-0.02,0.0)
    road.material_override = _safety_material(Color("#655141"),1.0)
    stage.add_child(road)

    _safety_building(stage,Vector3(6.0,2.0,5.0),Color("#a87859"),Color("#713d38"))
    _safety_building(stage,Vector3(20.0,2.0,5.0),Color("#7d6b58"),Color("#41405a"))
    _safety_building(stage,Vector3(6.0,2.0,20.0),Color("#96694f"),Color("#583b35"))
    _safety_building(stage,Vector3(20.0,2.0,20.0),Color("#65735e"),Color("#394d3e"))

    var tree_positions:Array[Vector3] = [Vector3(-4.0,1.5,3.0),Vector3(30.0,1.5,2.0),Vector3(-5.0,1.5,24.0),Vector3(30.0,1.5,23.0)]
    for p in tree_positions:
        var trunk:MeshInstance3D = MeshInstance3D.new()
        var trunk_mesh:CylinderMesh = CylinderMesh.new()
        trunk_mesh.top_radius = 0.18
        trunk_mesh.bottom_radius = 0.32
        trunk_mesh.height = 2.4
        trunk.mesh = trunk_mesh
        trunk.position = p
        trunk.material_override = _safety_material(Color("#51382b"),1.0)
        stage.add_child(trunk)
        var crown:MeshInstance3D = MeshInstance3D.new()
        var crown_mesh:SphereMesh = SphereMesh.new()
        crown_mesh.radius = 1.3
        crown_mesh.height = 2.6
        crown.mesh = crown_mesh
        crown.position = p + Vector3(0.0,1.8,0.0)
        crown.material_override = _safety_material(Color("#2f6b45"),0.92)
        stage.add_child(crown)

func _safety_building(parent:Node3D,pos:Vector3,wall:Color,roof:Color) -> void:
    var body:MeshInstance3D = MeshInstance3D.new()
    var body_mesh:BoxMesh = BoxMesh.new()
    body_mesh.size = Vector3(5.5,4.0,4.5)
    body.mesh = body_mesh
    body.position = pos
    body.material_override = _safety_material(wall,0.82)
    parent.add_child(body)
    var top:MeshInstance3D = MeshInstance3D.new()
    var roof_mesh:CylinderMesh = CylinderMesh.new()
    roof_mesh.top_radius = 0.0
    roof_mesh.bottom_radius = 3.7
    roof_mesh.height = 2.2
    top.mesh = roof_mesh
    top.position = pos + Vector3(0.0,3.0,0.0)
    top.material_override = _safety_material(roof,0.9)
    parent.add_child(top)

func _safety_material(color:Color,roughness:float) -> StandardMaterial3D:
    var material:StandardMaterial3D = StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = roughness
    return material

func _setup_marker() -> void:
    if marker != null or get_parent() == null: return
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
    if event is InputEventMouseButton:
        if event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
            if not _ui_has_focus(): _handle_world_click(event.position)
        elif event.button_index==MOUSE_BUTTON_MIDDLE:
            middle_dragging=event.pressed
            last_mouse=event.position
        elif event.button_index==MOUSE_BUTTON_RIGHT and event.pressed:
            selected_monster={}
            destination=Vector2.INF
    elif event is InputEventMouseMotion and middle_dragging:
        var delta:Vector2=event.position-last_mouse
        last_mouse=event.position
        camera_yaw-=delta.x*0.45
        camera_pitch=clamp(camera_pitch-delta.y*0.18,CAMERA_PITCH_MIN,CAMERA_PITCH_MAX)
    elif event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE:
        destination=Vector2.INF
        selected_monster={}

func _handle_world_click(screen_position:Vector2)->void:
    var clicked:=_pick_monster(screen_position)
    if not clicked.is_empty():
        selected_monster=clicked
        var hero_value:Variant=legacy.get("hero") if legacy else null
        if not hero_value is Dictionary: return
        var hero:Dictionary=hero_value
        var hero_pos:=Vector2(float(hero.get("pos_x",595.0)),float(hero.get("pos_y",340.0)))
        var monster_pos:Vector2=clicked.get("pos",hero_pos)
        var distance:=hero_pos.distance_to(monster_pos)
        var desired:=CombatRules.class_engagement_map(hero)
        if distance<=desired:
            destination=Vector2.INF
        else:
            var direction:=monster_pos.direction_to(hero_pos)
            destination=CombatRules.snap_map_point(monster_pos+direction*desired)
        return
    var map_point:Vector2=_screen_to_map(screen_position)
    if map_point!=Vector2.INF:
        selected_monster={}
        destination=CombatRules.snap_map_point(map_point)

func _pick_monster(screen_position:Vector2)->Dictionary:
    if legacy==null or camera==null: return {}
    var monsters_value:Variant=legacy.get("monsters")
    if not monsters_value is Array: return {}
    var best:Dictionary={}
    var best_distance:float=58.0
    for item in monsters_value as Array:
        if not item is Dictionary: continue
        var monster:Dictionary=item
        if int(monster.get("hp",0))<=0: continue
        var p:Variant=monster.get("pos",Vector2.ZERO)
        if not p is Vector2: continue
        var screen:Vector2=camera.unproject_position(_map_to_world(p as Vector2)+Vector3(0.0,1.0,0.0))
        var distance:float=screen.distance_to(screen_position)
        if distance<best_distance:
            best_distance=distance
            best=monster
    return best

func _process(delta:float)->void:
    if legacy==null or camera==null or not camera.is_inside_tree(): return
    _update_camera_input(delta)
    _apply_camera()
    var hero_value:Variant=legacy.get("hero")
    if not hero_value is Dictionary: return
    var hero:Dictionary=hero_value
    var current:Vector2=Vector2(float(hero.get("pos_x",595.0)),float(hero.get("pos_y",340.0)))
    if destination!=Vector2.INF:
        var distance:float=current.distance_to(destination)
        if distance<=STOP_DISTANCE:
            current=destination
            destination=Vector2.INF
        else:
            current+=current.direction_to(destination)*min(distance,MOVE_SPEED*delta)
    current=_clamp_to_map(current,hero)
    hero["pos_x"]=current.x
    hero["pos_y"]=current.y
    if marker!=null:
        marker.visible=destination!=Vector2.INF
        if marker.visible: marker.position=_map_to_world(destination)+Vector3(0.0,0.06,0.0)

func _update_camera_input(delta:float)->void:
    # WASD is camera-only. It never changes hero.pos_x/pos_y.
    var yaw_axis:float=0.0
    var pitch_axis:float=0.0
    if Input.is_key_pressed(KEY_A): yaw_axis-=1.0
    if Input.is_key_pressed(KEY_D): yaw_axis+=1.0
    if Input.is_key_pressed(KEY_W): pitch_axis+=1.0
    if Input.is_key_pressed(KEY_S): pitch_axis-=1.0
    camera_yaw+=yaw_axis*CAMERA_YAW_SPEED*delta*57.2958
    camera_pitch=clamp(camera_pitch+pitch_axis*CAMERA_PITCH_SPEED*delta*57.2958,CAMERA_PITCH_MIN,CAMERA_PITCH_MAX)

func _screen_to_map(screen_position:Vector2)->Vector2:
    var origin:Vector3=camera.project_ray_origin(screen_position)
    var direction:Vector3=camera.project_ray_normal(screen_position)
    if abs(direction.y)<0.00001: return Vector2.INF
    var distance:float=-origin.y/direction.y
    if distance<0.0: return Vector2.INF
    var point:Vector3=origin+direction*distance
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
