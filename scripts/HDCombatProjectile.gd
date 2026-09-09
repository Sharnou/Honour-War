class_name HDCombatProjectile
extends Node3D

@export var speed:float = 22.0
@export var lifetime:float = 1.0
var target:Node3D
var damage:int = 0

func setup(target_node:Node3D, amount:int)->void:
    target = target_node
    damage = amount

func _process(delta:float)->void:
    lifetime -= delta
    if lifetime <= 0.0 or not is_instance_valid(target):
        queue_free()
        return
    global_position = global_position.move_toward(target.global_position + Vector3.UP * 1.0, speed * delta)
    look_at(target.global_position + Vector3.UP * 1.0, Vector3.UP)
    if global_position.distance_to(target.global_position + Vector3.UP * 1.0) < 0.25:
        queue_free()
