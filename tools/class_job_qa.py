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
    if len(tiers)!=5 or [x["required_level"] for x in tiers]!=levels or not all(x.get("gender_variants") and x.get("visual_identity") and x.get("pet_affinity") for x in tiers): raise SystemExit(f"CLASS_JOB_QA_FAIL: {cls} tier architecture/appearance/pet metadata")
    if tiers[-1]["job_name"]!=fifth[cls]: raise SystemExit(f"CLASS_JOB_QA_FAIL: {cls} fifth tier")
    for x in tiers:
        ids.append(x["id"])
        if len(x.get("skills",[]))!=8 or len([s for s in x.get("skill_list","").split(";") if s])!=8 or not x.get("skill_profiles") or not x.get("clothing") or not x.get("emotions") or not x.get("gender") or not x.get("signature_weapon") or not x.get("stat_growth") or not x.get("equipment_progression"): raise SystemExit(f"CLASS_JOB_QA_FAIL: {x['id']} metadata")
if len(ids)!=35 or len(set(ids))!=35: raise SystemExit("CLASS_JOB_QA_FAIL: job IDs")
all_skills=[tuple(t["skills"]) for cls in expected for t in d["classes"][cls]["tiers"]]
if len(set(all_skills))!=35: raise SystemExit("CLASS_JOB_QA_FAIL: tier skill loadouts are not unique")
rangers=d["classes"]["Ranger"]["tiers"]
if not all(t.get("weapon_family") in ("Fantasy Gun","Bolt Machine Gun") for t in rangers): raise SystemExit("CLASS_JOB_QA_FAIL: Ranger firearm identity")
if not all(t.get("ammo_type")=="machine_gun_bolt" and t.get("ammo_name")=="Machine Gun Bolts" for t in rangers): raise SystemExit("CLASS_JOB_QA_FAIL: Ranger must use Machine Gun Bolts in every tier")
print("CLASS_JOB_QA_PASS: 7 classes, 35 jobs, five tiers, authored skills/stat growth/equipment/appearance metadata, Ranger firearm/ammunition identity.")
