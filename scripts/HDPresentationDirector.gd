class_name HDPresentationDirector
extends Node3D

@export var camera_path: NodePath
@export var target_path: NodePath
@export var camera_height := 13.5
@export var camera_distance := 17.5
@export var camera_smoothing := 6.0
@export var orthographic_size := 16.0
@export var look_ahead := 1.2

var _camera: Camera3D
var _target: Node3D

func set_camera(value: Camera3D) -> void:
    _camera = value
    if _camera:
        _camera.projection = Camera3D.PROJECTION_ORTHOGONAL
        _camera.size = orthographic_size
        _camera.current = true

func set_target(value: Node3D) -> void:
    _target = value

func _ready() -> void:
    var resolved_camera := get_node_or_null(camera_path) as Camera3D
    if resolved_camera:
        set_camera(resolved_camera)
    var resolved_target := get_node_or_null(target_path) as Node3D
    if resolved_target:
        set_target(resolved_target)

func _process(delta: float) -> void:
    if not _camera or not is_instance_valid(_camera) or not _target or not is_instance_valid(_target):
        return
    var forward := -_target.global_transform.basis.z
    var desired := _target.global_position + Vector3(0.0, camera_height, camera_distance) + forward * look_ahead
    var blend := clamp(1.0 - exp(-camera_smoothing * max(delta, 0.001)), 0.0, 1.0)
    _camera.global_position = _camera.global_position.lerp(desired, blend)
    _camera.look_at(_target.global_position + forward * look_ahead, Vector3.UP)
