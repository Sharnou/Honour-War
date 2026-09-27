# Sharnou Engine — Honour War

SharnouEngine is the only active game engine for the canonical Honour War project.

Permanent stack:
- Project: honour-war
- IDE: Sharnou-IDE
- Engine: SharnouEngine
- Protocol: Sharnou Project Protocol (SPP)
- Game: 3D HD MMORPG/ARPG
- Platform: Windows 64-bit
- Movement: Ragnarok-style click-to-move; no WASD

## Tool policy

Honour War does not use, invoke, install, or download Visual Studio, MSBuild, Windows SDK development packages, Unity, Unreal Engine, or unrelated external programming tools. Sharnou-IDE is the exclusive authoring/controller layer and SharnouEngine is the exclusive runtime.

## Asset policy

Sharnou-IDE accepts registered source formats and automatically routes them through the project conversion/validation pipeline. This is source-format acceptance, not permission to ship every source format.

The canonical runtime asset strategy is:
- glTF 2.x (.gltf/.glb): 3D scenes, meshes, nodes and animations.
- KTX2 (.ktx2): compressed 3D material textures; glTF may reference them with KHR_texture_basisu.
- AVIF (.avif): all shipped raster/2D visual assets such as UI, HUD, icons, portraits, cards, menus, backgrounds and visual evidence.

Thus AVIF is the only shipped raster/2D format, while glTF/GLB and KTX2 are the complementary 3D asset formats.

## Honour War integration

The engine must identify the canonical project id honour-war, accept the Sharnou-IDE SPP handoff, preserve the existing Honour War content/data, validate generated assets, and expose native self-test and runtime-test commands.

No Unity or Unreal runtime remains in the active path.
