#!/usr/bin/env python3
"""Static contract checks for the rental-only SS AI companion."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
script = ROOT / "scripts" / "HWSSCompanionDirector.gd"
runtime = ROOT / "scripts" / "HWSSRentRuntime.gd"

def main() -> None:
    text = script.read_text(encoding="utf-8")
    runtime_text = runtime.read_text(encoding="utf-8")
    required = [
        "func _try_heal",
        "func _try_fight",
        "func _find_nearest_enemy",
        'const ASURA_SKILL:String = "Asura Strike"',
        '"Heal Hero"',
        '"Heal Self"',
        'target.set_meta("last_hit_skill",ASURA_SKILL)',
        'ss_visual.add_to_group("ss_companion")',
    ]
    for marker in required:
        if marker not in text:
            raise SystemExit("Missing SS AI contract: " + marker)
    if 'class_name HWSSRentRuntime' in runtime_text:
        raise SystemExit("HWSSRentRuntime must remain an autoload singleton without class_name")
    forbidden = ["Barracks", "soldier production", "guarded bank", "tower defense"]
    city_text = (ROOT / "scripts" / "CitySystem.gd").read_text(encoding="utf-8").lower()
    for marker in forbidden:
        if marker.lower() in city_text:
            raise SystemExit("Obsolete city feature remains: " + marker)
    print("SS AI QA passed")

if __name__ == "__main__":
    main()
