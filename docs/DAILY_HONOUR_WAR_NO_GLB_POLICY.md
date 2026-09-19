# Honour War — Permanent No-GLB Policy

Status: **PERMANENT**
Effective: 2026-09-19

## Rule

The generated HD `.glb` asset library is permanently retired from Honour War.

Daily Honour War Upgrade and all future development work **must not**:
- regenerate HD GLB character, pet, monster, or MVP assets;
- download HD GLB assets;
- import HD GLB assets into Godot;
- attach generated GLB scenes at runtime;
- recreate the retired `assets/3d/generated/**/*.glb` library.

## Visual development path

Future visual improvements must be implemented directly in the native Godot project using authored Godot scenes, meshes, materials, shaders, animation, lighting, terrain, VFX, UI, and gameplay presentation systems.

The repository `Screenshot/` folder remains the authoritative visual source for the game's intended appearance.

The existing gameplay systems, classes, pets, monsters, skills, combat, maps, towns, progression, age system, refinement, items, UI, saving, multiplayer contracts, and Windows EXE requirements remain part of Honour War and must not be removed because the GLB library was retired.

## Daily upgrade gate

Every Daily Honour War Upgrade must verify that no `.glb` files exist under `assets/3d/generated/`. If any are introduced, the upgrade must fail.

Every visual upgrade must preserve the direct `Screenshot/` visual reference and improve the native Godot runtime rather than restoring the retired GLB pipeline.
