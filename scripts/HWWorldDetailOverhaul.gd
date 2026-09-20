extends Node3D
## Compatibility entry point for the production HD world pass.
## The active implementation is HWWorldDetailOverhaulV3.gd.
const V3 = preload("res://scripts/HWWorldDetailOverhaulV3.gd")

func _ready() -> void:
    var parent := get_parent()
    if parent == null:
        return
    var world := V3.new()
    world.name = "HWWorldDetailOverhaulV3"
    parent.add_child(world)
    queue_free()
