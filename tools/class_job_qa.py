#!/usr/bin/env python3
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
d=json.loads((ROOT/"data/honour_war_class_jobs.json").read_text(encoding="utf-8"))
expected=["Warrior","Mage","Archer","Thief","Acolyte","Merchant","Ranger"]; levels=[1,25,50,150,200]
fifth={"Warrior":"Abyssal Warlord","Mage":"Eternal Spellwright","Archer":"Causality Marksman","Thief":"Absolute Shadow","Acolyte":"Eternal Benediction","Merchant":"Infinite Quartermaster","Ranger":"Verdant Paragon"}
if set(d.get("classes",{}))!=set(expected): raise SystemExit("CLASS_JOB_QA_FAIL: class set")
ids=[]
for cls in expected:
    tiers=d["classes"][cls]["tiers"]
    if len(tiers)!=5 or [x["required_level"] for x in tiers]!=levels: raise SystemExit(f"CLASS_JOB_QA_FAIL: {cls} tier architecture")
    if tiers[-1]["job_name"]!=fifth[cls]: raise SystemExit(f"CLASS_JOB_QA_FAIL: {cls} fifth tier")
    for x in tiers:
        ids.append(x["id"])
        if len(x.get("skills",[]))!=8 or not x.get("clothing") or not x.get("emotions") or not x.get("gender") or not x.get("signature_weapon"): raise SystemExit(f"CLASS_JOB_QA_FAIL: {x['id']} metadata")
if len(ids)!=35 or len(set(ids))!=35: raise SystemExit("CLASS_JOB_QA_FAIL: job IDs")
print("CLASS_JOB_QA_PASS: 7 classes, 35 jobs, five tiers, appearance, emotion, skills, equipment and power metadata.")
