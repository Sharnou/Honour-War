#!/usr/bin/env python3
"""Static regression checks for the rental-only SS (SUPER SHAMBION) system."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
runtime = (ROOT / "scripts" / "HWSSRentRuntime.gd").read_text(encoding="utf-8")
npc = (ROOT / "scripts" / "HWSSRentNPCDirector.gd").read_text(encoding="utf-8")
companion = (ROOT / "scripts" / "HWSSCompanionDirector.gd").read_text(encoding="utf-8")
project = (ROOT / "project.godot").read_text(encoding="utf-8")

assert 'RENT_PRICE_ZENY:int = 1000000' in runtime
assert 'SS_CLASS_NAME:String = "SS (SUPER SHAMBION)"' in runtime
assert 'SS_LEVEL:int = 0' in runtime
assert 'SS_DEFAULT_SKILL:String = "Asura Strike"' in runtime
assert 'COLLECTION_ITEM_LIMIT:int = 50' in runtime
assert 'COLLECTION_CARD_LIMIT:int = 20' in runtime
assert '"behavior":{"follow":true,"heal":true,"fight":true}' in runtime
assert '"go_button":"GO"' in runtime
assert 'func can_create_as_character_class' in runtime
assert 'normalized != "SS"' in runtime
# An autoload singleton must not also declare a global class with the same name.
assert 'class_name HWSSRentRuntime' not in runtime
assert 'HWSSRentRuntime="*res://scripts/HWSSRentRuntime.gd"' in project
assert project.count('HWSSRentRuntime="*res://scripts/HWSSRentRuntime.gd"') == 1
assert 'Rent' in npc
assert 'PRICE_ZENY:int = 1000000' in npc
assert 'rental_price_zeny' in npc
assert 'ss_companion' in companion
assert 'Asura Strike' in companion

# Explicitly reject the retired soldier/tower-defense system in the active SS scripts.
for forbidden in ("HWCompanionArmyRuntime", "soldier_production", "guarded_bank", "tower_defense"):
    assert forbidden not in runtime
    assert forbidden not in npc
    assert forbidden not in companion

print("SS rental QA: PASS")
