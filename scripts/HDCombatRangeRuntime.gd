class_name HDCombatRangeRuntime
extends CombatRuntime

## Compatibility facade retained for existing scenes.
## All authoritative class, pet and monster distances now live in CombatRules
## and are consumed by CombatRuntime. This class intentionally adds no second
## combat loop, preventing duplicate timers, damage or target selection.
