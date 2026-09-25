# Honour War — Sharnou Engine Migration

Honour War's active engine is now Sharnou Engine, a custom native C++ engine.

## Replaced runtime engines

Unity and Unreal Engine 5.8 are no longer the active game runtime.

The previous Unity implementation is retained only as a legacy reference while native equivalents are migrated. No active Sharnou Engine build links against Unity or Unreal.

## Development environment

- Microsoft Visual Studio Community 2022
- MSVC C++20
- CMake
- vcpkg
- Windows 64-bit
- Direct3D 11 bootstrap renderer

## Migration rule

Existing Honour War design data and progression must be preserved. The migration is an implementation replacement, not a game-design reset.

The native engine must retain the existing:
- 7 classes
- 5 class tiers
- 70 class/gender profiles
- skills and scaling rules
- monsters and maps
- equipment, items and cards
- pets and pet skills/equipment
- quests/events
- character ageing and saved progression
- click-to-move controls
- @go X:Y coordinate travel
- real gameplay screenshot/runtime-test requirements

Additional native engine subsystems are to be implemented around this canonical data contract.
