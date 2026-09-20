extends Node
## Final gameplay framing pass: preserve player camera controls while giving the real frame more world context.
var camera:Camera3D

func _ready() -> void:
    process_priority = 1200
    camera = get_parent().get_node_or_null("Camera3D") as Camera3D

func _process(_delta:float) -> void:
    if camera == null:
        camera = get_parent().get_node_or_null("Camera3D") as Camera3D
    if camera == null:
        return
    camera.fov = 50.0
    camera.near = 0.05
    camera.far = 900.0
