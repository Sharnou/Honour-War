from pathlib import Path
import csv

ROOT = Path(__file__).resolve().parents[1]
CSV_PATH = ROOT / "data" / "top_100_items_cards.csv"
GDSCRIPT_PATH = ROOT / "scripts" / "Top100Database.gd"

with CSV_PATH.open("r", encoding="utf-8", newline="") as handle:
    rows = list(csv.DictReader(handle))

assert len(rows) == 100, f"expected 100 rows, got {len(rows)}"
assert [int(r["rank"]) for r in rows] == list(range(1, 101)), "ranks must be exactly 1..100"
names = [r["name"] for r in rows]
assert len(set(names)) == 100, "Top-100 names must be unique"

rates = [float(r["default_drop_rate_percent"]) for r in rows]
assert all(rate > 0 for rate in rates), "all base rates must be positive"
assert all(rates[i] > rates[i + 1] for i in range(99)), "base rates must strictly descend by rank"
assert abs(sum(rates) - 5.5) < 0.00001, f"base pool total must be 5.5%, got {sum(rates)}"
assert all(r["age_rule"] == "Age bonus applied separately" for r in rows), "age must never be baked into base rates"
assert all(r["drop_pool"] == "Top-100 pool" for r in rows), "all entries must belong to Top-100 pool"

source = GDSCRIPT_PATH.read_text(encoding="utf-8")
assert "const TOP_100:Array = [" in source
assert source.count('"rank":') == 100, "GDScript catalog must contain exactly 100 rank entries"
assert "default_drop_rate_percent" in source
assert "age_bonus_separate\":true" in source
assert "static func validate()" in source

print("Honour War Top-100 database QA: PASS")
print("entries=100")
print(f"base_pool_rate_percent={sum(rates):.6f}")
print(f"highest_base_rate_percent={rates[0]:.6f}")
print(f"lowest_base_rate_percent={rates[-1]:.6f}")
print("age_bonus_in_base_rates=false")
