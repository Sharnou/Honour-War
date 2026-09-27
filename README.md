# Honour War — Sharnou Engine 3D HD MMORPG/ARPG

Honour War is the **canonical `honour-war` project** and uses **Sharnou-IDE + SharnouEngine** as its exclusive active development/runtime stack.

## Permanent project identity

- **Project ID:** `honour-war`
- **Canonical repository:** `https://github.com/Sharnou/Honour-War`
- **IDE:** Sharnou-IDE — `https://github.com/Sharnou/Sharnou-IDE`
- **Game engine:** SharnouEngine / Sharnou Engine
- **Authoring protocol:** Sharnou Project Protocol (SPP)
- **Native runtime language:** C++20
- **Platform:** Windows 64-bit
- **Game style:** 3D HD MMORPG/ARPG
- **Movement:** Ragnarok Online-style click-to-move; no WASD movement

Honour War is launched and validated through Sharnou-IDE. The project rejects Visual Studio, MSBuild, Windows SDK development installations, Sharnou Engine build system, Sharnou Engine dependency/runtime layer, Unity, Unreal Engine, and automatic external programming-tool downloads. Sharnou-IDE is the authoritative project controller.

## Sharnou-IDE → SharnouEngine workflow

1. Sharnou-IDE identifies the project as canonical `honour-war`.
2. Sharnou-IDE validates `Tools/SharnouIDE/honour-war.spp.json` against the SharnouEngine contract.
3. SPP is compiled to engine-consumable JSON bytecode by Sharnou-IDE.
4. The engine bridge verifies the canonical IDE, project and engine identities.
5. Sharnou-IDE compiles the SPP generation queue and invokes SharnouEngine's native generation entry point.
6. SharnouEngine writes the native generated Honour War runtime package and re-validates canonical data before launch.
7. No external compiler, IDE, build system or programming-tool download is performed.

## IDE conversion policy

Existing Honour War IDE/project metadata is treated as migration input and converted to the Sharnou-IDE SPP contract. Non-Sharnou IDEs are not runtime controllers for Honour War. The repository's policy gates reject active `.sln`, `.slnx`, `.vcxproj`, Sharnou Engine build system and Sharnou Engine dependency/runtime layer build paths outside legacy/archive areas.

## Asset format policy

Honour War uses an **AVIF-only shipped visual asset policy**.

- **AVIF (.avif)** is the only approved shipped raster/visual asset format for UI, HUD, menus, backgrounds, icons, portraits, item/skill/card art, skyboxes, loading art and visual evidence.
- **FBX/OBJ** are historical/archive interchange formats only. They are not active generation inputs or shipped runtime visual assets.
- **GLTF/GLB/KTX2** are permanently rejected from active Honour War runtime visual delivery.
- Other shipped raster formats including PNG/JPEG/WebP/GIF/BMP/TGA/DDS are rejected.
- Runtime geometry is compiled into the native SharnouEngine representation rather than a GLTF/GLB container.

Approved active generation flow is:

Locked Screenshot/reference inspection → SharnouEngine native generation → SharnouEngine native geometry/material/animation compilation → AVIF visual delivery → SharnouEngine runtime validation.

Neural4D, Blender, Substance 3D Painter, Unity, Unreal Engine and Godot are not active Honour War generators. Historical material is archive/reference material only and must never be invoked by the active build or runtime path.

Existing historical reference images can remain as references; they are not generated runtime assets.

## Preserved Honour War design/data

The canonical data under `data/` remains the source of truth, including 70 character profiles, 35 jobs across 7 classes and 5 tiers, monsters, maps, 300 equipment entries, 300 cards, pets, pet skills/equipment, quests/events and progression systems.

## Runtime evidence

A build, launch, gameplay test, or screenshot is only marked PASS when an actual SharnouEngine runtime executes. Static source inspection alone is not runtime evidence.

© Sharnou — Honour War

## Automatic generation command

Use the authoritative local hand-off:

```powershell
powershell -File Tools/SharnouIDE/SharnouIDE.ps1 -Command auto
```

This compiles the SPP queue in Sharnou-IDE, invokes SharnouEngine native generation, and then runs the SharnouEngine canonical self-test. It is an explicit development action and is not a daily/background update system.
