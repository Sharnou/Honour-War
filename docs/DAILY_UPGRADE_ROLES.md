# Honour War — Daily Upgrade Roles

This is a permanent development contract for every future upgrade pass.

## 1. Continue in place
- Preserve the existing Godot architecture and working systems.
- Upgrade the repository in place; do not restart the game from a clean template.
- Prefer production systems and authored assets over cosmetic placeholder layers.

## 2. Automated quality loop
For each requested fix or feature:
1. Inspect the current implementation and the newest failing Action.
2. Make the smallest architecture-compatible correction.
3. Run the relevant Godot validation and regression gates.
4. Inspect the newest Action result before beginning another correction.
5. If the same defect has been attempted three times without clearing the gate, stop repeating that approach and move to a fresh implementation path or independent diagnostic approach.

## 3. Independent engineering review
When a blocker survives repeated attempts, the upgrade pass may consult another engineering/AI implementation approach for a fresh diagnosis. The alternative approach must still be validated against the repository's actual Godot version and architecture.

## 4. Visual production path
The baseline art pipeline is:

Visual reference/RAG -> Blender -> Substance 3D Painter handoff -> GLB/GLTF -> Godot 4.7.x.

Generated geometry is a development fallback only. Production authored GLB/GLTF assets take precedence at runtime.

## 5. Current gameplay contract
- SS (SUPER SHAMBION) is rental-only and is never a character-creation class.
- Rent NPC is the only acquisition path; rental price is 1,000,000 Zeny.
- SS follows the real hero, heals the hero and itself automatically, and fights using Asura Strike.
- SS equipment and status points are owner-editable while rented.
- The equipment interface exposes GO to end the rental.
- SS starts at level 0 and uses the owner's character age.
- Do not reintroduce soldier production, soldier banks, guarded bank income, soldier death batching, or whole-game tower-defense systems.
- Hero maximum level remains 250; monster maximum level remains 300.
- Character-age effects must not alter the base database drop-rate values.

## 6. Release gates
A feature is not considered complete until the relevant gates pass:
- Godot script/scene import validation.
- SS rental regression when SS changes.
- GLB semantic/PBR validation when assets change.
- Windows export and executable smoke test for release-impacting changes.
