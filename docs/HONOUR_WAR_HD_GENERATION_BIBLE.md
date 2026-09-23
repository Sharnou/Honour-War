# Honour War — HD 3D MMORPG / Anime-Inspired Generation Bible

Status: PERMANENT / RELEASE-BLOCKING

This is the authoritative high-level generation contract for all future Honour War visual and gameplay cycles.

## 1. Product identity
Honour War is a desktop HD 3D MMORPG/ARPG with an anime-inspired medieval/fantasy visual identity and Ragnarok Online-inspired interaction and camera behavior.

Every generated asset, map, character, monster, animation, effect, UI element, camera pass, screenshot and gameplay test must preserve this identity.

## 2. Visual quality target
The target is authored HD 3D presentation, not placeholder or primitive-only presentation.

Required visual characteristics:
- complete visible hero body during normal gameplay, including face, hair, hands, legs and feet;
- expressive anime-inspired facial proportions and readable silhouettes;
- layered armor, clothing, accessories and class-specific weapon silhouettes;
- high-detail PBR materials with physically coherent roughness/metallic/normal information;
- detailed terrain with authored ground variation, vegetation, rocks, paths, cliffs and water;
- authored buildings, interiors/exteriors, ruins, bridges, props and environmental landmarks;
- dense but readable towns, fields, mountains, rivers, snow areas and dungeons;
- daylight presentation with strong contact shadows and readable depth;
- animation with clear locomotion, attack wind-up, impact, recovery, hit reaction, death and idle states;
- readable skill VFX, impact effects, damage feedback and loot feedback;
- no black placeholder meshes, red/yellow point markers, missing body parts or primitive-only final presentation.

## 3. MMORPG gameplay presentation
The gameplay loop is hero-centered: explore world and towns; fight monsters in the world/dungeons; receive experience, Zeny, cards, equipment and refinement materials; progress hero level to 250; support monster levels to 300; use classes, class-specific skills, equipment, refinement, card mixing and basic-skill progression; preserve progression with autosave.

Cities are RPG service hubs. They are not strategy bases and do not contain soldiers, squads, tower-defense systems, income banks, base-building systems or strategy-war systems.

### 4A. Permanent city-building/service exclusion
Honour War is not a strategy/base-building game. Never generate, restore, expose, or connect Town Hall, Blacksmith, Market, Barracks, Magic Tower, city resources, city upgrades, or any associated city-service/build/construction implementation. Never generate building-connection skills, building-linked skill effects, building dependencies, construction actions, build-mode panels, or city-service commands. These are removed from the World Director and all generation pipelines and must remain absent.

## 4. Permanent exclusions
Never regenerate or reintroduce soldier systems, squad production/replacement, soldier level caps or automatic soldier skills, soldier death-count mechanics, soldier-specific rewards, guarded income banks, base-building/construction, building/construction UI panels, tower-defense/defense towers, base-sight or strategic sight overlays, skill shrines, soldier workshops, transformer/futuristic machinery designs, strategy-war HUD/commands, player-vs-player/team combat or server-authoritative PvP damage wrappers, monsters spawned inside cities as a strategy mechanic, GLB/GLTF as production intake/final-art pipeline, or Godot as the target runtime.

The repository exclusion gate is authoritative and release-blocking.

## 5. Approved asset pipeline
Visual RAG/reference analysis → gap register → detailed generation brief → Neural4D / Blender asset generation and processing → Substance 3D Painter material pass → FBX/OBJ production interchange → Unreal Engine 5.8 integration → collision/LOD/material validation → animation integration → runtime gameplay validation → real Windows EXE build → real gameplay screenshot capture → visual comparison and defect register → next controlled visual cycle.

Do not use GLB/GLTF as an alternate shortcut around this pipeline.

## 6. Character generation specification
Every hero/NPC generation pass must check full-body topology and silhouette, face readability, hair silhouette, hands/fingers and weapon grip, legs/boots/feet, armor/clothing layers, class identity, material differentiation, idle/walk/run/attack/hit/death animation coverage and correct world scale.

