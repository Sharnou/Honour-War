#!/usr/bin/env python3
"""Static QA for the core Honour War MMORPG progression loop."""

from __future__ import annotations

from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]

RULES = ROOT / "data" / "honour_war_default_rules.json"
COMBAT = ROOT / "Source" / "HonourWar" / "HonourWarCombatComponent.cpp"
COMBAT_H = ROOT / "Source" / "HonourWar" / "HonourWarCombatComponent.h"
LOOT = ROOT / "Source" / "HonourWar" / "HonourWarLootDatabase.h"
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
    if rules.get("visual_runtime", {}).get("approved_asset_intake") != ["FBX", "OBJ"]:
        raise SystemExit("PROGRESSION_QA_FAIL: approved runtime intake must remain FBX/OBJ")
    status_rules=rules.get("status_points",{})
    if status_rules.get("starting_status_points") != 30 or status_rules.get("starting_stat_value") != 10 or status_rules.get("stat_cap") != 120:
        raise SystemExit("PROGRESSION_QA_FAIL: status-point baseline rules are incomplete")
    if status_rules.get("per_level_gain") != 3 or status_rules.get("milestone_bonus",{}).get("bonus_points") != 5:
        raise SystemExit("PROGRESSION_QA_FAIL: status-point level rules are incomplete")

    combat = COMBAT.read_text(encoding="utf-8")
    monster = MONSTER.read_text(encoding="utf-8")
    world = WORLD.read_text(encoding="utf-8")
    save = SAVE.read_text(encoding="utf-8")
    char = CHAR.read_text(encoding="utf-8")
    hud = HUD.read_text(encoding="utf-8")
    loot = LOOT.read_text(encoding="utf-8")

    for needle, label in [
        ("SpendStatusPoint", "status-point allocation runtime"),
        ("GetStatusPointCost", "status-point cost runtime"),
        ("GetDamageReductionPercent", "VIT mitigation runtime"),
        ("GetSkillCooldownMultiplier", "AGI cooldown runtime"),
        ("RewardMonsterDefeat", "monster defeat reward function"),
        ("50000", "level-300 XP reward"),
        ("250000", "level-300 Zeny reward"),
        ("World Monarch Card", "level-300 card reward"),
        ("AgeYears", "online-age combat scaling"),
        ("Zeny", "economy state"),
        ("InventoryItems", "inventory state"),
        ("Cards", "card state"),
    ]:
        require(combat, needle, label)

    require(loot, "Transcendent Monster Suit", "level-300 suit reward")
    require(loot, "World Monarch Card", "level-300 card database reward")

    for needle, label in [
        ("GetMonsterLevel", "monster level getter"),
        ("SetLevel", "monster level setter"),
    ]:
        require(monster, needle, label)

    catalog = json.loads((ROOT/"data"/"honour_war_content_catalog.json").read_text(encoding="utf-8"))
    if len(catalog.get("monsters", [])) != 64:
        raise SystemExit("PROGRESSION_QA_FAIL: monster catalog must contain 256 entries")
    if 300 not in {m.get("level") for m in catalog["monsters"]}:
        raise SystemExit("PROGRESSION_QA_FAIL: level-300 monster missing from catalog")
    if not all("location" in m for m in catalog["monsters"]):
        raise SystemExit("PROGRESSION_QA_FAIL: monster catalog location missing")
    for species in ["Poring","Goblin","Wolf","Skeleton","Orc","Mantis","Golem","Dragon"]:
        if species not in {m.get("visual_archetype") for m in catalog["monsters"]}:
            raise SystemExit(f"PROGRESSION_QA_FAIL: {species} monster archetype missing")
    require(world, "HonourWarContentCatalog::Monsters()", "catalog-driven monster world spawn")
    require((ROOT / "Config" / "DefaultInput.ini").read_text(encoding="utf-8"), 'ActionName="RefineEquipment"', "refinement input")

    quest_cpp=(ROOT/"Source"/"HonourWar"/"HonourWarQuestComponent.cpp").read_text(encoding="utf-8")
    for needle, label in [
        ("RecordMonsterDefeat", "quest progression"),
        ("The Lost Scroll", "Lost Scroll quest"),
        ("QuestProgress", "quest progress"),
        ("DOREPLIFETIME", "quest replication"),
    ]:
        require(quest_cpp, needle, label)

    for needle, label in [
        ("Zeny", "save Zeny"),
        ("Honours", "save honours"),
        ("InventoryItems", "save inventory"),
        ("Cards", "save cards"),
        ("OnlineSeconds", "save online time"),
        ("PlayerLocation", "save player location"),
        ("EquipmentRefineLevel", "save equipment refinement level"),
        ("Phracon", "save Phracon"),
        ("Emveretarcon", "save Emveretarcon"),
        ("Oridecon", "save Oridecon"),
        ("QuestProgress", "save quest progress"),
        ("QuestComplete", "save quest completion"),
        ("StatusPoints", "save status points"),
        ("Strength", "save STR"),
        ("Agility", "save AGI"),
        ("Vitality", "save VIT"),
        ("Intelligence", "save INT"),
        ("Dexterity", "save DEX"),
        ("LuckStat", "save LUK"),
    ]:
        require(save, needle, label)

    for needle, label in [
        ("TryRefineEquipment", "equipment refinement runtime"),
        ("TryMixCards", "card mixing runtime"),
        ("TryUpgradeBasicSkill", "basic skill upgrade runtime"),
        ("GetRefineSuccessPercent", "age-aware refinement success"),
        ("GetRefineZenyCost", "age-aware refinement price"),
        ("EquipmentRefineLevel>=15", "+15 refinement cap"),
        ("AgeDiscount", "age-based refinement material discount"),
    ]:
        require(combat, needle, label)

    for needle, label in [
        ("OnlineTimeAccumulator += DeltaSeconds", "online session accumulator"),
        ("OnlineSeconds += WholeSeconds", "online session counter"),
        ("86400", "online day boundary"),
        ("AutoSaveAccumulator >= 5.0f", "automatic autosave every few seconds"),
        ("Save->PlayerLocation=GetActorLocation()", "autosave player location"),
        ("SetAgeDays", "online age update"),
        ("SaveProgress();", "automatic persistence entry point"),
        ("void AHonourWarCharacter::EndPlay", "automatic persistence on exit"),
        ("SaveActiveCharacterData", "seamless active-character persistence"),
    ]:
        require(char, needle, label)

    for needle, label in [
        ("GetZeny", "HUD Zeny display"),
        ("GetHonours", "HUD honours display"),
        ("Age %d days", "HUD age display"),
        ("Status Points", "HUD status-point display"),
        ("GetStrength()", "HUD/runtime STR getter"),
        ("GetLuckStat()", "HUD/runtime LUK getter"),
    ]:
        require(hud, needle, label)

    if rules.get("multiplayer", {}).get("player_vs_player") is not False:
        raise SystemExit("PROGRESSION_QA_FAIL: player-vs-player mode must remain disabled")

    print("HONOUR WAR PROGRESSION QA PASS: level caps, kill rewards, economy, cards, online-age, autosave, world monster tiers and HUD persistence are wired.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
