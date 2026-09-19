# Honour War — Permanent No-GLB / No-Meshy Asset Generation Policy

Status: **PERMANENT**
Effective: 2026-09-19

## Mandatory rule

The generated HD `.glb` asset library is permanently retired from Honour War.

Daily Honour War Upgrade and all future development work **must not**:
- regenerate HD GLB character, pet, monster, or MVP assets;
- download HD GLB assets;
- import HD GLB assets into Godot;
- attach generated GLB scenes at runtime;
- recreate the retired `assets/3d/generated/**/*.glb` library.

## Meshy is permanently rejected

Meshy is **rejected for all future Honour War asset generation**.

Daily upgrades must not:
- use Meshy as an asset-generation dependency;
- generate production assets with Meshy;
- restore a Meshy-based replacement for the retired GLB pipeline.

## Tripo 3D is optional, not an automatic GLB replacement

Tripo 3D may be considered as an **optional external concept/model-generation source** for a specific future asset.

Using Tripo 3D does **not** mean that GLBs should be regenerated or restored.

Any Tripo-generated asset must first pass a defined project pipeline covering:
1. visual design and topology requirements;
2. runtime format and import requirements;
3. materials and textures;
4. animation requirements;
5. collision and LOD/performance requirements;
6. licensing and usage rights;
7. Forward+ D3D12 compatibility;
8. deterministic CI validation;
9. actual in-game visual QA.

Until those gates are satisfied, a Tripo-generated asset must not become a production dependency.

## Preferred production visual pipeline

The authoritative production runtime remains native Godot resources and scenes: meshes, materials, shaders, animation, lighting, terrain, VFX, UI, and gameplay presentation.

The repository `Screenshot/` folder remains the authoritative visual reference for the intended game appearance.

## Daily upgrade gate

Every Daily Honour War Upgrade must verify that:
- no `.glb` files exist under `assets/3d/generated/`;
- Meshy is not introduced as a generation dependency;
- the retired generated-HD-GLB pipeline is not restored.

The existing gameplay systems and game requirements must remain intact.

## Visual objective

Improve the native Godot runtime toward the quality shown in `Screenshot/`. Reference screenshots must not be embedded into the game as a substitute for real game graphics.
