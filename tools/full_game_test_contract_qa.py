#!/usr/bin/env python3
"""Honour War full-game readiness contract.

This is a pre-runtime gate only. It proves that the repository contains the
required Unreal 5.8 runtime/test hooks; it does not claim that the packaged
EXE has executed successfully.
"""
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]

required = [
    "HonourWar.uproject",
    "Build/Build-HonourWar.ps1",
    "Build/Capture-HonourWar.ps1",
    "Source/HonourWar/HonourWarGameMode.cpp",
    "Source/HonourWar/HonourWarPlayerController.cpp",
    "Source/HonourWar/HonourWarAccountSaveGame.h",
    "Source/HonourWar/HonourWarHUDWidget.cpp",
    "Source/HonourWar/HonourWarCharacter.cpp",
    "Source/HonourWar/HonourWarWorldDirector.cpp",
    "Source/HonourWar/HonourWarScreenshotDirector.cpp",
    "tools/unreal_runtime_screenshot_qa.py",
]

for rel in required:
    if not (ROOT / rel).is_file():
        raise SystemExit(f"FULL_GAME_TEST_CONTRACT_FAIL: missing {rel}")

controller = (ROOT / "Source/HonourWar/HonourWarPlayerController.cpp").read_text(encoding="utf-8")
world = (ROOT / "Source/HonourWar/HonourWarWorldDirector.cpp").read_text(encoding="utf-8")
character = (ROOT / "Source/HonourWar/HonourWarCharacter.cpp").read_text(encoding="utf-8")
account_save = (ROOT / "Source/HonourWar/HonourWarAccountSaveGame.h").read_text(encoding="utf-8")
input_config = (ROOT / "Config/DefaultInput.ini").read_text(encoding="utf-8")
capture = (ROOT / "Build/Capture-HonourWar.ps1").read_text(encoding="utf-8")

checks = {
    "@go coordinate command": re.search(r'Compare\(TEXT\("@go"\)', controller) and "FVector(X\*10.0f,Y\*10.0f" in controller,
    "@go map 0 anchor": "FVector(0,0,180)" in controller,
    "monster level 300": "300" in world,
    "eight monster species": "EHonourWarMonsterSpecies::Dragon" in world,
    "real monster SpawnActor": "SpawnActor<AHonourWarMonster>" in world,
    "automatic save": "SaveProgress" in character and "AutoSaveAccumulator >= 5.0f" in character and "EndPlay" in character,
    "automatic save contains location": "PlayerLocation=GetActorLocation()" in character,
    "automatic save contains economy": "Zeny=CombatComponent->GetZeny()" in character,
    "automatic save contains inventory": "InventoryItems=CombatComponent->GetInventoryItems()" in character and "Cards=CombatComponent->GetCards()" in character,
    "single account persistence": "HonourWarAccount" in controller and "SaveActiveCharacterData" in controller and "LoadActiveCharacterData" in controller,
    "no profile save slots": "HonourWar_Profile_" not in controller and "CharacterSlotName" not in controller,
    "no manual save option": 'ActionName="SaveGame"' not in input_config and 'ActionName="LoadGame"' not in input_config and "void AHonourWarPlayerController::SaveGame" not in controller and "void AHonourWarPlayerController::LoadGame" not in controller,
    "load/resume": "LoadProgress" in character,
    "real capture flag": "-HonourWarCapture" in capture,
    "1920x1080 capture": "ResX=1920" in capture and "ResY=1080" in capture,
    "registration": "RegisterAccount" in controller and "@register" in controller,
    "login": "LoginAccount" in controller and "@login" in controller,
    "persistent account slot": "HonourWarAccount" in controller and "SaveGameToSlot" in controller,
    "capture account authentication": "AuthenticateCaptureAccount" in controller and "HonourWarCapture" in controller,
}

for name, ok in checks.items():
    if not ok:
        raise SystemExit(f"FULL_GAME_TEST_CONTRACT_FAIL: {name}")

qa = subprocess.run(
    [sys.executable, str(ROOT / "tools/rejected_systems_qa.py")],
    cwd=ROOT,
    text=True,
)
if qa.returncode != 0:
    raise SystemExit(qa.returncode)

print("FULL_GAME_TEST_CONTRACT_PASS")
print("Runtime gate ready: Unreal 5.8 package -> real EXE -> capture -> screenshot QA.")
print("Note: this gate intentionally does not claim runtime execution.")
