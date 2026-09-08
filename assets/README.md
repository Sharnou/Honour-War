# Honour War — Authored 3D Asset Pipeline

This directory is the production integration boundary for real, authored MMORPG assets. The repository does not contain a fake or inflated binary asset package.

## Required asset standards

- **Characters, pets, monsters, and MVPs:** GLB/GLTF with skeletal rigs, clean humanoid or creature proportions, named bones, collision proxies, and LOD meshes.
- **Materials:** PBR metallic/roughness workflow; texture sizes should be selectable by graphics profile.
- **Animation clips:** `idle`, `walk`, `run`, `turn`, `attack_anticipation`, `attack`, `attack_recovery`, `hit`, `stagger`, `knockback`, `death`, `cast`, `skill`, and `ultimate` where applicable.
- **Equipment sockets:** `head`, `face`, `body`, `weapon`, `offhand`, `back`, and `accessory`.
- **VFX:** class-specific effects must expose a readable cast telegraph, impact, damage response, and cleanup lifetime.
- **World assets:** towns, roads, buildings, vegetation, dungeon props, portals, and boss arenas should use modular meshes and LODs.

## Naming convention

Use lowercase snake case and keep the gameplay identifier stable:

```text
assets/characters/hero/warrior/warrior.glb
assets/characters/hero/warrior/warrior_attack_01.glb
assets/pets/dire_wolf/dire_wolf.glb
assets/monsters/orc/orc.glb
assets/mvps/baphomet/baphomet.glb
assets/animations/combat/warrior_attack_01.res
assets/vfx/class_skills/warrior/immortal_arsenal.tscn
```

The runtime must always retain a procedural fallback when an authored asset is absent. A missing binary asset is a content task, not a reason to fabricate a large package or break the game.
