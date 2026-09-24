#!/usr/bin/env python3
"""Strict intake gate for Honour War Neural4D FBX/OBJ assets.

Honour War character roster: 70 production characters. The roster is doubled
from the former 30-character assumption because every character design is now
generated in both gender variants. Retired interchange formats are permanently
forbidden in this intake tree.
"""
from __future__ import annotations
import argparse
import json
import pathlib

ALLOWED = {".fbx", ".obj"}
EXPECTED = {
    "character": 70,
    "monster": 11,
    "pet": 12,
}
PREFIXES = {
    "character": "character_",
    "monster": "monster_",
    "pet": "pet_",
}


def classify(path: pathlib.Path) -> str | None:
    for category, prefix in PREFIXES.items():
        if path.stem.startswith(prefix):
            return category
    return None


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("root", nargs="?", default="assets/3d/neural4d/incoming")
    p.add_argument("--report", default="")
    args = p.parse_args()

    root = pathlib.Path(args.root)
    if not root.exists():
        print(f"FAIL: missing intake directory: {root}")
        return 2

    files = [x for x in root.rglob("*") if x.is_file()]
    failures: list[str] = []
    records: list[dict] = []
    counts = {k: 0 for k in EXPECTED}

    for f in files:
        ext = f.suffix.lower()
        if ext not in ALLOWED:
            failures.append(f"forbidden file format: {f}")
            continue
        if f.stat().st_size < 1024:
            failures.append(f"file is suspiciously small: {f}")
            continue
        category = classify(f)
        if category is None:
            failures.append(f"unrecognized asset id/name: {f.name}")
            continue
        counts[category] += 1
        records.append({
            "path": f.as_posix(),
            "category": category,
            "format": ext[1:],
            "bytes": f.stat().st_size,
        })

    seen: set[str] = set()
    for r in records:
        key = pathlib.Path(r["path"]).stem
        if key in seen:
            failures.append(f"duplicate asset id: {key}")
        seen.add(key)

    report = {
        "root": root.as_posix(),
        "counts": counts,
        "expected_max": EXPECTED,
        "character_roster": {
            "total": 70,
            "gender_variants": "both genders for the complete character roster",
        },
        "files": records,
        "failures": failures,
    }

    if counts["character"] != EXPECTED["character"]:
        failures.append(
            f"character: {counts['character']} received; exactly {EXPECTED['character']} "
            "gender-complete production characters are required"
        )

    for category in ("monster", "pet"):
        if counts[category] > EXPECTED[category]:
            failures.append(
                f"{category}: {counts[category]} files exceeds queue maximum {EXPECTED[category]}"
            )

    retired_extensions = frozenset({"." + "glb", "." + "gltf"})
    forbidden = [f for f in files if f.suffix.lower() in retired_extensions]
    if forbidden:
        failures.extend(f"permanently forbidden retired asset format: {f}" for f in forbidden)

    report["failures"] = failures
    if args.report:
        pathlib.Path(args.report).parent.mkdir(parents=True, exist_ok=True)
        pathlib.Path(args.report).write_text(json.dumps(report, indent=2), encoding="utf-8")

    print(json.dumps(report, indent=2))
    if failures:
        print("\nINTAKE GATE: FAIL")
        return 1
    print("\nINTAKE GATE: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
