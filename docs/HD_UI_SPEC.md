# Honour War — Unreal Engine 5.8 MMORPG HUD Specification

Honour War is an MMORPG/ARPG, not a strategy game.

## Reference-driven layout

The player-facing HUD is rebuilt from the locked Honour War reference images:
- Screenshot/image_a4469f29.jpg
- Screenshot/ChatGPT Image Sep 16, 2026, 12_22_47 AM.png

The implementation follows their information hierarchy and visual placement while remaining an original Honour War UI.

## Visible HUD surfaces

Upper-left:
- portrait/profile treatment;
- character name;
- level and class;
- HP, SP and EXP;
- compact age/honour information.

Left side:
- Inventory;
- Character;
- Skills;
- Quests.

Upper-right:
- mail/social/system icon row;
- circular-style minimap with compass;
- map coordinates, zone and local time.

Right side:
- active quest tracker.

Lower-left:
- MMORPG chat with channel tabs, history and message entry.

Lower-right:
- Map;
- Bag;
- Shop;
- Party;
- Guild.

## Explicitly removed

Do not render:
- center-bottom 8-slot COMBAT SKILLS bar;
- large standalone player panel;
- developer/command toolbar;
- strategy, army or tower command interface.

Skill hotkeys 1 through 8 remain available as gameplay input and are not rendered as a bottom skill strip. The Skills button provides access to the skill interface.

## Visual language

Use:
- dark translucent glass panels;
- warm gold accents;
- portrait/profile framing;
- compact information density;
- readable typography;
- circular/minimap presentation;
- small utility buttons;
- restrained obstruction of the 3D world.

## Scaling

The reference layout is authored around 1920x1080 and uses anchors/safe areas for smaller screens.

## Acceptance

HUD acceptance requires a real Unreal Engine 5.8 runtime frame over the actual 3D game world. Concept art and generated images are not gameplay evidence.