## 7. Monster generation specification
Every monster pass must check distinct species silhouette, complete anatomy and terrain contact, level-tier readability, attack/hit/death animation, targeting behavior, loot/defeat feedback and environment-appropriate placement outside cities.

## 8. World generation specification
Each map pass must include navigable terrain, authored spawn/encounter areas, roads and landmarks, town/dungeon boundaries, appropriate water/cliffs/bridges/ruins/vegetation, collision matching visual geometry, readable lighting and camera framing that keeps the hero completely visible.

## 9. Camera and controls — immutable
The desktop interaction model remains Ragnarok Online-inspired: left-click ground = click-to-move; left-click living monster = select/engage; right-mouse drag = camera orbit; mouse wheel = bounded zoom; W/A/S/D = secondary movement; 1–8 = gameplay skills; Q = camera reset.

Default camera: perspective projection, elevated/isometric-style MMORPG framing, approximately -50° pitch and approximately 45° yaw, with the full hero body readable during normal play.

## 10. HUD specification
HUD must remain compact and MMORPG-oriented. Required information includes hero portrait/profile, name/class/level, HP/SP/EXP, age/honour where applicable, minimap/coordinate context, active quest tracking, world chat, compact gameplay/economy status and normal RPG inventory/character/skills/quest access where implemented.

Never add construction panels, strategy command panels, soldier controls or tower controls.

## 11. Animation and VFX quality gate
Every gameplay-visible character and monster must have idle, locomotion, combat anticipation, attack execution, impact/contact, recovery, hit reaction, death/defeat and appropriate VFX/audio event hooks. Effects must remain readable without obscuring hero or target.

## 12. Materials and lighting gate
Validate PBR material completeness, appropriate texture resolution, no missing textures, no broken black shaders, correct normal orientation, roughness response, metal/cloth/leather/skin differentiation, daylight exposure, contact shadows and readable silhouettes.

## 13. Runtime test matrix
A release candidate is not complete until these are tested:
1. Project opens without missing required assets.
2. Unreal 5.8 contract passes.
3. Permanent exclusion gate passes.
4. MMORPG camera/control contract passes.
5. Progression/reward/economy/autosave contract passes.
6. Visual RAG cycle contract passes.
7. HD asset-generator/intake contract passes.
8. Windows EXE build succeeds.
9. EXE launches successfully.
10. Hero is fully visible in gameplay.
11. Town is visually authored and readable.
12. World terrain/environment is visibly 3D, not placeholder geometry.
13. Monster is fully modeled and animated.
14. Monster targeting and click-to-engage work.
15. Hero movement/camera/zoom work.
16. Skills 1–8 are usable where implemented.
17. Hit/impact/death feedback is visible.
18. Loot/experience/Zeny/card/equipment rewards work.
19. Refinement/card mixing/basic skill progression work.
20. Autosave/resume works.
21. No excluded system is visible or active.
22. Real gameplay screenshot is captured from the built EXE.

## 14. Screenshot acceptance gate
The final screenshot must show real runtime output, not an editor viewport, mockup, concept image or placeholder. Preferred capture contains the full hero body, visible face/equipment, detailed terrain/environment, a visible monster or gameplay encounter, readable MMORPG HUD and correct camera framing, with no construction/strategy/soldier/tower UI, black placeholder geometry or GLB/GLTF-derived production artifact.

## 15. High-detail generation priorities
When compute is limited, prioritize: 1) hero full-body quality; 2) camera/control readability; 3) town/world geometry; 4) monsters/combat animation; 5) materials/lighting; 6) combat VFX/hit feedback; 7) HUD polish; 8) secondary NPC/prop density; 9) distant environment detail; 10) optional cosmetic polish.

Never sacrifice the permanent gameplay identity to add unrelated systems.

## 16. Cycle persistence
This document is a persistent design contract. Future generation cycles must improve detail and completeness without deleting approved RPG/MMORPG systems or reintroducing rejected strategy systems. Each cycle adds fidelity, fixes defects and preserves previously accepted gameplay behavior.
