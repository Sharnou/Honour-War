# Honour War — canonical Sharnou Engine project

Honour War (honour-war) is developed and run exclusively through Sharnou-IDE -> SharnouEngine.

- Game: 3D HD MMORPG/ARPG
- Platform: Windows 64-bit
- IDE: Sharnou-IDE
- Engine: SharnouEngine
- Protocol: Sharnou Project Protocol (SPP)
- Movement: Ragnarok Online-style click-to-move; no WASD

## Exclusive tool policy

Do not use, invoke, install, or download Visual Studio, MSBuild, Windows SDK development packages, Unity, Unreal Engine, or unrelated external programming tools.

Sharnou-IDE is the only authoring/controller IDE. SharnouEngine is the only Honour War game/runtime engine. No automatic daily/background update system is part of this project.

## Automatic project handoff

The canonical project files under Tools/SharnouIDE bind this repository to the canonical Sharnou-IDE project id honour-war and SharnouEngine runtime.

The IDE boundary accepts registered source formats and automatically converts/validates them as required. It preserves original sources and never downloads an external programming tool.

## Runtime asset strategy

The runtime uses complementary formats:
- .gltf / .glb — 3D scene/model containers.
- .ktx2 — compressed 3D textures, including Basis Universal textures referenced from glTF through KHR_texture_basisu.
- .avif — the only shipped raster/2D visual format: UI, HUD, icons, portraits, cards, menus, backgrounds, skyboxes and distribution visuals.

AVIF-only therefore applies to shipped raster/2D visuals; it does not prohibit glTF/GLB or KTX2, which serve the 3D pipeline.

FBX/OBJ may be accepted as source/interchange input and converted by Sharnou-IDE. Runtime delivery is normalized to glTF/GLB + KTX2 + AVIF.

## Canonical identity

Every build and generation job must identify project id honour-war, IDE Sharnou-IDE, and engine SharnouEngine.

A runtime build/test is only marked PASS after the actual SharnouEngine executable runs. Static inspection is not runtime evidence.

## Preserved game design

The migration preserves the existing Honour War content/data, including 70 character profiles, 35 jobs across 7 classes and 5 tiers, monsters, maps, equipment, cards, pets, quests/events, ageing/saved progression, and Ragnarok-style click movement.

© Sharnou — Honour War
