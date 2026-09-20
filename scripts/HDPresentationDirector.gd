class_name HDPresentationDirector
extends Node3D

@export var camera_path:NodePath
@export var target_path:NodePath
@export var camera_fov:float=60.0
@export var preferred_distance:float=28.0
@export var preferred_pitch:float=-56.0
@export var world_compression:float=0.58

var _camera:Camera3D
var _target:Node3D
var _composition_applied:bool=false

func set_camera(value:Camera3D)->void:
    _camera=value
    if _camera:
        var camera_script:Script=_camera.get_script() as Script
        var is_isometric:bool=camera_script != null and camera_script.resource_path.ends_with("HWIsometricCamera.gd")
        if not is_isometric:
            _camera.projection=Camera3D.PROJECTION_PERSPECTIVE
            _camera.fov=camera_fov
        _camera.near=0.08
        _camera.far=700.0
        _camera.current=true

func set_target(value:Node3D)->void:
    _target=value

func _ready()->void:
    var resolved_camera:=get_node_or_null(camera_path) as Camera3D
    if resolved_camera:set_camera(resolved_camera)
    var resolved_target:=get_node_or_null(target_path) as Node3D
    if resolved_target:set_target(resolved_target)

func _process(_delta:float)->void:
    if _camera==null:return
    var movement:Node=get_parent().get_node_or_null("MovementStabilityFix")
    if movement!=null:
        movement.set("target_camera_distance",preferred_distance)
        movement.set("target_camera_pitch",preferred_pitch)
    if _composition_applied:return
    var detail:Node=get_parent().get_node_or_null("HWWorldDetailOverhaul")
    if detail==null:return
    var detail_root:Node3D=detail.get("root") as Node3D
    var center_value:Variant=detail.get("center")
    if detail_root==null or not center_value is Vector3:return
    var center:Vector3=center_value
    detail_root.scale=Vector3.ONE*world_compression
    detail_root.position=center*(1.0-world_compression)
    _composition_applied=true
