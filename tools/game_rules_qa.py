#!/usr/bin/env python3
"""Honour War canonical rules and gameplay QA."""
from pathlib import Path
import json, re, sys
ROOT=Path(__file__).resolve().parents[1]
rules=json.loads((ROOT/"data/honour_war_default_rules.json").read_text(encoding="utf-8"))
catalog=json.loads((ROOT/"data/honour_war_content_catalog.json").read_text(encoding="utf-8"))
if rules.get("schema_version")!="3.0.0": raise SystemExit("GAME_RULES_QA_FAIL: rules schema")
if rules.get("hero_level_cap")!=250 or rules.get("monster_level_cap")!=300: raise SystemExit("GAME_RULES_QA_FAIL: level caps")
if rules.get("monster_variant_count")!=256 or rules.get("monster_population",{}).get("variants")!=256: raise SystemExit("GAME_RULES_QA_FAIL: monster population")
if len(catalog.get("monsters",[]))!=256: raise SystemExit("GAME_RULES_QA_FAIL: catalog monster count")
status=rules.get("status_points",{})
for key,val in {"starting_status_points":30,"starting_stat_value":10,"stat_cap":120,"per_level_gain":3}.items():
    if status.get(key)!=val: raise SystemExit(f"GAME_RULES_QA_FAIL: status rule {key}")
if status.get("milestone_bonus",{}).get("bonus_points")!=5 or status.get("milestone_bonus",{}).get("every_levels")!=25:
    raise SystemExit("GAME_RULES_QA_FAIL: status milestone")
combat=rules.get("combat_rules",{})
for key in ["normal_attack","critical","lucky_defense","miss","mitigation","skill_cost","skill_cooldown","monster_archetype_behavior","low_health_enrage"]:
    if key not in combat: raise SystemExit(f"GAME_RULES_QA_FAIL: combat rule {key}")
if len(combat["monster_archetype_behavior"])!=8: raise SystemExit("GAME_RULES_QA_FAIL: monster behavior archetypes")
if rules.get("map_rules",{}).get("maps")!=24: raise SystemExit("GAME_RULES_QA_FAIL: map count")
if rules.get("multiplayer",{}).get("player_vs_player") is not False: raise SystemExit("GAME_RULES_QA_FAIL: PvP must remain disabled")
if rules.get("visual_runtime",{}).get("approved_asset_intake")!=["FBX","OBJ"]: raise SystemExit("GAME_RULES_QA_FAIL: visual intake")
if "city_system" in rules: raise SystemExit("GAME_RULES_QA_FAIL: retired city service section remains")
if rules.get("death_rules",{}).get("death_limit") is not False: raise SystemExit("GAME_RULES_QA_FAIL: death limit")
if rules.get("refinement_rules",{}).get("cap")!=15: raise SystemExit("GAME_RULES_QA_FAIL: refinement cap")
if rules.get("equipment_rules",{}).get("level_requirement_range")!=[1,250]: raise SystemExit("GAME_RULES_QA_FAIL: equipment level range")
print("GAME_RULES_QA_PASS: canonical rules, 256 monsters, six-stat allocation, combat, death, refinement, equipment, maps and network restrictions are coherent.")
