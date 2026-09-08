class_name HDPresentationDirector
extends Node3D

@export var camera_path: NodePath
@export var target_path: NodePath
@export var camera_height := 13.5
@export var camera_distance := 17.5
@export var camera_smoothing := 6.0
@export var orthographic_size := 16.0

var _camera: Camera3D
var _target: Node3D

func _ready() -> void:
    _camera = get_node_or_null(camera_path) as Camera3D
    _target = get_node_or_null(target_path) as Node3D
    if _camera:
        _camera.projection = Camera3D.PROJECTION_ORTHOGONAL
        _camera.size = orthographic_size
        _camera.current = true

func _process(delta: float) -> void:
    if not _camera or not _target:
        return
    var desired := _target.global_position + Vector3(0.0, camera_height, camera_distance)
    _camera.global_position = _camera.global_position.lerp(desired, clamp(delta * camera_smoothing, 0.0, 1.0))
    _camera.look_at(_target.global_position, Vector3.UP)
