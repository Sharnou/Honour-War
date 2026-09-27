#!/usr/bin/env python3
from pathlib import Path
import json
import sys
import tempfile

# Allow this test to run directly as:
#   python Tools\tests\test_asset_registry.py
# without requiring the repository to be installed as a Python package.
REPO_ROOT = Path(__file__).resolve().parents[2]
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from Tools.sharnou_asset_registry import scan, write_registry


def main() -> int:
    with tempfile.TemporaryDirectory() as temp:
        root = Path(temp)

        (root / "scene.gltf").write_text(
            '{"asset":{"version":"2.0"}}', encoding="utf-8"
        )
        (root / "model.glb").write_bytes(b"glTF")
        (root / "albedo.ktx2").write_bytes(b"\xABKTX 20\xBB\x0D\x0A\x1A\x0A")
        (root / "login.avif").write_bytes(b"valid-avif-fixture")

        (root / "ignored.txt").write_text("ignored", encoding="utf-8")
        (root / "rejected.png").write_bytes(b"not-runtime")

        records = scan(root)
        by_id = {r.asset_id: r for r in records}

        assert len(records) == 4
        assert by_id["scene.gltf"].kind == "scene_gltf"
        assert by_id["model.glb"].kind == "scene_gltf"
        assert by_id["albedo.ktx2"].kind == "texture_ktx2"
        assert by_id["login.avif"].kind == "avif"
        assert "rejected.png" not in by_id
        assert all(len(r.sha256) == 64 for r in records)

        out = root / "registry.json"
        write_registry(records, out)
        data = json.loads(out.read_text(encoding="utf-8"))
        assert data["schema"] == "sharnou.asset-registry.v1"
        assert data["project"] == "honour-war"
        assert data["engine"] == "SharnouEngine"
        assert data["formats"] == [".gltf", ".glb", ".ktx2", ".avif"]
        assert ".png" in data["rejected_runtime_formats"]
        assert data["authoring_only_formats"] == [".fbx", ".obj"]
        assert len(data["assets"]) == 4

    print("PASS: asset registry scans glTF/GLB/KTX2/AVIF and rejects non-runtime formats.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
