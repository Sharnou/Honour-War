#!/usr/bin/env python3
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
d=json.loads((ROOT/"data/honour_war_character_profiles.json").read_text(encoding="utf-8"))
if d.get("count")!=70 or len(d.get("profiles",[]))!=70: raise SystemExit("CHARACTER_PROFILE_QA_FAIL: expected 70 profiles")
if len({x["character_id"] for x in d["profiles"]})!=70: raise SystemExit("CHARACTER_PROFILE_QA_FAIL: duplicate character IDs")
for x in d["profiles"]:
    for k in ("id","character_id","name","class","tier","job_id","job_name","title","gender","face","hair","clothing","equipment","combat","emotions"):
        if not x.get(k): raise SystemExit(f"CHARACTER_PROFILE_QA_FAIL: {x.get('id','unknown')} missing {k}")
    if len(x["combat"].get("signature_skills",[]))!=8: raise SystemExit(f"CHARACTER_PROFILE_QA_FAIL: {x['id']} skill count")
    if x["tier"] not in (1,2,3,4,5): raise SystemExit(f"CHARACTER_PROFILE_QA_FAIL: tier {x['id']}")
    if not x.get("stat_profile") or not x.get("pet_profile"): raise SystemExit(f"CHARACTER_PROFILE_QA_FAIL: authored progression/pet metadata {x['id']}")
for c in ("Warrior","Mage","Archer","Thief","Acolyte","Merchant","Ranger"):
    for g in ("male","female"):
        rows=[x for x in d["profiles"] if x["class"]==c and x["gender"]==g]
        if len(rows)!=5 or {x["tier"] for x in rows}!={1,2,3,4,5}: raise SystemExit(f"CHARACTER_PROFILE_QA_FAIL: class/gender/tier coverage {c}/{g}")
print("CHARACTER_PROFILE_QA_PASS: 70 characters have gender, face, hair, clothing, equipment, emotions, job, skills, stats and combat identity metadata.")
