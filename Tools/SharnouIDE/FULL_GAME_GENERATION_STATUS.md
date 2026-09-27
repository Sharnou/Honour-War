# Honour War — Full-Game Generation Status

## Canonical stack

- Project: `honour-war`
- IDE/controller: `Sharnou-IDE`
- Game/runtime engine: `SharnouEngine`
- Protocol: Sharnou Project Protocol (SPP)
- Daily/background update system: disabled

## Generation package completed

The repository contains the canonical full-game SPP program and handoff seed:

- `Tools/SharnouIDE/project/main.spp`
- `Tools/SharnouIDE/project/full-game.spp`
- `Build/Runtime/honour-war.sppc.json`
- `Build/Runtime/honour-war.full-generation.json`

The generated SPP handoff contains 22 commands:

- 1 canonical project bind
- 17 full-game generation domains
- player spawn
- startup position
- mesh binding
- AVIF visual binding

## Canonical content covered

70 character profiles, 7 classes, 35 jobs, 280 class-skill entries, 256 monster variants, 24 maps, 300 equipment entries, 76 general items, 300 cards, 20 pets, 120 pet skills, 100 pet equipment entries, 797 encyclopedia entries, 12 quests, and 6 world events.

## Runtime format contract

- `.gltf` / `.glb`: 3D scene/model containers
- `.ktx2`: 3D material textures
- `KHR_texture_basisu`: glTF KTX2 binding
- `.avif`: shipped raster/2D visual format
- `.fbx` / `.obj`: source/interchange model inputs
- any registered source format: accepted at the Sharnou-IDE input boundary and converted/validated when supported

## Runtime gate

A real gameplay PASS requires the actual approved `SharnouEngine.exe` executable to run through Sharnou-IDE.

Current repository audit on 2026-09-27 reports:

- `.gltf` files: 0
- `.glb` files: 0
- `.ktx2` files: 0
- `.avif` files: 0
- `SharnouEngine.exe` files: 0

Therefore the source-generation contract is complete, but the native executable and actual binary 3D/texture asset generation have not been falsely marked as completed.

## Approved execution handoff

Once an approved SharnouEngine executable exists in one of the manifest runtime locations, Sharnou-IDE runs:

`powershell -File Tools/SharnouIDE/SharnouIDE.ps1 -Command full-generate`

No external engine, external IDE, compiler/SDK download, or automatic daily update system is used by this handoff.
