# Honour War expansion architecture

This project grows from the existing Godot prototype instead of being restarted.

## Current foundation
- `Main.tscn` and `scripts/Main.gd` remain the playable prototype entry point.
- `GameData.gd` centralizes classes, class tiers, cities, monsters, materials, hero defaults, level caps, and age rules.
- `SaveSystem.gd` provides versioned persistence and migration while preserving the existing save path.
- `WorldSystem.gd` defines scalable monster stats, level scaling, drops/cards, refinement chance, and age discounts.
- `CitySystem.gd` defines the first expandable city-building layer.

## Target architecture
1. Client: Godot scenes, UI, input, rendering, effects, audio and original assets.
2. Gameplay domain: characters, class progression, skills, combat, monsters, items, cards, refinement, crafting, quests and city building.
3. Online layer: authoritative server, sessions, movement/combat validation, chat, parties, guilds, trading and persistence.
4. Data layer: accounts, characters, inventories, equipment, cards, currencies, quests, cities and world state.
5. Operations: automated tests, save migration, server logging, backups, anti-cheat validation and deployment.

## Progression target
- Hero level cap: 250.
- Monster level cap: 300.
- Six class families with five progression tiers each.
- Ultimate-tier quests and mastery gates will be added before unlocking tier 5.
- Character age starts at 18 and increases from accumulated online days; age bonuses affect selected skill effectiveness, refinement and economy according to the design.

## Important implementation rule
The existing prototype is preserved as the playable shell. New systems should be introduced behind focused scripts and data definitions so individual systems can be tested without replacing the whole game.

## Roadmap order
- Phase 1: data architecture, persistence, class/level progression, inventory/equipment and deterministic item definitions.
- Phase 2: real combat entities, monster AI, maps, drops/cards, skills and quests.
- Phase 3: crafting/refinement/economy and city building.
- Phase 4: online server and database persistence.
- Phase 5: parties, guilds, trading, social systems, world events and live operations.
- Phase 6: original high-resolution art, animation, VFX, audio, optimization, testing and release packaging.
