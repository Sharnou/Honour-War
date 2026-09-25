# Sharnou Engine — Honour War

Sharnou Engine is the active custom native game engine for Honour War.

## Permanent project baseline

- Engine: Sharnou Engine
- Runtime: native Windows C++
- Compiler/toolchain: Microsoft Visual Studio Community 2022 / MSVC
- C++ standard: C++20
- Build system: CMake
- Package manager: vcpkg for third-party development dependencies
- Graphics backend: Direct3D 11 during the bootstrap renderer stage
- Target: Windows 64-bit
- Game: 3D HD MMORPG/ARPG
- Input: Ragnarok-style click-to-move and camera controls; no WASD movement

Unity and Unreal Engine are not runtime dependencies of the active Sharnou Engine build.

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

The canonical JSON files remain under data/ and are loaded by the native runtime.

## Current native runtime

The bootstrap runtime implements a real Win32 window and Direct3D renderer, a native Honour War gameplay loop, click movement, camera drag/zoom input, monster selection, eight skill slots, @go coordinate teleportation, persistent save data, catalog validation, and a startup self-test.

This is the first native engine runtime slice. It is not a claim that every production-grade MMORPG system, visual asset, network service, editor, animation system, renderer feature, and content pipeline is already finished.
