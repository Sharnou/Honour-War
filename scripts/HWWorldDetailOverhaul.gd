extends Node3D
## Production HD world entry point: hide the legacy flat world and layer native dense detail passes.
const MapBoost = preload("res://scripts/HWMapDetailBoost.gd")
const PronteraDetail = preload("res://scripts/HWPronteraReferenceDetail.gd")
const CameraFrame = preload("res://scripts/HWCameraFrameV3.gd")

func _ready() -> void:
    var parent := get_parent()
    if parent == null:
        return
    var legacy_world := parent.get_node_or_null("World3D")
    if legacy_world != null:
        # Keep the live gameplay world visible. Detail passes layer on top of it;
        # hiding World3D also hid the recovery geometry and caused black captures.
        legacy_world.visible = true
    var legacy_background := parent.get_node_or_null("HDEnvironmentDirector/HDEnvironmentBackground")
    if legacy_background != null:
        legacy_background.visible = false
    var boost: Node3D = MapBoost.new()
    boost.name = "HWMapDetailBoost"
    parent.call_deferred("add_child", boost)
    var prontera: Node3D = PronteraDetail.new()
    prontera.name = "HWPronteraReferenceDetail"
    parent.call_deferred("add_child", prontera)
    var frame: Node = CameraFrame.new()
    frame.name = "HWCameraFrameV3"
    parent.call_deferred("add_child", frame)
    queue_free()
