#!/usr/bin/env python3
"""Honour War material/visual integrity scan.

Scans native Godot scene/resource text for missing material assignments and
obvious empty visual-resource declarations. It is intentionally conservative:
valid material resources, authored colors, and textureless procedural materials
are not treated as errors.
"""
from pathlib import Path
import re, sys

ROOT=Path(__file__).resolve().parents[1]
errors=[]
warnings=[]

SCENE_EXT={".tscn",".tres"}
CODE_EXT={".gd",".gdshader"}
ASSET_EXT={".obj",".fbx",".dae",".gltf",".glb"}

def fail(msg): errors.append(msg)

def scan_text(path:Path,text:str):
    # Explicit null material assignments are always suspicious in scene files.
    for i,line in enumerate(text.splitlines(),1):
        low=line.lower()
        if re.search(r"\bmaterial(?:_override)?\s*=\s*null\b",low):
            fail(f"{path.relative_to(ROOT)}:{i}: explicit null material assignment")
        if re.search(r"\bmaterial(?:_override)?\s*=\s*\"\"",low):
            fail(f"{path.relative_to(ROOT)}:{i}: empty material assignment")
        # Surface material arrays with an empty slot are commonly exported as
        # null and leave black/default geometry at runtime.
        if "surface_materials" in low and "null" in low:
            warnings.append(f"{path.relative_to(ROOT)}:{i}: inspect surface material list")

def main():
    for path in ROOT.rglob("*"):
        if not path.is_file() or any(part in {".git",".godot","build","dist"} for part in path.parts):
            continue
        if path.suffix.lower() in SCENE_EXT|CODE_EXT:
            try: scan_text(path,path.read_text(encoding="utf-8"))
            except UnicodeDecodeError: warnings.append(f"{path}: non-UTF8, skipped")
    # Require the runtime guard and its integration contract.
    guard=ROOT/"scripts/HWMaterialIntegrityDirector.gd"
    if not guard.exists():
        fail("missing scripts/HWMaterialIntegrityDirector.gd")
    else:
        text=guard.read_text(encoding="utf-8")
        for token in ("GeometryInstance3D","surface_get_material","surface_set_material","StandardMaterial3D"):
            if token not in text:
                fail(f"material guard missing {token}")
    scene=ROOT/"Main3D.tscn"
    if scene.exists() and "HWMaterialIntegrityDirector" not in scene.read_text(encoding="utf-8"):
        fail("Main3D.tscn does not instantiate HWMaterialIntegrityDirector")
    print("HONOUR WAR MATERIAL / VISUAL INTEGRITY QA")
    print(f"INFO: scanned native scenes/resources under {ROOT}")
    for w in warnings[:20]: print("WARNING:",w)
    if len(warnings)>20: print(f"WARNING: {len(warnings)-20} additional warnings suppressed")
    if errors:
        for e in errors: print("ERROR:",e)
        return 1
    print("PASS: no explicit null/empty material assignments found; runtime repair guard installed")
    return 0

if __name__=="__main__":
    sys.exit(main())
