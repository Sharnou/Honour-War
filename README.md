# Honour War — Unity 6.0 LTS HD MMORPG/ARPG

Development status: **Unity 6.0 LTS (6000.0.x) production migration**. Godot is permanently retired. Unreal Engine 5.8 is no longer the active runtime or CI engine.

## Permanent visual identity

Honour War is an HD 3D anime-inspired MMORPG/ARPG with a medieval/fantasy world, full-body 3D characters, class-specific equipment, expressive animation, readable combat VFX, dense environments and a compact MMORPG HUD.

The visual target is regenerated from the locked repository reference images. The authoritative visual source remains the Screenshot/ folder. The approved asset pipeline remains:

Visual RAG/reference analysis → gap register → visual brief regeneration → Neural4D or Blender → Substance 3D Painter → FBX/OBJ → **Unity 6.0 LTS** → runtime validation → real gameplay screenshot → reference comparison.

GLB/GLTF is not an approved intake format for the project pipeline.

## MMORPG controls and camera

The interaction model remains Ragnarok Online-inspired desktop MMORPG control:

- Left click ground: click-to-move target path.
- Left click living monster: select target and enter class engagement range.
- Right-mouse hold + drag: perspective/isometric camera orbit.
- Mouse wheel: bounded camera zoom.
- W/A/S/D: secondary direct movement.
- 1–8: gameplay skill inputs.
- Q: reset camera framing.

The camera remains an elevated perspective MMORPG camera with the complete hero visible during normal gameplay.

## MMORPG HUD

The HUD remains driven by the locked repository visual anchors:
- `Screenshot/ChatGPT Image Sep 16, 2026, 12_22_47 AM.png`
- `Screenshot/image_a4469f29.jpg`

The target HUD includes:
- upper-left portrait/profile with name, level/class, HP/SP/EXP, age and honour;
- circular minimap with map coordinates, compass and time;
- active quest tracker;
- lower-left world chat with editable input;
- compact MMORPG combat/economy status.

Removed permanently:
- build/menu overlay panels and construction UI;
- soldier, squad, workshop and tower systems;
- base-building and base-sight overlays;
- strategy-war controls;
- player-vs-player team combat controls.

## Engine

**Unity 6.0 LTS (6000.0.x) is the active engine baseline.** The Unity project lives in `Unity/`.

The selected baseline is Unity 6.0 LTS. Unity's official documentation identifies 6.0 LTS as the 6000.0 release line; the current project is pinned to the 6000.0.71f1 patch. Unity documents Windows 10 21H1+ as supported for Unity 6.0. Unity 6.0 LTS remains supported through October 2026.

The previous Unreal C++ implementation is retained temporarily as migration/reference material so existing Honour War systems and design logic are not silently discarded during the C# port. It is not an active runtime, build target or CI gate.

## Current Unity playable baseline

`Unity/Assets/Scripts/HonourWarBootstrap.cs` currently provides a real Unity runtime vertical slice with:

- register/login entry flow;
- character/class selection;
- Warrior, Mage, Archer, Thief, Acolyte, Merchant and Ranger;
- eight initial skills for every class;
- third-person/elevated gameplay camera;
- live player movement;
- monster test population;
- local automatic save/resume;
- `@help` command path;
- `@go 0 230:220` coordinate movement;
- Tier-5 skill-rest gate;
- F9 capture of the actual running Unity game framebuffer.

This is the migration foundation, not a claim that every legacy Unreal gameplay system has already been ported.

## Real screenshot rule

Only an image captured from the **running Unity game** counts as gameplay evidence. Generated artwork, reference images, mockups and editor screenshots do not count.

Press **F9 during live gameplay** to invoke Unity `ScreenCapture.CaptureScreenshot`. The resulting PNG is written beneath:

`Application.persistentDataPath/HonourWarScreenshots/`

The repository also contains `Build/Run-Unity-HonourWar.ps1` for opening the project or building a Windows executable with the installed Unity 6.0 LTS Editor.

## Runtime testing rule

Static contract validation is not gameplay evidence. A genuine runtime result requires the Unity Editor or a packaged Unity player to execute the game.

Runtime testing must distinguish:

- Unity runtime exceptions/errors;
- crashes/player termination;
- class-selection failures;
- movement failures;
- skill failures;
- command-routing failures;
- save/load failures;
- camera/player initialization failures.

## Fifth-tier class progression

The class tree retains five tiers:
Tier 1 Foundation (Lv. 1), Tier 2 Specialization (Lv. 25), Tier 3 Advanced (Lv. 50), Tier 4 Mastery (Lv. 150), Tier 5 Transcendence (Lv. 200).

Tier 5 remains rooted in the original first-tier profession and preserves profession-specific weapon family, silhouette, equipment identity and skill lineage. The Unity port must preserve this design contract while migrating implementation from C++ to C#.

## Travel command

The MMO command contract includes:

`@go 0 230:220`

The Unity migration's live gameplay slice executes this command and moves the player to the requested coordinate space.

## Copyright

© Sharnou — Honour War
