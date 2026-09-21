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
