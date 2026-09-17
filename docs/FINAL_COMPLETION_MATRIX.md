# Honour War — Final Completion Matrix

Target runtime: **Godot 4.7.2 stable**. Godot 4.7 is the project feature target.

## Release gates

1. **Engine/runtime** — project imports without script/scene parse errors on Godot 4.7.2.
2. **Playable shell** — `Main3D.tscn` is the main scene, Forward+ is selected, camera/movement systems load, and the legacy state owner remains available.
3. **Hero progression** — level cap 250, class advancement, skill trees, equipment, refinement materials, age progression, save/restore.
4. **Combat** — class combat ranges, skills, damage feedback, VFX, pet combat, and combat animation presentation.
5. **Pets** — every playable class receives its bonded pet; pet progression and combat are retained through level 250.
6. **World** — towns, fields, dungeons, monsters, generated 3D asset inventory, warp gates, and coordinate travel (`@go MAP X:Y`).
7. **MMORPG cities** — towns provide NPC/services such as healing, shops, equipment/refinement, card/item services, quests and social interaction. Cities are hubs only; no army, production, bank, territory-control or tower-defense loop exists.
8. **Online authority** — authenticated peers, server-side movement/warp validation, authoritative event broadcast, disconnect persistence.
9. **Accounts/persistence** — account registration/login, player persistence, and local save/restore contracts pass.
10. **Parties** — four-player party creation/invite/accept flow and authentication requirements pass.
11. **HD presentation** — Visual RAG → Blender → Substance 3D Painter → GLB/GLTF → Godot 4.7 remains the target for authored final assets; generated assets are validated by CI.
12. **Windows release** — Windows x86_64 export uses Godot export templates and produces a playable `.exe` package.

## Automated validation order

`godot-validation` → `game-completeness` → `online-authority` → `server-smoke` → `persistence` → `party` → `world-state` → Windows export.

A failure is a release blocker; do not hide it by disabling the test.

## Current production gaps

The repository has a validated gameplay foundation, but a commercially finished MMORPG still requires authored production character/monster/environment assets, complete animation libraries, production server/database deployment, authentication hardening, anti-cheat, scalable world streaming, matchmaking/live-operations infrastructure, production audio, and large-scale performance testing. These are genuine production deliverables and must not be represented as complete merely because deterministic CI contracts pass.

## Permanent architecture boundary

Honour War is an **MMORPG/ARPG only**. Future upgrade passes must never reintroduce soldiers, soldier production, banks, tower-defense, barracks or strategy-city mechanics.
