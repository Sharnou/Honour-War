# Honour War — Canonical Top-100 Loot Database

The Top-100 database is now a real game-data contract, not only a design note.

## Base drop-rate rule

The `default_drop_rate_percent` field is the character-age-independent base chance stored for each Top-100 entry.

- Rank 1: **0.100000%**
- Rank 100: **0.010000%**
- All 100 rates are strictly descending by rank.
- The complete base Top-100 pool sums to **5.500000%**.
- Character age is **not included** in these stored rates.

## Age rule

Character age is applied separately by `OnlineAgeSystem` / `LootProgressionSystem` after the base rate is read. Therefore the database itself remains stable across the character's lifetime.

At age 18, the entry uses its stored default rate before the age bonus.

At age 60, the existing permanent age rule supplies the separate Top-100 age bonus of **+4.2%**. This is not written into the database's default rates.

## Database contents

Ranks 1–60 are equipment:

- 10 weapons
- 10 armor pieces
- 10 helmets
- 10 garments
- 10 footwear pieces
- 10 accessories

Ranks 61–100 are cards:

- 40 monster/character/world cards

Every entry contains:

- rank
- type
- slot
- name
- rarity
- status/effects
- default drop rate
- Top-100 pool membership
- explicit separation from character-age bonuses

## Runtime source

`res://scripts/Top100Database.gd` is the runtime source of truth used by `LootProgressionSystem.gd`.

`data/top_100_items_cards.csv` is the auditable tabular copy for balancing, review, and future content tooling.

## Validation

`tools/top100_database_qa.py` verifies exactly 100 entries, unique names, sequential ranks, positive strictly descending base rates, the 5.5% base pool total, and that age bonuses are kept separate.

The GitHub Actions workflow `.github/workflows/honour-war-top100-database-qa.yml` runs this validation on relevant changes.

## Important balancing note

These are the current canonical Honour War database values introduced for the complete Top-100 system. They are deliberately independent from age. If future balancing changes these base rates, the change must be made to both the runtime catalog and its CSV audit copy and must preserve the age-separation rule unless the game design is explicitly changed.
