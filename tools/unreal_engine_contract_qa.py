#!/usr/bin/env python3
"""Honour War permanent Unreal Engine 5.8 repository contract."""

from __future__ import annotations
import json
from pathlib import Path
import sys

ROOT=Path(__file__).resolve().parents[1]
required=[
    ROOT/"HonourWar.uproject",
    ROOT/"Config"/"DefaultEngine.ini",
    ROOT/"Source"/"HonourWar"/"HonourWar.Build.cs",
    ROOT/"Source"/"HonourWar"/"HonourWarGameMode.h",
    ROOT/"Source"/"HonourWar"/"HonourWarGameMode.cpp",
    ROOT/"Source"/"HonourWar"/"HonourWarCharacter.h",
    ROOT/"Source"/"HonourWar"/"HonourWarCharacter.cpp",
    ROOT/"Source"/"HonourWar"/"HonourWarCombatComponent.h",
    ROOT/"Source"/"HonourWar"/"HonourWarCombatComponent.cpp",
    ROOT/"Source"/"HonourWar"/"HonourWarWorldDirector.h",
    ROOT/"Source"/"HonourWar"/"HonourWarWorldDirector.cpp",
    ROOT/"Source"/"HonourWar"/"HonourWarMonster.h",
    ROOT/"Source"/"HonourWar"/"HonourWarMonster.cpp",
    ROOT/"Source"/"HonourWar"/"HonourWarHUD.h",
    ROOT/"Source"/"HonourWar"/"HonourWarHUD.cpp",
    ROOT/"Source"/"HonourWar"/"HonourWarHUDWidget.h",
    ROOT/"Source"/"HonourWar"/"HonourWarHUDWidget.cpp",
    ROOT/"Source"/"HonourWar"/"HonourWarClassProgression.h",
    ROOT/"Source"/"HonourWar"/"HonourWarPlayerController.h",
    ROOT/"Source"/"HonourWar"/"HonourWarPlayerController.cpp",
    ROOT/"Source"/"HonourWar"/"HonourWarScreenshotDirector.h",
    ROOT/"Source"/"HonourWar"/"HonourWarScreenshotDirector.cpp",
    ROOT/"data"/"honour_war_class_tiers.json",
    ROOT/"data"/"honour_war_maps.json",
    ROOT/"docs"/"MMORPG_MOUSE_CONTROL_SPEC.md",
    ROOT/"docs"/"VISUAL_DEVELOPMENT_CYCLE_CONTRACT.md",
    ROOT/"assets"/"3d"/"visual_rag"/"LATEST_VISUAL_BRIEF.json",
]
for path in required:
    if not path.is_file():
        print(f"UNREAL_CONTRACT_FAIL: missing {path.relative_to(ROOT)}")
        sys.exit(1)

project=json.loads((ROOT/"HonourWar.uproject").read_text(encoding="utf-8"))
if project.get("EngineAssociation")!="5.8":
    print("UNREAL_CONTRACT_FAIL: EngineAssociation must be 5.8")
    sys.exit(1)

hud=(ROOT/"Source"/"HonourWar"/"HonourWarHUDWidget.cpp").read_text(encoding="utf-8")
retired=["COMBAT SKILLS","BuildSkillBar","SkillButtons","SkillTitle","SkillRow","PlayerPanel"]
for phrase in retired:
    if phrase in hud:
        print(f"UNREAL_CONTRACT_FAIL: retired HUD element remains: {phrase}")
        sys.exit(1)

for phrase in ["Inventory","Character","Skills","Quests","Prontera City","Active Quest","Party","Guild","MMORPGChat","MMORPGMiniMap"]:
    if phrase not in hud:
        print(f"UNREAL_CONTRACT_FAIL: MMORPG HUD element missing: {phrase}")
        sys.exit(1)

progression=(ROOT/"Source"/"HonourWar"/"HonourWarClassProgression.h").read_text(encoding="utf-8")
for phrase in ["EHonourWarClassTier","Tier5","EHonourWarFifthTierArchetype","NaturalFifthTier","FifthTierProfile"]:
    if phrase not in progression:
        print(f"UNREAL_CONTRACT_FAIL: fifth-tier class system missing: {phrase}")
        sys.exit(1)

controller=(ROOT/"Source"/"HonourWar"/"HonourWarPlayerController.cpp").read_text(encoding="utf-8")
for phrase in ["HandleMouseClick","GetHitResultUnderCursorByChannel","SetMouseTarget","SetMouseDestination","HandleMouseWheel","RotateCameraFromMouse","bHasLastMousePosition"]:
    if phrase not in controller:
        print(f"UNREAL_CONTRACT_FAIL: MMORPG mouse control missing: {phrase}")
        sys.exit(1)

world=(ROOT/"Source"/"HonourWar"/"HonourWarWorldDirector.cpp").read_text(encoding="utf-8")
for phrase in ["BuildBiomeRegions","ForestRegion","MountainRegion","DesertRegion","SnowRegion","BuildDungeonGate","BuildRiverBridge"]:
    if phrase not in world:
        print(f"UNREAL_CONTRACT_FAIL: map design layer missing: {phrase}")
        sys.exit(1)

capture=(ROOT/"Source"/"HonourWar"/"HonourWarScreenshotDirector.cpp").read_text(encoding="utf-8")
if "FScreenshotRequest::RequestScreenshot(Output,true,false,false,FIntRect(),true)" not in capture:
    print("UNREAL_CONTRACT_FAIL: real screenshot must capture actual game viewport with HUD visible")
    sys.exit(1)

visual=(ROOT/"assets"/"3d"/"visual_rag"/"LATEST_VISUAL_BRIEF.json").read_text(encoding="utf-8")
for phrase in ["HD anime-inspired isometric MMORPG","Unreal Engine 5.8","FBX","OBJ","Screenshot/"]:
    if phrase not in visual:
        print(f"UNREAL_CONTRACT_FAIL: visual cycle identity missing: {phrase}")
        sys.exit(1)

cycle=(ROOT/"docs"/"VISUAL_DEVELOPMENT_CYCLE_CONTRACT.md").read_text(encoding="utf-8")
if "Every completed visual cycle" not in cycle or "does not re-enable" not in cycle:
    print("UNREAL_CONTRACT_FAIL: development-cycle visual contract missing or unsafe")
    sys.exit(1)

for path in ROOT.rglob("*"):
    if not path.is_file():
        continue
    rel=path.relative_to(ROOT).as_posix().lower()
    if path.suffix.lower() in {".gd",".tscn",".tres",".godot",".import",".uid"}:
        print(f"UNREAL_CONTRACT_FAIL: retired Godot file remains: {rel}")
        sys.exit(1)
    if rel=="project.godot" or rel.endswith("/godot-validation.yml"):
        print(f"UNREAL_CONTRACT_FAIL: retired Godot project/workflow remains: {rel}")
        sys.exit(1)

print("UNREAL_CONTRACT_PASS: Unreal Engine 5.8 + MMORPG HUD contract is active.")
