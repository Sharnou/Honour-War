# Honour War — Primary Visual Source for Unreal Engine 5.8

The complete repository Screenshot/ folder is the authoritative visual source.

Locked visual anchors:
1. Screenshot/ChatGPT Image Sep 16, 2026, 12_22_47 AM.png
2. Screenshot/image_a4469f29.jpg

## MMORPG HUD correction

Honour War is an MMORPG/ARPG, not a strategy game.

The reference-driven HUD uses:
- upper-left profile/portrait, name, level/class and HP/SP/EXP;
- left Inventory / Character / Skills / Quests navigation;
- upper-right mail/social/settings controls;
- circular minimap with coordinates, compass and time;
- right-side active quest tracker;
- lower-left chat;
- lower-right Map / Bag / Shop / Party / Guild shortcuts.

The following previous implementation is permanently removed from the player-facing HUD:
- center-bottom 8-slot COMBAT SKILLS strip;
- standalone rectangular player panel;
- developer/command toolbar;
- strategy/tower/army command UI.

Keyboard skill activation remains a gameplay feature but has no mandatory bottom skill strip.

## Engine

Unreal Engine 5.8 is the sole runtime and build target. Godot is permanently rejected.

## Visual workflow

Visual RAG → Neural4D or Blender → Substance 3D Painter → FBX/OBJ → Unreal Engine 5.8 → real runtime screenshot.

## Acceptance

Passing source checks is not sufficient. The actual Unreal executable must render the game and the screenshot must contain the real 3D world plus the reference-driven HUD.
