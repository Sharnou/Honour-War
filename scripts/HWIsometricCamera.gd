extends Node3D

## Honour War classic isometric/2.5D camera.
## The camera is orthographic, fixed-angle, and smoothly tracks the active hero.

@export_group("Target Tracking")
@export var target:Node3D
@export_range(0.01, 1.0, 0.01) var smoothness:float = 0.12

@export_group("Classic Camera Angle")
@export_range(0.0, 90.0, 0.5) var pitch_angle:float = 35.0
@export_range(0.0, 360.0, 0.5) var yaw_angle:float = 45.0

@export_group("Position Tuning")
@export var target_offset:Vector3 = Vector3(0.0, 0.0, 0.0)
@export_range(4.0, 20.0, 0.1) var orthographic_size:float = 10.0

var camera:Camera3D
var timer:float = 0.0

func _ready()->void:
    camera = get_node_or_null("Camera3D") as Camera3D
    if camera == null:
        camera = Camera3D.new()
        camera.name = "Camera3D"
        add_child(camera)
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = orthographic_size
    camera.current = true
    camera.near = 0.08
    camera.far = 500.0
    rotation_degrees = Vector3(-pitch_angle, yaw_angle, 0.0)
    _resolve_target()
    if target != null:
        global_position = target.global_position + target_offset

func _physics_process(_delta:float)->void:
    if target == null or not is_instance_valid(target):
        _resolve_target()
    if target == null:
        return
    var destination:Vector3 = target.global_position + target_offset
    global_position = global_position.lerp(destination, smoothness)
    rotation_degrees = Vector3(-pitch_angle, yaw_angle, 0.0)

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
        if result.size() > 0:
            return
