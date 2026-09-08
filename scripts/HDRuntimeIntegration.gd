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
var _bound_actor: Node3D
var _bound_pet: Node3D
var _last_target:Variant = null

func _ready() -> void:
    camera_director = get_node_or_null(camera_director_path)
    pet_director = get_node_or_null(pet_director_path)
    combat_feedback = get_node_or_null(combat_feedback_path)
    _configure_camera()
    _configure_pet()

func _process(_delta: float) -> void:
    _resolve_runtime_actor()
    _resolve_runtime_pet()
    _resolve_combat_target()

func _resolve_runtime_actor() -> void:
    var actor: Node3D = null
    if target_path != NodePath():
        actor = get_node_or_null(target_path) as Node3D
    if actor == null and get_parent() != null:
        var candidate: Variant = get_parent().get("hero_visual")
        if candidate is Node3D:
            actor = candidate
    if actor == null or not is_instance_valid(actor):
        return
    if actor == _bound_actor:
        return
    _bound_actor = actor
    if camera_director and camera_director.has_method("set_target"):
        camera_director.set_target(actor)
    if pet_director and pet_director.has_method("set_owner_node"):
        pet_director.set_owner_node(actor)

func _resolve_runtime_pet() -> void:
    if pet_director == null or not pet_director.has_method("set_pet_visual"):
        return
    var candidate: Variant = get_parent().get("pet_visual") if get_parent() else null
    if candidate is Node3D and is_instance_valid(candidate):
        if candidate != _bound_pet:
            _bound_pet = candidate
            pet_director.set_pet_visual(candidate)

func _resolve_combat_target() -> void:
    var runtime:Node = get_parent()
    if runtime == null:
        return
    var legacy:Node = runtime.get_node_or_null("LegacyGame")
    var combat:Node = legacy.get_node_or_null("CombatRuntime") if legacy else null
    if combat == null:
        return
    var candidate:Variant = combat.get("target")
    if candidate == _last_target:
        return
    _last_target = candidate
    if pet_director and pet_director.has_method("set_target_node"):
        var target_visual:Node3D = _find_monster_visual(candidate)
        pet_director.set_target_node(target_visual)

func _find_monster_visual(target:Variant) -> Node3D:
    if not target is Dictionary:
        return null
    var visual_id:String = str(target.get("visual_id",target.get("name","monster")))
    var visuals:Variant = get_parent().get("monster_visuals")
    if visuals is Dictionary:
        var visual:Variant = visuals.get(visual_id)
        if visual is Node3D and is_instance_valid(visual):
            return visual
    return null

func _configure_camera() -> void:
    if camera_director == null:
        return
    var camera := get_viewport().get_camera_3d()
    if camera and camera_director.has_method("set_camera"):
        camera_director.set_camera(camera)

func _configure_pet() -> void:
    if pet_director == null:
        return
    if owner_path != NodePath() and pet_director.has_method("set_owner_node"):
        var owner := get_node_or_null(owner_path) as Node3D
        if owner:
            pet_director.set_owner_node(owner)

func emit_damage(amount: int, world_position: Vector3, critical: bool = false) -> void:
    if combat_feedback and combat_feedback.has_method("show_damage"):
        combat_feedback.show_damage(amount, world_position, critical)

func emit_telegraph(world_position: Vector3, radius: float, duration: float) -> void:
    if combat_feedback and combat_feedback.has_method("show_telegraph"):
        combat_feedback.show_telegraph("circle", world_position, radius, duration)

func emit_skill(skill_id: String, world_position: Vector3) -> void:
    if combat_feedback and combat_feedback.has_method("play_skill_effect"):
        combat_feedback.play_skill_effect(skill_id, world_position)
