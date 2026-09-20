# Honour War — Primary Visual Source

Status: **Permanent / authoritative / release-blocking**

## Canonical visual source

The **entire repository folder** below is the direct visual source for Honour War:

- Folder: `Screenshot/`
- GitHub: https://github.com/Sharnou/Honour-War/tree/main/Screenshot

The game is **not** to be visually designed from generic MMORPG references, stock images, search results, or substitute pictures when this folder is available.

### Authoritative reference set

These repository images are all part of the canonical source set:

1. `Screenshot/ChatGPT Image Sep 7, 2026, 03_54_35 PM.png`
2. `Screenshot/ChatGPT Image Sep 8, 2026, 12_13_55 AM.png`
3. `Screenshot/ChatGPT Image Sep 8, 2026, 12_30_08 AM.png`
4. `Screenshot/ChatGPT Image Sep 14, 2026, 02_17_52 PM.png`
5. `Screenshot/ChatGPT Image Sep 15, 2026, 11_17_00 PM.png`
6. `Screenshot/ChatGPT Image Sep 16, 2026, 12_22_47 AM.png`
7. `Screenshot/ChatGPT Image Sep 18, 2026, 11_57_21 PM.png`

**Rule:** treat the complete `Screenshot/` folder as the visual reference set. Do not select a single image as a replacement for the folder unless the user explicitly changes the rule.

## What the source controls

The reference set controls the target visual language for:

- character silhouette, proportions, full-body framing, face and legs
- clothing, armor, weapons, accessories and materials
- character age/style/emotion presentation
- pets and companion presentation
- monster silhouette, scale and readability
- terrain, vegetation, roads, buildings, towns and map density
- camera distance, pitch, composition and staging
- daylight, exposure, contrast, shadows and environment lighting
- combat attacks, impact/hit feedback, skill VFX and animation readability
- NPCs and world interaction presentation
- UI composition, equipment/status presentation, icons and skill presentation
- overall 3D asset density, polish and visual hierarchy

The objective is to **generate an original Honour War implementation whose visual result is driven directly by these references**, not merely to label the current low-detail output as HD.

## Asset production rule

Use the permanent production pipeline:

**Reference images → Visual RAG analysis → Blender/Neural4D → FBX/OBJ → Godot 4.7 Forward+**

For daily production updates, **FBX and OBJ are the approved Neural4D intake formats. GLB/GLTF are rejected as daily-update intake/output formats.**

Production assets must be authored as actual 3D geometry/materials and integrated into the game. Camera or lighting adjustments alone do not satisfy a missing-detail requirement.

Known, plausible materials only. Never use Transformers, mystery materials, or `Unknown Material` placeholders.

## Visual QA rule

Every visual regression must verify that the source folder exists and contains the complete reference set before approving the visual pipeline.

The visual QA gate is release-blocking if:

- the source folder is missing
- any canonical reference file is missing
- a workflow substitutes a generic image source
- the rendered game falls back to primitive-only presentation where authored production assets are required


## FINAL HD 3D VISUAL TARGET — PERMANENTLY LOCKED

The following two images are now designated the **final visual-detail anchor references** and must remain permanently active for Honour War:

1. `Screenshot/ChatGPT Image Sep 16, 2026, 12_22_47 AM.png`
2. `Screenshot/image_a4469f29.jpg`

These two references define the **minimum locked target level** for the finished game's HD 3D presentation. The target is not allowed to regress to a lower-detail, primitive, placeholder, flat, sparse, low-poly or generic presentation.

### Detail-density lock

For every playable map and every gameplay camera view, continuously reproduce the reference-level information density at the appropriate scale:

- complete terrain surface treatment, elevation/readable ground transitions and material variation;
- dense, purposeful architecture with complete walls, roofs, windows, doors, trim, supports, signs, stairs, bridges and structural details;
- roads, paths, paving, curbs, borders, drainage, transitions and navigational landmarks;
- layered vegetation including trees, branches, leaves, bushes, grass, flowers and ground scatter;
- rocks, cliffs, ruins, fences, posts, lamps, banners, ropes, docks and environmental structures;
- lived-in props such as crates, barrels, carts, tables, benches, market stalls, tools, containers, signs and decorative objects;
- water surfaces, shorelines, docks, boats and shoreline transition details where applicable;
- map-specific landmarks and storytelling objects rather than repeated generic decoration;
- dungeon walls/floors/ceilings, columns, arches, torches, crystals, debris, doors, traps and depth layers where applicable;
- character full-body geometry, face, hair, hands, clothing layers, armor, weapon, legs and feet;
- unique pet and monster silhouettes, anatomy, materials, equipment and readable combat poses;
- physically readable materials for skin, hair, cloth, leather, wood, stone, metal, glass/crystal, water and magic;
- shadows, contact shading, ambient occlusion, controlled highlights, atmospheric depth and readable daylight;
- combat anticipation, contact, impact, hit sparks, trails, projectiles, AoE indicators, damage feedback and skill VFX;
- complete HUD, icons, skill bar, status/equipment presentation and world-map presentation at the same polish level.

### Map-by-map rule

Every map is treated as a finished authored environment, not a reusable empty template. Each map must receive primary, secondary and tertiary detail passes and must remain visually distinct while obeying the locked reference quality floor. Increasing the number of maps must never be used as a reason to reduce detail density.

### Regression rule

A new visual build may improve on the locked target, but it may **never lower the target detail level**. Any screenshot, runtime capture or EXE that visibly falls below this target is a visual regression and must not be accepted as a finished release.

### Exactness clarification

“Exactly as this picture” means the **same visual-detail target, density, readability, composition quality, material richness, character/environment completeness and polish level**, implemented as original Honour War 3D assets. The reference images are not to be pasted into the game, traced into a fake background, or used as a 2D substitute for missing 3D geometry.

### Release gate

The final HD target is not considered achieved merely because scripts, contracts or EXE smoke tests pass. A release must also have a real gameplay screenshot captured from the running game and visually inspected against both locked anchor references. If the real gameplay frame is visibly below the locked target, the visual work continues.

## Player identity/UI exception

The following existing Honour War identity behavior remains part of the authoritative visual/UI contract:

1. Local character name is completely hidden in the 3D world.
2. Remote character names are hidden by default.
3. A remote player's real character name appears on mouse hover, relevant party/PvP context, or explicit social/chat reveal.
4. Never use a class name such as `Swordsman` as a permanent player nameplate.
5. No permanent player HP/SP world-foot bars under player characters.
6. Enemy combat HP bars remain permitted.
7. Real character names remain authoritative in chat, party, PvP, right-click player context, and equipment/status inspection UI.

## Permanent rule

Every Daily Honour War Upgrade, visual build, screenshot capture, and Windows EXE release must treat `Screenshot/` as the direct visual source. Visual changes must preserve gameplay systems while moving the rendered result toward this reference set.