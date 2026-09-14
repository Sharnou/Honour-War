# Honour War — Role-Based Full-Game Upgrade Pipeline

This document is the operating contract for autonomous Honour War development.

## Goal

Raise the entire game toward a high-fidelity Ragnarok Online-style MMORPG presentation while preserving existing gameplay and saved progress. Do not restart the project and do not treat procedural placeholder primitives as finished production art.

## Development roles

### 1. Creative / Visual Director
Owns the visual target across the whole game. Uses Visual RAG / multimodal references to compare the current build against the intended quality bar and defines the next highest-value visual corrections.

### 2. Character Art Lead
Owns all six base classes (Warrior, Mage, Archer, Thief, Acolyte, Merchant), every advanced class, class silhouettes, faces, hair, body proportions, armor, weapons, class VFX, and readable combat poses. The result must remain recognizably distinct per class and progression tier.

### 3. Companion / Monster Art Lead
Owns automatic class pets, pet progression visuals, monster families, MVP/boss silhouettes, attacks, casts, hit reactions, death presentation, and readable threat levels.

### 4. Environment Art Lead
Owns towns, dungeons, roads, terrain, water, vegetation, architecture, props, landmarks, map readability, and environmental storytelling. Avoid repeating identical placeholder buildings when authored assets are available.

### 5. Technical Art / Asset Pipeline Lead
Owns Blender → Substance 3D Painter → GLB/GLTF → Godot 4 integration, material quality, PBR maps, LOD strategy, import settings, texture budgets, naming conventions, collision proxies, animation imports, and fallback behavior.

### 6. Gameplay / Combat Director
Owns class progression, skills, targeting, attacks, pets, soldiers, cities, loot, refinement, MVPs, dungeon/town travel, multiplayer-facing systems, and balance. Visual progression must reflect gameplay progression.

### 7. Animation / VFX Director
Owns locomotion, idle, attack, cast, hit, death, skill telegraphs, particles, trails, impact effects, class signatures, camera feedback, and animation blending.

### 8. UI / UX Director
Owns the MMORPG HUD, character/pet/equipment/skill windows, maps, quest panels, combat feedback, inventory, refinement, notifications, and controller/mouse clarity. Avoid floating identity/equipment text that distracts from the character.

### 9. Performance / Rendering Engineer
Owns Godot Forward+ rendering, lighting, shadows, draw-call awareness, texture memory, shader cost, LOD/culling, and stable operation on the project's current hardware while preserving the visual target.

### 10. QA / Release Engineer
Owns parser safety, scene loading, broken references, autoload collisions, save migration, regression checks, Git history hygiene, and verification that new assets and scripts are actually present before declaring completion.

## Production loop

1. Review the latest repository state and current visual output.
2. Use Visual RAG / multimodal references when available to identify the largest visual gap.
3. Assign the highest-impact work to the appropriate role(s).
4. Build or integrate real assets through Blender → Substance 3D Painter → GLB/GLTF → Godot 4 whenever tooling/assets are available.
5. Use procedural Godot fallbacks only as temporary compatibility layers, never as evidence of finished production art.
6. Wire the asset or system into the actual playable scene.
7. Validate scripts, scenes, imports, saves, and regressions.
8. Commit the completed increment to `main`.
9. Repeat the loop every 24 hours through the daily development automation.

## Non-negotiable visual quality rules

- Full-body heroes and readable silhouettes.
- Realistic/high-detail materials and authored textures as the production target.
- Every class and advancement tier receives meaningful visual differentiation.
- Pets, monsters, towns, dungeons, props, weapons, armor, VFX, and UI are part of the same quality pass.
- Do not claim high-detail authored GLB/GLTF assets exist unless the files are actually committed.
- Preserve working gameplay systems and saved player progress.
