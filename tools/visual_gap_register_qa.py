#!/usr/bin/env python3
"""Validate the Visual RAG-first production gap register.

This intentionally does not require Blender or Substance 3D Painter in CI.
It prevents specification-only gaps from being reported as authored production.
"""
from pathlib import Path
import json
import sys

ROOT = Path(__file__).resolve().parents[1]
REGISTER = ROOT / "assets/3d/PRODUCTION_VISUAL_GAP_REGISTER.json"
REQUIRED_ORDER = [
    "Visual RAG",
    "Blender",
    "Substance 3D Painter",
    "GLB/GLTF",
    "Godot 4.7 Forward+",
    "automated integrity/runtime/export validation",
]
FORBIDDEN = {
    "Barracks",
    "Tower Defense",
    "Soldier Production",
    "Guarded Bank",
    "soldier army or respawn loops",
    "guarded-bank income or occupation",
    "bank territories",
    "strategy-city progression",
}

def main():
    if not REGISTER.exists():
        print(f"ERROR: missing {REGISTER.relative_to(ROOT)}")
        return 1
    data = json.loads(REGISTER.read_text(encoding="utf-8"))
    if data.get("pipeline_order") != REQUIRED_ORDER:
        print("ERROR: pipeline order does not match the permanent production role order")
        return 1
    gaps = data.get("current_gaps", [])
    if not gaps:
        print("ERROR: current_gaps must remain explicit until authored assets are verified")
        return 1
    for gap in gaps:
        for key in ("id", "visual_rag_target", "blender_contract", "substance_contract", "interchange", "godot_integration", "status", "blocker"):
            if not gap.get(key):
                print(f"ERROR: gap {gap.get('id', '<unknown>')} missing {key}")
                return 1
        if gap["status"] not in {"authored_production", "deterministic_generated", "specification_only", "blocked_external_tool"}:
            print(f"ERROR: invalid status for {gap['id']}: {gap['status']}")
            return 1
        if gap["status"] == "authored_production" and gap.get("blocker"):
            print(f"ERROR: authored production gap cannot retain a blocker: {gap['id']}")
            return 1
    prohibited = set(data.get("prohibited_systems", []))
    missing = FORBIDDEN - prohibited
    if missing:
        print("ERROR: prohibited system list is incomplete:", sorted(missing))
        return 1
    print("VISUAL GAP REGISTER QA")
    print(f"PASS: {len(gaps)} explicit gap records; production claims remain evidence-gated")
    return 0

if __name__ == "__main__":
    sys.exit(main())
