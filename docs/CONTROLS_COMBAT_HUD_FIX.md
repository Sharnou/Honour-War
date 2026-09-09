# Honour War — Controls, Combat Range & HUD Fix

## Target behavior

- Mouse is the primary world interaction: left click ground to move; click an enemy to select/attack it.
- WASD and arrow keys are movement controls only when explicitly mapped as character movement; they never pan, drag, or follow the camera.
- Camera remains fixed/stable during keyboard movement.
- Swordsman uses short-range melee logic and closes distance to an enemy before striking.
- Archer uses long-range targeting and projectile/arrow presentation; it does not need to stand beside the target.
- Hero/pet bond damage is presented as a clean numeric combat event. Internal/debug/build/status strings must never be appended to combat numbers.
- Window/desktop launch remains compatible with Godot 4.2.2 Compatibility/OpenGL on legacy hardware while the project production renderer stays Forward+.

## Architecture

`MovementStabilityFix` owns camera and mouse/keyboard world movement. `CombatRuntime` owns attack range and target selection. Presentation systems consume combat events and must not mutate the authoritative target state.
