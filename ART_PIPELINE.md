# Honour War — Permanent HD 3D Art Pipeline

Honour War's approved visual production pipeline is fixed as:

**Visual RAG → Neural4D / authored DCC → FBX/OBJ → native Godot 4.7.2 → validation → real runtime/build test**

The repository visual contract is defined by:

- `Screenshot/ChatGPT Image Sep 16, 2026, 12_22_47 AM.png`
- `Screenshot/image_a4469f29.jpg`

These references are authoritative for daily visual target and gap analysis. Do not replace them with generic HD/MMORPG assumptions.

## Mandatory first stage

Every manual or automatic Honour War development pass must begin with Visual RAG / multimodal visual-reference analysis.

Before any Blender generation, Neural4D generation, code visual implementation, material decision, lighting decision, animation decision, camera decision or UI art decision, the pass must produce a current visual target/gap analysis.

The analysis must use the newest real Honour War gameplay screenshot when available, compare it with both authoritative repository references, identify the highest-impact visual deficits, and convert those deficits into concrete production requirements.

## Micro-detail fidelity

Daily visual work must target the reference presentation at both macro and micro levels, including:

- character silhouette, body proportions, full-body visibility, face/head readability and expression
- hair, clothing, armor, weapons, accessories and layered equipment
- class-specific visual identity and advanced-class identity
- pet model, placement, proportions, animation and combat presentation
- monster/MVP silhouette, anatomy, equipment, materials and presentation
- terrain shape, ground breakup, vegetation, buildings, streets and props
- texture detail, UV quality, PBR response, roughness, metallic response, normal/AO detail and emissive materials
- lighting, shadows, highlights, ambient occlusion, exposure, atmosphere, fog and daylight presentation
- camera distance, perspective, framing and readable character/monster composition
- animation pose, anticipation, contact, impact, recovery, hit reaction and death presentation
- attacks, projectiles, AOE, skill VFX, critical feedback and combat readability
- UI/HUD scale, spacing, typography hierarchy, icons, bars, panels and overlays

Relevant visible reference details must be explicitly represented in implementation requirements rather than silently simplified.

## Permanent generation rules

- Meshy is permanently rejected for Honour War generation.
- GLB is permanently rejected from daily updates and production/runtime intake.
- GLTF is permanently rejected from daily updates and production/runtime intake.
- Neural4D is an approved generation source.
- FBX is the approved Neural4D intake format for rigged/animated characters, pets and monsters.
- OBJ is the approved Neural4D intake format for approved static assets where appropriate.
- Authored DCC assets are preferred over procedural placeholders.
- Final runtime assets must be converted/imported into native Godot 4.7.2 scenes/resources.
- No future daily upgrade may reintroduce GLB/GLTF or Meshy dependencies.
- Visual QA must verify the native no-GLB/no-GLTF pipeline.

## Blender

Blender remains an approved authored-DCC production tool for:

- hero and NPC modeling
- class armor and weapons
- pets, monsters and MVPs
- towns, buildings, dungeon environments and props
- rigging, skinning and animation
- UV layout and game-ready optimization
- LOD meshes and collision/proxy geometry
- FBX/OBJ export

Blender work must occur only after the Visual RAG analysis for the current pass.

## Substance 3D Painter

Substance 3D Painter remains an approved texturing/material-authoring tool for:

- high-detail PBR material authoring
- armor, weapons, skin, scales, fur and environment materials
- Base Color, Normal, Roughness, Metallic, AO and Emissive maps
- class, equipment and rarity material variants
- premium/glowing material treatments

Substance work must follow the current Visual RAG material requirements. The daily intake/runtime contract remains FBX/OBJ → native Godot; GLB/GLTF is not an approved interchange format.

## Neural4D / FBX / OBJ

Neural4D is an approved generation source when available.

- FBX: rigged/animated characters, pets and monsters.
- OBJ: approved static meshes.
- Stable asset IDs must remain independent of display names.
- Asset specifications must include required topology/detail, materials, scale, orientation, rig/animation requirements and Godot integration requirements.

## Godot 4

Godot 4.7.2 is the final runtime target for:

- MMORPG gameplay, combat, skills, AI, UI, camera and input
- world streaming and dungeon/town systems
- equipment, pets, cards, loot and progression
- networking/server integration
- animation playback and AnimationTree integration
- particles, shaders, lighting, fog and post-processing
- LOD and performance management
- native scene/resource integration of approved FBX/OBJ assets

Runtime code must not search for, import, preload or prefer GLB/GLTF assets.

## Real screenshot validation

Visual QA screenshots must come from the actual Honour War Main3D runtime/build. Generated concept art or mockups are not acceptable as gameplay evidence.

Validation must cover, as applicable:

- asset existence and correct asset ID
- FBX/OBJ import success
- materials/textures and PBR response
- skeleton/animation integrity
- collision and scale
- lighting and camera presentation
- combat/VFX presentation
- UI presentation
- runtime stability
- actual screenshot/build evidence

## Final visual target

The target is a high-detail, stylized fantasy MMORPG presentation matching the authoritative Honour War repository references: detailed full-body class silhouettes, visible faces and legs, expressive pets, recognizable monsters/MVPs, layered equipment, PBR materials, rich town/field/dungeon environments, atmospheric lighting, readable combat effects and polished animation.

The target is not primitive geometry, generic MMORPG art or photorealism for its own sake. It is premium real-time stylized HD game art whose visual details are governed by the repository references.

## Production priority

1. Visual RAG target/gap analysis
2. Hero silhouettes and class identity
3. Detailed game-ready hero meshes and rigs
4. PBR materials and visible equipment
5. Hero animation sets
6. Pet models, rigs and animation sets
7. Monster and MVP models
8. Town, field and dungeon environment kits
9. Skill/VFX assets and combat reactions
10. Cinematic lighting, atmosphere and post-processing
11. LOD, texture budgets, batching and runtime performance

## Stable asset IDs

Gameplay data must never depend on display names.

- `hero_<class>_<gender>`
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

Production assets must enter the game through the approved FBX/OBJ-to-native-Godot pipeline.

Runtime code must not search for, import, preload or prefer GLB/GLTF assets. Procedural visuals are fallback-only development geometry and must not be considered final Honour War art.

## Asset manifest

See `assets/3d/HD_ASSET_MANIFEST.md` for the production asset contract and the initial hero/pet/monster/MVP import list.

## Daily Honour War Upgrade contract

Every manual or automatic daily pass must:

1. Start with Visual RAG / multimodal visual-reference analysis.
2. Inspect the newest real gameplay screenshot when available.
3. Compare against `Screenshot/ChatGPT Image Sep 16, 2026, 12_22_47 AM.png` and `Screenshot/image_a4469f29.jpg`.
4. Identify and prioritize the current visual gaps.
5. Translate those gaps into concrete asset/model/material/lighting/animation/camera/VFX/UI requirements.
6. Preserve existing systems, assets, options, saves and progress.
7. Use Neural4D or authored DCC production assets through FBX/OBJ.
8. Keep GLB/GLTF completely excluded from daily updates and runtime intake.
9. Validate the actual Godot runtime and capture real gameplay evidence.
10. Never claim an asset or stage exists unless it has been verified.

The complete visual-reference rules are documented in `VISUAL_REFERENCE_CONTRACT.md`.

## Failure / unavailable-tool rule

If Visual RAG, Neural4D, Blender, Substance 3D Painter or another external art tool is unavailable, the pass still begins with whatever visual-reference analysis is available. The pass then improves manifests, asset specifications, generation scaffolding, import/runtime integration and validation. The unavailable stage must be explicitly recorded and must never be represented as completed.
