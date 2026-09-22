#!/usr/bin/env python3
"""Permanent Honour War exclusion contract.

This validator is deliberately strict: rejected runtime systems and retired
asset exporters must not be reintroduced.  Validator implementation files may
contain the forbidden strings as data used to detect them; active generators
may not.
"""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "Source"
TOOL_DIR = ROOT / "tools"

# These are validator implementations, not active generators.  Keep this set
# exact so a new tool cannot silently opt out of exclusion scanning.
VALIDATOR_FILES = frozenset(
    {
        "rejected_systems_qa.py",
        "validate_hd_assets.py",
        "validate_art_generators.py",
        "unreal_engine_contract_qa.py",
    }
)

ACTIVE_GENERATOR_FILES = (
    "tools/blender/honour_war_monster_assets.py",
    "tools/blender/honour_war_production_assets.py",
    "tools/blender/honour_war_visual_max_assets.py",
    "tools/blender/build_ss_production_asset.py",
    "tools/blender/run_visual_max_assets.py",
)

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
    "BuildSectionPanel",
    "DefenseTower",
    "IncomeBank",
    "squad production",
    "transformer",
)

EXCLUDED_TERMS = (
    "bpy.ops.export_scene.gltf",
    "bpy.ops.wm.gltf_export",
    "strategy/tower/army",
    "guarded income bank",
    "tower-defense",
    "base sight overlay",
    "building/construction UI",
)

RETIRED_ASSET_EXTENSIONS = frozenset({".glb", ".gltf"})

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


def check_validator_allowlist() -> None:
    actual = frozenset(path.name for path in TOOL_DIR.glob("*.py") if path.name in VALIDATOR_FILES)
    if actual != VALIDATOR_FILES:
        fail(
            "validator exemption set changed unexpectedly: "
            f"expected={sorted(VALIDATOR_FILES)} actual={sorted(actual)}"
        )


def scan_runtime() -> None:
    if not SOURCE_DIR.is_dir():
        fail("runtime Source directory is missing")
    for path in SOURCE_DIR.rglob("*"):
        if not path.is_file() or path.suffix.lower() not in {".h", ".cpp", ".py", ".ini", ".json"}:
            continue
        text = path.read_text(encoding="utf-8", errors="ignore")
        for marker in EXCLUDED_SYMBOLS + EXCLUDED_TERMS:
            if marker in text:
                fail(f"rejected runtime marker remains in {path.relative_to(ROOT)}: {marker}")


def scan_active_generators() -> None:
    for relative in ACTIVE_GENERATOR_FILES:
        path = ROOT / relative
        if not path.is_file():
            fail(f"active generator is missing: {relative}")
        text = path.read_text(encoding="utf-8", errors="ignore")
        for marker in EXCLUDED_SYMBOLS + EXCLUDED_TERMS:
            if marker in text:
                fail(f"rejected generator marker remains in {relative}: {marker}")
        for extension in RETIRED_ASSET_EXTENSIONS:
            if extension in text.lower():
                fail(f"retired asset extension remains in active generator {relative}: {extension}")


def scan_non_validator_tooling() -> None:
    for path in TOOL_DIR.rglob("*.py"):
        if path.name in VALIDATOR_FILES:
            continue
        text = path.read_text(encoding="utf-8", errors="ignore")
        for marker in EXCLUDED_SYMBOLS:
            if marker in text:
                fail(f"rejected generator/tool marker remains in {path.relative_to(ROOT)}: {marker}")
        for marker in EXCLUDED_TERMS:
            if marker in text:
                fail(f"rejected generator/tool marker remains in {path.relative_to(ROOT)}: {marker}")


def check_removed_files() -> None:
    for relative in REMOVED_FILES:
        if (ROOT / relative).exists():
            fail(f"rejected file remains: {relative}")


def check_no_legacy_binary_formats() -> None:
    for path in ROOT.rglob("*"):
        if path.is_file() and path.suffix.lower() in RETIRED_ASSET_EXTENSIONS:
            fail(f"rejected GLB/GLTF asset remains: {path.relative_to(ROOT)}")


def check_city_monster_exclusion() -> None:
    world = ROOT / "Source" / "HonourWar" / "HonourWarWorldDirector.cpp"
    if not world.is_file():
        fail("HonourWarWorldDirector.cpp is missing")
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
    check_validator_allowlist()
    scan_runtime()
    scan_active_generators()
    scan_non_validator_tooling()
    check_removed_files()
    check_no_legacy_binary_formats()
    check_city_monster_exclusion()
    print(
        "EXCLUSION_QA_PASS: rejected strategy/soldier/build systems are permanently removed; "
        "active art generators are FBX/OBJ-only; validator exemptions are fixed."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
