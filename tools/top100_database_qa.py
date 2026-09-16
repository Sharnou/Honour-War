from pathlib import Path
import csv

ROOT = Path(__file__).resolve().parents[1]
CSV_PATH = ROOT / "data" / "top_100_items_cards.csv"
GDSCRIPT_PATH = ROOT / "scripts" / "Top100Database.gd"

with CSV_PATH.open("r", encoding="utf-8", newline="") as handle:
    rows = list(csv.DictReader(handle))

assert len(rows) == 200, f"expected 200 rows, got {len(rows)}"
items = [r for r in rows if r["pool"] == "Top-100 Items"]
cards = [r for r in rows if r["pool"] == "Top-100 Cards"]
assert len(items) == 100, f"expected 100 item rows, got {len(items)}"
assert len(cards) == 100, f"expected 100 card rows, got {len(cards)}"
assert [int(r["rank"]) for r in items] == list(range(1, 101)), "item ranks must be exactly 1..100"
assert [int(r["rank"]) for r in cards] == list(range(1, 101)), "card ranks must be exactly 1..100"
names = [r["name"] for r in rows]
assert len(set(names)) == 200, "all Top-100 item/card names must be globally unique"

for label, pool in (("items", items), ("cards", cards)):
    rates = [float(r["default_drop_rate_percent"]) for r in pool]
    assert all(rate > 0 for rate in rates), f"{label}: all base rates must be positive"
    assert all(rates[i] > rates[i + 1] for i in range(99)), f"{label}: rates must descend by rank"
    assert abs(sum(rates) - 5.5) < 0.00001, f"{label}: base pool total must be 5.5%, got {sum(rates)}"
    assert all(r["age_rule"] == "Age bonus applied separately" for r in pool), f"{label}: age must never be baked into base rates"

source = GDSCRIPT_PATH.read_text(encoding="utf-8")
assert "const ITEM_NAMES:Array" in source
assert "const CARD_NAMES:Array" in source
assert "const ENTRIES_PER_POOL:int = 100" in source
assert "static func items()->Array" in source
assert "static func cards()->Array" in source
assert "static func item_count()->int" in source
assert "static func card_count()->int" in source
assert "static func validate()->bool" in source

print("Honour War Top-100 database QA: PASS")
print("items=100")
print("cards=100")
print("total_entries=200")
print("item_base_pool_rate_percent=5.500000")
print("card_base_pool_rate_percent=5.500000")
print("combined_base_pool_rate_percent=11.000000")
print("age_bonus_in_base_rates=false")
