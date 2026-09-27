#!/usr/bin/env python3
from pathlib import Path
import json
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from Tools.sharnou_gltf_importer import inspect_scene


def main() -> int:
    with tempfile.TemporaryDirectory() as temp:
        root = Path(temp)
        scene = root / "scene.gltf"
        scene.write_text(json.dumps({
            "asset": {"version": "2.0", "generator": "test"},
            "scene": 0,
            "scenes": [{"nodes": [0]}],
            "nodes": [{"mesh": 0}],
            "meshes": [{"primitives": [{"attributes": {"POSITION": 0}, "material": 0}]}],
            "materials": [{}],
            "textures": [{"source": 0}],
            "images": [{"uri": "textures/hero.avif"}],
            "buffers": [{"uri": "geometry.bin", "byteLength": 4}],
            "bufferViews": [{"buffer": 0, "byteOffset": 0, "byteLength": 4}],
            "accessors": [{"bufferView": 0, "componentType": 5126, "count": 1, "type": "VEC3"}],
            "skins": [{}],
            "animations": [{}]
        }), encoding="utf-8")
        result = inspect_scene(str(scene))
        assert result["asset_version"] == "2.0"
        assert result["counts"]["nodes"] == 1
        assert result["counts"]["primitives"] == 1
        assert result["counts"]["meshes"] == 1
        assert result["counts"]["animations"] == 1
        ids = {d["asset_id"] for d in result["dependencies"]}
        assert "textures/hero.avif" in ids
        assert "geometry.bin" in ids
    print("PASS: glTF 2.x scene ingestion, structural counts, and dependency extraction.")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
