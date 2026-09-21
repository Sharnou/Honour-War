# Honour War — HD Game Specification

## Identity

Honour War is a medieval/fantasy MMORPG/ARPG set around a year-1500 visual era. It is not a strategy game.

Modern, futuristic, science-fiction and machine-centric presentation is prohibited: no robots, transformers, factories, rockets, spaceships or similar elements.

## Core progression

- Hero maximum level: 250.
- Monster maximum level: 300.
- Soldier maximum level: 50.
- Heroes gain experience and Zeny/items/cards from monsters.
- Level-300 monsters can provide top-tier rewards.
- Hero respawns at the city/base point after death with no death-count limit.

## Classes

Base classes:
Warrior, Mage, Archer, Thief, Acolyte, Merchant.

Advanced combat classes may extend the class tree; Ranger is retained as an advanced class.

## Combat

Combat is real-time. Class-specific engagement ranges and skills are authoritative data. Melee classes close distance before damage lands. Ranged classes can attack from longer distances with visible projectiles. Monsters pursue and attack using authored range values.

## Pets

Playable heroes can have combat pets. Pet roles include melee, ranged, caster, tank, healer and assassin archetypes. Pet progression, equipment and skills are separate from hero combat state but remain synchronized with the gameplay presentation.

## Equipment and cards

Items use rarity, stats, sockets, cards and refinement. Refinement uses Phracon, Zeny, Emveretarcon and Oridecon. Refinement is capped at +15. Card/item progression is data-driven.

## Age

Character age advances from online days. Age affects:
- basic skill effects;
- refinement success;
- required refinement materials;
- selected item prices;
- character appearance.

The save system stores the latest save time and reconstructs elapsed online-day progression.

## Cities, towns and maps

Towns provide RPG services such as equipment, crafting, refinement, storage, social interaction and travel. World environments are richly dressed medieval spaces with distinct map identities.

Fast travel uses the command:
@go [map] [x]:[y]

## Multiplayer

The runtime is built for server-authoritative multiplayer. Party/PvP group sizes include 2v1, 3v3 and 4v4. Character movement, combat, progression, equipment and persistence must remain authoritative.

## UI

Player HUD:
- status/level/age;
- HP/SP/EXP;
- target;
- minimap/world map;
- chat;
- numeric 1–8 gameplay skills without requiring a persistent bottom skill strip;
- contextual RPG windows.

The obsolete development command toolbar is not part of the game.

## Visual acceptance

The target is determined by the two locked repository visual anchors and the full Screenshot/ reference set. Production completion requires a real Unreal Engine 5.8 runtime/EXE screenshot showing the actual game, not a mockup.


## Fifth-tier class and control requirements

The Unreal implementation must preserve the five-tier progression and expose Tier 5 / Transcendence at level 200. Fifth-tier identity remains tied to the original profession.

Mouse-first desktop MMORPG controls are mandatory: left-click ground movement, left-click target selection/approach/attack, right-drag camera orbit, and wheel zoom.


## City, base and soldier gameplay

Cities are RPG progression hubs rather than a strategy-game HUD. A developed city can contain hero services for weapon refinement, card mixing, storage, skills and soldier production.

Soldiers are production units with a level cap of 50 and two automatic combat skills. Soldiers can occupy guarded income banks only after the local guarding monster is defeated. Every five fallen soldiers return to the city production point. Soldier production and bank income are world systems and must not replace the mouse-first MMORPG HUD.

## Rewards

Monster defeat is a complete reward event:
- experience;
- Zeny;
- honour;
- item drops;
- card drops.

Level-300 monsters are the top-tier reward source and can provide Mythic equipment/suits and a world-level card.

## Visual/gameplay invariants

Every visual cycle must regenerate the visual target around the HD 3D anime-inspired MMORPG identity and preserve the Ragnarok Online-inspired perspective/isometric mouse-and-camera convention. Runtime proof is a real Unreal Engine 5.8 Windows EXE frame.
