#!/usr/bin/env python3
"""Semantic and binary validation for Honour War generated GLB assets."""

from __future__ import annotations

import json
import struct
import sys
from pathlib import Path

ROOT = Path("assets/3d/generated")
MAGIC = b"glTF"
JSON_CHUNK = 0x4E4F534A

HERO_CLASSES = {"Warrior", "Mage", "Archer", "Thief", "Acolyte", "Merchant"}
HERO_TIERS = {"Foundation", "Specialization", "Advanced", "Mastery", "Transcendence"}
HERO_WEAPONS = {
    "Warrior": "Sword",
    "Mage": "Staff",
    "Archer": "Bow",
    "Thief": "Dagger",
    "Acolyte": "Mace",
    "Merchant": "Hammer",
}


def read_glb_json(path: Path) -> dict:
    data = path.read_bytes()
    if len(data) < 20:
        raise ValueError(f"{path}: file too small for a GLB header")
    if data[:4] != MAGIC:
        raise ValueError(f"{path}: invalid GLB magic")

    version, total_length = struct.unpack_from("<II", data, 4)
    if version != 2:
        raise ValueError(f"{path}: expected GLB version 2, got {version}")
    if total_length != len(data):
        raise ValueError(
            f"{path}: header length {total_length} does not match file size {len(data)}"
        )

    first_chunk_length, first_chunk_type = struct.unpack_from("<II", data, 12)
    if first_chunk_type != JSON_CHUNK:
        raise ValueError(f"{path}: first GLB chunk is not JSON")
    start = 20
    end = start + first_chunk_length
    if end > len(data):
        raise ValueError(f"{path}: JSON chunk exceeds file length")

    raw_json = data[start:end].rstrip(b" \t\r\n\x00")
    try:
        return json.loads(raw_json.decode("utf-8"))
    except Exception as exc:  # pragma: no cover - error path is the diagnostic
        raise ValueError(f"{path}: invalid JSON chunk: {exc}") from exc


def node_names(doc: dict) -> set[str]:
    result = set()
    for node in doc.get("nodes", []):
        name = node.get("name")
        if isinstance(name, str):
            result.add(name)
    return result


def validate_asset(path: Path) -> None:
    if path.stat().st_size < 1024:
        raise ValueError(f"{path}: suspiciously small GLB")

    doc = read_glb_json(path)
    asset = doc.get("asset", {})
    if asset.get("version") != "2.0":
        raise ValueError(f"{path}: glTF asset.version must be 2.0")
    if not doc.get("meshes"):
        raise ValueError(f"{path}: no meshes found")
    if not doc.get("materials"):
        raise ValueError(f"{path}: no materials found")

    names = node_names(doc)
    rel = path.relative_to(ROOT).as_posix()

    if rel.startswith("characters/"):
        parts = Path(rel).parts
        if len(parts) != 3:
            raise ValueError(f"{path}: unexpected hero layout")
        class_id, tier = parts[0], Path(parts[2]).stem
        if class_id not in HERO_CLASSES:
            raise ValueError(f"{path}: unknown hero class {class_id}")
        if tier not in HERO_TIERS:
            raise ValueError(f"{path}: unknown hero tier {tier}")
        required = {"Torso", "Head", "Eye", "Iris", "Mouth", HERO_WEAPONS[class_id]}
        missing = sorted(required - names)
        if missing:
            raise ValueError(f"{path}: missing required hero nodes: {', '.join(missing)}")
        if len(names) < 12:
            raise ValueError(f"{path}: hero node count too low ({len(names)})")

    elif rel.startswith("pets/"):
        if len(names) < 3:
            raise ValueError(f"{path}: pet node count too low ({len(names)})")

    elif rel.startswith("monsters/"):
        if len(names) < 2:
            raise ValueError(f"{path}: monster node count too low ({len(names)})")


def main() -> int:
    files = sorted(ROOT.rglob("*.glb")) if ROOT.exists() else []
    print("HONOUR WAR GENERATED GLB QUALITY GATE")
    print(f"Discovered GLBs: {len(files)}")

    if len(files) < 53:
        print(f"ERROR: expected at least 53 generated GLBs, found {len(files)}")
        return 1

    failures = []
    for path in files:
        try:
            validate_asset(path)
        except Exception as exc:
            failures.append(str(exc))

    if failures:
        print("FAILED GLB ASSETS:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    hero_count = sum(1 for p in files if "characters" in p.parts)
    pet_count = sum(1 for p in files if "pets" in p.parts)
    monster_count = sum(1 for p in files if "monsters" in p.parts)
    print(f"Heroes: {hero_count} | Pets: {pet_count} | Monsters: {monster_count}")
    print("PASS: binary structure, glTF 2.0 JSON, meshes, materials and semantic hero nodes are valid.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
