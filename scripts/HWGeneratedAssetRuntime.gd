extends Node

## Native runtime visual bridge.
## The former generated-GLB attachment system is permanently retired.
## Approved Neural4D FBX/OBJ sources are normalized into native Godot actors;
## this node never loads, imports, downloads or attaches GLB/GLTF assets.

const POLL_INTERVAL:float = 0.50
var elapsed:float = 0.0

func _ready() -> void:
    process_priority = 880
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("_sync")

func _process(delta:float) -> void:
    elapsed += delta
    if elapsed < POLL_INTERVAL:
        return
    elapsed = 0.0
    _sync()

func _sync() -> void:
    var scene_root:Node = get_tree().current_scene
    if scene_root == null:
        return
    _ensure_native_visibility(scene_root)

func _ensure_native_visibility(scene_root:Node) -> void:
    var hero_value:Variant = scene_root.get("hero_visual")
    if hero_value is Node3D:
        (hero_value as Node3D).visible = true

    var monsters_value:Variant = scene_root.get("monster_visuals")
    if monsters_value is Dictionary:
        for value:Variant in (monsters_value as Dictionary).values():
            if value is Node3D:
                (value as Node3D).visible = true

    var pet_value:Variant = scene_root.get("pet_visual")
    if pet_value is Node3D:
        (pet_value as Node3D).visible = true
