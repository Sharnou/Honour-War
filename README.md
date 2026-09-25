# Honour War — Sharnou Engine 3D HD MMORPG/ARPG

Development status: **native Sharnou Engine migration**. Sharnou Engine and Sharnou IDE are the permanent active stack. Unity and Unreal Engine 5.8 are not active game runtime dependencies.

## Permanent project identity

- **Game engine:** Sharnou Engine
- **IDE:** Sharnou IDE
- **Authoring protocol:** Sharnou Project Protocol (SPP)
- **Native runtime language:** C++20
- **Platform:** Windows 64-bit
- **Game style:** 3D HD MMORPG/ARPG
- **Movement:** Ragnarok Online-style click-to-move; no WASD movement
- **Graphics bootstrap:** native Direct3D 11 runtime layer

Honour War is launched and validated through `Sharnou-IDE`. Direct Visual Studio/MSBuild/Windows SDK/CMake/vcpkg/Unity/Unreal project paths are rejected by policy. The IDE does not download or bootstrap external programming tools.

## Preserved Honour War design/data

The canonical data under `data/` remains the source of truth:

- 70 character profiles
- 35 jobs across 7 classes and 5 tiers
- 256 monsters
- 24 maps
- 300 equipment entries
- 76 general items
- 300 cards
- 20 pets
- 120 pet skills
- 100 pet equipment entries
- class skills and 8% per-level scaling contract
- quests/events, visual profiles, affixes and audio manifests

## Sharnou IDE → Sharnou Engine workflow

1. Sharnou IDE validates `Tools/SharnouIDE/honour-war.spp.json`.
2. Sharnou IDE compiles the SPP project into engine-consumable JSON bytecode.
3. The Sharnou Engine bridge verifies the canonical IDE and engine identities and selects only an approved existing `SharnouEngine.exe` runtime.
4. Self-test/runtime-test/run are executed only through the Sharnou IDE session.
5. No external compiler/toolchain download is performed by the project.

## Runtime evidence

A build, launch, gameplay test, or screenshot is only marked PASS when the native Sharnou Engine executable actually executes. Static source inspection alone is not runtime evidence.

## Art pipeline

GLB/GLTF remains rejected as project intake. Approved flow remains:

Visual RAG/reference analysis → Neural4D or Blender processing → FBX/OBJ → Sharnou Engine asset import/validation → runtime validation → real gameplay screenshot.

## Copyright

© Sharnou — Honour War
