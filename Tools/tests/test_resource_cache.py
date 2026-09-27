#!/usr/bin/env python3
from pathlib import Path
import json
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from Tools.sharnou_resource_cache import ResourceCache, STATES


def main() -> int:
    with tempfile.TemporaryDirectory() as temp:
        root = Path(temp)
        scene = root / "scene.gltf"
        scene.write_text('{"asset":{"version":"2.0"}}', encoding="utf-8")
        cache = ResourceCache()
        entry = cache.register("scene.gltf", scene, "scene_gltf")
        assert entry.residency == "unloaded"
        assert entry.references == 0
        cache.acquire("scene.gltf")
        assert entry.residency == "queued"
        assert entry.references == 1
        cache.transition("scene.gltf", "loading")
        cache.transition("scene.gltf", "cpu_ready")
        cache.transition("scene.gltf", "gpu_pending")
        cache.transition("scene.gltf", "gpu_resident")
        cache.release("scene.gltf")
        assert entry.residency == "evictable"
        scene.write_text('{"asset":{"version":"2.0"},"changed":true}', encoding="utf-8")
        assert cache.invalidate_changed("scene.gltf") is True
        assert entry.residency == "unloaded"
        assert entry.references == 0
        assert STATES == ("unloaded", "queued", "loading", "cpu_ready", "gpu_pending", "gpu_resident", "evictable")
        out = root / "cache.json"
        cache.save(out)
        data = json.loads(out.read_text(encoding="utf-8"))
        assert data["schema"] == "sharnou.resource-cache.v1"
        assert data["project"] == "honour-war"
        assert data["engine"] == "SharnouEngine"
        assert len(data["entries"]) == 1
    print("PASS: resource cache registration, residency, references, invalidation, and serialization.")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
