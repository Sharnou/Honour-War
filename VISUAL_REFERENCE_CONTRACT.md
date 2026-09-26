# Honour War — Authoritative Visual Reference Contract

Status: PERMANENT / RELEASE-BLOCKING

## Canonical source

The repository Screenshot/ folder is the direct visual source. Two minimum detail anchors are locked:

- Screenshot/ChatGPT Image Sep 16, 2026, 12_22_47 AM.png
- Screenshot/image_a4469f29.jpg

## First stage

Every Honour War visual/development pass begins with Visual RAG or multimodal reference analysis. No asset, material, lighting, animation, camera or UI implementation decision is made before the current gap analysis.

## Locked detail floor

The finished game must show, at normal gameplay distance:
- complete hero body, face, hair, hands, legs and feet;
- class-specific layered equipment and weapons;
- distinct pet and monster silhouettes;
- detailed terrain, roads, vegetation and architecture;
- purposeful props and map landmarks;
- believable PBR material response;
- bright medieval daylight and readable contact shadows;
- camera framing that keeps the hero readable;
- attack anticipation/contact/recovery and visible hit feedback;
- projectiles/AOE/skill VFX;
- a complete dark/gold MMORPG HUD with profile, RPG navigation, minimap, quest tracker, chat and utility shortcuts, with no center-bottom skill strip.

A runtime that falls back to sparse primitive-only presentation is a visual regression.

## Sole runtime

SharnouEngine is the only Honour War engine/runtime target, controlled exclusively by Sharnou-IDE. Godot, Unity and Unreal Engine are permanently rejected as active runtime/build targets.

## Asset interchange

Approved runtime delivery:
- glTF 2.x (`.gltf` / `.glb`) for 3D scene/model containers;
- KTX2 (`.ktx2`) for GPU-facing 3D material textures;
- `KHR_texture_basisu` when a glTF asset uses Basis Universal KTX2 textures.

Approved authoring/interchange:
- FBX for rigged/animated assets;
- OBJ for approved static assets;
- texture maps authored in Substance 3D Painter or equivalent production tooling.

Rejected:
- non-KTX2 shipped 3D material textures;
- non-AVIF shipped 2D raster visuals;
- Meshy;
- generic substitute references as a replacement for the repository source;
- futuristic/modern/scifi presentation.

## Originality

The game must be an original Honour War implementation driven by the visual characteristics of the references. Reference images are never pasted into the world or used as a 2D background.

## Real screenshot rule

Visual acceptance requires a screenshot from the actual Unreal Engine 5.8 runtime/EXE. A generated concept image or reference screenshot does not count.

## Scope

Characters, classes, advanced classes, pets, monsters/MVPs, equipment, weapons, cards/refinement presentation, towns, fields, dungeons, props, animation, VFX, lighting, camera and UI.
