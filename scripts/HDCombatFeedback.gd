class_name HDCombatFeedback
extends Node

signal damage_number_requested(amount: int, world_position: Vector3, critical: bool)
signal telegraph_requested(shape: String, world_position: Vector3, radius: float, duration: float)
signal skill_effect_requested(effect_id: String, world_position: Vector3)

func show_damage(amount: int, world_position: Vector3, critical: bool = false) -> void:
    if amount <= 0:
        return
    damage_number_requested.emit(amount, world_position, critical)

func show_telegraph(shape: String, world_position: Vector3, radius: float, duration: float = 0.8) -> void:
    if radius <= 0.0 or duration <= 0.0:
        return
    telegraph_requested.emit(shape, world_position, radius, duration)

func play_skill_effect(effect_id: String, world_position: Vector3) -> void:
    if effect_id.is_empty():
        return
    skill_effect_requested.emit(effect_id, world_position)
