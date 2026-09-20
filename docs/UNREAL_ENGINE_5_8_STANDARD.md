# Honour War — Unreal Engine 5.8 Technical Standard

## Engine

- Runtime: Unreal Engine 5.8
- Target: Windows PC
- Primary module: HonourWar
- Renderer: UE 5.8 with Nanite-capable geometry where appropriate, Lumen/global illumination for production scenes, virtual shadow maps, HDR exposure and atmospheric depth.
- Gameplay camera: perspective isometric-style third-person camera; 360° horizontal orbit; pitch constrained to readable gameplay ranges.

Unreal Engine 5.8 is the authoritative engine version for all Honour War runtime work. The engine feature set supports the project direction, including updated worldbuilding, terrain, vegetation and production rendering workflows.

## Architecture

C++ owns authoritative gameplay and replication foundations. UMG owns the player-facing HUD. Data assets/JSON/CSV remain source data for items, cards, classes, monsters and progression.

Core systems:
- Character progression: level 1–250.
- Monster progression: level 1–300.
- Hero age based on online days.
- Class-specific skills and engagement ranges.
- Pet combat foundation.
- Equipment/cards/refinement data model.
- Save/resume.
- Multiplayer foundation.
- World/map presentation.

## Visual production

Visual RAG → visual specification → Neural4D/Blender → FBX/OBJ → Substance 3D Painter texture sets → Unreal Engine 5.8 import → materials/LOD/collision/animation validation → real EXE screenshot.

Procedural runtime geometry is a development bootstrap only. It is not accepted as the final art library.

## Reference fidelity

The minimum visual-detail anchors are:
- Screenshot/ChatGPT Image Sep 16, 2026, 12_22_47 AM.png
- Screenshot/image_a4469f29.jpg

The final presentation must show full-body characters, readable faces/legs/feet, class-specific clothing and equipment, dense medieval environments, surface material variation, vegetation/props, readable combat effects and a polished non-diegetic MMORPG HUD.

## Player-facing UI

The primary combat HUD contains:
- player level/class/age;
- HP, SP and EXP;
- target information;
- minimap/world-map panel;
- compact chat;
- centered 8-slot COMBAT SKILLS bar;
- no legacy developer/command toolbar.

## Runtime screenshot gate

The packaged EXE supports -HonourWarCapture. The capture director waits for the game world to settle, requests a screenshot to Saved/Screenshots/HonourWar-real-runtime.png, then exits. CI may validate the file on a self-hosted Unreal 5.8 Windows runner.

## Prohibited presentation

No modern/sci-fi/futuristic machines, robots, transformers, factories, space/rocket visuals or development command bars. Honour War remains a medieval/fantasy MMORPG/ARPG.
