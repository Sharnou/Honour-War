#!/usr/bin/env python3
"""Honour War production-art validation.

Validates the Blender -> Substance 3D Painter -> GLB/GLTF -> Godot 4 contract
without requiring proprietary DCC applications in CI.
"""
from pathlib import Path
import re
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
    if 'renderer/rendering_method="forward_plus"' not in text:
        fail("project.godot must use renderer/rendering_method=forward_plus")
    if 'run/main_scene="res://Main3D.tscn"' not in text:
        fail("Main3D.tscn must remain the main scene")


def validate_pipeline_docs():
    require(ROOT / "ART_PIPELINE.md")
    require(ROOT / "assets/3d/HD_ASSET_MANIFEST.md")
    require(ROOT / "tools/blender/honour_war_hd_asset_builder.py")
    require(ROOT / "tools/blender/export_honour_war_glb.py")
    require(ROOT / "scripts/HDAssetRuntime.gd")


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


def validate_asset_files():
    roots = [ROOT / "assets/3d"]
    model_files = []
    for base in roots:
        if base.exists():
            model_files.extend(base.rglob("*.glb"))
            model_files.extend(base.rglob("*.gltf"))
    for model in model_files:
        if model.stat().st_size == 0:
            fail(f"Empty production model: {model.relative_to(ROOT)}")
    notes.append(f"Production GLB/GLTF files discovered: {len(model_files)}")

    for blend in (ROOT / "assets").rglob("*.blend") if (ROOT / "assets").exists() else []:
        fail(f"Blender source files must not be committed inside runtime asset folders: {blend.relative_to(ROOT)}")


def validate_stable_ids():
    manifest = ROOT / "assets/3d/HD_ASSET_MANIFEST.md"
    if not manifest.exists():
        return
    text = manifest.read_text(encoding="utf-8")
    for token in re.findall(r"(?:hero|pet|monster|mvp)_[a-z0-9_]+\.glb", text):
        if not re.fullmatch(r"(?:hero|pet|monster|mvp)_[a-z0-9_]+\.glb", token):
            fail(f"Invalid stable asset ID: {token}")


def validate_runtime_bridge():
    path = ROOT / "scripts/HDAssetRuntime.gd"
    if not path.exists():
        return
    text = path.read_text(encoding="utf-8")
    required = (
        "ResourceLoader.exists(path)",
        "PackedScene",
        "global_transform",
        "current.queue_free()",
    )
    for token in required:
        if token not in text:
            fail(f"HDAssetRuntime.gd missing expected runtime behavior: {token}")


def main():
    validate_project()
    validate_pipeline_docs()
    validate_directories()
    validate_asset_files()
    validate_stable_ids()
    validate_runtime_bridge()
    print("HONOUR WAR HD ART VALIDATION")
    print("Pipeline: Blender -> Substance 3D Painter -> GLB/GLTF -> Godot 4")
    for note in notes:
        print("INFO:", note)
    if errors:
        for error in errors:
            print("ERROR:", error)
        return 1
    print("PASS: production art contract is structurally valid")
    return 0


if __name__ == "__main__":
    sys.exit(main())
