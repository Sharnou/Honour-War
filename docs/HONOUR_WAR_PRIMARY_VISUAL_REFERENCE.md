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

**Reference images → Blender → Substance 3D Painter → GLB/GLTF → Godot 4.7 Forward+**

Production assets must be authored as actual 3D geometry/materials and integrated into the game. Camera or lighting adjustments alone do not satisfy a missing-detail requirement.

Known, plausible materials only. Never use Transformers, mystery materials, or `Unknown Material` placeholders.

## Visual QA rule

Every visual regression must verify that the source folder exists and contains the complete reference set before approving the visual pipeline.

The visual QA gate is release-blocking if:

- the source folder is missing
- any canonical reference file is missing
- a workflow substitutes a generic image source
- the rendered game falls back to primitive-only presentation where authored production assets are required

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
