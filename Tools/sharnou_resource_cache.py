#!/usr/bin/env python3
"""Deterministic SharnouEngine resource-cache foundation.

Metadata-only cache for the Honour War runtime. It never claims that a resource
is GPU-resident; residency is an explicit state transition owned by the future
native renderer.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from dataclasses import asdict, dataclass
from pathlib import Path

STATES = ("unloaded", "queued", "loading", "cpu_ready", "gpu_pending", "gpu_resident", "evictable")

@dataclass
class CacheEntry:
    asset_id: str
    source: str
    kind: str
    size: int
    sha256: str
    residency: str = "unloaded"
    references: int = 0

class ResourceCache:
    def __init__(self) -> None:
        self.entries: dict[str, CacheEntry] = {}

    def register(self, asset_id: str, source: Path, kind: str) -> CacheEntry:
        if kind not in {"scene_gltf", "texture_ktx2", "avif"}:
            raise ValueError(f"unsupported resource kind: {kind}")
        if not source.is_file():
            raise FileNotFoundError(source)
        h = hashlib.sha256()
        with source.open("rb") as f:
            while chunk := f.read(1024 * 1024):
                h.update(chunk)
        entry = CacheEntry(asset_id, str(source.resolve()), kind, source.stat().st_size, h.hexdigest())
        old = self.entries.get(asset_id)
        if old and old.sha256 == entry.sha256:
            entry.residency = old.residency
            entry.references = old.references
        self.entries[asset_id] = entry
        return entry

    def acquire(self, asset_id: str) -> CacheEntry:
        entry = self.entries[asset_id]
        entry.references += 1
        if entry.residency == "unloaded":
            entry.residency = "queued"
        return entry

    def release(self, asset_id: str) -> CacheEntry:
        entry = self.entries[asset_id]
        if entry.references <= 0:
            raise RuntimeError(f"release without acquire: {asset_id}")
        entry.references -= 1
        if entry.references == 0 and entry.residency == "gpu_resident":
            entry.residency = "evictable"
        return entry

    def transition(self, asset_id: str, state: str) -> CacheEntry:
        if state not in STATES:
            raise ValueError(f"invalid residency state: {state}")
        entry = self.entries[asset_id]
        entry.residency = state
        return entry

    def invalidate_changed(self, asset_id: str) -> bool:
        entry = self.entries[asset_id]
        source = Path(entry.source)
        if not source.is_file():
            entry.residency = "unloaded"
            return True
        h = hashlib.sha256()
        with source.open("rb") as f:
            while chunk := f.read(1024 * 1024):
                h.update(chunk)
        changed = h.hexdigest() != entry.sha256
        if changed:
            entry.sha256 = h.hexdigest()
            entry.size = source.stat().st_size
            entry.residency = "unloaded"
        return changed

    def save(self, output: Path) -> None:
        output.parent.mkdir(parents=True, exist_ok=True)
        payload = {
            "schema": "sharnou.resource-cache.v1",
            "engine": "SharnouEngine",
            "project": "honour-war",
            "states": list(STATES),
            "entries": [asdict(e) for e in sorted(self.entries.values(), key=lambda x: x.asset_id)],
        }
        output.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


def main() -> int:
    p = argparse.ArgumentParser(description="Build a deterministic Honour War resource cache from a registry.")
    p.add_argument("registry", type=Path)
    p.add_argument("--output", type=Path, default=Path("Build/Runtime/resource_cache.json"))
    args = p.parse_args()
    data = json.loads(args.registry.read_text(encoding="utf-8"))
    if data.get("project") != "honour-war" or data.get("engine") != "SharnouEngine":
        print("[SharnouResourceCache][ERROR] invalid registry identity")
        return 2
    cache = ResourceCache()
    for item in data.get("assets", []):
        try:
            cache.register(item["asset_id"], Path(item["source"]), item["kind"])
        except (KeyError, FileNotFoundError, ValueError) as exc:
            print(f"[SharnouResourceCache][ERROR] {exc}")
            return 3
    cache.save(args.output)
    print(f"[SharnouResourceCache] PASS entries={len(cache.entries)} output={args.output.resolve()}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
