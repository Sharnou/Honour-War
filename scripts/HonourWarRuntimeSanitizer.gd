class_name HonourWarRuntimeSanitizer
extends Node

## Removes obsolete 3D nameplates/equipment labels left by older runtime passes.
const SCAN_INTERVAL:float = 0.5
var elapsed:float = 0.0

func _ready()->void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("_sanitize")

func _process(delta:float)->void:
    elapsed += delta
    if elapsed < SCAN_INTERVAL:
        return
    elapsed = 0.0
    _sanitize()

func _sanitize()->void:
    var root:Node = get_tree().current_scene
    if root == null:
        return
    _scan(root)

func _scan(node:Node)->void:
    for child in node.get_children():
        if child is Label3D:
            child.visible = false
            child.queue_free()
            continue
        _scan(child)
