# Honour War — Immediate HD 3D Generation Runbook

Status: READY TO EXECUTE
Target engine: Godot 4.7.2
Generation source: Neural4D
Runtime handoff: FBX for rigged/animated assets; OBJ only for approved static assets

## What is being generated

The retired visual library is replaced by a controlled 53-asset regeneration queue:
- 30 class/tier characters: 6 classes × 5 tiers
- 11 monsters
- 12 pets

The repository already contains the authoritative visual reference material in `Screenshot/`. The queue and prompts are designed to preserve the full-body, class-specific and high-detail requirements.

## Phase 1 — generate a six-character pilot

Run one asset for each base class first:
```text
python3 tools/neural4d_batch_generate.py --only character_acolyte_advanced character_archer_advanced character_mage_advanced character_merchant_advanced character_thief_advanced character_warrior_advanced
```

Use PBR generation. The current API workflow is asynchronous: submit a generation, poll the returned UUID, then request the approved FBX conversion. Neural4D documents text-to-3D generation, UUID polling, and FBX/OBJ conversion in its API documentation. citeturn2search2turn2search0

## Phase 2 — inspect before scaling

For every pilot asset:
1. Verify full face, hair, torso, hands, legs and boots are present.
2. Verify the class silhouette and weapon are immediately identifiable.
3. Verify no floating, merged or unrelated geometry.
4. Verify UVs, PBR materials, normals and scale.
5. Verify rig/skeleton exists for characters, monsters and pets that require combat animation.
6. Reject and regenerate failures rather than patching a bad model into the game.

Do not accept an asset merely because it looks good in the Neural4D viewer.

## Phase 3 — import into Godot

Place approved FBX assets under:
`assets/3d/neural4d/incoming/<category>/`

Godot 4.7.2 supports FBX through its ufbx importer; OBJ is supported but is unsuitable for skeletons/animation/PBR-heavy character workflows. Therefore characters, monsters and animated pets stay FBX. citeturn3search0

Create native Godot scenes/resources from the imported assets:
- `CharacterBody3D` / actor root
- `Skeleton3D` and `AnimationPlayer` where supplied
- native `StandardMaterial3D`/PBR resources
- collision shapes
- LOD/performance settings
- class/pet/monster metadata
- native scene instantiation from the existing gameplay systems

The FBX is an approved source handoff, not the final gameplay architecture.

## Phase 4 — replace procedural visuals

Only after the pilot passes QA:
1. Connect the Acolyte/Archer/Mage/Merchant/Thief/Warrior base visuals.
2. Connect the five progression tiers for each class.
3. Connect all 11 monster visuals.
4. Connect all 12 pet visuals.
5. Preserve all existing gameplay systems, progression, skills, combat, pets, teleport, city, soldier, banking, save and multiplayer logic.
6. Keep the procedural actor construction only as a missing-asset fallback until every approved asset is wired.

## Phase 5 — actual game QA

Run, in order:
1. Godot project validation.
2. Full gameplay runtime QA.
3. Game completeness regression.
4. Windows EXE smoke test.
5. Real running-game screenshot capture at 1920×1080.
6. Human visual inspection of the screenshot.
7. Repeat generation/import for any asset that fails visual inspection.

The screenshot is a hard gate: the hero must be fully visible, the town/terrain must read clearly, and the game must no longer look like the current procedural blockout.

## Batch cost and timing

The current 53-item text-generation queue is 53 generation calls plus one format conversion per asset. Neural4D currently documents 60 credits for text-to-3D generation and 10 credits for format conversion, before retries. That makes the nominal full queue 3,710 credits. Image-to-3D is a separate, higher-cost path and is preferable when an exact screenshot silhouette must be reproduced. citeturn2search0turn2search1

## Security

Never commit the Neural4D API key. Set it only in the local shell/CI secret:
`NEURAL4D_API_KEY`

Example:
```text
NEURAL4D_API_KEY=<your-private-key>
python3 tools/neural4d_batch_generate.py --limit 6
```

## Hard project rules

- Meshy remains rejected.
- The retired generated binary visual library is not restored.
- Do not introduce a forbidden runtime interchange format.
- Final runtime remains native Godot 4.7.2 scenes/resources.
- Generated assets are accepted only after actual in-game visual QA.
