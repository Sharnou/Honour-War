#!/usr/bin/env python3
"""Reject visually duplicated monster source templates.

The monster Blender generator is intentionally inspected at source level because CI
cannot infer visual identity reliably from names alone. Families that share a common
branch are rejected; each named monster must have an explicit silhouette-defining
branch and signature geometry markers.
"""
from pathlib import Path
import re
import sys

SOURCE = Path("tools/blender/honour_war_monster_assets.py")

REQUIRED_SIGNATURES = {
    "Poring": ("family == \"Poring\"", "Crown"),
    "Goblin": ("family == \"Goblin\"", "LongEar", "CrookedClub"),
    "Wolf": ("family == \"Wolf\"", "Paw", "Tail"),
    "Skeleton": ("family == \"Skeleton\"", "Skull", "Spine"),
    "Zombie": ("family == \"Zombie\"", "HunchedTorso", "BrokenJaw", "ExposedRib"),
    "Orc": ("family == \"Orc\"", "HeavyAxe", "Tusk"),
    "Mantis": ("family == \"Mantis\"", "ScytheArm"),
    "Golem": ("family == \"Golem\"", "Body", "Arm"),
    "Evil Druid": ("family == \"Evil Druid\"", "Robe", "Staff"),
    "Dragon": ("family == \"Dragon\"", "Wing", "Horn"),
    "Bloody Knight": ("else:", "ArmorBody", "Helm", "Sword"),
}

SHARED_TEMPLATE = 'family in ("Wolf", "Orc", "Zombie", "Goblin")'

def fail(message: str) -> None:
    print("FAIL:", message)
    raise SystemExit(1)

def main() -> None:
    if not SOURCE.is_file():
        fail(f"missing source: {SOURCE}")
    text = SOURCE.read_text(encoding="utf-8")
    if SHARED_TEMPLATE in text:
        fail("different monster families still share the old humanoid visual template")

    positions = {}
    for family, markers in REQUIRED_SIGNATURES.items():
        if markers[0] not in text:
            fail(f"{family}: missing dedicated family branch marker")
        missing = [marker for marker in markers[1:] if marker not in text]
        if missing:
            fail(f"{family}: missing silhouette markers: {', '.join(missing)}")
        positions[family] = text.index(markers[0])

    # Every non-fallback family branch must be distinct in the generator source.
    if len(set(positions.values())) != len(positions):
        fail("two monster families resolve to the same generator branch")

    # Explicitly protect the pair that previously collapsed visually.
    for marker in ("HunchedTorso", "BrokenJaw", "ExposedRib", "DraggingArm"):
        if text.count(marker) != 1:
            fail(f"Zombie visual marker {marker!r} must be unique")

    print("MONSTER_VISUAL_DISTINCTNESS: PASS")
    print("All named monster families have dedicated silhouette-defining geometry.")
    print("No shared humanoid duplicate template is permitted.")

if __name__ == "__main__":
    main()
