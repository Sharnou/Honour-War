# Honour War — Permanent No-GLB / No-Meshy / Neural4D Asset Policy

Status: **PERMANENT**
Effective: 2026-09-20

## Mandatory retirement rules

The previous generated HD `.glb` asset library is permanently retired from Honour War.

Daily Honour War Upgrade and all future development work **must not**:
- restore or regenerate the retired HD GLB library;
- download or import generated GLB assets;
- attach generated GLB scenes at runtime;
- recreate `assets/3d/generated/**/*.glb`.

A repository search on 2026-09-20 found no current Meshy or GLB production assets on the main branch.

## Meshy is permanently rejected

Meshy is **rejected for all future Honour War asset generation**.

Daily upgrades and production tooling must not:
- use Meshy as an asset-generation dependency;
- generate production assets with Meshy;
- restore a Meshy-based asset pipeline;
- treat old Meshy-generated assets as acceptable source material.

If an old generated asset cannot be proven to have an approved source, it must be treated as retired and regenerated from an approved source.

## Neural4D is approved as an optional generation source

Neural4D may be used to regenerate the retired visual asset set, subject to the project's visual and technical QA gates.

**Neural4D is a generator, not a replacement file format.** Its documented exports include FBX, OBJ, BLEND, GLB, STL and USDZ. Honour War must **not** use its GLB export.

For game characters, pets and monsters, the preferred Neural4D handoff is:
1. Generate from approved Honour War visual references and written asset briefs.
2. Prefer **FBX** for rigged/animated characters and creatures.
3. Prefer **OBJ** only for assets where rigging/animation is not required.
4. Import the approved source into Godot 4.7.2 using the supported importer.
5. Convert/normalize it into the project's native Godot scene/resource structure.
6. Keep the final runtime presentation native to Godot: meshes, materials, animation, shaders, lighting, VFX and scenes.
7. Do not commit or introduce a generated GLB as an intermediate production dependency.

Neural4D generation must not silently replace the project's gameplay systems, class identity, progression, skill effects, pet systems, monster roles, or visual reference requirements.

## Required Neural4D quality gates

Every regenerated asset must pass:
1. visual silhouette and proportions against `Screenshot/`;
2. full-body visibility for humanoids, including face and legs;
3. correct class/monster/pet identity;
4. topology and normals;
5. material and PBR assignment;
6. UV/texture integrity;
7. rig/skeleton and animation requirements where applicable;
8. collision and LOD/performance requirements;
9. Forward+ D3D12 compatibility;
10. deterministic CI validation;
11. actual in-game visual QA;
12. licensing/commercial-use verification for the Neural4D account and generation used.

## Preferred production pipeline

The production runtime remains native Godot 4.7.2 scenes/resources and scenes.

Neural4D is an **asset-generation source only**. It does not change the runtime architecture and does not authorize restoration of the retired GLB pipeline.

The repository `Screenshot/` folder remains the authoritative visual reference for the intended game appearance. Reference screenshots must not be embedded into the game as a substitute for real graphics.

## Daily upgrade gate

Every Daily Honour War Upgrade must verify:
- no `.glb` files exist under `assets/3d/generated/`;
- Meshy is not present as a production generation dependency;
- no retired Meshy-generated asset is restored;
- Neural4D, when used, is documented as the generation source;
- approved Neural4D assets use an allowed non-GLB handoff such as FBX/OBJ;
- the final runtime remains native Godot;
- the retired generated-HD-GLB pipeline is not restored.

The existing gameplay systems and game requirements must remain intact.
