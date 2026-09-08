class_name HDPetCombatDirector
extends Node3D

signal pet_state_changed(pet: Node, state: String)
signal pet_command_requested(state: String)
signal pet_role_changed(role: String)
signal pet_target_changed(target: Node3D)

const STATES:Array[String] = ["Follow", "Assist", "Defend", "Aggressive", "Hold", "Return"]
const ROLES:Array[String] = ["Guardian", "DPS", "Ranged", "Support", "Hybrid"]

@export var follow_distance:float = 2.5
@export var follow_smoothing:float = 5.0
@export var leash_distance:float = 9.0
@export var combat_distance:float = 3.0
@export var decision_interval:float = 0.65

var pet_state:String = "Follow"
var pet_role:String = "Hybrid"
var owner_node:Node3D
var pet_visual:Node3D
var target_node:Node3D
var _base_scale:=Vector3.ONE
var _decision_timer:float=0.0
var _last_hp:int=-1
var _last_target_position:=Vector3.ZERO

func set_owner_node(value:Node3D)->void:
    owner_node=value

func set_pet_visual(value:Node3D)->void:
    pet_visual=value
    if pet_visual and is_instance_valid(pet_visual):
        _base_scale=pet_visual.scale

func set_target_node(value:Node3D)->void:
    if target_node==value: return
    target_node=value
    pet_target_changed.emit(target_node)

func set_pet_state(value:String)->void:
    if not STATES.has(value): return
    pet_state=value
    pet_state_changed.emit(self,pet_state)
    pet_command_requested.emit(pet_state)

func set_pet_role(value:String)->void:
    if not ROLES.has(value): return
    if pet_role==value: return
    pet_role=value
    pet_role_changed.emit(pet_role)

func configure_role_from_pet(pet:Dictionary)->void:
    var species:String=str(pet.get("species","Wolf Cub"))
    var configured:String=str(pet.get("role",""))
    if ROLES.has(configured):
        set_pet_role(configured)
        return
    match species:
        "Wolf": set_pet_role("DPS")
        "Dragon": set_pet_role("Ranged")
        "Falcon": set_pet_role("Ranged")
        "Wolf Cub": set_pet_role("Support")
        _: set_pet_role("Hybrid")

func command_follow()->void: set_pet_state("Follow")
func command_assist()->void: set_pet_state("Assist")
func command_defend()->void: set_pet_state("Defend")
func command_aggressive()->void: set_pet_state("Aggressive")
func command_hold()->void: set_pet_state("Hold")
func command_return()->void: set_pet_state("Return")

func _process(delta:float)->void:
    if not owner_node or not is_instance_valid(owner_node): return
    if not pet_visual or not is_instance_valid(pet_visual): return
    _decision_timer+=delta
    if _decision_timer>=decision_interval:
        _decision_timer=0.0
        _combat_decision()
    if pet_state=="Hold": return
    if pet_state=="Aggressive" and target_node and is_instance_valid(target_node):
        _move_toward_target(delta)
        return
    if pet_state=="Assist" and target_node and is_instance_valid(target_node):
        var assist_destination:=target_node.global_position-target_node.global_transform.basis.z*combat_distance
        pet_visual.global_position=pet_visual.global_position.lerp(assist_destination,clamp(delta*follow_smoothing,0.0,1.0))
        return
    if pet_state=="Defend":
        _defend_owner(delta)
        return
    _follow_owner(delta)

func _combat_decision()->void:
    var legacy:Node=owner_node.get_parent().get_node_or_null("LegacyGame") if owner_node.get_parent() else null
    if legacy==null: return
    var hero_value:Variant=legacy.get("hero")
    if not hero_value is Dictionary: return
    var pet_value:Variant=hero_value.get("pet",{})
    if pet_value is Dictionary:
        configure_role_from_pet(pet_value)
        _last_hp=int(pet_value.get("hp",0))
    if pet_state=="Defend" or pet_state=="Return":
        if target_node and _distance_to_owner(target_node)>leash_distance*1.5:
            set_target_node(null)
        return
    if target_node==null or not is_instance_valid(target_node):
        return
    _last_target_position=target_node.global_position

func _defend_owner(delta:float)->void:
    var anchor:=owner_node.global_position
    var destination:=anchor-owner_node.global_transform.basis.z*1.8
    if target_node and is_instance_valid(target_node) and pet_role=="Guardian":
        destination=target_node.global_position-target_node.global_transform.basis.z*2.4
    pet_visual.global_position=pet_visual.global_position.lerp(destination,clamp(delta*follow_smoothing,0.0,1.0))

func _follow_owner(delta:float)->void:
    var distance:=pet_visual.global_position.distance_to(owner_node.global_position)
    var effective_distance:=follow_distance
    if pet_state=="Return" or distance>leash_distance: effective_distance=1.6
    var destination:=owner_node.global_position-owner_node.global_transform.basis.z*effective_distance
    pet_visual.global_position=pet_visual.global_position.lerp(destination,clamp(delta*follow_smoothing,0.0,1.0))

func _move_toward_target(delta:float)->void:
    var distance:=combat_distance
    match pet_role:
        "Guardian": distance=2.4
        "DPS": distance=2.0
        "Ranged": distance=5.0
        "Support": distance=4.0
        _: distance=3.0
    var destination:=target_node.global_position-target_node.global_transform.basis.z*distance
    pet_visual.global_position=pet_visual.global_position.lerp(destination,clamp(delta*follow_smoothing*1.25,0.0,1.0))

func _distance_to_owner(node:Node3D)->float:
    if node==null or not is_instance_valid(node) or owner_node==null: return INF
    return node.global_position.distance_to(owner_node.global_position)
