#!/usr/bin/env python3
"""Static contract checks for the rental-only SS AI companion."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
script = ROOT / "scripts" / "HWSSCompanionDirector.gd"
runtime = ROOT / "scripts" / "HWSSRentRuntime.gd"
city_system = ROOT / "scripts" / "CitySystem.gd"


def main() -> None:
    text = script.read_text(encoding="utf-8")
    runtime_text = runtime.read_text(encoding="utf-8")
    required = [
        "func _try_heal",
        "func _try_fight",
        'const ASURA_SKILL:String = "Asura Strike"',
        '"Heal Hero"',
        '"Heal Self"',
        'legacy.get(\"monsters\")',
        'legacy.call("defeat_monster",target)',
        'ss_visual.add_to_group("ss_companion")',
        'func _play_skill_vfx',
    ]
    for marker in required:
        if marker not in text:
            raise SystemExit("Missing SS AI contract: " + marker)

    if 'class_name HWSSRentRuntime' in runtime_text:
        raise SystemExit("HWSSRentRuntime must remain an autoload singleton without class_name")
    if "HWSSAIController" in (ROOT / "project.godot").read_text(encoding="utf-8"):
        raise SystemExit("Redundant HWSSAIController autoload must not return")
    if (ROOT / "scripts" / "HWSSAIController.gd").exists():
        raise SystemExit("Redundant HWSSAIController.gd must not return")

    # CitySystem intentionally exposes BUILDINGS only as an empty compatibility
    # array. Accept typed/untyped empty-array syntax while rejecting any active
    # legacy strategy building registry if a future change turns it into a dict.
    city_text = city_system.read_text(encoding="utf-8")
    building_match = re.search(
        r'const BUILDINGS(?:\s*:\s*[A-Za-z0-9_]+)?\s*:?=\s*(?P<value>\[\]|\{(?P<body>.*?)\n\})',
        city_text,
        re.DOTALL,
    )
    if not building_match:
        raise SystemExit("CitySystem BUILDINGS contract is missing")

    if building_match.group("value") == "[]":
        building_names = set()
    else:
        building_names = set(re.findall(r'\"([^\"]+)\"\s*:\s*\{', building_match.group("body") or ""))

    obsolete_buildings = {"Barracks", "Tower Defense", "Soldier Production", "Guarded Bank"}
    obsolete_active = sorted(name for name in building_names if name in obsolete_buildings)
    if obsolete_active:
        raise SystemExit("Obsolete active city feature remains: " + ", ".join(obsolete_active))

    print("SS AI QA passed")


if __name__ == "__main__":
    main()
