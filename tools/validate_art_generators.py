#!/usr/bin/env python3
"""Fail if active Honour War art generators can reintroduce retired GLB/GLTF."""

from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
FILES = [
    ROOT / "tools/blender/honour_war_monster_assets.py",
    ROOT / "tools/blender/honour_war_production_assets.py",
    ROOT / "tools/blender/honour_war_visual_max_assets.py",
    ROOT / "tools/blender/build_ss_production_asset.py",
    ROOT / "tools/blender/run_visual_max_assets.py",
]

# Build retired exporter markers at runtime so this validator's detection
# vocabulary cannot itself be mistaken for an active exporter invocation.
FORBIDDEN = (
    "bpy.ops.export_scene." + "gltf",
    "bpy.ops.wm." + "gltf_export",
)

errors = []
for path in FILES:
    if not path.is_file():
        errors.append(f"missing generator: {path.relative_to(ROOT)}")
        continue
    body = path.read_text(encoding="utf-8", errors="ignore")
    for marker in FORBIDDEN:
        if marker in body:
            errors.append(f"{path.relative_to(ROOT)} contains retired exporter {marker}")

for path in FILES:
    if path.is_file():
        body = path.read_text(encoding="utf-8", errors="ignore")
        if ".glb" in body.lower() or ".gltf" in body.lower():
            errors.append(f"{path.relative_to(ROOT)} still contains retired GLB/GLTF extension text")

if errors:
    for error in errors:
        print("ART_GENERATOR_QA_FAIL:", error)
    sys.exit(1)

print("ART_GENERATOR_QA_PASS: active Blender generators are FBX/OBJ-only and cannot emit GLB/GLTF.")
