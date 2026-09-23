# Honour War — Permanent Exclusions

This file is a project-level design constraint.

Honour War is an HD 3D anime-inspired MMORPG/ARPG. The following systems and design directions are permanently rejected and must not be regenerated:

- Soldier systems, soldier level caps, automatic soldier skills, soldier death replacement, soldier squad production, soldier commander systems, and soldier-based reward routing.
- Guarded income banks or any soldier-occupied income-bank economy.
- Defense towers, tower-defense combat, strategy-war bases, strategy construction systems, or other strategy-war mechanics.
- Base-building systems and base sight/minimap overlays.
- Skill shrine and soldier workshop layers.
- Building/construction UI tools or a build-mode/menu overlay.
- Player-vs-player server-authoritative combat, team-slot combat, and server-authoritative monster-damage wrappers.
- Monsters spawning inside the city. Runtime monster spawn positions must remain outside the permanent city exclusion radius.
- Transformer/futuristic machinery designs.
- GLB and GLTF assets/exporters/runtime intake. Approved runtime interchange remains FBX and OBJ.

This exclusion document is authoritative for future implementation and art generation. A future change that conflicts with it must fail QA instead of silently reintroducing the rejected feature.


## Engine and city-building hard exclusion

- Unreal Engine 5.8 is the only supported engine for Honour War.
- Godot of any version is permanently removed. Godot project files, scenes, scripts, shaders, export presets, generated artifacts, and Godot-specific runtime/generation tooling must not exist or be regenerated.
- The following city-building options are permanently rejected and must never be generated, restored, or exposed in runtime/UI/data/generators:
  1. Town Hall
  2. Blacksmith
  3. Market
  4. Barracks
  5. Magic Tower
  6. City resources
  7. City upgrades
- Permanent exclusion QA must hard-fail if any rejected city feature or Godot artifact returns to an active runtime, data, generator, or project surface.


## 2026-09-22 validation pass
Monster runtime now uses the explicit eight-species level roster and enforces the city exclusion radius before spawn.

## Permanent city-building/service prohibition

Honour War is **not a strategy/base-building game**. The following are permanently removed from both generation and runtime design and must never be regenerated, restored, exposed, or connected to gameplay:

- Rejected city-building assets.
- City service implementations.
- Town Hall generation.
- Blacksmith generation.
- Market generation.
- Barracks generation.
- Magic Tower generation.
- City resource generation.
- City upgrade generation.
- Town Hall, Blacksmith, Market, Barracks, and Magic Tower entities/components in the World Director.
- Any associated build/service implementations, construction actions, building dependencies, building connections, building-linked skills, or skill effects that activate/connect buildings.
- Any build mode, construction menu, building target selector, city-service command, or strategy-building progression.

These exclusions are absolute. Do not implement them as hidden, disabled, placeholder, debug-only, optional, future, or unused systems. Any future generator or runtime change containing these systems must fail the permanent-exclusion QA gate.
