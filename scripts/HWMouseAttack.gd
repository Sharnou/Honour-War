extends Node
func _ready()->void:
    set_process_unhandled_input(true)
func _unhandled_input(event:InputEvent)->void:
    if not event is InputEventMouseButton: return
    if not event.pressed or event.button_index!=MOUSE_BUTTON_LEFT: return
