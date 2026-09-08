class_name HDCombatPresentation
extends Node

signal combat_text_requested(text: String, world_position: Vector3, critical: bool)
signal telegraph_requested(shape: String, world_position: Vector3, radius: float, duration: float)
signal skill_requested(effect_id: String, world_position: Vector3)

@export var feedback_path: NodePath
var feedback: Node

func _ready() -> void:
    feedback = get_node_or_null(feedback_path)
    if feedback == null:
        feedback = get_parent().get_node_or_null("HDCombatFeedback")
    if feedback and feedback.has_signal("damage_number_requested"):
        feedback.damage_number_requested.connect(_on_damage)
    if feedback and feedback.has_signal("telegraph_requested"):
        feedback.telegraph_requested.connect(_on_telegraph)
    if feedback and feedback.has_signal("skill_effect_requested"):
        feedback.skill_effect_requested.connect(_on_skill)

func _on_damage(amount: int, world_position: Vector3, critical: bool) -> void:
    var prefix := "CRITICAL " if critical else ""
    combat_text_requested.emit(prefix + str(amount), world_position, critical)

func _on_telegraph(shape: String, world_position: Vector3, radius: float, duration: float) -> void:
    telegraph_requested.emit(shape, world_position, radius, duration)

func _on_skill(effect_id: String, world_position: Vector3) -> void:
    skill_requested.emit(effect_id, world_position)
