class_name HDPetCombatDirector
extends Node3D

signal pet_state_changed(pet: Node, state: String)
signal pet_command_requested(state: String)

const STATES := ["Follow", "Assist", "Defend", "Aggressive", "Hold", "Return"]
@export var follow_distance := 2.5
@export var follow_smoothing := 5.0
@export var leash_distance := 9.0
@export var combat_distance := 3.0

var pet_state := "Follow"
var owner_node: Node3D
var target_node: Node3D

func set_owner_node(value: Node3D) -> void:
    owner_node = value

func set_target_node(value: Node3D) -> void:
    target_node = value

func set_pet_state(value: String) -> void:
    if not STATES.has(value):
        return
    pet_state = value
    pet_state_changed.emit(self, pet_state)
    pet_command_requested.emit(pet_state)

func command_follow() -> void:
    set_pet_state("Follow")

func command_assist() -> void:
    set_pet_state("Assist")

func command_defend() -> void:
    set_pet_state("Defend")

func command_aggressive() -> void:
    set_pet_state("Aggressive")

func command_hold() -> void:
    set_pet_state("Hold")

func command_return() -> void:
    set_pet_state("Return")

func _process(delta: float) -> void:
    if not owner_node or not is_instance_valid(owner_node):
        return
    if pet_state == "Hold":
        return
    if pet_state == "Aggressive" and target_node and is_instance_valid(target_node):
        _move_toward_target(delta)
        return
    if pet_state == "Assist" and target_node and is_instance_valid(target_node):
        var assist_destination := target_node.global_position - target_node.global_transform.basis.z * combat_distance
        global_position = global_position.lerp(assist_destination, clamp(delta * follow_smoothing, 0.0, 1.0))
        return
    _follow_owner(delta)

func _follow_owner(delta: float) -> void:
    var distance := global_position.distance_to(owner_node.global_position)
    var effective_distance := follow_distance
    if pet_state == "Return" or distance > leash_distance:
        effective_distance = 1.6
    var destination := owner_node.global_position - owner_node.global_transform.basis.z * effective_distance
    global_position = global_position.lerp(destination, clamp(delta * follow_smoothing, 0.0, 1.0))

func _move_toward_target(delta: float) -> void:
    var destination := target_node.global_position - target_node.global_transform.basis.z * combat_distance
    global_position = global_position.lerp(destination, clamp(delta * follow_smoothing * 1.25, 0.0, 1.0))
