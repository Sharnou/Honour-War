# Honour War — Final Completion Matrix

Target runtime: **Godot 4.7.2 stable**. Godot 4.7 is the project feature target. The official Godot archive lists 4.7 stable, and current Windows downloads are on the 4.7.x line. citeturn0search3turn0search6

## Release gates

1. **Engine/runtime** — project imports without script/scene parse errors on Godot 4.7.2.
2. **Playable shell** — `Main3D.tscn` is the main scene, Forward+ is selected, camera/movement systems load, and the legacy state owner remains available.
3. **Hero progression** — level cap 250, class advancement, skill trees, equipment, refinement materials, age progression, save/restore.
4. **Combat** — class combat ranges, skills, damage feedback, VFX, pet combat, and combat animation presentation.
5. **Pets** — every playable class receives its bonded pet; pet progression and combat are retained.
6. **World** — towns, dungeons, monsters, generated 3D asset inventory, warp gates, and coordinate travel (`@go MAP X:Y`).
7. **City/army** — city/base production, soldiers, tower-defense and bank/territory gameplay remain part of the production design and must be exercised by gameplay QA before final public release.
8. **Online authority** — authenticated peers, server-side movement/warp validation, authoritative event broadcast, disconnect persistence.
9. **Accounts/persistence** — account registration/login, player persistence, and local save/restore contracts pass.
10. **Parties** — four-player party creation/invite/accept flow and authentication requirements pass.
11. **HD presentation** — Blender → Substance 3D Painter → GLB/GLTF → Godot 4 pipeline remains the target for authored final assets; generated assets are validated by CI.
12. **Windows release** — Windows x86_64 export uses Godot export templates and produces a playable `.exe` package. Godot's documented command-line release export is `--export-release` with a Windows preset. citeturn0search0turn0search2

## Automated validation order

`godot-validation` → `game-completeness` → `online-authority` → `server-smoke` → `persistence` → `party` → `world-state` → Windows export.

A failure is a release blocker; do not hide it by disabling the test.

## Important boundary

A CI-passing prototype is not the same thing as a commercially finished MMORPG. Final authored character meshes, animation sets, environment art, networking infrastructure, anti-cheat, matchmaking/server operations, database deployment, and large-scale performance testing still require production work outside a text-only repository patch. The matrix deliberately keeps those gates explicit rather than marking them complete prematurely.
