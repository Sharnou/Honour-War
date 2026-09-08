# Honour War — HD 3D Art Pipeline

Honour War uses a dedicated 3D production pipeline:

**Godot 4 + Blender + Substance 3D Painter**

Ren'Py is not part of the Honour War runtime or content pipeline.

## Roles

### Godot 4
- Runtime/game engine
- MMORPG gameplay, combat, skills, AI, UI, camera and input
- World streaming and dungeon/town systems
- Equipment, pets, cards, loot and progression
- Networking/server integration
- Animation playback, particles, shaders, lighting and post-processing

### Blender
- Hero and NPC modeling
- Class armor and weapons
- Pets, monsters and MVPs
- Towns, buildings, dungeon environments and props
- Rigging and animation
- UV layout and optimized game-ready meshes
- GLB/GLTF export for Godot

### Substance 3D Painter
- High-detail PBR material authoring
- Armor, weapon, skin, scales, fur and environmental textures
- Normal/roughness/metallic/AO/emissive texture maps
- Class and rarity material variants
- Glowing and premium equipment materials

## Visual target

The target is a **high-detail, stylized Ragnarok-style HD MMORPG** presentation rather than primitive placeholder geometry or photorealism.

Priority order:

1. Silhouette and character readability
2. Detailed game-ready meshes
3. High-quality PBR materials
4. Layered armor and visible equipment
5. Detailed monsters and MVPs
6. High-quality animation
7. Skill/VFX presentation
8. Rich towns and dungeon environments
9. Cinematic lighting, shadows and atmosphere
10. Performance-aware LOD and texture budgets

## Asset naming

Use stable IDs so gameplay data does not depend on display names:

- `hero_<class>_base`
- `armor_<id>`
- `weapon_<id>`
- `headgear_<id>`
- `pet_<id>`
- `monster_<id>`
- `mvp_<id>`
- `map_<id>`
- `prop_<id>`

Export production assets as `.glb`/`.gltf` with textures and materials prepared for Godot.

## Development rule

Existing Honour War gameplay systems should be upgraded in place. The 3D art pipeline replaces primitive visual placeholders progressively; it does not require restarting the game architecture.
