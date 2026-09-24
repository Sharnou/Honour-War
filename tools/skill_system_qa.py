#!/usr/bin/env python3
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
jobs=json.loads((ROOT/"data/honour_war_class_jobs.json").read_text(encoding="utf-8"))
profiles=json.loads((ROOT/"data/honour_war_character_profiles.json").read_text(encoding="utf-8"))
skills=json.loads((ROOT/"data/honour_war_skill_system.json").read_text(encoding="utf-8"))
classes=["Warrior","Mage","Archer","Thief","Acolyte","Merchant","Ranger"]
species=["Poring","Goblin","Wolf","Skeleton","Orc","Mantis","Golem","Dragon"]
entries=skills["skills"]
if skills["counts"] != {"classes":7,"jobs":35,"characters":70,"class_skill_entries":280,"skills_per_job":8,"tier5_characters":14,"tier5_skill_entries":56}: raise SystemExit("SKILL_QA_FAIL: counts")
if len(entries)!=280 or len({x["id"] for x in entries})!=280 or len({x["name"] for x in entries})!=280: raise SystemExit("SKILL_QA_FAIL: entry IDs/names")
for cl in classes:
    if len(jobs["classes"][cl]["tiers"])!=5: raise SystemExit(f"SKILL_QA_FAIL: {cl} tier count")
    for t in jobs["classes"][cl]["tiers"]:
        es=[x for x in entries if x["job_id"]==t["id"]]
        if len(es)!=8: raise SystemExit(f"SKILL_QA_FAIL: {t['id']} skill count")
        for i,e in enumerate(es,1):
            if e["slot"]!=i or e["skill_level_cap"]!=10 or e["skill_level_multiplier"]!=0.08: raise SystemExit(f"SKILL_QA_FAIL: {e['id']} scaling")
            if set(e["monster_impact"])!=set(species): raise SystemExit(f"SKILL_QA_FAIL: {e['id']} monster coverage")
            if e["name"] not in t["skills"]: raise SystemExit(f"SKILL_QA_FAIL: {e['id']} missing from job loadout")
    t5=next(t for t in jobs["classes"][cl]["tiers"] if t["tier"]==5)
    if len([x for x in entries if x["job_id"]==t5["id"]])!=8: raise SystemExit(f"SKILL_QA_FAIL: {cl} T5")
for cl in classes:
    for g in ("male","female"):
        rows=[p for p in profiles["profiles"] if p["class"]==cl and p["gender"]==g]
        if len(rows)!=5: raise SystemExit(f"SKILL_QA_FAIL: profile coverage {cl}/{g}")
        for row in rows:
            names=row["combat"]["signature_skills"]
            job=next(t for t in jobs["classes"][cl]["tiers"] if t["tier"]==row["tier"])
            if names!=job["skills"]: raise SystemExit(f"SKILL_QA_FAIL: profile/job skill mismatch {row['id']}")
if len(skills["tier5_monster_impact"])!=7 or any(x["skill_count"]!=8 for x in skills["tier5_monster_impact"]): raise SystemExit("SKILL_QA_FAIL: T5 impact coverage")
cpp=(ROOT/"Source/HonourWar/HonourWarCombatComponent.cpp").read_text(encoding="utf-8")
pch=(ROOT/"Source/HonourWar/HonourWarPlayerController.cpp").read_text(encoding="utf-8")
sv=(ROOT/"Source/HonourWar/HonourWarSaveGame.h").read_text(encoding="utf-8")
if "GetSkillImpactMultiplierForSpecies" not in cpp or "TryResetSkills" not in cpp or "SkillPoints" not in sv: raise SystemExit("SKILL_QA_FAIL: runtime skill/respec integration")
if "@restskills" not in pch or "@skill" not in pch: raise SystemExit("SKILL_QA_FAIL: command integration")
print("SKILL_QA_PASS: 280 authored class-skill entries, 8 per job across 35 jobs, 70-character synchronization, 56 Tier-5 skills with 8 monster-family impact values each, skill allocation and Tier-5 respec runtime hooks.")
