# Honour War — Godot 3D + Ren'Py Architecture

Honour War's real-time MMORPG gameplay and 3D rendering remain in Godot. Ren'Py is reserved for an optional narrative/codex layer, cinematic dialogue, lore scenes, and story presentation.

This separation is deliberate: Ren'Py is primarily a visual-novel engine, while Godot provides the Node3D, Camera3D, character-body, imported glTF scene, material, lighting, particle, and animation systems needed by the real-time game.

## Runtime layers

- Godot 3D world: maps, characters, pets, monsters, MVPs, combat effects, camera, lighting.
- Existing gameplay backend: levels, classes, skills, equipment, cards, pets, loot, city systems, save data, commands.
- 3D presentation bridge: reads the gameplay backend and displays it as a 3D scene.
- HD asset library: real `.glb`/`.gltf` scenes are loaded when available; procedural fallback visuals remain for development.
- Optional Ren'Py narrative package: story chapters, lore, dialogues, and cinematic text/image scenes that can be launched separately or linked from a future launcher.

## Asset policy

The target 2+ GB edition must be made from real authored/generated content. Do not duplicate files or use filler data merely to reach a size number.

Preferred 3D source format is glTF 2.0 (`.glb` or `.gltf`) because Godot supports it directly and it carries meshes, materials, skeletons, and animations.

## Quality tiers

- LOW: Intel HD/older integrated GPU focused.
- HIGH: balanced visual quality.
- ULTRA: maximum practical scene density and effects for capable hardware.

The Compatibility renderer remains available for systems with OpenGL 3.3 support. A separate higher-end build can later use a modern Godot renderer when hardware allows.
