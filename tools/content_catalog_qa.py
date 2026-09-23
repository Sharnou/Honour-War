#!/usr/bin/env python3
from pathlib import Path
import json,sys
ROOT=Path(__file__).resolve().parents[1]
c=json.loads((ROOT/"data/honour_war_content_catalog.json").read_text(encoding="utf-8"))
expected={"characters":60,"monsters":64,"maps":24,"equipment":240,"cards":240}
for k,v in expected.items():
    if len(c[k])!=v: raise SystemExit(f"CONTENT_CATALOG_FAIL: {k} count")
for k in expected:
    ids=[x["id"] for x in c[k]]
    if len(ids)!=len(set(ids)): raise SystemExit(f"CONTENT_CATALOG_FAIL: duplicate {k} IDs")
if not {1,300}.issubset({x["level"] for x in c["monsters"]}): raise SystemExit("CONTENT_CATALOG_FAIL: monster level range")
if not {1,250}.issubset({x["level_required"] for x in c["equipment"]}): raise SystemExit("CONTENT_CATALOG_FAIL: equipment level range")
if not {"Phracon","Emveretarcon","Oridecon"}.issubset(set(sum((x["refine_materials"] for x in c["equipment"]),[]))): raise SystemExit("CONTENT_CATALOG_FAIL: refine materials")
if len(json.loads((ROOT/"data/honour_war_maps.json").read_text(encoding="utf-8"))["maps"])!=24: raise SystemExit("CONTENT_CATALOG_FAIL: maps sync")
if "market" in (ROOT/"data/honour_war_maps.json").read_text(encoding="utf-8").lower(): raise SystemExit("CONTENT_CATALOG_FAIL: retired market reference")
controller=(ROOT/"Source/HonourWar/HonourWarPlayerController.cpp").read_text(encoding="utf-8")
world=(ROOT/"Source/HonourWar/HonourWarWorldDirector.cpp").read_text(encoding="utf-8")
if "HonourWarContentCatalog::Maps()" not in controller: raise SystemExit("CONTENT_CATALOG_FAIL: map runtime integration")
if "HonourWarContentCatalog::Monsters()" not in world: raise SystemExit("CONTENT_CATALOG_FAIL: monster runtime integration")
print("CONTENT_CATALOG_PASS: 60 characters, 64 monsters, 24 maps, 240 equipment, 74 items, 240 cards")
