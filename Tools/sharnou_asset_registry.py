#!/usr/bin/env python3
"""Deterministic SharnouEngine asset registry/resource-cache foundation.

Tracks canonical asset IDs, file hashes, dependencies and residency without
loading GPU resources. The registry is deliberately format-aware for the
Honour War runtime contract: glTF/GLB scenes, KTX2 textures and AVIF UI art.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Iterable

SUPPORTED = {".gltf": "scene_gltf", ".glb": "scene_gltf", ".ktx2": "texture_ktx2", ".avif": "avif"}

@dataclass
class AssetRecord:
    asset_id: str
    source: str
    kind: str
    size: int
    sha256: str
    dependencies: list[str] = field(default_factory=list)
    residency: str = "unloaded"


def canonical_id(path: Path, root: Path) -> str:
    rel = path.resolve().relative_to(root.resolve()).as_posix()
    return rel.lower()


def digest(path: Path, chunk: int = 1024 * 1024) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        while data := f.read(chunk):
            h.update(data)
    return h.hexdigest()


def scan(root: Path) -> list[AssetRecord]:
    records: list[AssetRecord] = []
    for path in sorted(p for p in root.rglob("*") if p.is_file() and p.suffix.lower() in SUPPORTED):
        records.append(AssetRecord(
            asset_id=canonical_id(path, root),
            source=str(path.resolve()),
            kind=SUPPORTED[path.suffix.lower()],
            size=path.stat().st_size,
            sha256=digest(path),
        ))
    return records


def write_registry(records: Iterable[AssetRecord], output: Path) -> None:
    payload = {
        "schema": "sharnou.asset-registry.v1",
        "project": "honour-war",
        "engine": "SharnouEngine",
        "formats": [".gltf", ".glb", ".ktx2", ".avif"],
        "assets": [asdict(r) for r in records],
    }
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


def main() -> int:
    p = argparse.ArgumentParser(description="Build the Honour War SharnouEngine asset registry.")
    p.add_argument("root", type=Path)
    p.add_argument("--output", type=Path, default=Path("Build/Runtime/asset_registry.json"))
    args = p.parse_args()
    root = args.root.resolve()
    if not root.is_dir():
        print(f"[SharnouAssetRegistry][ERROR] root does not exist: {root}")
        return 2
    records = scan(root)
    write_registry(records, args.output)
    print(f"[SharnouAssetRegistry] PASS indexed={len(records)} output={args.output.resolve()}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
