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
    ROOT/"Source"/"HonourWar"/"HonourWarPlayerState.h",
    ROOT/"Source"/"HonourWar"/"HonourWarGameState.h",
    ROOT/"Source"/"HonourWar"/"HonourWarGameState.cpp",
    ROOT/"Source"/"HonourWar"/"HonourWarPlayerState.cpp",
    ROOT/"Source"/"HonourWar"/"HonourWarLootDatabase.h",
    ROOT/"Source"/"HonourWar"/"HonourWarQuestComponent.h",
    ROOT/"Source"/"HonourWar"/"HonourWarQuestComponent.cpp",
    ROOT/"Source"/"HonourWar"/"HonourWarCombatEffect.h",
    ROOT/"Source"/"HonourWar"/"HonourWarCombatEffect.cpp",
    ROOT/"Source"/"HonourWar"/"HonourWarDamagePopup.h",
    ROOT/"Source"/"HonourWar"/"HonourWarDamagePopup.cpp",
    ROOT/"Source"/"HonourWar"/"HonourWarScreenshotDirector.h",
    ROOT/"Source"/"HonourWar"/"HonourWarScreenshotDirector.cpp",
    ROOT/"data"/"honour_war_class_tiers.json",
    ROOT/"data"/"honour_war_maps.json",
    ROOT/"docs"/"MMORPG_MOUSE_CONTROL_SPEC.md",
    ROOT/"docs"/"VISUAL_DEVELOPMENT_CYCLE_CONTRACT.md",
    ROOT/"docs"/"HONOUR_WAR_HD_MMO_ANIME_STYLE_CONTRACT.md",
    ROOT/"docs"/"HONOUR_WAR_HD_GENERATION_BIBLE.md",
    ROOT/"assets"/"3d"/"visual_rag"/"LATEST_VISUAL_BRIEF.json",
    ROOT/"docs"/"HONOUR_WAR_PERMANENT_EXCLUSIONS.md",
    ROOT/"tools"/"rejected_systems_qa.py",
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
for phrase in ["Prontera City","Active Quest","MMORPGChat","MMORPGMiniMap","Equip +","Age %d days"]:
    if phrase not in hud:
        print(f"UNREAL_CONTRACT_FAIL: MMORPG HUD element missing: {phrase}")
        sys.exit(1)

progression=(ROOT/"Source"/"HonourWar"/"HonourWarClassProgression.h").read_text(encoding="utf-8")
for phrase in ["EHonourWarClassTier","Tier5","EHonourWarFifthTierArchetype","NaturalFifthTier","FifthTierProfile"]:
    if phrase not in progression:
        print(f"UNREAL_CONTRACT_FAIL: fifth-tier class system missing: {phrase}")
        sys.exit(1)

controller=(ROOT/"Source"/"HonourWar"/"HonourWarPlayerController.cpp").read_text(encoding="utf-8")
for phrase in ["HandleMouseClick","GetHitResultUnderCursorByChannel","SetMouseTarget","SetMouseDestination","HandleMouseWheel","RotateCameraFromMouse","bHasLastMousePosition","ExecuteGoCommand","Anchors"]:
    if phrase not in controller:
        print(f"UNREAL_CONTRACT_FAIL: MMORPG mouse control missing: {phrase}")
        sys.exit(1)

combat=(ROOT/"Source"/"HonourWar"/"HonourWarCombatComponent.cpp").read_text(encoding="utf-8")
monster=(ROOT/"Source"/"HonourWar"/"HonourWarMonster.cpp").read_text(encoding="utf-8")
character_header=(ROOT/"Source"/"HonourWar"/"HonourWarCharacter.h").read_text(encoding="utf-8")
character_reaction=(ROOT/"Source"/"HonourWar"/"HonourWarCharacter.cpp").read_text(encoding="utf-8")
for phrase in ["void ReceiveMonsterDamage(float Damage,int32 AttackerLevel=1);","void PlayIncomingAttackReaction(bool bCritical);"]:
    if phrase not in character_header:
        print(f"UNREAL_CONTRACT_FAIL: player attack-reaction API missing: {phrase}")
        sys.exit(1)
