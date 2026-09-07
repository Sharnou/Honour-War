# Honour War — Equipment, Cards, MVPs and Auto Loot

## Equipment slots

Players have ten equipment slots:

1. Weapon
2. Shield
3. Upper Headgear
4. Middle Headgear
5. Lower Headgear
6. Armor
7. Garment
8. Shoes
9. Accessory 1
10. Accessory 2

### Card sockets

- Maximum sockets on one item: **4**.
- Upper headgear can reach **4 card sockets** on top-tier headgear.
- Middle/lower headgear can reach up to 3/2 sockets depending on the item.
- Weapons can reach up to 3 sockets.
- Armor, shields, garments and shoes can reach up to 3 sockets.
- Accessories can reach up to 2 sockets.
- Refinement does not create sockets.
- Cards are restricted to compatible equipment families.

## Item effects

Equipment supports attack, magic power, defense, HP, SP, critical rate, evasion, healing, movement speed, XP gain, boss damage, item-drop rate, elemental bonuses/resistances and reward bonuses.

Examples:

- Celestial Crown: high defense/HP/magic and 4 headgear sockets.
- Saint Halo: healing/SP bonuses and 4 headgear sockets.
- Eternal Assassin Blade: high attack and critical rate.
- Golden Crown: HP/defense and +5% all rewards.
- Celestial Greaves: HP/defense/movement and 3 sockets.

## Cards

The card database contains 20 cards across Common, Uncommon, Rare, Epic and MVP rarities.

Card effects include:

- Item-drop rate
- Family-specific damage
- HP and movement speed
- Critical damage
- Poison resistance
- Family defense
- Attack speed
- Defense
- Magic resistance
- Boss damage
- Physical/magic damage
- Fire damage
- Ice resistance
- Item quantity
- XP gain
- All-damage bonuses

MVP cards are guaranteed from their corresponding MVP when the player can collect them and automatic loot is enabled.

## Monster drops

Normal monsters have family-specific tables for cards, crafting materials, refine materials and consumables. Examples include Wolf Claw, Goblin Ear, Orc Tusk, Mantis Shell, Skeleton Bone, Zombie Heart, Golem Core, Druid Relic and Dragon Scale.

## MVP system

Ten endgame MVPs are available:

- Orc Lord — Lv250
- Baphomet — Lv255
- Evil Druid Lord — Lv260
- Fire Dragon — Lv270
- Ice Titan — Lv275
- Queen Ant — Lv280
- Ancient Golem — Lv290
- Thanatos — Lv300
- Moonlight Dragon — Lv300
- Abyss Emperor — Lv300

MVPs have increased HP, attack and defense, unique skills, unique MVP cards and premium loot. MVP encounters are gated to hero level 200+; the higher endgame has the increased spawn chance.

## Automatic loot

The command system supports:

- `@autoloot` — show status and keep the current setting.
- `@autoloot on` — enable automatic pickup.
- `@autoloot off` — disable automatic pickup; new drops are retained as ground loot.
- `@autoloot status` — show automatic-loot status and pending ground drops.
- `@loot` — manually collect pending ground drops when possible.

Automatic loot covers cards, equipment, materials and normal items. The setting is saved with the hero.

## Runtime behavior

Defeat rewards are processed through one unified loot pipeline so the legacy combat runtime and manual attack path do not duplicate the same drop. Ground drops remain persisted in the hero state until collected.
