# Honour War — Unreal Engine 5.8 HD UI Specification

## Player HUD

The player-facing interface is a clean non-diegetic MMORPG HUD:

- upper-left: character class, level, age, HP, SP and EXP;
- upper-center: target status;
- upper-right: minimap/world-map panel and zone landmarks;
- lower-left: compact chat dock;
- center-bottom: COMBAT SKILLS, eight large readable slots, keyboard 1–8;
- contextual windows for character, inventory, equipment, pet, skills, refinement and system settings.

## Visual language

Use dark translucent panels, thin warm metallic/gold borders, high-contrast text, compact spacing and strong title hierarchy. Icons must remain recognizable at 1920×1080 and scale cleanly.

## Skill bar

The eight-slot bar is the primary combat surface. Each slot has:
- key number;
- class-specific skill icon;
- skill name/short label;
- cooldown feedback;
- unavailable/out-of-range feedback;
- active/cast feedback;
- hover tooltip.

No old developer/command toolbar is displayed.

## World labels

Local player names are hidden in the 3D world. Remote names are hidden by default and may appear for hover, party/PvP context or explicit social reveal. Enemy combat health bars remain permitted.

Permanent player HP/SP bars under characters are not used.

## Windows

Inventory, equipment, skill tree, pet, refinement, quest and social windows share the same panel language and safe-area spacing. Settings include UI scale and reduced-motion controls.

## Feedback

Every player action produces visible accepted/rejected/cooldown/completed feedback. Combat feedback uses animation, sound, hit VFX and concise floating text without obscuring the playfield.
