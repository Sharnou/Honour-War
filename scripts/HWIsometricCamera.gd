extends Node3D

## Compatibility stub for the authored Camera3D node.
## MovementStabilityFix is the single camera owner in the production scene;
## keeping a second current camera here caused projection/follow conflicts.

@export var target:Node3D
@export var pitch_angle:float = 35.0
@export var yaw_angle:float = 45.0
@export var orthographic_size:float = 10.0

func _ready()->void:
    # Do not create a child Camera3D and do not claim the viewport camera.
    # The root Camera3D remains controlled by MovementStabilityFix.
    pass
