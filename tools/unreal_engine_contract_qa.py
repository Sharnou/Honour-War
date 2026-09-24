#!/usr/bin/env python3
"""Honour War Unreal Engine 5.8 repository contract."""
from __future__ import annotations
import json
from pathlib import Path
import sys
ROOT=Path(__file__).resolve().parents[1]
required=[ROOT/"HonourWar.uproject",ROOT/"Source"/"HonourWar.Target.cs",ROOT/"Source"/"HonourWarEditor.Target.cs",ROOT/"Config"/"DefaultEngine.ini",ROOT/"Source"/"HonourWar"/"HonourWar.Build.cs",ROOT/"Source"/"HonourWar"/"HonourWarGameMode.h",ROOT/"Source"/"HonourWar"/"HonourWarGameMode.cpp",ROOT/"Source"/"HonourWar"/"HonourWarCharacter.h",ROOT/"Source"/"HonourWar"/"HonourWarCharacter.cpp",ROOT/"Source"/"HonourWar"/"HonourWarCombatComponent.h",ROOT/"Source"/"HonourWar"/"HonourWarCombatComponent.cpp",ROOT/"Source"/"HonourWar"/"HonourWarWorldDirector.h",ROOT/"Source"/"HonourWar"/"HonourWarWorldDirector.cpp",ROOT/"Source"/"HonourWar"/"HonourWarMonster.h",ROOT/"Source"/"HonourWar"/"HonourWarMonster.cpp",ROOT/"Source"/"HonourWar"/"HonourWarHUD.h",ROOT/"Source"/"HonourWar"/"HonourWarHUD.cpp",ROOT/"Source"/"HonourWar"/"HonourWarHUDWidget.h",ROOT/"Source"/"HonourWar"/"HonourWarHUDWidget.cpp",ROOT/"Source"/"HonourWar"/"HonourWarClassProgression.h",ROOT/"Source"/"HonourWar"/"HonourWarPlayerController.h",ROOT/"Source"/"HonourWar"/"HonourWarPlayerController.cpp",ROOT/"Source"/"HonourWar"/"HonourWarPlayerState.h",ROOT/"Source"/"HonourWar"/"HonourWarGameState.h",ROOT/"Source"/"HonourWar"/"HonourWarGameState.cpp",ROOT/"Source"/"HonourWar"/"HonourWarPlayerState.cpp",ROOT/"Source"/"HonourWar"/"HonourWarLootDatabase.h",ROOT/"Source"/"HonourWar"/"HonourWarContentCatalog.h",ROOT/"Source"/"HonourWar"/"HonourWarQuestComponent.h",ROOT/"Source"/"HonourWar"/"HonourWarQuestComponent.cpp",ROOT/"Source"/"HonourWar"/"HonourWarCombatEffect.h",ROOT/"Source"/"HonourWar"/"HonourWarCombatEffect.cpp",ROOT/"Source"/"HonourWar"/"HonourWarDamagePopup.h",ROOT/"Source"/"HonourWar"/"HonourWarDamagePopup.cpp",ROOT/"Source"/"HonourWar"/"HonourWarScreenshotDirector.h",ROOT/"Source"/"HonourWar"/"HonourWarScreenshotDirector.cpp",ROOT/"data"/"honour_war_class_tiers.json",ROOT/"data"/"honour_war_maps.json",ROOT/"data"/"honour_war_content_catalog.json",ROOT/"tools"/"content_catalog_qa.py",ROOT/"docs"/"MMORPG_MOUSE_CONTROL_SPEC.md",ROOT/"docs"/"VISUAL_DEVELOPMENT_CYCLE_CONTRACT.md",ROOT/"docs"/"HONOUR_WAR_HD_MMO_ANIME_STYLE_CONTRACT.md",ROOT/"docs"/"HONOUR_WAR_HD_GENERATION_BIBLE.md",ROOT/"assets"/"3d"/"visual_rag"/"LATEST_VISUAL_BRIEF.json",ROOT/"docs"/"HONOUR_WAR_PERMANENT_EXCLUSIONS.md",ROOT/"tools"/"rejected_systems_qa.py"]
for p in required:
    if not p.is_file(): print(f"UNREAL_CONTRACT_FAIL: missing {p.relative_to(ROOT)}"); sys.exit(1)
project=json.loads((ROOT/"HonourWar.uproject").read_text(encoding="utf-8"))
if project.get("EngineAssociation")!="5.8": print("UNREAL_CONTRACT_FAIL: EngineAssociation must be 5.8"); sys.exit(1)
if any(p.get("Name")=="UMG" for p in project.get("Plugins", [])): print("UNREAL_CONTRACT_FAIL: UMG must remain a module, not a project plugin"); sys.exit(1)
catalog=json.loads((ROOT/"data"/"honour_war_content_catalog.json").read_text(encoding="utf-8"))
for k,v in {"characters":70,"monsters":256,"maps":24,"equipment":300,"cards":300}.items():
    if len(catalog[k])!=v: print(f"UNREAL_CONTRACT_FAIL: catalog {k} count"); sys.exit(1)
