#!/usr/bin/env python3
"""Validate the permanent Visual RAG-first Unreal production cycle."""

from __future__ import annotations

import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
BRIEF = ROOT / "assets" / "3d" / "visual_rag" / "LATEST_VISUAL_BRIEF.json"
STYLE = ROOT / "docs" / "HONOUR_WAR_HD_MMO_ANIME_STYLE_CONTRACT.md"
CYCLE = ROOT / "docs" / "VISUAL_DEVELOPMENT_CYCLE_CONTRACT.md"
PIPELINE = ROOT / "ART_PIPELINE.md"


def require(condition: bool, message: str) -> None:
    if not condition:
        print("VISUAL_CYCLE_QA_FAIL: " + message)
        raise SystemExit(1)


def main() -> int:
    for path in (BRIEF, STYLE, CYCLE, PIPELINE):
        require(path.is_file(), f"missing required visual-cycle file: {path.relative_to(ROOT)}")

    brief = json.loads(BRIEF.read_text(encoding="utf-8"))
    style = STYLE.read_text(encoding="utf-8")
    cycle = CYCLE.read_text(encoding="utf-8")
    pipeline = PIPELINE.read_text(encoding="utf-8")

    require(brief.get("engine") == "Unreal Engine 5.8", "visual brief engine is not Unreal Engine 5.8")
    require(brief.get("identity") == "HD 3D anime-inspired isometric MMORPG/ARPG", "visual identity drifted")
    require(brief.get("direct_visual_source") == "Screenshot/", "Screenshot/ is not the authoritative visual source")
    require(brief.get("runtime_formats") == ["FBX", "OBJ"], "runtime intake must remain FBX/OBJ")
    require(brief.get("rejected_formats") == ["GLB", "GLTF"], "GLB/GLTF retirement is not explicit")
    required_camera = brief.get("required", {}).get("camera", {})
    require(required_camera.get("style") == "Ragnarok Online-inspired perspective/isometric MMORPG camera", "camera identity drifted")
    require(required_camera.get("complete_hero_framing") is True, "complete hero framing is not required")
    required_controls = brief.get("required", {}).get("controls", {})
    require(required_controls.get("left_click_ground") == "click-to-move", "click-to-move missing")
    require(required_controls.get("left_click_monster") == "select-and-engage", "monster target interaction missing")
    require(required_controls.get("right_drag") == "camera_orbit", "right-drag camera orbit missing")
    require(required_controls.get("mouse_wheel") == "bounded_zoom", "mouse-wheel zoom missing")
    require(brief.get("cycle_rules", {}).get("visual_rag_required_first") is True, "Visual RAG-first rule missing")
    require(brief.get("cycle_rules", {}).get("regenerate_visual_brief_each_completed_cycle") is True, "brief regeneration rule missing")
    require(brief.get("cycle_rules", {}).get("refresh_3d_assets_each_completed_cycle") is True, "3D refresh rule missing")
    require(brief.get("cycle_rules", {}).get("validate_real_unreal_runtime_each_completed_cycle") is True, "real runtime rule missing")
    require(brief.get("cycle_rules", {}).get("daily_unattended_upgrade") is False, "unattended upgrade system must remain disabled")

    for text, label in [(style, "style contract"), (cycle, "visual cycle contract"), (pipeline, "art pipeline")]:
        for phrase in [
            "HD 3D anime-inspired",
            "Ragnarok Online-inspired",
            "Visual RAG",
            "FBX/OBJ",
            "Unreal Engine 5.8",
            "right-mouse drag",
        ]:
            require(phrase in text, f"{label} missing {phrase}")

    print("VISUAL_CYCLE_QA_PASS: HD 3D anime MMORPG identity, Visual RAG-first regeneration, FBX/OBJ Unreal intake, and Ragnarok-inspired camera/control contract are locked.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
