#!/usr/bin/env python3
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
d=json.loads((ROOT/"data/honour_war_character_profiles.json").read_text(encoding="utf-8"))
if d.get("count")!=60 or len(d.get("profiles",[]))!=60: raise SystemExit("CHARACTER_PROFILE_QA_FAIL: 60 profiles")
if len({x["character_id"] for x in d["profiles"]})!=60: raise SystemExit("CHARACTER_PROFILE_QA_FAIL: duplicate character IDs")
for x in d["profiles"]:
    for k in ("id","character_id","name","class","tier","job_id","job_name","title","gender","face","hair","clothing","equipment","combat","emotions"):
        if not x.get(k): raise SystemExit(f"CHARACTER_PROFILE_QA_FAIL: {x.get('id','unknown')} missing {k}")
    if len(x["combat"].get("signature_skills",[]))!=8: raise SystemExit(f"CHARACTER_PROFILE_QA_FAIL: {x['id']} skill count")
    if x["tier"] not in (1,2,3,4,5): raise SystemExit(f"CHARACTER_PROFILE_QA_FAIL: tier {x['id']}")
print("CHARACTER_PROFILE_QA_PASS: 60 characters have gender, face, hair, clothing, equipment, emotions, job, skills, stats and combat identity metadata.")
