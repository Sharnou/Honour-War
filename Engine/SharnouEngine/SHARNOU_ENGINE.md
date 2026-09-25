# Sharnou Engine — Honour War

Sharnou Engine is the **only active game engine** for Honour War.

## Permanent project baseline

- Engine: **Sharnou Engine**
- IDE: **Sharnou IDE**
- Authoring protocol: **Sharnou Project Protocol (SPP)**
- Runtime: native Windows 64-bit C++20
- Graphics backend: Direct3D 11 bootstrap renderer
- Game style: **3D HD MMORPG/ARPG**
- Input: Ragnarok-style click-to-move and camera controls; no WASD movement

## Toolchain policy

Honour War does **not** use or download Visual Studio, MSBuild, Windows SDK development packages, CMake, vcpkg, Unity, Unreal Engine, or any other external programming-tool bundle as part of the project workflow.

Sharnou IDE is the authoritative authoring, validation, protocol-compilation, launch, and runtime-test controller. The repository does not claim that native C++ source can be rebuilt without a compiler and the platform interfaces required by that compiler; instead, the normal project workflow is runtime-first and never bootstraps those tools automatically.

## Honour War data contract

The engine consumes the repository's canonical data rather than discarding it:

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
- 8 skills per job with the existing skill-level scaling rules

The canonical JSON files remain under `data/` and are loaded/validated by the native runtime.

## Runtime responsibilities

The active runtime foundation covers the native game window/render loop, Direct3D 11 rendering, Honour War data validation, click-to-move movement, camera orbit/zoom, monster target selection, eight skill slots, `@go MAP X:Y` routing, persistent save data, and startup self-test.

A runtime executable is only marked PASS after actual execution. Source inspection alone is not runtime evidence.

## Art pipeline

GLB/GLTF remains rejected as project intake. Approved flow:

Visual RAG/reference analysis → Neural4D or Blender processing → FBX/OBJ → Sharnou Engine asset import/validation → runtime validation → real gameplay evidence.

## Migration boundary

Legacy Unity/Unreal material is retained only as historical/recovery material where present. It is not an active runtime dependency.
