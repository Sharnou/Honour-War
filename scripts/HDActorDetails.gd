extends Node3D

## Legacy actor-name/detail overlay disabled for the production Honour War HUD.
## Character, pet and monster floating labels are intentionally not created here.
## This also prevents stale Label3D references when the runtime sanitizes legacy UI nodes.

func _ready()->void:
	set_process(false)
	_clear_legacy_labels()

func _clear_legacy_labels()->void:
	for child in get_children():
		if child is Label3D:
			child.queue_free()
