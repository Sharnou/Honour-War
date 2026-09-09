class_name HDControlPass
extends Node

## Compatibility-safe marker/controller configuration for the HD mouse-first pass.
## MovementStabilityFix remains the camera owner; no camera pan is performed here.
const MOUSE_FIRST:bool = true
const KEYBOARD_NEVER_PANS_CAMERA:bool = true
const SWORDSMAN_RANGE:float = 2.4
const ARCHER_RANGE:float = 12.0
const MONSTER_MELEE_RANGE:float = 2.2

func _ready()->void:
    process_mode = Node.PROCESS_MODE_ALWAYS
