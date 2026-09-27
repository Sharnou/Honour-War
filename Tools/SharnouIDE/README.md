# Honour War — Sharnou IDE integration

This folder is the authoritative Honour War integration point for Sharnou-IDE.

The project opens and validates through `Tools/SharnouIDE/SharnouIDE.ps1`. Sharnou-IDE is the only authoring/controller layer and SharnouEngine is the only Honour War runtime.

## Full-game generation

The canonical full-game SPP program is:

`Tools/SharnouIDE/project/main.spp`

It covers every current generation domain:

- characters
- class progression
- skills
- monsters
- pets
- equipment
- items
- cards
- refinement
- maps
- terrain
- architecture
- props
- animation metadata
- combat VFX metadata
- HUD and UI layout
- save/progression state

The IDE compiles this SPP handoff to `Build/Runtime/honour-war.sppc.json` and, when an approved `SharnouEngine.exe` already exists, routes `full-generate`, self-test, runtime-test, or run directly to that executable.

## Runtime asset roles

- `.gltf` / `.glb`: 3D scene/model containers
- `.ktx2`: compressed 3D material textures with `KHR_texture_basisu`
- `.avif`: shipped raster/2D visual assets
- `.fbx` / `.obj`: source/interchange model inputs
- any registered source format: accepted at the IDE intake boundary and converted when safely supported

## Tool policy

The active project does not invoke, install, download, or bootstrap another engine, another IDE, or unrelated programming tools. External compiler/SDK acquisition is never automatic.

## Runtime evidence

Static policy, source inspection and SPP compilation are not gameplay evidence. A gameplay PASS or screenshot PASS requires the actual approved SharnouEngine executable to run.
