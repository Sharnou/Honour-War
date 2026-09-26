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

Honour War is launched and validated through Sharnou-IDE. The project rejects Visual Studio, MSBuild, Windows SDK development installations, CMake, vcpkg, Unity, Unreal Engine, and automatic external programming-tool downloads. Sharnou-IDE is the authoritative project controller.

## Sharnou-IDE → SharnouEngine workflow

1. Sharnou-IDE identifies the project as canonical `honour-war`.
2. Sharnou-IDE validates `Tools/SharnouIDE/honour-war.spp.json` against the SharnouEngine contract.
3. SPP is compiled to engine-consumable JSON bytecode by Sharnou-IDE.
4. The engine bridge verifies the canonical IDE, project and engine identities.
5. Only an already-existing approved SharnouEngine runtime is eligible for launch.
6. No external compiler, IDE, build system or programming-tool download is performed.

## IDE conversion policy

Existing Honour War IDE/project metadata is treated as migration input and converted to the Sharnou-IDE SPP contract. Non-Sharnou IDEs are not runtime controllers for Honour War. The repository's policy gates reject active `.sln`, `.slnx`, `.vcxproj`, CMake and vcpkg build paths outside legacy/archive areas.

## Asset format policy

Honour War uses a role-specific runtime asset strategy:

- **glTF 2.x (`.gltf` / `.glb`)** for 3D scene/model containers.
- **KTX2 (`.ktx2`)** for shipped GPU-facing 3D material textures; glTF assets using Basis Universal textures use `KHR_texture_basisu`.
- **AVIF (`.avif`)** for UI, menu/background artwork, icons, skyboxes and other 2D/distribution raster imagery.
- **FBX/OBJ** are authoring/interchange inputs and are converted before runtime packaging.

Existing historical reference images can remain as references; they are not new generated runtime assets.

Approved model intake remains FBX/OBJ through:

Visual RAG/reference analysis → Neural4D or Blender processing → FBX/OBJ → Sharnou Engine asset validation → runtime validation.

glTF/GLB is the approved runtime 3D container. FBX/OBJ remain authoring/interchange inputs and are not shipped runtime model formats.

## Preserved Honour War design/data

The canonical data under `data/` remains the source of truth, including 70 character profiles, 35 jobs across 7 classes and 5 tiers, monsters, maps, 300 equipment entries, 300 cards, pets, pet skills/equipment, quests/events and progression systems.

## Runtime evidence

A build, launch, gameplay test, or screenshot is only marked PASS when an actual SharnouEngine runtime executes. Static source inspection alone is not runtime evidence.

© Sharnou — Honour War
