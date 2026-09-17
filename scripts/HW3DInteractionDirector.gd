extends Node

## Runtime interaction bridge for procedural 3D actors.
## Adds valid Area3D ray-pick targets because CollisionShape3D cannot be a direct
## child of a plain Node3D. This keeps right-click Equip usable without changing
## the visual hierarchy or gameplay state.

var scanned: Dictionary = {}
var scan_elapsed:float = 0.0
const SCAN_INTERVAL_SECONDS:float = 0.75

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("_scan")

func _process(delta:float) -> void:
    scan_elapsed += max(0.0,delta)
    if scan_elapsed >= SCAN_INTERVAL_SECONDS:
        scan_elapsed = 0.0
        _scan()

func _scan() -> void:
    var scene:Node = get_tree().current_scene
    if scene == null:
        return
    for actor in get_tree().get_nodes_in_group("player"):
        _add_pick_area(actor, 0.9, 2.8)
    for actor in get_tree().get_nodes_in_group("remote_player"):
        _add_pick_area(actor, 0.9, 2.8)
    for actor in get_tree().get_nodes_in_group("enemy"):
        _add_pick_area(actor, 0.75, 2.2)
    for actor in scene.find_children("*", "Node3D", true, false):
        if actor.has_meta("hw_player") or actor.has_meta("hw_remote_player") or actor.has_meta("hw_enemy"):
            _add_pick_area(actor, 0.9, 2.8)

func _add_pick_area(actor: Node, radius: float, height: float) -> void:
    if actor == null or not is_instance_valid(actor) or not actor is Node3D:
        return
    var key := actor.get_instance_id()
    if scanned.has(key):
        return
    var area := Area3D.new()
    area.name = "HWInteractionHitbox"
    area.collision_layer = 1
    area.collision_mask = 0
    area.input_ray_pickable = true
    var shape := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = radius
    capsule.height = height
    shape.shape = capsule
    shape.position.y = height * 0.5
    area.add_child(shape)
    actor.add_child(area)
    scanned[key] = true
