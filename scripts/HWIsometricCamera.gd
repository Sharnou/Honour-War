extends Node3D

## Honour War classic isometric/2.5D camera.
## Adds smooth mouse-wheel zoom and 90-degree stepped keyboard rotation while
## preserving the existing Camera3D node and legacy camera references.

@export_group("Target Tracking")
@export var target:Node3D
@export_range(0.01, 1.0, 0.01) var smoothness:float = 0.12

@export_group("Classic Camera Angle")
@export_range(0.0, 90.0, 0.5) var pitch_angle:float = 35.0
@export_range(0.0, 360.0, 0.5) var yaw_angle:float = 45.0
@export_range(1.0, 90.0, 1.0) var rotation_step_degrees:float = 90.0

@export_group("Position Tuning")
@export var target_offset:Vector3 = Vector3(0.0, 0.0, 0.0)
@export_range(4.0, 20.0, 0.1) var orthographic_size:float = 10.0
@export_range(4.0, 20.0, 0.1) var min_zoom:float = 5.0
@export_range(4.0, 24.0, 0.1) var max_zoom:float = 15.0
@export_range(0.1, 5.0, 0.1) var zoom_step:float = 1.25
@export_range(0.01, 1.0, 0.01) var zoom_smoothness:float = 0.18
@export_range(0.01, 1.0, 0.01) var rotation_smoothness:float = 0.16

var camera:Camera3D
var target_zoom:float = 10.0
var target_yaw_radians:float = 0.0
var _yaw_radians:float = 0.0

func _ready()->void:
    # This script extends Node3D, so self can never be safely cast to Camera3D.
    # Always use the authored child camera when present; create one only as a fallback.
    camera = get_node_or_null("Camera3D") as Camera3D
    if camera == null:
        camera = Camera3D.new()
        camera.name = "Camera3D"
        add_child(camera)
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    target_zoom = clamp(orthographic_size, min_zoom, max_zoom)
    camera.size = target_zoom
    camera.current = true
    camera.near = 0.08
    camera.far = 500.0
    _yaw_radians = deg_to_rad(yaw_angle)
    target_yaw_radians = _yaw_radians
    rotation_degrees = Vector3(-pitch_angle, rad_to_deg(_yaw_radians), 0.0)
    _resolve_target()
    if target != null:
        global_position = target.global_position + target_offset

func _unhandled_input(event:InputEvent)->void:
    if event is InputEventMouseButton:
        var mouse_event:InputEventMouseButton = event as InputEventMouseButton
        if mouse_event.pressed:
            if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
                target_zoom = clamp(target_zoom - zoom_step, min_zoom, max_zoom)
            elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
                target_zoom = clamp(target_zoom + zoom_step, min_zoom, max_zoom)
    elif event.is_action_pressed("camera_rotate_left"):
        _rotate_camera(-rotation_step_degrees)
    elif event.is_action_pressed("camera_rotate_right"):
        _rotate_camera(rotation_step_degrees)

func _rotate_camera(degrees_delta:float)->void:
    target_yaw_radians = fposmod(target_yaw_radians + deg_to_rad(degrees_delta), TAU)

func _physics_process(_delta:float)->void:
    if target == null or not is_instance_valid(target):
        _resolve_target()
    if target != null:
        var destination:Vector3 = target.global_position + target_offset
        global_position = global_position.lerp(destination, smoothness)
    if camera != null:
        camera.size = lerp(camera.size, target_zoom, zoom_smoothness)
    _yaw_radians = lerp_angle(_yaw_radians, target_yaw_radians, rotation_smoothness)
    rotation_degrees = Vector3(-pitch_angle, rad_to_deg(_yaw_radians), 0.0)

func _resolve_target()->void:
    var scene:Node = get_tree().current_scene
    if scene == null:
        return
    var candidates:Array[Node] = []
    _collect_hero_candidates(scene, candidates)
    if candidates.size() > 0:
        target = candidates[0] as Node3D
        return
    var hero:Node = scene.find_child("Hero", true, false)
    if hero is Node3D:
        target = hero as Node3D

func _collect_hero_candidates(node:Node, result:Array[Node])->void:
    if result.size() > 0:
        return
    if node is Node3D:
        var node_name:String = node.name.to_lower()
        if node_name == "hero" or node_name.contains("player"):
            result.append(node)
            return
    for child in node.get_children():
        _collect_hero_candidates(child, result)
