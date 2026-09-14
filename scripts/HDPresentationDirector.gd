class_name HDPresentationDirector
extends Node3D

@export var camera_path:NodePath
@export var target_path:NodePath
@export var camera_fov:float=58.0

var _camera:Camera3D
var _target:Node3D

func set_camera(value:Camera3D)->void:
    _camera=value
    if _camera:
        # HWIsometricCamera owns projection, zoom, yaw and pitch. Do not reset
        # those values here or it would fight the interactive camera controller.
        var camera_script:Object=_camera.get_script()
        var is_isometric:bool=camera_script != null and camera_script.resource_path.ends_with("HWIsometricCamera.gd")
        if not is_isometric:
            _camera.projection=Camera3D.PROJECTION_PERSPECTIVE
            _camera.fov=camera_fov
        _camera.near=0.08
        _camera.far=500.0
        _camera.current=true

func set_target(value:Node3D)->void:
    _target=value

func _ready()->void:
    var resolved_camera:=get_node_or_null(camera_path) as Camera3D
    if resolved_camera: set_camera(resolved_camera)
    var resolved_target:=get_node_or_null(target_path) as Node3D
    if resolved_target: set_target(resolved_target)

func _process(_delta:float)->void:
    # Camera position/orientation belongs exclusively to HWIsometricCamera.
    return
