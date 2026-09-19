# Honour War — Neural4D Regeneration Manifest

Status: APPROVED SOURCE PLAN
Date: 2026-09-20

Purpose: regenerate the retired visual asset set without Meshy and without GLB.

Generation source: Neural4D.
Preferred export: FBX for animated/rigged characters, pets and monsters; OBJ only for static assets.
Forbidden export: GLB.
Final runtime: native Godot 4.7.2 scenes/resources.

## Shared generation requirements
- Use the matching Honour War reference image(s) from `Screenshot/`.
- Preserve recognizable class/monster/pet identity.
- Full character body must be visible, including face and legs.
- High-detail realistic/Ragnarok-inspired fantasy 3D presentation.
- PBR materials, clean normals, UVs, production topology.
- No text, logos, watermarks or unrelated props on the model.
- Humanoid characters: production-ready rig/A-pose or T-pose suitable for animation.
- Creatures/pets: production-ready rig where combat animation requires it.
- Generate each asset independently; do not merge unrelated actors.
- Final imported asset must pass Godot Forward+ D3D12 runtime QA.

## Characters — 30 assets
Acolyte: Advanced, Foundation, Mastery, Specialization, Transcendence
Archer: Advanced, Foundation, Mastery, Specialization, Transcendence
Mage: Advanced, Foundation, Mastery, Specialization, Transcendence
Merchant: Advanced, Foundation, Mastery, Specialization, Transcendence
Thief: Advanced, Foundation, Mastery, Specialization, Transcendence
Warrior: Advanced, Foundation, Mastery, Specialization, Transcendence

Character generation prompt basis:
"Honour War [CLASS] [TIER], full-body high-detail 3D fantasy MMORPG combat character, realistic proportions, complete face and legs visible, class-specific clothing, armor, weapon silhouette and materials, strong readable silhouette, production-ready humanoid topology, A-pose/T-pose, PBR materials, no environment, no text, no logo, no watermark."

## Monsters — 11 assets
- Bloody Knight
- Dragon
- Evil Druid
- Goblin
- Golem
- Mantis
- Orc
- Poring
- Skeleton
- Wolf
- Zombie

Monster generation prompt basis:
"Honour War [MONSTER], full-body high-detail 3D fantasy MMORPG monster, distinctive anatomy and silhouette, physically coherent proportions, detailed skin/armor/materials, combat-ready creature design, production-ready topology and normals, rig-ready where animation is required, isolated model, no text, no logo, no watermark."

## Pets — 12 assets
- Acolyte pet
- Arcane Orb
- Archer pet
- Clockwork
- Falcon
- Mage pet
- Merchant pet
- Panther
- Poring Angel
- Thief pet
- Warrior pet
- Wolf

Pet generation prompt basis:
"Honour War [PET], full-body high-detail 3D fantasy MMORPG companion, visually tied to its owner class, distinctive silhouette, combat companion proportions, detailed materials, expressive but readable face, rig-ready for combat animation, isolated model, no text, no logo, no watermark."

## Acceptance sequence
1. Generate asset in Neural4D.
2. Inspect all sides, silhouette, proportions, thin parts, hidden surfaces and materials.
3. Export FBX for rigged/animated assets or OBJ for approved static assets.
4. Import into Godot 4.7.2 without creating a GLB.
5. Normalize materials, animation, collision and LOD as native project resources.
6. Run deterministic CI validation.
7. Run actual in-game Forward+ D3D12 visual QA.
8. Reject and regenerate any asset that fails a gate.

## Source policy
Meshy is permanently rejected.
Neural4D is the approved optional regeneration source.
Neural4D GLB export is forbidden for Honour War.
Tripo 3D remains optional only if a future asset needs it and all project gates are met.
