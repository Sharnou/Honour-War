#!/usr/bin/env python3
"""Honour War permanent Unreal Engine 5.8 repository contract."""

from __future__ import annotations
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]

required = [
    ROOT / "HonourWar.uproject",
    ROOT / "Config" / "DefaultEngine.ini",
    ROOT / "Source" / "HonourWar" / "HonourWar.Build.cs",
    ROOT / "Source" / "HonourWar" / "HonourWarGameMode.h",
    ROOT / "Source" / "HonourWar" / "HonourWarGameMode.cpp",
    ROOT / "Source" / "HonourWar" / "HonourWarCharacter.h",
    ROOT / "Source" / "HonourWar" / "HonourWarCharacter.cpp",
    ROOT / "Source" / "HonourWar" / "HonourWarCombatComponent.h",
    ROOT / "Source" / "HonourWar" / "HonourWarCombatComponent.cpp",
    ROOT / "Source" / "HonourWar" / "HonourWarWorldDirector.h",
    ROOT / "Source" / "HonourWar" / "HonourWarWorldDirector.cpp",
    ROOT / "Source" / "HonourWar" / "HonourWarMonster.h",
    ROOT / "Source" / "HonourWar" / "HonourWarMonster.cpp",
    ROOT / "Source" / "HonourWar" / "HonourWarHUD.h",
    ROOT / "Source" / "HonourWar" / "HonourWarHUD.cpp",
    ROOT / "Source" / "HonourWar" / "HonourWarHUDWidget.h",
    ROOT / "Source" / "HonourWar" / "HonourWarHUDWidget.cpp",
    ROOT / "Source" / "HonourWar" / "HonourWarPlayerController.h",
    ROOT / "Source" / "HonourWar" / "HonourWarPlayerController.cpp",
    ROOT / "Source" / "HonourWar" / "HonourWarScreenshotDirector.h",
    ROOT / "Source" / "HonourWar" / "HonourWarScreenshotDirector.cpp",
]

for path in required:
    if not path.is_file():
        print(f"UNREAL_CONTRACT_FAIL: missing {path.relative_to(ROOT)}")
        sys.exit(1)

project = json.loads((ROOT / "HonourWar.uproject").read_text(encoding="utf-8"))
if project.get("EngineAssociation") != "5.8":
    print("UNREAL_CONTRACT_FAIL: EngineAssociation must be 5.8")
    sys.exit(1)

for path in ROOT.rglob("*"):
    if not path.is_file():
        continue
    rel = path.relative_to(ROOT).as_posix().lower()
    if path.suffix.lower() in {".gd",".tscn",".tres",".godot",".import",".uid"}:
        print(f"UNREAL_CONTRACT_FAIL: retired Godot file remains: {rel}")
        sys.exit(1)
    if rel=="project.godot" or rel.endswith("/godot-validation.yml"):
        print(f"UNREAL_CONTRACT_FAIL: retired Godot project/workflow remains: {rel}")
        sys.exit(1)
    if rel.endswith("/rungodot.bat"):
        print(f"UNREAL_CONTRACT_FAIL: retired Godot launcher remains: {rel}")
        sys.exit(1)

for text_file in [
    ROOT / "README.md",
    ROOT / "ART_PIPELINE.md",
    ROOT / "VISUAL_REFERENCE_CONTRACT.md",
    ROOT / "docs" / "NO_GODOT_FOREVER.md",
    ROOT / "docs" / "UNREAL_ENGINE_5_8_STANDARD.md",
]:
    content=text_file.read_text(encoding="utf-8")
    if "Unreal Engine 5.8" not in content:
        print(f"UNREAL_CONTRACT_FAIL: missing UE5.8 marker in {text_file.relative_to(ROOT)}")
        sys.exit(1)

print("UNREAL_CONTRACT_PASS: Unreal Engine 5.8 is the sole active Honour War runtime.")
