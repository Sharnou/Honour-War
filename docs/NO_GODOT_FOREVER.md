# Honour War — No Godot Forever

Status: PERMANENT

Honour War has permanently rejected Godot as its game runtime and build target.

## Sole runtime

Unreal Engine 5.8 is the only supported game engine for the Honour War runtime, Windows packaging, game screenshots and production renderer.

No future pass may:
- restore project.godot, Main3D.tscn or Godot .gd runtime code;
- use Godot as a fallback renderer or validation engine;
- add Godot workflows or Godot export steps;
- describe a Godot build as an Honour War release;
- reintroduce the retired Godot runtime architecture.

## Migration policy

The old Godot implementation is retired rather than kept as a hidden fallback. Gameplay specifications, progression data, visual contracts and design intent are migrated into Unreal C++/UMG/data assets.

## Visual runtime

Visual RAG/reference analysis remains the first art/design stage. It informs the visual specification, then production assets are authored/processed through Neural4D or Blender and textured in Substance 3D Painter. Rigged/animated assets use FBX; approved static assets may use OBJ. Unreal Engine 5.8 performs the actual runtime rendering.

GLB and GLTF remain rejected for daily Honour War updates and runtime intake. Meshy remains rejected.

## Evidence

A gameplay screenshot is valid only when captured from the running Unreal Engine 5.8 executable/game instance. Concept art, generated images and reference images are not gameplay evidence.
