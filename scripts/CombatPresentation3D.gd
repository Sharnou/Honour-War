class_name CombatPresentation3D
extends Node

## Presentation layer for authored and procedural combat animation integration.
## It never owns gameplay authority; it only reacts to combat events.

var actor_states: Dictionary = {}
var event_history: Array[Dictionary] = []
const MAX_HISTORY := 32

func register_actor(actor_id: String, actor: Node3D) -> void:
    if actor == null:
        return
    actor_states[actor_id] = {
        "actor": actor,
        "state": "idle",
        "state_time": 0.0,
        "hit_flash": 0.0,
        "stun_time": 0.0,
        "knockback_velocity": Vector3.ZERO,
        "death_time": 0.0
    }

func unregister_actor(actor_id: String) -> void:
    actor_states.erase(actor_id)

func play(actor_id: String, state: String, duration: float = 0.0, knockback: Vector3 = Vector3.ZERO) -> void:
    if not actor_states.has(actor_id):
        return
    var data: Dictionary = actor_states[actor_id]
    data["state"] = state
    data["state_time"] = max(duration, 0.0)
    if state == "hit" or state == "stagger":
        data["hit_flash"] = 0.12
        data["stun_time"] = max(duration, 0.08)
    if state == "knockback":
        data["knockback_velocity"] = knockback
        data["stun_time"] = max(duration, 0.18)
    if state == "death":
        data["death_time"] = max(duration, 0.8)
    actor_states[actor_id] = data
    event_history.push_back({"actor": actor_id, "state": state})
    if event_history.size() > MAX_HISTORY:
        event_history.pop_front()
    _try_authored_animation(data["actor"], state)

func _try_authored_animation(actor: Node3D, state: String) -> void:
    if actor == null:
        return
    var tree := actor.get_node_or_null("AnimationTree")
    if tree != null and tree.has_method("get"):
        var playback = tree.get("parameters/playback")
        if playback != null and playback.has_method("travel"):
            playback.travel(state)
            return
    var player := actor.get_node_or_null("AnimationPlayer")
    if player != null and player.has_method("has_animation") and player.has_animation(state):
        player.play(state)

func _process(delta: float) -> void:
    for actor_id in actor_states.keys():
        var data: Dictionary = actor_states[actor_id]
        var actor: Node3D = data["actor"]
        if actor == null or not is_instance_valid(actor):
            continue
        data["state_time"] = max(float(data["state_time"]) - delta, 0.0)
        data["hit_flash"] = max(float(data["hit_flash"]) - delta, 0.0)
        data["stun_time"] = max(float(data["stun_time"]) - delta, 0.0)
        data["death_time"] = max(float(data["death_time"]) - delta, 0.0)
        var impulse: Vector3 = data["knockback_velocity"]
        if impulse.length() > 0.01 and float(data["stun_time"]) > 0.0:
            actor.position += impulse * delta
            data["knockback_velocity"] = impulse.move_toward(Vector3.ZERO, delta * 8.0)
        if float(data["state_time"]) <= 0.0 and data["state"] != "death":
            data["state"] = "idle"
        actor_states[actor_id] = data