controller=(ROOT/"Source"/"HonourWar"/"HonourWarPlayerController.cpp").read_text(encoding="utf-8")
world=(ROOT/"Source"/"HonourWar"/"HonourWarWorldDirector.cpp").read_text(encoding="utf-8")
if "HonourWarContentCatalog::Maps()" not in controller: print("UNREAL_CONTRACT_FAIL: map catalog not used"); sys.exit(1)
if "HonourWarContentCatalog::Monsters()" not in world: print("UNREAL_CONTRACT_FAIL: monster catalog not used"); sys.exit(1)
hud=(ROOT/"Source"/"HonourWar"/"HonourWarHUDWidget.cpp").read_text(encoding="utf-8")
for phrase in ["CreateWarriorCharacter","CreateMageCharacter","CreateArcherCharacter","CreateThiefCharacter","CreateAcolyteCharacter","CreateMerchantCharacter","CreateRangerCharacter"]:
    if phrase not in hud: print(f"UNREAL_CONTRACT_FAIL: seven-class character creation missing: {phrase}"); sys.exit(1)
if "Prontera City" not in hud and "Crownfall Capital" not in hud:
    print("UNREAL_CONTRACT_FAIL: HUD missing recognized capital map label"); sys.exit(1)
for phrase in ["Active Quest","MMORPGChat","MMORPGMiniMap","Equip +","Age %d days"]:
    if phrase not in hud: print(f"UNREAL_CONTRACT_FAIL: HUD missing {phrase}"); sys.exit(1)
for phrase in ["COMBAT SKILLS","BuildSkillBar","SkillButtons","SkillTitle","SkillRow","PlayerPanel"]:
    if phrase in hud: print(f"UNREAL_CONTRACT_FAIL: retired HUD element remains: {phrase}"); sys.exit(1)
progression=(ROOT/"Source"/"HonourWar"/"HonourWarClassProgression.h").read_text(encoding="utf-8")
for phrase in ["EHonourWarClassTier","Tier5","EHonourWarFifthTierArchetype","NaturalFifthTier","FifthTierProfile"]:
    if phrase not in progression: print(f"UNREAL_CONTRACT_FAIL: fifth-tier class system missing: {phrase}"); sys.exit(1)
for phrase in ["HandleMouseClick","GetHitResultUnderCursorByChannel","SetMouseTarget","SetMouseDestination","HandleMouseWheel","RotateCameraFromMouse","bHasLastMousePosition","ExecuteGoCommand","HonourWarContentCatalog::Maps()"]:
    if phrase not in controller: print(f"UNREAL_CONTRACT_FAIL: MMORPG control/map integration missing: {phrase}"); sys.exit(1)
combat=(ROOT/"Source"/"HonourWar"/"HonourWarCombatComponent.cpp").read_text(encoding="utf-8"); monster=(ROOT/"Source"/"HonourWar"/"HonourWarMonster.cpp").read_text(encoding="utf-8"); ch=(ROOT/"Source"/"HonourWar"/"HonourWarCharacter.h").read_text(encoding="utf-8"); cr=(ROOT/"Source"/"HonourWar"/"HonourWarCharacter.cpp").read_text(encoding="utf-8")
for phrase in ["void ReceiveMonsterDamage(float Damage,int32 AttackerLevel=1);","void PlayIncomingAttackReaction(bool bCritical);"]:
    if phrase not in ch: print(f"UNREAL_CONTRACT_FAIL: reaction API missing: {phrase}"); sys.exit(1)
for phrase in ["HitStutterTimer=0.25f","GetCharacterMovement()->StopMovementImmediately()","CombatComponent->ReceiveMonsterAttack(Damage,AttackerLevel)"]:
    if phrase not in cr: print(f"UNREAL_CONTRACT_FAIL: player reaction missing: {phrase}"); sys.exit(1)
if "SpawnActor<AHonourWarMonster>" not in world: print("UNREAL_CONTRACT_FAIL: monster spawning missing"); sys.exit(1)
if "ReceiveCombatHit(float Damage,EHonourWarClass SourceClass,bool bCritical)" not in monster: print("UNREAL_CONTRACT_FAIL: monster combat reaction missing"); sys.exit(1)
quest=(ROOT/"Source"/"HonourWar"/"HonourWarQuestComponent.cpp").read_text(encoding="utf-8")
for phrase in ["RecordMonsterDefeat","The Lost Scroll","QuestProgress","QuestGoal","DOREPLIFETIME"]:
    if phrase not in quest: print(f"UNREAL_CONTRACT_FAIL: quest missing {phrase}"); sys.exit(1)
game_mode=(ROOT/"Source"/"HonourWar"/"HonourWarGameMode.cpp").read_text(encoding="utf-8")
for phrase in ["HandleGuildCommand","@guild","HandleChatCommand","@say"]:
    if phrase not in game_mode: print(f"UNREAL_CONTRACT_FAIL: chat/guild missing {phrase}"); sys.exit(1)
visual=(ROOT/"assets"/"3d"/"visual_rag"/"LATEST_VISUAL_BRIEF.json").read_text(encoding="utf-8")
for phrase in ["HD 3D anime-inspired isometric MMORPG","Unreal Engine 5.8","FBX","OBJ","Screenshot/","Ragnarok Online-inspired"]:
    if phrase not in visual: print(f"UNREAL_CONTRACT_FAIL: visual contract missing {phrase}"); sys.exit(1)
for p in ROOT.rglob("*"):
    if p.is_file():
        rel=p.relative_to(ROOT).as_posix().lower()
        if p.suffix.lower() in {".gd",".tscn",".tres",".godot",".import",".uid"} or rel=="project.godot" or rel.endswith("/godot-validation.yml"):
            print(f"UNREAL_CONTRACT_FAIL: retired Godot file remains: {rel}"); sys.exit(1)
print("UNREAL_CONTRACT_PASS: Unreal 5.8 + 70-character/256-monster/24-map/300-equipment/300-card catalog integrated.")
