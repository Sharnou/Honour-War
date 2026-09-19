#!/usr/bin/env python3
"""Honour War native HD production-art validation.

The retired generated GLB/GLTF library is intentionally absent. CI validates
the approved native Godot 4.7.2 visual pipeline and optional Neural4D FBX/OBJ
handoff without importing GLB assets.
"""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
errors = []
notes = []

def fail(message):
    errors.append(message)

def require(path):
    if not path.exists():
        fail(f"Missing required path: {path.relative_to(ROOT)}")

def validate_project():
    project = ROOT / "project.godot"
    require(project)
    if not project.exists():
        return
    text = project.read_text(encoding="utf-8")
    for token in (
        'renderer/rendering_method="forward_plus"',
        'run/main_scene="res://Main3D.tscn"',
        'config/features=PackedStringArray("4.7")',
    ):
        if token not in text:
            fail(f"project.godot missing required token: {token}")

def validate_pipeline_docs():
    for relative in (
        "docs/DAILY_HONOUR_WAR_NO_GLB_POLICY.md",
        "docs/DAILY_HONOUR_WAR_VISUAL_UPGRADE_ROLE.md",
        "docs/NEURAL4D_REGENERATION_MANIFEST.md",
        "scripts/HDAssetRuntime.gd",
        "scripts/HWNativeWorldRecovery.gd",
    ):
        require(ROOT / relative)

def validate_directories():
    for relative in (
        "assets/3d/characters",
        "assets/3d/pets",
        "assets/3d/monsters",
        "assets/3d/maps",
        "assets/3d/props",
        "assets/3d/weapons",
        "assets/3d/armor",
        "assets/3d/effects",
    ):
        require(ROOT / relative)

def validate_no_retired_runtime_assets():
    generated = ROOT / "assets/3d/generated"
    glbs = list(generated.rglob("*.glb")) if generated.exists() else []
    gltfs = list(generated.rglob("*.gltf")) if generated.exists() else []
    if glbs or gltfs:
        for item in glbs + gltfs:
            fail(f"Retired generated GLB/GLTF asset present: {item.relative_to(ROOT)}")
    notes.append(f"Generated GLB/GLTF files: {len(glbs) + len(gltfs)}")

def validate_neural4d_policy():
    policy = (ROOT / "docs/DAILY_HONOUR_WAR_NO_GLB_POLICY.md").read_text(encoding="utf-8")
    manifest = (ROOT / "docs/NEURAL4D_REGENERATION_MANIFEST.md").read_text(encoding="utf-8")
    for token in (
        "Status: **PERMANENT**",
        "Meshy is **rejected for all future Honour War asset generation**",
        "Neural4D is approved as an optional generation source",
        "Honour War must **not** use its GLB export",
        "native Godot 4.7.2 scenes/resources",
    ):
        if token not in policy:
            fail(f"Permanent visual policy missing: {token}")
    for token in ("FBX", "OBJ", "53", "retired"):
        if token not in manifest:
            fail(f"Neural4D regeneration manifest missing: {token}")

def validate_runtime_bridge():
    path = ROOT / "scripts/HDAssetRuntime.gd"
    if not path.exists():
        return
    text = path.read_text(encoding="utf-8")
    for token in (
        "HD generated GLB assets were permanently retired",
        "Daily upgrades must NOT regenerate, download, import, or attach GLB assets",
        "native Godot runtime",
    ):
        if token not in text:
            fail(f"HDAssetRuntime.gd missing native no-GLB contract: {token}")

def validate_runtime_world_recovery():
    path = ROOT / "scripts/HWNativeWorldRecovery.gd"
    if not path.exists():
        return
    text = path.read_text(encoding="utf-8")
    for token in ("HWRecoveryGround", "HWRecoveryRoad", "HWRecoveryTreeCrown", "HWNativeRecoveryEnvironment"):
        if token not in text:
            fail(f"Native world recovery missing: {token}")

def main():
    validate_project()
    validate_pipeline_docs()
    validate_directories()
    validate_no_retired_runtime_assets()
    validate_neural4d_policy()
    validate_runtime_bridge()
    validate_runtime_world_recovery()
    print("HONOUR WAR HD NATIVE ART VALIDATION")
    print("Pipeline: approved generation -> FBX/OBJ -> native Godot 4.7.2 -> Forward+")
    for note in notes:
        print("INFO:", note)
    if errors:
        for error in errors:
            print("ERROR:", error)
        return 1
    print("PASS: native HD production art contract is structurally valid")
    return 0

if __name__ == "__main__":
    sys.exit(main())
