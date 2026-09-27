#!/usr/bin/env python3
"""Verify Honour War has exactly one active game generator: SharnouEngine."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXTERNAL_GENERATOR_FILES = [
    ROOT / "tools" / "neural4d_batch_generate.py",
    ROOT / "tools" / "validate_neural4d_assets.py",
    ROOT / "tools" / "blender" / "build_ss_production_asset.py",
    ROOT / "tools" / "blender" / "honour_war_asset_pipeline.py",
    ROOT / "tools" / "blender" / "honour_war_environment_builder.py",
    ROOT / "tools" / "blender" / "honour_war_hd_asset_builder.py",
    ROOT / "tools" / "blender" / "honour_war_monster_assets.py",
    ROOT / "tools" / "blender" / "honour_war_production_assets.py",
    ROOT / "tools" / "blender" / "honour_war_visual_max_assets.py",
    ROOT / "tools" / "blender" / "run_visual_max_assets.py",
    ROOT / "tools" / "blender" / "VISUAL_MAX_BUILD_TRIGGER.txt",
]
MANIFEST = ROOT / "Engine" / "SharnouEngine" / "HONOUR_WAR_GENERATION.json"

errors: list[str] = []
if not MANIFEST.is_file():
    errors.append("missing SharnouEngine generation manifest")
else:
    data = json.loads(MANIFEST.read_text(encoding="utf-8"))
    if data.get("generation_authority") != "SharnouEngine-only":
        errors.append("generation authority is not SharnouEngine-only")
    if data.get("active_generators") != ["SharnouEngine"]:
        errors.append("active generator list is not exactly [SharnouEngine]")
    if data.get("external_generation") is not False:
        errors.append("external generation is enabled")
    if data.get("runtime_visual_format") != ".avif":
        errors.append("runtime visual format is not .avif")
for path in EXTERNAL_GENERATOR_FILES:
    if path.exists():
        errors.append(f"retired external generator still active: {path.relative_to(ROOT)}")

if errors:
    for error in errors:
        print("SHARNOU_GENERATION_QA_FAIL:", error)
    raise SystemExit(1)

print("SHARNOU_GENERATION_QA_PASS: SharnouEngine is the sole active Honour War generator.")
