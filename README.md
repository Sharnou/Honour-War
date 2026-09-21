# Honour War — Unreal Engine 5.8 HD MMORPG/ARPG

Development status: Unreal Engine 5.8 HD 3D production foundation. Godot has been permanently retired.

## Permanent visual identity

Honour War is permanently defined as an HD 3D anime-inspired MMORPG/ARPG with a medieval/fantasy world, full-body 3D characters, class-specific equipment, expressive animation, readable combat VFX, dense environments and a compact MMORPG HUD.

The visual target is regenerated from the locked repository reference images on every development visual cycle. A completed cycle is not accepted until the regenerated brief, refreshed production assets, Unreal runtime validation and real EXE screenshot agree with the visual contract.

The authoritative visual source is the Screenshot/ folder. Visual production uses the approved pipeline:
Visual RAG/reference analysis → gap register → visual brief regeneration → Neural4D or Blender → Substance 3D Painter → FBX/OBJ → Unreal Engine 5.8 → runtime validation → real EXE screenshot → reference comparison.

## MMORPG controls and camera

The interaction model is permanently Ragnarok Online-inspired desktop MMORPG control, implemented independently in Unreal:

- Left click ground: click-to-move.
- Left click living monster: select target, move into the class engagement range, then perform the basic attack.
- Right-mouse hold + drag: orbit the perspective/isometric camera horizontally and vertically.
- Mouse wheel: smooth bounded camera zoom.
- W/A/S/D: secondary direct movement.
- 1–8: gameplay skill inputs without requiring a bottom skill strip.
- Q: reset camera framing.

The camera remains a perspective, elevated isometric-style MMORPG camera with the complete hero visible during normal gameplay. Camera framing, movement, targeting and zoom are gameplay contracts, not optional presentation features.

## MMORPG HUD

The HUD is driven by the two locked repository visual anchors:
- Screenshot/ChatGPT Image Sep 16, 2026, 12_22_47 AM.png
- Screenshot/image_a4469f29.jpg

Current reference-driven HUD:
- upper-left portrait/profile with name, level/class, HP/SP/EXP, age and honour;
- circular minimap with map coordinates, compass and time;
- active quest tracker;
- lower-left world chat with editable message input;
- compact MMORPG combat/economy status.

Removed permanently:
- build/menu overlay panels and construction UI;
- soldier, squad, workshop and tower systems;
- base-building and base-sight overlays;
- strategy-war controls;
- player-vs-player team combat controls.

## Engine

Unreal Engine 5.8 is the sole runtime and Windows build target. No Godot runtime, project, scene, source file or workflow is part of the active game.

## Real screenshot rule

Only a screenshot captured from the running Unreal Engine 5.8 game/Windows EXE counts as game evidence. Generated artwork, reference images and mockups never count.

Run the packaged executable with the HonourWarCapture argument to produce:
Saved/Screenshots/HonourWar-real-runtime.png

The active Windows runner must actually build, launch and capture the executable before an EXE screenshot can be declared verified.

## Visual target

The world remains medieval/fantasy with detailed terrain, buildings, vegetation, props, monsters, full-body heroes, readable combat effects and bright daylight. Futuristic/scifi machinery, robots, transformers, factories, rockets and space presentation are excluded.

## Validation

The active release gate is tools/rejected_systems_qa.py plus tools/unreal_engine_contract_qa.py and the Unreal Windows build/runtime screenshot workflows. Retired Godot validation is not a current game gate.

## Fifth-tier class progression

The class tree has five tiers:
Tier 1 Foundation (Lv. 1), Tier 2 Specialization (Lv. 25), Tier 3 Advanced (Lv. 50), Tier 4 Mastery (Lv. 150), Tier 5 Transcendence (Lv. 200).

Tier 5 remains rooted in the original first-tier profession and preserves profession-specific weapon family, silhouette, equipment identity and skill lineage. Unreal exposes this through EHonourWarClassTier and EHonourWarFifthTierArchetype.

## Copyright

© Sharnou — Honour War