for phrase in [
    "void AHonourWarCharacter::ReceiveMonsterDamage(float Damage,int32 AttackerLevel)",
    "void AHonourWarCharacter::PlayIncomingAttackReaction(bool bCritical)",
    "CombatComponent->ReceiveMonsterAttack(Damage,AttackerLevel)",
    "HitStutterTimer=0.25f",
    "HitStutterTimer=FMath::Max(0.0f,HitStutterTimer-DeltaSeconds)",
    "if(HitStutterTimer>0.0f)",
    "GetCharacterMovement()->StopMovementImmediately()"
]:
    if phrase not in character_reaction:
        print(f"UNREAL_CONTRACT_FAIL: player hit-stutter reaction missing: {phrase}")
        sys.exit(1)
for phrase in ["Character->PlayIncomingAttackReaction(bCritical)","ReceiveMonsterAttack(float Damage,int32 AttackerLevel)"]:
    if phrase not in combat:
        print(f"UNREAL_CONTRACT_FAIL: incoming attack reaction call-chain missing: {phrase}")
        sys.exit(1)

effect=(ROOT/"Source"/"HonourWar"/"HonourWarCombatEffect.cpp").read_text(encoding="utf-8")
popup=(ROOT/"Source"/"HonourWar"/"HonourWarDamagePopup.cpp").read_text(encoding="utf-8")
for phrase in ["Initialize","SetLifeSpan","SetLightColor"]:
    if phrase not in effect:
        print(f"UNREAL_CONTRACT_FAIL: combat effect missing: {phrase}")
        sys.exit(1)
for phrase in ["SetText","SetTextRenderColor","SetXScale","SetLifeSpan"]:
    if phrase not in popup:
        print(f"UNREAL_CONTRACT_FAIL: damage popup missing: {phrase}")
        sys.exit(1)

quest=(ROOT/"Source"/"HonourWar"/"HonourWarQuestComponent.cpp").read_text(encoding="utf-8")
for phrase in ["RecordMonsterDefeat","The Lost Scroll","QuestProgress","QuestGoal","DOREPLIFETIME"]:
    if phrase not in quest:
        print(f"UNREAL_CONTRACT_FAIL: quest system missing: {phrase}")
        sys.exit(1)

game_mode=(ROOT/"Source"/"HonourWar"/"HonourWarGameMode.cpp").read_text(encoding="utf-8")
for phrase in ["HandleGuildCommand","@guild","HandleChatCommand","@say"]:
    if phrase not in game_mode:
        print(f"UNREAL_CONTRACT_FAIL: guild server command missing: {phrase}")
        sys.exit(1)

game_state=(ROOT/"Source"/"HonourWar"/"HonourWarGameState.cpp").read_text(encoding="utf-8")
for phrase in ["AddWorldMessage","WorldMessages","DOREPLIFETIME"]:
    if phrase not in game_state:
        print(f"UNREAL_CONTRACT_FAIL: world chat state missing: {phrase}")
        sys.exit(1)

character=(ROOT/"Source"/"HonourWar"/"HonourWarCharacter.cpp").read_text(encoding="utf-8")
for phrase in ["ServerSetClassId_Implementation","OnRepCharacterClass","DOREPLIFETIME(AHonourWarCharacter,CharacterClass)"]:
    if phrase not in character:
        print(f"UNREAL_CONTRACT_FAIL: replicated class system missing: {phrase}")
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
for phrase in ["HD 3D anime-inspired isometric MMORPG","Unreal Engine 5.8","FBX","OBJ","Screenshot/","Ragnarok Online-inspired"]:
    if phrase not in visual:
        print(f"UNREAL_CONTRACT_FAIL: visual cycle identity missing: {phrase}")
        sys.exit(1)

cycle=(ROOT/"docs"/"VISUAL_DEVELOPMENT_CYCLE_CONTRACT.md").read_text(encoding="utf-8")
if "Every completed visual cycle" not in cycle or "does not re-enable" not in cycle:
    print("UNREAL_CONTRACT_FAIL: development-cycle visual contract missing or unsafe")
    sys.exit(1)

bible=(ROOT/"docs"/"HONOUR_WAR_HD_GENERATION_BIBLE.md").read_text(encoding="utf-8")
for phrase in ["HD 3D MMORPG / Anime-Inspired Generation Bible","Permanent exclusions","Approved asset pipeline","Runtime test matrix","Screenshot acceptance gate","Ragnarok Online-inspired"]:
    if phrase not in bible:
        print(f"UNREAL_CONTRACT_FAIL: generation bible incomplete: {phrase}")
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
