# Honour War — Godot 4 Playable Prototype

## Requirements
- Godot 4.2 or newer

## Run
1. Install Godot 4.
2. Open the `project.godot` file.
3. Press F6 or F5 to run.

## Controls
- WASD / Arrow Keys: move
- SPACE: hero + bonded pet attack
- R: refine hero equipment
- T: refine pet equipment
- Q: complete a quest
- C: craft
- B: buy Phracon

## Included
- Six classes with automatic class-bonded combat pets
- Class-specific pet roles: Warrior/War Wolf Tank, Mage/Arcane Sprite Support Caster, Archer/Falcon Ranged Striker, Thief/Shadow Cat Assassin, Acolyte/Holy Poring Healer, Merchant/Iron Beetle Guardian
- Pets spawn automatically with the character and require no feeding or manual upkeep
- Pets fight alongside the hero automatically and follow through fast transmission between towns and dungeons
- Pet maximum level 100, independent EXP, HP/SP growth, skill levels, skill points, pet skills, kills, equipment, inventory, crafting materials, and refinement +0 to +15
- Pet-specific Skill Items and Pet Refine Items can drop from monsters
- Archer automatically receives a Falcon companion as its class pet
- Six hero classes and class evolution up to hero level 250
- Class-specific weapons and basic skills
- Online-time aging
- Age-based skill, refinement, and price bonuses
- Phracon, Emveretarcon, Oridecon, and Zeny
- Monsters, combat, EXP, leveling, cards, items, and Zeny drops
- Quests and crafting
- Fast transmission using commands such as `@go 0 230:220`
- Automatic save/resume in the Godot user data folder

## Pet Design Rule
Every playable character always has exactly one automatic bonded class pet. The pet is part of the character's combat party, shares progression through combat rewards, and never requires food. Changing class in the prototype rebonds the character to that class's signature pet.

## Scope
This is an offline single-player prototype. A production MMORPG still needs authoritative multiplayer servers, accounts, database persistence, networking, anti-cheat, production art, animations, sound, and deployment.
