#!/usr/bin/env python3
"""Honour War SharnouEngine AVIF-only HD asset validation."""

from __future__ import annotations

import json
from pathlib import Path

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


def validate_project_contract() -> None:
    manifest = ROOT / "Tools" / "SharnouIDE" / "honour-war.spp.json"
    require_file(manifest)
    if not manifest.is_file():
        return
    data = json.loads(manifest.read_text(encoding="utf-8"))
    if data.get("canonical_identity", {}).get("project_id") != "honour-war":
        fail("Canonical Honour War project id is missing")
    if data.get("canonical_identity", {}).get("canonical") is not True:
        fail("Canonical Honour War flag is missing")
    if data.get("ide", {}).get("id") != "Sharnou-IDE":
        fail("Sharnou-IDE is not authoritative")
    if data.get("engine", {}).get("id") != "SharnouEngine":
        fail("SharnouEngine is not the active engine")
    policy = data.get("asset_format_policy", {})
    if policy.get("runtime_visual_format") != ".avif":
        fail("Runtime visual format must be .avif")
    rejected = set(policy.get("rejected_runtime_visual_formats", []))
    for ext in (".gltf", ".glb", ".ktx2", ".png", ".jpg", ".jpeg", ".webp", ".gif", ".bmp", ".tga", ".dds"):
        if ext not in rejected:
            fail(f"Missing rejected runtime visual format: {ext}")


def validate_data_contract() -> None:
    for relative in (
        "data/honour_war_content_catalog.json",
        "data/honour_war_visual_style.json",
        "assets/3d/visual_rag/LATEST_VISUAL_BRIEF.json",
        "Content/HonourWarArt/ART_ASSET_MANIFEST.json",
    ):
        require_file(ROOT / relative)


def validate_visual_tree() -> None:
    for root in (ROOT / "assets", ROOT / "Content"):
        if not root.is_dir():
            continue
        for path in root.rglob("*"):
            if not path.is_file():
                continue
            rel = str(path.relative_to(ROOT)).replace("\\", "/")
            if "/Legacy/" in f"/{rel}/":
                continue
            if path.suffix.lower() in {".gltf", ".glb", ".ktx2", ".png", ".jpg", ".jpeg", ".webp", ".gif", ".bmp", ".tga", ".dds"}:
                fail(f"Retired/non-AVIF active visual file present: {rel}")

    for required_root in (
        ROOT / "assets" / "visual",
        ROOT / "assets" / "ui",
        ROOT / "Content" / "visual",
        ROOT / "Content" / "ui",
    ):
        if required_root.is_dir():
            for path in required_root.rglob("*"):
                if path.is_file() and path.suffix.lower() != ".avif":
                    fail(f"Non-AVIF runtime visual present: {path.relative_to(ROOT)}")


def validate_no_retired_exporters() -> None:
    generators = list((ROOT / "tools" / "blender").rglob("*.py"))
    forbidden = ("bpy.ops.export_scene.gltf", "bpy.ops.wm.gltf_export", ".glb", ".gltf", ".ktx2")
    for path in generators:
        rel = str(path.relative_to(ROOT)).replace("\\", "/")
        body = path.read_text(encoding="utf-8", errors="ignore").lower()
        for marker in forbidden:
            if marker in body:
                fail(f"Retired format marker in active Blender generator: {rel} -> {marker}")
def main() -> int:
    validate_project_contract()
    validate_data_contract()
    validate_visual_tree()
    validate_no_retired_exporters()

    if ERRORS:
        for error in ERRORS:
            print("HD_ART_FAIL:", error)
        return 1

    print("HONOUR WAR AVIF-ONLY HD ART VALIDATION PASS")
    print("SharnouEngine | AVIF-only shipped visuals | FBX/OBJ private authoring intake")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
