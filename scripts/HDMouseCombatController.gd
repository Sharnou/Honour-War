class_name HDMouseCombatController
extends Node3D

## Ragnarok-style mouse interaction layer.
## MovementStabilityFix remains the single owner of the camera transform.

@export var camera_path:NodePath = NodePath("../Camera3D")
@export var legacy_game_path:NodePath = NodePath("../LegacyGame")
@export var attack_range:float = 2.4
@export var archer_range:float = 12.0
@export var move_speed:float = 6.0

var _camera:Camera3D
var _legacy:Node
var _destination:Vector3
var _has_destination:bool = false

func _ready()->void:
    _camera = get_node_or_null(camera_path) as Camera3D
    _legacy = get_node_or_null(legacy_game_path)
    set_process_input(true)

func _unhandled_input(event:InputEvent)->void:
    if not _camera or not is_instance_valid(_camera):
        return
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        if _ui_has_focus():
            return
        var mouse_event:=event as InputEventMouseButton
        var from:=_camera.project_ray_origin(mouse_event.position)
        var direction:=_camera.project_ray_normal(mouse_event.position)
        var hit:=Plane(Vector3.UP, 0.0).intersects_ray(from, direction)
        if hit != null:
            _destination = hit
            _has_destination = true

func _physics_process(delta:float)->void:
    if not _has_destination or not _legacy:
        return
    if not "hero" in _legacy:
        return
    var hero:Dictionary = _legacy.hero
    var current:=Vector2(float(hero.get("pos_x", 0.0)), float(hero.get("pos_y", 0.0)))
    var target:=Vector2(_destination.x, _destination.z)
    var distance:=current.distance_to(target)
    if distance <= 0.08:
        hero["pos_x"] = target.x
        hero["pos_y"] = target.y
        _has_destination = false
        return
    var step:=min(distance, move_speed * delta)
    var next:=current.move_toward(target, step)
    hero["pos_x"] = next.x
    hero["pos_y"] = next.y

func _ui_has_focus()->bool:
    var focus:=get_viewport().gui_get_focus_owner()
    return focus != null and focus is Control
