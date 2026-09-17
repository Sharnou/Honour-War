# Honour War — Permanent Daily Upgrade Roles

This document is a permanent development contract for every future manual or automated Honour War update. Every upgrade must continue from the existing repository and preserve working gameplay, assets, options, saves, and architecture.

## 1. Visual RAG — reference / visual analysis / production target definition
- Perform visual/reference analysis first for every visual-production pass.
- Compare the current Honour War presentation with the defined high-fidelity 3D MMO/ARPG target.
- Convert the visual gap into concrete production targets for characters, monsters, pets, equipment, towns, dungeons, terrain, props, materials, animation, lighting, VFX, camera, and UI.
- Do not claim a visual asset exists unless it is actually present and integrated.

## 2. Blender — production asset creation
Use Blender for production modeling, rigging, skinning, animation, UVs, LODs, scene preparation, and export preparation. Preserve readable full-body characters, faces, legs, equipment silhouettes, pets, monsters, environments, and combat animation requirements.

## 3. Substance 3D Painter — PBR materials
Use Substance 3D Painter for production PBR texturing and material variants, including physically based base color, roughness, metallic, normal/detail maps and class/item/environment variants where applicable.

## 4. GLB/GLTF — production interchange
Use GLB/GLTF as the production interchange format containing meshes, materials, skeletons, skinning, and animations required by the Godot runtime. Validate exported assets before runtime integration.

## 5. Godot 4.7 — runtime integration
Godot 4.7.x Forward+ is the runtime authority for:
- animation playback and blending
- lighting, atmosphere, camera and world presentation
- VFX and combat feedback
- gameplay, classes, progression, equipment, pets and monsters
- UI and player interaction
- networking and authoritative multiplayer
- world/map streaming and town/dungeon transitions
- persistence and autosave

## 6. Validation / build / regression
Every production-impacting update must use the available automated integrity checks, Godot 4.7.x validation, runtime checks, and Windows export regression. Inspect the newest Action result before starting another correction. Do not report a feature, asset, EXE, or test as complete until it is actually verified.

If the same defect survives three implementation attempts, stop repeating the same approach and perform a fresh diagnostic or independent engineering/AI review, then validate the new implementation against the repository.

## 7. Permanent MMORPG/ARPG boundary — reject active strategy mechanics
Honour War is MMORPG/ARPG only. Every validation pass must reject any active implementation of:
- Barracks
- Tower Defense
- Soldier Production
- Guarded Bank

Also reject related legacy strategy loops such as soldier armies, soldier spawning/respawn production, guarded-bank income/occupation, bank territories, or strategy-city progression. A compatibility symbol or historical text may exist only when it is inert and explicitly proven not to create gameplay.

**No strategy mechanics were restored.** Cities remain MMORPG/ARPG service hubs only: NPCs, shops, healing, equipment, refinement, cards, market, magic, quests, warp, rental, and social services.

## 8. Canonical Honour War gameplay constraints
- Six playable base classes remain: Warrior, Mage, Archer, Thief, Acolyte, Merchant.
- Class advancement, class-specific skills/builds, equipment and pets remain active gameplay systems.
- Hero maximum level remains 250; monster maximum level remains 300; pet maximum level remains 250.
- Every character automatically owns its class-appropriate combat pet; no feeding requirement.
- SS / SUPER SHAMBION remains rental-only through the Rent NPC at 1,000,000 Zeny; it is never a character-creation class.
- SS starts at level 0, follows the real hero, heals the hero and itself, fights with Asura Strike, and exposes owner equipment/status control plus GO termination.
- Hero age continues to advance from online days and may affect presentation, basic-skill effects, refinement success, material consumption and item prices without changing base database drop-rate values.
- Fast travel remains `@go [map] [x]:[y]`.
- Constant daylight remains the current presentation default.
- Preserve the Blender → Substance 3D Painter → GLB/GLTF → Godot 4.7 production path.

## 9. Daily execution order
1. Visual RAG / reference and gap analysis.
2. Inspect current repository state and newest CI/runtime failures.
3. Choose the highest-impact concrete production gap.
4. Implement in place without restarting or removing working systems.
5. Validate Godot, gameplay contracts, networking, asset integrity and relevant regression tests.
6. Run Windows export regression when the change can affect the release build.
7. Inspect the result and only then continue to the next upgrade.

This role definition is permanent for future Honour War daily upgrades.
