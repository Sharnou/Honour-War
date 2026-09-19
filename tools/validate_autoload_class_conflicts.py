#!/usr/bin/env python3
"""Fail early when a Godot autoload singleton also declares the same global class_name."""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "project.godot"

project_text = PROJECT.read_text(encoding="utf-8")
autoload_section = re.search(r"(?ms)^\[autoload\]\s*(.*?)(?=^\[|\Z)", project_text)
if not autoload_section:
    print("AUTOLOAD_CLASS_CONFLICT_QA: PASS (no autoload section)")
    raise SystemExit(0)

autoload_names = set()
for line in autoload_section.group(1).splitlines():
    line = line.strip()
    if not line or line.startswith("#") or "=" not in line:
        continue
    name = line.split("=", 1)[0].strip()
    if name:
        autoload_names.add(name)

conflicts = []
for path in sorted((ROOT / "scripts").rglob("*.gd")):
    text = path.read_text(encoding="utf-8", errors="replace")
    match = re.search(r"(?m)^\s*class_name\s+([A-Za-z_][A-Za-z0-9_]*)\s*$", text)
    if match and match.group(1) in autoload_names:
        conflicts.append(f"{path.relative_to(ROOT)}: class_name {match.group(1)}")

if conflicts:
    print("AUTOLOAD_CLASS_CONFLICT_QA: FAIL")
    for item in conflicts:
        print(f" - {item}")
    raise SystemExit(1)

print(f"AUTOLOAD_CLASS_CONFLICT_QA: PASS ({len(autoload_names)} autoloads checked)")
