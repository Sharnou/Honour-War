class_name HDPetCombatDirector
extends Node3D

signal pet_state_changed(pet: Node, state: String)

const STATES := ["Follow", "Assist", "Defend", "Aggressive", "Hold", "Return"]
@export var follow_distance := 2.5
@export var follow_smoothing := 5.0
var pet_state := "Follow"
var owner_node: Node3D

func set_owner_node(value: Node3D) -> void:
    owner_node = value

func set_pet_state(value: String) -> void:
    if not STATES.has(value):
        return
    pet_state = value
    pet_state_changed.emit(self, pet_state)

func _process(delta: float) -> void:
    if not owner_node or pet_state == "Hold":
        return
    if pet_state == "Return" or pet_state == "Follow":
        var destination := owner_node.global_position - owner_node.global_transform.basis.z * follow_distance
        global_position = global_position.lerp(destination, clamp(delta * follow_smoothing, 0.0, 1.0))
