# Honour War — Unreal Engine 5.8 HD MMORPG/ARPG

> Development status: Unreal Engine 5.8 migration and HD 3D production foundation. Godot has been permanently retired.

## Engine standard

- Unreal Engine 5.8 — sole runtime and Windows build target.
- Windows PC.
- C++ gameplay/runtime foundation with UMG HUD.
- Visual RAG is the first visual/design stage.

Unreal Engine 5.8 is the project's locked renderer/runtime choice. The repository no longer uses Godot for the game runtime or build pipeline.

## Visual target

The entire Screenshot/ folder is authoritative. The two locked detail anchors are:

- Screenshot/ChatGPT Image Sep 16, 2026, 12_22_47 AM.png
- Screenshot/image_a4469f29.jpg

The target is a premium stylized medieval/fantasy MMORPG presentation: complete full-body characters, visible faces and legs, distinct class equipment, expressive pets, recognizable monsters/MVPs, dense towns/fields/dungeons, detailed terrain and props, rich materials, bright daylight, readable combat VFX and a polished MMORPG HUD.

The current Unreal foundation includes a native 3D town/field bootstrap with layered buildings, roads, market dressing, walls, vegetation, monsters, full-body class-driven hero presentation and an eight-slot combat skill HUD. Authored production FBX/OBJ art still needs to replace the bootstrap meshes before the final locked visual target can be declared complete.

## Game foundation

- Hero level cap: 250.
- Monster level cap: 300.
- Soldier level cap: 50.
- Six base classes: Warrior, Mage, Archer, Thief, Acolyte, Merchant.
- Ranger is an advanced combat class.
- Monsters provide EXP, Zeny, items and cards.
- Hero respawns near the city/base point after death.
- Online-time age progression affects skills, refinement, economy and appearance.
- Refinement uses Phracon, Zeny, Emveretarcon and Oridecon.
- Online multiplayer foundation and parties are part of the design.
- Fast travel uses @go [map] [x]:[y].
- Constant daylight is the current visual baseline.
- No futuristic/modern/sci-fi machinery, robots, transformers, factories or space-themed presentation.

## Player HUD

The intended player-facing HUD has:
- upper-left player information and HP/SP/EXP;
- upper-center target;
- upper-right map/minimap;
- lower-left chat;
- center-bottom COMBAT SKILLS with 8 slots bound to 1–8;
- contextual character, inventory, equipment, pet, skills, refinement and system windows.

The old development/command toolbar is not part of the game.

## Art pipeline

Visual RAG → Neural4D or Blender → Substance 3D Painter → FBX/OBJ → Unreal Engine 5.8 → runtime/EXE validation

GLB, GLTF and Meshy are permanently rejected. See:
- NO_GODOT_FOREVER.md
- ART_PIPELINE.md
- VISUAL_REFERENCE_CONTRACT.md
- docs/UNREAL_VISUAL_SPEC.md
- Content/HonourWarArt/ART_ASSET_MANIFEST.json

## Build

Set UNREAL_ENGINE_ROOT to the UE 5.8 installation directory.

PowerShell:
powershell -ExecutionPolicy Bypass -File Build/Build-HonourWar.ps1 -Package

Windows launcher:
Build/Run-HonourWar.bat

For real runtime evidence, package the game and launch it with -HonourWarCapture; the screenshot director writes to Saved/Screenshots/HonourWar-real-runtime.png.

## Validation

tools/unreal_engine_contract_qa.py verifies the Unreal 5.8 project contract and rejects retired Godot files/workflows.

The actual UE compile/package gate uses a Windows runner with Unreal Engine 5.8 installed; the repository cannot truthfully claim a successful UE build until that environment executes the build.

## Copyright

© Sharnou — Honour War
