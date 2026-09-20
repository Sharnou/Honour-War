# Honour War — Unreal Engine 5.8 HD MMORPG/ARPG

Development status: Unreal Engine 5.8 migration and HD 3D production foundation. Godot has been permanently retired.

## MMORPG HUD

Honour War is an MMORPG/ARPG, not a strategy game.

The HUD is driven by the two locked repository visual anchors:
- Screenshot/ChatGPT Image Sep 16, 2026, 12_22_47 AM.png
- Screenshot/image_a4469f29.jpg

Current reference-driven HUD:
- upper-left portrait/profile with name, level/class, HP/SP/EXP and age/honour;
- left Inventory / Character / Skills / Quests navigation;
- upper-right mail/social/settings controls;
- circular minimap with map coordinates, compass and time;
- active quest tracker;
- lower-left chat;
- lower-right Map / Bag / Shop / Party / Guild shortcuts.

Removed:
- center-bottom 8-slot COMBAT SKILLS HUD;
- standalone player panel;
- developer command toolbar;
- strategy/tower/army interface.

Skill hotkeys 1 through 8 remain functional gameplay inputs without rendering a bottom skill strip.

## Engine

Unreal Engine 5.8 is the sole runtime and Windows build target. No Godot runtime, project, scene, source file or workflow remains on main.

## Real screenshot rule

Only a screenshot captured from the running Unreal Engine 5.8 game/Windows EXE counts as game evidence. Generated artwork, reference images and mockups never count.

Run the packaged executable with the HonourWarCapture argument to produce:
Saved/Screenshots/HonourWar-real-runtime.png

The active Windows runner must actually build, launch and capture the executable before an EXE screenshot can be declared verified.

## Visual target

The world remains medieval/fantasy with detailed terrain, buildings, vegetation, props, monsters, full-body heroes, readable combat effects and bright daylight. Futuristic/scifi machinery, robots, transformers, factories, rockets and space presentation are excluded.

## Validation

The old Godot workflow run #1762, Match completeness contract to generated eight-slot combat bar, belongs to the retired Godot pipeline and is not a current game gate. The current contract is tools/unreal_engine_contract_qa.py and the current runtime gate is the Unreal Windows build/screenshot workflow.

## Copyright

© Sharnou — Honour War


## Fifth-tier class progression

The class tree has five tiers:
Tier 1 Foundation (Lv. 1), Tier 2 Specialization (Lv. 25), Tier 3 Advanced (Lv. 50), Tier 4 Mastery (Lv. 150), Tier 5 Transcendence (Lv. 200).

Tier 5 remains rooted in the original first-tier profession and preserves profession-specific weapon family, silhouette, equipment identity and skill lineage. Unreal exposes this through `EHonourWarClassTier` and `EHonourWarFifthTierArchetype`.

## Mouse-first MMORPG controls

Left click on ground moves the hero. Left click on a monster selects it and moves the hero into class-specific engagement range, then uses the basic attack. Right-mouse drag rotates the camera. Mouse wheel zooms the camera. W/A/S/D remains available as a secondary control scheme.
