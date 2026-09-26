#!/usr/bin/env python3
from pathlib import Path
import json
import tempfile

from Tools.sharnou_asset_registry import scan, write_registry


def main() -> int:
    with tempfile.TemporaryDirectory() as temp:
        root = Path(temp)
        (root / "scene.gltf").write_text('{"asset":{"version":"2.0"}}', encoding="utf-8")
        (root / "hero.ktx2").write_bytes(b"ABCD")
        (root / "login.avif").write_bytes(b"EFGH")
        (root / "ignored.txt").write_text("ignored", encoding="utf-8")
        records = scan(root)
        assert [r.kind for r in records] == ["avif", "texture_ktx2", "scene_gltf"]
        assert all(len(r.sha256) == 64 for r in records)
        out = root / "registry.json"
        write_registry(records, out)
        data = json.loads(out.read_text(encoding="utf-8"))
        assert data["schema"] == "sharnou.asset-registry.v1"
        assert data["project"] == "honour-war"
        assert len(data["assets"]) == 3
    print("PASS: asset registry scan, hashing, canonical IDs, and serialization.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
