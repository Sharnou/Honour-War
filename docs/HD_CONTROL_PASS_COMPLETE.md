# HD Control Pass

The requested behavior is now defined in the production architecture: mouse-first movement/target interaction, stable camera ownership, swordsman melee engagement, archer long-range engagement/projectiles, clean combat-number presentation, and compatibility-safe desktop launch.

Implementation components: `HDMouseCombatController`, `HDCombatRules`, `HDCombatProjectile`, and `HDCombatNumberFilter`. Existing `MovementStabilityFix` remains the authoritative camera owner.
