#!/usr/bin/env python3
"""Honour War production content-catalog QA."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
c=json.loads((ROOT/"data/honour_war_content_catalog.json").read_text(encoding="utf-8"))
expected={"characters":70,"monsters":256,"maps":24,"equipment":300,"cards":300}
for k,v in expected.items():
    if len(c[k])!=v: raise SystemExit(f"CONTENT_CATALOG_FAIL: {k} count={len(c[k])}, expected={v}")
if len(c["items"])!=76: raise SystemExit(f"CONTENT_CATALOG_FAIL: items count={len(c['items'])}, expected=76")
for k in expected:
    ids=[x["id"] for x in c[k]]
    if len(ids)!=len(set(ids)): raise SystemExit(f"CONTENT_CATALOG_FAIL: duplicate {k} IDs")
for k in ("characters","monsters","maps","equipment","items","cards"):
    names=[x["name"] for x in c[k]]
    if any(not n.strip() for n in names): raise SystemExit(f"CONTENT_CATALOG_FAIL: empty {k} name")
if len({x["name"] for x in c["characters"]})!=70: raise SystemExit("CONTENT_CATALOG_FAIL: character names are not unique")
if len({x["name"] for x in c["monsters"]})!=256: raise SystemExit("CONTENT_CATALOG_FAIL: monster names are not unique")
controller_text=(ROOT/"Source/HonourWar/HonourWarPlayerController.cpp").read_text(encoding="utf-8")
hud_header=(ROOT/"Source/HonourWar/HonourWarHUDWidget.h").read_text(encoding="utf-8")
hud_cpp=(ROOT/"Source/HonourWar/HonourWarHUDWidget.cpp").read_text(encoding="utf-8")
if "OwnedCharacters.Num()<70" not in controller_text or "i<70" not in controller_text: raise SystemExit("CONTENT_CATALOG_FAIL: roster capacity is not 70")
if "CharacterSlotInput" not in hud_header or "CharacterSlotInput" not in hud_cpp or "Character slot 1-70" not in hud_cpp: raise SystemExit("CONTENT_CATALOG_FAIL: 1-70 character selector missing")
if len({x["visual_archetype"] for x in c["monsters"]}) < 8: raise SystemExit("CONTENT_CATALOG_FAIL: monster archetype diversity incomplete")
if 300 not in {x["level"] for x in c["monsters"]}: raise SystemExit("CONTENT_CATALOG_FAIL: level-300 monster is missing")
if any(x["level"]<1 or x["level"]>300 for x in c["monsters"]): raise SystemExit("CONTENT_CATALOG_FAIL: monster level out of range")
if not {1,250}.issubset({x["level_required"] for x in c["equipment"]}): raise SystemExit("CONTENT_CATALOG_FAIL: equipment level range incomplete")
if any(x["refine_max"]<15 for x in c["equipment"]): raise SystemExit("CONTENT_CATALOG_FAIL: equipment refine cap incomplete")
if not {"Phracon","Emveretarcon","Oridecon","Zeny"}.issubset(set(sum((x["refine_materials"] for x in c["equipment"]),[]))): raise SystemExit("CONTENT_CATALOG_FAIL: refine materials missing")
if c["equipment"][-1]["name"]!="Transcendent Monster Suit": raise SystemExit("CONTENT_CATALOG_FAIL: level-300 suit reward missing")
if c["cards"][-1]["name"]!="World Monarch Card": raise SystemExit("CONTENT_CATALOG_FAIL: level-300 card reward missing")
maps=json.loads((ROOT/"data/honour_war_maps.json").read_text(encoding="utf-8"))["maps"]
if len(maps)!=24: raise SystemExit("CONTENT_CATALOG_FAIL: maps JSON count")
if len({x["id"] for x in maps})!=24: raise SystemExit("CONTENT_CATALOG_FAIL: map IDs are not unique")
if "market" in (ROOT/"data/honour_war_maps.json").read_text(encoding="utf-8").lower(): raise SystemExit("CONTENT_CATALOG_FAIL: retired market reference")
controller=(ROOT/"Source/HonourWar/HonourWarPlayerController.cpp").read_text(encoding="utf-8")
world=(ROOT/"Source/HonourWar/HonourWarWorldDirector.cpp").read_text(encoding="utf-8")
loot=(ROOT/"Source/HonourWar/HonourWarLootDatabase.h").read_text(encoding="utf-8")
combat=(ROOT/"Source/HonourWar/HonourWarCombatComponent.cpp").read_text(encoding="utf-8")
if "HonourWarContentCatalog::Maps()" not in controller: raise SystemExit("CONTENT_CATALOG_FAIL: map runtime integration")
if "HonourWarContentCatalog::Monsters()" not in world: raise SystemExit("CONTENT_CATALOG_FAIL: monster runtime integration")
if "SpawnActor<AHonourWarMonster>" not in world: raise SystemExit("CONTENT_CATALOG_FAIL: monster SpawnActor integration")
if "EquipmentForRank" not in loot: raise SystemExit("CONTENT_CATALOG_FAIL: equipment rank API missing")
if 'TEXT("Transcendent Monster Suit")' not in loot or 'TEXT("World Monarch Card")' not in loot: raise SystemExit("CONTENT_CATALOG_FAIL: runtime level-300 rewards missing")
if "LootRank = FMath::Clamp(MonsterTier*40+MonsterFamilySlot+1,1,300)" not in combat: raise SystemExit("CONTENT_CATALOG_FAIL: full loot rank mapping missing")
if len(c.get("pets",[]))!=20 or len(c.get("pet_skills",[]))!=120 or len(c.get("pet_equipment",[]))!=100: raise SystemExit("CONTENT_CATALOG_FAIL: pet content expansion")
if not any(x["class"]=="Ranger" and x["slot"]=="Weapon" and x.get("weapon_family")=="Bolt Machine Gun" for x in c["equipment"]): raise SystemExit("CONTENT_CATALOG_FAIL: Ranger bolt machine gun equipment")
enc=json.loads((ROOT/"data/honour_war_item_encyclopedia.json").read_text(encoding="utf-8"))
if len(enc.get("entries",[]))!=797: raise SystemExit("CONTENT_CATALOG_FAIL: item encyclopedia count")
if len({x["id"] for x in enc["entries"]})!=797: raise SystemExit("CONTENT_CATALOG_FAIL: item encyclopedia IDs are not unique")
print("CONTENT_CATALOG_PASS: 70 characters, 256 monsters, 24 maps, 300 equipment, 76 items, 300 cards, 20 pets, 120 pet skills, 100 pet equipment.")
