#!/usr/bin/env python3
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
d=json.loads((ROOT/"data/honour_war_item_encyclopedia.json").read_text(encoding="utf-8")); e=d["entries"]
if len(e)!=797 or len({x["id"] for x in e})!=797: raise SystemExit("ITEM_HELP_QA_FAIL: unique entries")
for prefix,count in [("EQUIP_",300),("ITEM_",76),("CARD_",300),("JOBEQ_",14),("JOBCARD_",7),("PETEQ_",100)]:
    vals=[x["id"] for x in e if x["id"].startswith(prefix)]
    if len(vals)!=count or len(set(vals))!=count: raise SystemExit(f"ITEM_HELP_QA_FAIL: {prefix} count/uniqueness")
    if prefix in ("EQUIP_","ITEM_","CARD_","PETEQ_"):
        expected_ids=[f"{prefix}{i:03d}" for i in range(1,count+1)]
        if sorted(vals)!=sorted(expected_ids): raise SystemExit(f"ITEM_HELP_QA_FAIL: {prefix} ID sequence")
for x in e:
    if x["id"].startswith(("EQUIP_","ITEM_","CARD_","JOBEQ_","JOBCARD_","PETEQ_")) and (not x.get("source") or not x["source"].get("monster_id") or not x["source"].get("monster_name") or str(x["source"].get("monster_name","")).startswith("Monster #") or not x["source"].get("map_name") or not x.get("when")): raise SystemExit(f"ITEM_HELP_QA_FAIL: source/availability {x['id']}")
pet=[x for x in e if x["id"].startswith("PETEQ_")]
if len(pet)!=100 or any(not x.get("source") or not x["source"].get("monster_id") or not x["source"].get("map_name") or not x.get("when") for x in pet): raise SystemExit("ITEM_HELP_QA_FAIL: pet equipment source/availability")
catalog=json.loads((ROOT/"data/honour_war_content_catalog.json").read_text(encoding="utf-8"))
maps=json.loads((ROOT/"data/honour_war_maps.json").read_text(encoding="utf-8"))["maps"]
monsters={x["id"]:x for x in catalog["monsters"]}
valid_maps={x["id"] for x in maps}
enc_by_id={x["id"]:x for x in e}
for pool in ("equipment","items","cards","pet_equipment"):
    for x in catalog.get(pool,[]):
        if x["id"] not in enc_by_id: raise SystemExit(f"ITEM_HELP_QA_FAIL: catalog entry missing from encyclopedia {x['id']}")
for x in e:
    src=x.get("source")
    if src:
        m=monsters.get(src.get("monster_id"))
        if not m: raise SystemExit(f"ITEM_HELP_QA_FAIL: unknown source monster {x['id']} -> {src.get('monster_id')}")
        if src.get("monster_name")!=m["name"] or src.get("monster_level")!=m["level"]: raise SystemExit(f"ITEM_HELP_QA_FAIL: source monster mismatch {x['id']}")
        if src.get("map_id") not in valid_maps: raise SystemExit(f"ITEM_HELP_QA_FAIL: unknown source map {x['id']} -> {src.get('map_id')}")
pc=(ROOT/"Source/HonourWar/HonourWarPlayerController.cpp").read_text(encoding="utf-8")
ec=(ROOT/"Source/HonourWar/HonourWarItemEncyclopedia.cpp").read_text(encoding="utf-8")
combat=(ROOT/"Source/HonourWar/HonourWarCombatComponent.cpp").read_text(encoding="utf-8")
if "ExecuteHelpCommand" not in pc or "/help" not in pc or "BuildHelpLines" not in ec: raise SystemExit("ITEM_HELP_QA_FAIL: runtime help")
if "EQUIP_%03d" not in combat or "CARD_%03d" not in combat or "ITEM_%03d" not in combat: raise SystemExit("ITEM_HELP_QA_FAIL: runtime drops must expose canonical IDs")
print("ITEM_HELP_QA_PASS: 797 searchable catalog entries; every equipment/item/card/job reward/pet equipment entry has source monster, map and availability metadata.")
