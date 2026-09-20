extends Node3D
## Production HD world entry point: preserve the existing world builder and add the dense map-detail booster.
const MapBoost = preload("res://scripts/HWMapDetailBoost.gd")
const CameraFrame = preload("res://scripts/HWCameraFrameV3.gd")

func _ready() -> void:
    var parent := get_parent()
    if parent == null:
        return
    var boost: Node3D = MapBoost.new()
    boost.name = "HWMapDetailBoost"
    parent.add_child(boost)
    var frame: Node = CameraFrame.new()
    frame.name = "HWCameraFrameV3"
    parent.add_child(frame)
    queue_free()
