#!/usr/bin/env python3
"""Static QA for the core Honour War MMORPG progression loop."""

from __future__ import annotations

from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]

RULES = ROOT / "data" / "honour_war_default_rules.json"
COMBAT = ROOT / "Source" / "HonourWar" / "HonourWarCombatComponent.cpp"
COMBAT_H = ROOT / "Source" / "HonourWar" / "HonourWarCombatComponent.h"
MONSTER = ROOT / "Source" / "HonourWar" / "HonourWarMonster.h"
WORLD = ROOT / "Source" / "HonourWar" / "HonourWarWorldDirector.cpp"
SAVE = ROOT / "Source" / "HonourWar" / "HonourWarSaveGame.h"
CHAR = ROOT / "Source" / "HonourWar" / "HonourWarCharacter.cpp"
HUD = ROOT / "Source" / "HonourWar" / "HonourWarHUDWidget.cpp"


def require(text: str, needle: str, label: str) -> None:
    if needle not in text:
        raise SystemExit(f"PROGRESSION_QA_FAIL: missing {label}: {needle}")


def main() -> int:
    rules = json.loads(RULES.read_text(encoding="utf-8"))
    if rules.get("hero_level_cap") != 250:
        raise SystemExit("PROGRESSION_QA_FAIL: hero level cap must be 250")
    if rules.get("monster_level_cap") != 300:
        raise SystemExit("PROGRESSION_QA_FAIL: monster level cap must be 300")
    if rules.get("soldier_level_cap") != 50:
        raise SystemExit("PROGRESSION_QA_FAIL: soldier level cap must be 50")
    if rules.get("visual_runtime", {}).get("approved_asset_intake") != ["FBX", "OBJ"]:
        raise SystemExit("PROGRESSION_QA_FAIL: approved runtime intake must remain FBX/OBJ")

    combat = COMBAT.read_text(encoding="utf-8")
    combat_h = COMBAT_H.read_text(encoding="utf-8")
    monster = MONSTER.read_text(encoding="utf-8")
    world = WORLD.read_text(encoding="utf-8")
    save = SAVE.read_text(encoding="utf-8")
    char = CHAR.read_text(encoding="utf-8")
    hud = HUD.read_text(encoding="utf-8")

    for needle, label in [
        ("RewardMonsterDefeat", "monster defeat reward function"),
        ("50000", "level-300 XP reward"),
        ("250000", "level-300 Zeny reward"),
        ("World Monarch Card", "level-300 card reward"),
        ("Transcendent Monster Suit", "level-300 suit reward"),
        ("AgeYears", "online-age combat scaling"),
        ("Zeny", "economy state"),
        ("InventoryItems", "inventory state"),
        ("Cards", "card state"),
    ]:
        require(combat, needle, label)

    for needle, label in [
        ("GetMonsterLevel", "monster level getter"),
        ("SetLevel", "monster level setter"),
    ]:
        require(monster, needle, label)

    require(world, "const int32 MonsterLevels[] = {12, 28, 55, 90, 140, 180, 220, 260, 300};", "full monster level progression")

    soldier_cpp = (ROOT / "Source" / "HonourWar" / "HonourWarSoldier.cpp").read_text(encoding="utf-8")
    for needle, label in [
        ("AutoSkillIndex=(AutoSkillIndex+1)%2", "two automatic soldier skills"),
        ("Director->RegisterSoldierDeath()", "soldier death registration"),
        ("HandleMonsterDefeat", "soldier kill reward routing"),
        ("SetLifeSpan(0.2f)", "soldier death lifecycle"),
    ]:
        require(soldier_cpp, needle, label)

    for needle, label in [
        ("Zeny", "save Zeny"),
        ("Honours", "save honours"),
        ("InventoryItems", "save inventory"),
        ("Cards", "save cards"),
        ("OnlineSeconds", "save online time"),
    ]:
        require(save, needle, label)

    for needle, label in [
        ("OnlineTimeAccumulator += DeltaSeconds", "online session accumulator"),
        ("OnlineSeconds += WholeSeconds", "online session counter"),
        ("86400", "online day boundary"),
        ("AutoSaveAccumulator >= 60.0f", "60-second autosave"),
        ("SetAgeDays", "online age update"),
    ]:
        require(char, needle, label)

    for needle, label in [
        ("GetZeny", "HUD Zeny display"),
        ("GetHonours", "HUD honours display"),
        ("Age %d days", "HUD age display"),
    ]:
        require(hud, needle, label)

    for needle, label in [
        ("city_base", "soldier production rule"),
        ("guarded_bank_rule", "guarded bank rule"),
    ]:
        if needle not in RULES.read_text(encoding="utf-8"):
            raise SystemExit(f"PROGRESSION_QA_FAIL: missing {label}: {needle}")

    print("HONOUR WAR PROGRESSION QA PASS: level caps, kill rewards, economy, cards, online-age, autosave, world monster tiers and HUD persistence are wired.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
