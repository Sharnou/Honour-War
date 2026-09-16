# Honour War — Top-100 Loot Database

## Canonical definition

Honour War now has **two separate Top-100 databases**:

- **Top 100 Items** — ranks 1–100 equipment/items.
- **Top 100 Cards** — ranks 1–100 cards.
- **Total catalog entries: 200.**

The runtime source is `scripts/Top100Database.gd`. The audit copy is `data/top_100_items_cards.csv`.

## Base drop-rate rule

Each pool uses the same rank curve:

- Rank 1: `0.100000%`
- Rank 100: `0.010000%`
- 100-entry pool total: `5.500000%`
- Combined item + card base pool: `11.000000%`

Character age is **not** baked into these stored rates. The age bonus remains a separate gameplay modifier, preserving the established age-progression rule.

## Runtime API

`Top100Database.items()` returns the 100 item entries.

`Top100Database.cards()` returns the 100 card entries.

`Top100Database.get_item_by_rank(rank)` and `Top100Database.get_card_by_rank(rank)` resolve the two pools independently.

`Top100Database.item_count()` = `100`.

`Top100Database.card_count()` = `100`.

`Top100Database.count()` = `200`.

`LootProgressionSystem` exposes separate item/card lookup and resolution methods while retaining the older item-pool aliases for compatibility.

## Validation

`tools/top100_database_qa.py` verifies:

- exactly 200 CSV entries;
- exactly 100 item entries and 100 card entries;
- ranks 1–100 within each pool;
- globally unique names;
- descending base rates;
- 5.5% base-rate total per pool;
- age bonus excluded from stored base rates;
- required runtime database APIs exist.
