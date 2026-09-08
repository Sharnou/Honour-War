# Honour War — Permanent HD 3D Art Pipeline

Honour War's final visual production pipeline is fixed as:

**Blender → Substance 3D Painter → GLB/GLTF → Godot 4**

This is the basic logic for all future Honour War visual development.
Do not restart the game architecture to accommodate the art pipeline.
Upgrade the existing game in place and progressively replace development
placeholders with production assets.

## Roles

### Blender
- Hero and NPC modeling
- Class armor and weapons
- Pets, monsters and MVPs
- Towns, buildings, dungeon environments and props
- Rigging, skinning and animation
- UV layout and game-ready optimization
- LOD meshes and collision/proxy geometry
- GLB/GLTF export

### Substance 3D Painter
- High-detail PBR material authoring
- Armor, weapons, skin, scales, fur and environment materials
- Base Color, Normal, Roughness, Metallic, AO and Emissive maps
- Class, equipment and rarity material variants
- Premium/glowing material treatments

### GLB/GLTF
- Production interchange format between DCC and Godot
- Preserve meshes, materials, skeletons, animation clips and scene hierarchy
- Use stable asset IDs independent of display names

### Godot 4
- Final runtime/game engine
- MMORPG gameplay, combat, skills, AI, UI, camera and input
- World streaming and dungeon/town systems
- Equipment, pets, cards, loot and progression
- Networking/server integration
- Animation playback and AnimationTree integration
- Particles, shaders, lighting, fog and post-processing
- LOD and performance management

## Final visual target

The target is a **high-detail, stylized fantasy MMORPG** with the visual richness
of the Honour War reference presentation: detailed characters, expressive pets,
recognizable monsters/MVPs, layered equipment, rich environments, physically
based materials, cinematic lighting, strong combat readability and polished VFX.

The target is not primitive geometry and is not photorealism for its own sake.
It is stylized HD game art designed for real-time performance.

## Production priority

1. Hero silhouettes and class identity
2. Detailed game-ready hero meshes and rigs
3. PBR materials and visible equipment
4. Hero animation sets
5. Pet models, rigs and animation sets
6. Monster and MVP models
7. Town, field and dungeon environment kits
8. Skill/VFX assets and combat reactions
9. Cinematic lighting, atmosphere and post-processing
10. LOD, texture budgets, batching and runtime performance

## Stable asset IDs

Gameplay data must never depend on display names.

- `hero_<class>`
- `armor_<id>`
- `weapon_<id>`
- `headgear_<id>`
- `pet_<id>`
- `monster_<id>`
- `mvp_<id>`
- `map_<id>`
- `prop_<id>`
- `effect_<id>`

## Runtime rule

`res://scripts/HDAssetRuntime.gd` is the runtime bridge. When a production GLB
exists at the expected stable path, it replaces the corresponding procedural
visual automatically while preserving the gameplay reference used by combat,
AI, animation and HUD systems.

Procedural visuals are fallback-only development geometry. They must not be
considered final Honour War art.

## Asset manifest

See `assets/3d/HD_ASSET_MANIFEST.md` for the production asset contract and the
initial hero/pet/monster/MVP import list.
