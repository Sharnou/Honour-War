# Honour War — canonical Sharnou Engine project

Honour War (honour-war) is developed and run exclusively through **Sharnou-IDE -> SharnouEngine**.

- Game: 3D HD MMORPG/ARPG
- Platform: Windows 64-bit
- IDE: Sharnou-IDE
- Engine: SharnouEngine
- Protocol: Sharnou Project Protocol (SPP)
- Movement: Ragnarok Online-style click-to-move; no WASD

## Exclusive stack

Sharnou-IDE is the only authoring/controller IDE for Honour War. SharnouEngine is the only Honour War game/runtime engine. No Unity, Unreal Engine, Visual Studio, MSBuild, Windows SDK development installation, CMake, vcpkg, or unrelated external programming-tool download is part of the active Honour War path.

There is no automatic daily/background Honour War update system.

## Automatic project handoff

The canonical project files under Tools/SharnouIDE/ bind the repository to project id honour-war, Sharnou-IDE, and SharnouEngine.

Sharnou-IDE accepts any supplied source format at the intake boundary. It detects/classifies inputs, preserves originals, creates the required conversion/import job, and hands canonicalized output to SharnouEngine for validation. Unknown formats are preserved for inspection instead of silently discarded.

## Canonical runtime asset strategy

The asset strategy is complementary rather than mutually exclusive:

- **glTF 2.x (.gltf, .glb)** — 3D scene/model containers for meshes, nodes, skins and animations.
- **KTX2 (.ktx2)** — compressed GPU-facing 3D material textures using Basis Universal; glTF references them through `KHR_texture_basisu`.
- **AVIF (.avif)** — the shipped raster/2D visual format for UI, HUD, icons, portraits, cards, menus, backgrounds, skyboxes and distribution imagery.

AVIF-only applies to shipped raster/2D visuals. It does not reject glTF/GLB or KTX2, which are the complementary 3D asset formats.

FBX/OBJ remain approved source/interchange model inputs. They are converted before canonical runtime delivery. Other source formats may also enter through the Sharnou-IDE universal intake boundary when a registered adapter is available.

## Automatic Honour War / SharnouEngine jobs

The Sharnou-IDE handoff is designed to automatically perform the necessary project/asset work:

- format detection and validation
- source preservation and provenance hashing
- model/material/texture conversion and canonicalization
- dependency resolution
- SPP generation and compilation
- project graph synchronization
- SharnouEngine compatibility validation
- incremental rebuild/stale-output detection
- runtime smoke/self-test and runtime-test
- diagnostics and repair metadata
- real-runtime evidence capture

The active stack never downloads an external programming tool to perform one of these jobs.

## Canonical identity and runtime evidence

Every generation/build/test job must identify:
- project: honour-war
- IDE: Sharnou-IDE
- engine: SharnouEngine

A gameplay/build PASS requires the actual approved SharnouEngine executable to run. Static source inspection is not runtime evidence.

## Preserved game design

The migration preserves the existing Honour War content/data, including 70 character profiles, 35 jobs across 7 classes and 5 tiers, monsters, maps, equipment, cards, pets, quests/events, ageing/saved progression, and Ragnarok-style click movement.

See:
- `Engine/SharnouEngine/SHARNOU_ASSET_FORMATS.md`
- `Engine/SharnouEngine/sharnou_engine_architecture.json`
- `Tools/SharnouIDE/sharnou-ide-engine.integration.json`
- `Tools/SharnouIDE/honour-war.spp.json`
- `Tools/SharnouIDE/UNIVERSAL_ASSET_AUTOMATION.md`

© Sharnou — Honour War
