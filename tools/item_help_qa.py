#!/usr/bin/env python3
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
d=json.loads((ROOT/"data/honour_war_item_encyclopedia.json").read_text(encoding="utf-8")); e=d["entries"]
if len(e)!=795 or len({x["id"] for x in e})!=795: raise SystemExit("ITEM_HELP_QA_FAIL: unique entries")
for prefix,count in [("EQUIP_",300),("ITEM_",76),("CARD_",300)]:
    if len([x for x in e if x["id"].startswith(prefix)])!=count: raise SystemExit(f"ITEM_HELP_QA_FAIL: {prefix} count")
for x in e:
    if x["id"].startswith(("EQUIP_","ITEM_","CARD_")) and (not x.get("source") or not x["source"].get("monster_id") or not x["source"].get("map_name") or not x.get("when")): raise SystemExit(f"ITEM_HELP_QA_FAIL: source/availability {x['id']}")
pet=[x for x in e if x["id"].startswith("PETEQ_")]
if len(pet)!=100 or any(not x.get("source") or not x["source"].get("monster_id") or not x["source"].get("map_name") or not x.get("when") for x in pet): raise SystemExit("ITEM_HELP_QA_FAIL: pet equipment source/availability")
pc=(ROOT/"Source/HonourWar/HonourWarPlayerController.cpp").read_text(encoding="utf-8")
ec=(ROOT/"Source/HonourWar/HonourWarItemEncyclopedia.cpp").read_text(encoding="utf-8")
if "ExecuteHelpCommand" not in pc or "/help" not in pc or "BuildHelpLines" not in ec: raise SystemExit("ITEM_HELP_QA_FAIL: runtime help")
print("ITEM_HELP_QA_PASS: 795 searchable IDs with source monster, map and availability metadata.")
