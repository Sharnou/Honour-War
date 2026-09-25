# Honour War — Sharnou Engine 3D HD MMORPG/ARPG

Development status: **native Sharnou Engine migration**. Unity and Unreal Engine 5.8 are no longer the active game runtime.

## Permanent project identity

- **Game engine:** Sharnou Engine
- **IDE/toolchain:** Microsoft Visual Studio Community 2022 / MSVC
- **Language:** C++20
- **Build system:** CMake
- **Dependency manager:** vcpkg
- **Platform:** Windows 64-bit
- **Game style:** 3D HD MMORPG/ARPG
- **Movement:** Ragnarok Online-style click-to-move; no WASD movement
- **Graphics bootstrap:** native Direct3D 11

The Sharnou Engine runtime lives under Engine/SharnouEngine/.

## Preserved Honour War design/data

The canonical data under data/ remains the source of truth:

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

## Native runtime foundation

The current native engine slice provides:

- Win32 game window and engine loop
- Direct3D 11 renderer
- native Honour War data validation
- click-to-move movement
- right-drag camera orbit
- mouse-wheel camera zoom
- monster target selection
- eight skill inputs
- @go MAP X:Y command routing
- persistent character save data
- startup self-test across all 7 classes and 8 skill slots

The native engine is the active runtime architecture. Legacy Unity files are archived under Legacy/Unity so the previous prototype remains recoverable without remaining an active dependency.

## Art pipeline

GLB/GLTF remains rejected as project intake. Approved flow remains:

Visual RAG/reference analysis → Neural4D or Blender processing → FBX/OBJ → Sharnou Engine asset import/validation → runtime validation → real gameplay screenshot.

## Runtime evidence

A build, launch, gameplay test, or screenshot is only marked PASS when the native Sharnou Engine executable actually executes. Static source inspection alone is not treated as runtime evidence.

## Copyright

© Sharnou — Honour War
