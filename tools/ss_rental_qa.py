#!/usr/bin/env python3
"""Static regression checks for the rental-only Super Champion system."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
runtime = (ROOT / "scripts" / "HWSSRentRuntime.gd").read_text(encoding="utf-8")
npc = (ROOT / "scripts" / "HWSSRentNPCDirector.gd").read_text(encoding="utf-8")
companion = (ROOT / "scripts" / "HWSSCompanionDirector.gd").read_text(encoding="utf-8")
project = (ROOT / "project.godot").read_text(encoding="utf-8")

assert 'RENT_PRICE_ZENY:int = 1000000' in runtime
assert 'SS_CLASS_NAME:String = "Super Champion (Rental Only)"' in runtime
assert 'SS_MAX_LEVEL:int = 250' in runtime
assert 'SS_DEFAULT_SKILL:String = "Champion\'s Asura"' in runtime
assert 'COLLECTION_ITEM_LIMIT:int = 50' in runtime
assert 'COLLECTION_CARD_LIMIT:int = 20' in runtime
assert '"behavior":{"follow":true,"heal":true,"fight":true}' in runtime
assert '"go_button":"GO"' in runtime
assert 'func can_create_as_character_class' in runtime
assert 'normalized != "SS"' in runtime
assert 'rental_only":true' in runtime
assert 'all_fifth_job_skills' in runtime
assert 'fifth_job_equipment_classes' in runtime
assert 'HWRentalService="*res://scripts/HWSSRentRuntime.gd"' in project
assert project.count('HWRentalService="*res://scripts/HWSSRentRuntime.gd"') == 1
assert 'get_node_or_null("/root/HWRentalService")' in npc
assert 'Rent' in npc
assert 'PRICE_ZENY:int = 1000000' in npc
assert 'rental_price_zeny' in npc
assert 'ss_companion' in companion
assert 'Champion' in companion
for forbidden in ("HWCompanionArmyRuntime", "soldier_production", "guarded_bank", "tower_defense"):
    assert forbidden not in runtime
    assert forbidden not in npc
    assert forbidden not in companion

print("Super Champion rental QA: PASS")
