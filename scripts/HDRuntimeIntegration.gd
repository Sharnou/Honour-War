class_name HDRuntimeIntegration
extends Node

@export var camera_director_path: NodePath
@export var pet_director_path: NodePath
@export var combat_feedback_path: NodePath
@export var target_path: NodePath
@export var owner_path: NodePath

var camera_director: Node
var pet_director: Node
var combat_feedback: Node

func _ready() -> void:
    camera_director = get_node_or_null(camera_director_path)
    pet_director = get_node_or_null(pet_director_path)
    combat_feedback = get_node_or_null(combat_feedback_path)
    _configure_camera()
    _configure_pet()

func _configure_camera() -> void:
    if camera_director == null:
        return
    var camera := get_viewport().get_camera_3d()
    if camera and camera_director.has_method("set_camera"):
        camera_director.set_camera(camera)
    if target_path != NodePath() and camera_director.has_method("set_target"):
        var target := get_node_or_null(target_path)
        if target:
            camera_director.set_target(target)

func _configure_pet() -> void:
    if pet_director == null:
        return
    if owner_path != NodePath() and pet_director.has_method("set_owner_node"):
        var owner := get_node_or_null(owner_path)
        if owner:
            pet_director.set_owner_node(owner)
    if target_path != NodePath() and pet_director.has_method("set_target_node"):
        var target := get_node_or_null(target_path)
        if target:
            pet_director.set_target_node(target)

func emit_damage(amount: int, world_position: Vector3, critical: bool = false) -> void:
    if combat_feedback and combat_feedback.has_method("emit_damage"):
        combat_feedback.emit_damage(amount, world_position, critical)

func emit_telegraph(world_position: Vector3, radius: float, duration: float) -> void:
    if combat_feedback and combat_feedback.has_method("emit_telegraph"):
        combat_feedback.emit_telegraph(world_position, radius, duration)

func emit_skill(skill_id: String, world_position: Vector3) -> void:
    if combat_feedback and combat_feedback.has_method("emit_skill"):
        combat_feedback.emit_skill(skill_id, world_position)
