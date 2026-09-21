#!/usr/bin/env python3
"""Honour War Unreal Engine 5.8 HD production-art validation."""

from __future__ import annotations

import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
ERRORS: list[str] = []


def fail(message: str) -> None:
    ERRORS.append(message)


def require_file(path: Path) -> None:
    if not path.is_file():
        fail(f"Missing required file: {path.relative_to(ROOT)}")


def require_dir(path: Path) -> None:
    if not path.is_dir():
        fail(f"Missing required directory: {path.relative_to(ROOT)}")


def validate_project() -> None:
    project = ROOT / "HonourWar.uproject"
    require_file(project)
    if not project.is_file():
        return
    data = json.loads(project.read_text(encoding="utf-8"))
    if data.get("EngineAssociation") != "5.8":
        fail("HonourWar.uproject must target Unreal Engine 5.8")


def validate_visual_identity() -> None:
    brief = ROOT / "assets" / "3d" / "visual_rag" / "LATEST_VISUAL_BRIEF.json"
    style = ROOT / "data" / "honour_war_visual_style.json"
    contract = ROOT / "docs" / "HONOUR_WAR_HD_MMO_ANIME_STYLE_CONTRACT.md"
    require_file(brief)
    require_file(style)
    require_file(contract)
    if brief.is_file():
        data = json.loads(brief.read_text(encoding="utf-8"))
        if data.get("identity") != "HD 3D anime-inspired isometric MMORPG/ARPG":
            fail("Visual brief identity drifted")
        if data.get("runtime_formats") != ["FBX", "OBJ"]:
            fail("Visual brief runtime formats must remain FBX/OBJ")
        if data.get("rejected_formats") != ["GLB", "GLTF"]:
            fail("Visual brief must permanently reject GLB/GLTF")
    if style.is_file():
        data = json.loads(style.read_text(encoding="utf-8"))
        if data.get("engine") != "Unreal Engine 5.8":
            fail("Visual style engine drifted")
        if data.get("camera", {}).get("right_drag_orbit") is not True:
            fail("Right-drag camera orbit is not locked")
        if data.get("gameplay_control", {}).get("left_click_ground") != "click-to-move":
            fail("Click-to-move control is not locked")


def validate_required_paths() -> None:
    for relative in (
        "Source/HonourWar/HonourWarCharacter.cpp",
        "Source/HonourWar/HonourWarPlayerController.cpp",
        "Source/HonourWar/HonourWarCombatComponent.cpp",
        "Source/HonourWar/HonourWarMonster.cpp",
        "Source/HonourWar/HonourWarSoldier.cpp",
        "Source/HonourWar/HonourWarWorldDirector.cpp",
        "tools/validate_camera_controls.py",
        "tools/honour_war_progression_contract_qa.py",
        "tools/visual_gap_register_qa.py",
    ):
        require_file(ROOT / relative)

    for relative in (
        "assets/3d",
        "assets/3d/visual_rag",
        "assets/3d/neural4d",
        "Content/HonourWarArt",
    ):
        require_dir(ROOT / relative)


def validate_no_legacy_generators() -> None:
    generators = [
        ROOT / "tools" / "blender" / "honour_war_monster_assets.py",
        ROOT / "tools" / "blender" / "honour_war_production_assets.py",
        ROOT / "tools" / "blender" / "honour_war_visual_max_assets.py",
        ROOT / "tools" / "blender" / "build_ss_production_asset.py",
        ROOT / "tools" / "blender" / "run_visual_max_assets.py",
    ]
    forbidden_markers = (
        "bpy.ops.export_scene.gltf",
        "bpy.ops.wm.gltf_export",
        ".glb")",
        ".gltf")",
    )
    for path in generators:
        if not path.is_file():
            continue
        text = path.read_text(encoding="utf-8", errors="ignore")
        for marker in forbidden_markers:
            if marker in text:
                fail(f"Legacy GLB/GLTF exporter remains in {path.relative_to(ROOT)}: {marker}")


def validate_generated_tree() -> None:
    generated = ROOT / "assets" / "3d" / "generated"
    if not generated.is_dir():
        return
    for path in generated.rglob("*"):
        if path.is_file() and path.suffix.lower() in {".glb", ".gltf"}:
            fail(f"Retired generated asset format present: {path.relative_to(ROOT)}")


def main() -> int:
    validate_project()
    validate_visual_identity()
    validate_required_paths()
    validate_no_legacy_generators()
    validate_generated_tree()

    if ERRORS:
        for error in ERRORS:
            print("HD_ART_FAIL:", error)
        return 1

    print("HONOUR WAR HD ART VALIDATION PASS")
    print("Unreal Engine 5.8 | HD 3D anime-inspired MMORPG | FBX/OBJ intake | legacy GLB/GLTF exporters blocked")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
