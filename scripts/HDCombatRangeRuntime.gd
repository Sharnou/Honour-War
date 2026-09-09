class_name HDCombatRangeRuntime
extends CombatRuntime

## Compatibility wrapper kept in the scene for the HD combat layer.
## CombatRuntime is now the single authoritative simulation owner and reads
## CombatRules for every class, pet, and monster engagement distance.

func _ready()->void:
    super._ready()
