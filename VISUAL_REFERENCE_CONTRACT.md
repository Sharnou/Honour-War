# Honour War — Authoritative Visual Reference Contract

## Status

This document is a permanent daily-upgrade rule for Honour War.

The authoritative visual target is the reference material stored in:

- `Screenshot/ChatGPT Image Sep 16, 2026, 12_22_47 AM.png`
- `Screenshot/image_a4469f29.jpg`

These references are part of the Honour War visual contract. Daily upgrades must use the repository references as the primary visual target and must not replace them with generic HD/MMORPG assumptions.

## Mandatory first step

For **every** Honour War development pass, manual or automatic, the first execution stage is:

**Visual RAG / multimodal visual-reference analysis → current visual target/gap analysis**

No Blender generation, Neural4D generation, code-based visual implementation, material decision, lighting decision, animation decision, camera decision or UI art decision may begin before this analysis is produced.

The analysis must, when available:

1. Inspect the newest real Honour War gameplay screenshot.
2. Inspect the two authoritative repository references above.
3. Compare the current runtime against the intended reference presentation.
4. Identify visual differences at both macro and micro levels.
5. Prioritize the highest-impact gaps.
6. Convert the gaps into concrete production requirements.
7. Carry those requirements into the asset and runtime implementation stages.

## Micro-detail fidelity gate

The goal is not merely to make Honour War look generally similar. The daily visual pass must reproduce the reference presentation's relevant details as closely as technically possible, including:

- full-body character visibility and proportions
- face/head readability and expression
- hair, clothing, armor, weapons and accessories
- class-specific silhouettes and equipment layering
- pet proportions, placement and behavior
- monster/MVP silhouette, anatomy, equipment and presentation
- terrain shape, ground detail, vegetation and surface breakup
- buildings, streets, structures, shops and environmental props
- texture scale, surface response, roughness, metallic response and material separation
- shadows, highlights, ambient occlusion, reflections and emissive elements
- daylight/atmosphere, fog, exposure and color balance
- camera distance, framing, perspective and character readability
- animation pose, timing, anticipation, contact, impact, recovery and hit reaction
- attack/projectile/AOE/skill VFX shape, timing, intensity and readability
- damage feedback, critical-hit presentation and combat readability
- UI scale, spacing, typography hierarchy, icons, panels, bars and overlays
- visual consistency between gameplay, towns, fields, dungeons, combat and menus

Where a reference contains a visible detail that is relevant to the game, the implementation specification must explicitly account for it instead of silently simplifying it.

## Approved asset pipeline

After Visual RAG analysis, the approved production path is:

**Visual RAG → Neural4D / authored DCC → FBX/OBJ → native Godot 4.7.2 → validation → real runtime screenshot/test**

### Neural4D intake

- FBX is approved for rigged/animated characters, pets and monsters.
- OBJ is approved for static assets where appropriate.
- Neural4D is an approved generation source when available.
- Authored production assets are preferred over procedural placeholders.

### Explicit exclusions

- GLB is rejected from all daily updates and production/runtime intake.
- GLTF is rejected from all daily updates and production/runtime intake.
- Meshy is permanently rejected.
- No daily update may generate, import, depend on, or claim completion of a GLB/GLTF asset.

## Godot runtime requirement

The final runtime presentation must use native Godot 4.7.2 scenes/resources and verified imported assets. Visual implementations must preserve existing gameplay references, saves, systems, options and progression.

Procedural geometry may exist only as an explicitly identified development fallback. It must never be reported as production-authored art.

## Real screenshot requirement

Visual QA screenshots must be captured from the actual Honour War Main3D runtime/build. Generated concept images, mockups or reference images do not count as gameplay evidence.

Every daily visual pass should verify, where the changed scope permits:

- runtime asset presence
- import success
- materials/textures
- skeleton/animation integrity
- collision where applicable
- lighting and camera presentation
- combat/VFX presentation
- UI presentation
- runtime stability
- actual screenshot evidence

## Scope

This contract applies to the entire game:

- all six base classes and their advanced classes
- pets
- monsters and MVPs
- equipment, weapons, armor, cards and refinement presentation
- towns and shops
- fields and dungeons
- terrain and props
- VFX and combat feedback
- animation
- lighting and atmosphere
- camera
- UI/HUD
- gameplay presentation

## Failure/unavailable-tool rule

If Visual RAG, Neural4D, Blender, Substance 3D Painter or another external art tool is unavailable, the pass must still begin with the available visual-reference analysis. It must then improve the available manifests, asset specifications, generation scaffolding, import/runtime integration, tests and validation.

The pass must clearly record the unavailable stage and must never claim that an unavailable asset-generation or texturing operation was completed.

## Daily acceptance rule

A daily upgrade is not visually complete merely because it builds or runs. The changed visual scope must pass the reference gap analysis and runtime verification. Any remaining mismatch must remain explicitly tracked for a later pass.
