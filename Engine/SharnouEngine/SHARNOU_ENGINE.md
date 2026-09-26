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

Sharnou IDE is the authoritative authoring, validation, protocol-compilation, launch, and runtime-test controller. A native `SharnouEngine.exe` is generated only by the self-contained Sharnou compiler declared by the toolchain contract. The repository fails closed when that compiler is not present; it never downloads a replacement compiler or SDK automatically.

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

Runtime 3D scenes/models use glTF 2.x (`.gltf`/`.glb`), shipped 3D material textures use KTX2 (`.ktx2`) with `KHR_texture_basisu` where applicable, and 2D/UI/distribution raster visuals use AVIF (`.avif`). FBX/OBJ remain authoring/interchange inputs and are converted before runtime packaging.

## Migration boundary

Legacy Unity/Unreal material is retained only as historical/recovery material where present. It is not an active runtime dependency.
