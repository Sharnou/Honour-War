#!/usr/bin/env python3
"""Permanent Honour War exclusion contract."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

RUNTIME_DIRS = [ROOT / "Source", ROOT / "tools"]
EXCLUDED_SYMBOLS = (
    "HonourWarSoldier",
    "HonourWarIncomeBank",
    "HonourWarDefenseTower",
    "HonourWarBaseBuilding",
    "SoldierWorkshop",
    "SkillShrine",
    "SpawnSoldierSquad",
    "RegisterSoldierDeath",
    "EnsureCommanderSquads",
    "SetPlayerTarget",
    "CanAttackPlayer",
    "ReceivePlayerDamage",
    "ServerUseSkillOnPlayer",
    "ServerTryRefineEquipment",
    "ServerTryMixCards",
    "ServerTryUpgradeBasicSkill",
    "BaseSight",
    "TeamId",
    "PartySlot",
)

EXCLUDED_TERMS = (
    "bpy.ops.export_scene.gltf",
    "bpy.ops.wm.gltf_export",
    "strategy/tower/army",
)

REMOVED_FILES = (
    "Source/HonourWar/HonourWarSoldier.h",
    "Source/HonourWar/HonourWarSoldier.cpp",
    "Source/HonourWar/HonourWarIncomeBank.h",
    "Source/HonourWar/HonourWarIncomeBank.cpp",
    "Source/HonourWar/HonourWarDefenseTower.h",
    "Source/HonourWar/HonourWarDefenseTower.cpp",
    "Source/HonourWar/HonourWarBaseBuilding.h",
    "Source/HonourWar/HonourWarBaseBuilding.cpp",
    "Source/HonourWar/HonourWarPlayerState.cpp.tmp",
)

def fail(message: str) -> None:
    raise SystemExit(f"EXCLUSION_QA_FAIL: {message}")

def scan_runtime() -> None:
    for root in RUNTIME_DIRS:
        for path in root.rglob("*"):
            if not path.is_file() or path.suffix.lower() not in {".h", ".cpp", ".py", ".ini", ".json"}:
                continue
            if "rejected_systems_qa.py" in path.name:
                continue
            text = path.read_text(encoding="utf-8", errors="ignore")
            for marker in EXCLUDED_SYMBOLS + EXCLUDED_TERMS:
                if marker in text:
                    fail(f"rejected runtime marker remains in {path.relative_to(ROOT)}: {marker}")

def check_removed_files() -> None:
    for relative in REMOVED_FILES:
        if (ROOT / relative).exists():
            fail(f"rejected file remains: {relative}")

def check_no_legacy_binary_formats() -> None:
    for path in ROOT.rglob("*"):
        if path.is_file() and path.suffix.lower() in {".glb", ".gltf"}:
            fail(f"rejected GLB/GLTF asset remains: {path.relative_to(ROOT)}")

def check_city_monster_exclusion() -> None:
    world = ROOT / "Source" / "HonourWar" / "HonourWarWorldDirector.cpp"
    text = world.read_text(encoding="utf-8")
    required = "FVector2D(Slot.Location.X,Slot.Location.Y).Size()<7800.0f"
    if required not in text:
        fail("permanent city monster exclusion radius is missing")

    match = re.search(r"const FVector MonsterLocations\[\]=\{(.*?)\n    \};", text, re.S)
    if not match:
        fail("monster location array is missing")
    for xyz in re.findall(r"FVector\(([-+]?\d+(?:\.\d+)?),([-+]?\d+(?:\.\d+)?),", match.group(1)):
        x, y = float(xyz[0]), float(xyz[1])
        if (x * x + y * y) ** 0.5 < 7800.0:
            fail(f"monster spawn remains inside city exclusion radius: {x},{y}")

def main() -> int:
    scan_runtime()
    check_removed_files()
    check_no_legacy_binary_formats()
    check_city_monster_exclusion()
    print("EXCLUSION_QA_PASS: rejected strategy/soldier/build systems are permanently removed; city monster exclusion and FBX/OBJ-only runtime intake are enforced.")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
