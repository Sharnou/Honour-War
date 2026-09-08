# Honour War — Godot 4 HD MMORPG/ARPG

## Requirements
- Godot 4.2 or newer
- Forward+ / Vulkan recommended for the intended HD presentation

## Run
1. Install Godot 4.
2. Open `project.godot`.
3. Press F6 or F5 to run.

## Core controls
- WASD / Arrow Keys: move
- SPACE: hero + bonded pet attack
- R: refine hero equipment
- T: refine pet equipment
- Q: complete a quest
- C: craft
- B: buy Phracon
- F9: cycle graphics quality

## Game foundation
- Six classes with automatic class-bonded combat pets
- Class-specific pet roles and tactical behavior
- Pets fight alongside the hero automatically
- Pet progression, skills, equipment, crafting materials and refinement +0 to +15
- Hero progression up to level 250
- Online-time hero aging
- Age-based progression bonuses
- Monsters and MVPs with combat, EXP, cards, items and Zeny drops
- Quests, crafting, fast transmission and automatic save/resume
- Chat, combat feedback, target lock, combo and pet skill systems

## Production HD art rule

**Blender → Substance 3D Painter → GLB/GLTF → Godot 4**

This is the permanent Honour War visual production pipeline.

- Blender: production modeling, rigging, skinning, animation, UVs, LODs and export preparation
- Substance 3D Painter: PBR texturing and material variants
- GLB/GLTF: production interchange format containing meshes, materials, skeletons and animations
- Godot 4: Forward+ runtime, animation, lighting, atmosphere, VFX, gameplay, UI, networking and world streaming

Procedural geometry remains only as a development fallback. It is not the final
Honour War art direction.

## HD runtime architecture

`HDAssetRuntime.gd` detects production GLB assets by stable ID and replaces the
corresponding procedural actor without changing gameplay references. This lets
art production progress independently while combat, AI, pets, skills, HUD and
progression continue using the same runtime architecture.

The production asset contract is documented in:
- `ART_PIPELINE.md`
- `assets/3d/HD_ASSET_MANIFEST.md`
- `tools/blender/honour_war_hd_asset_builder.py`
- `tools/blender/export_honour_war_glb.py`

## Visual target

Honour War targets a high-detail, stylized fantasy MMORPG presentation:
detailed class silhouettes, expressive pets, recognizable monsters/MVPs, layered
equipment, PBR materials, rich town/field/dungeon environments, atmospheric
lighting, readable combat effects and polished animation.

The goal is not photorealism and not primitive geometry. The goal is premium
real-time stylized HD game art with scalable performance tiers.

## Multiplayer scope

The current repository remains an offline playable foundation. Production online
MMORPG deployment still requires authoritative servers, accounts, database
persistence, networking, anti-cheat, matchmaking/world services, live operations,
production audio and the complete production art library.
