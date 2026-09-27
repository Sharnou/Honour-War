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
        (root / "login.avif").write_bytes(b"valid-avif-fixture")
        (root / "ignored.txt").write_text("ignored", encoding="utf-8")

        records = scan(root)
        by_id = {r.asset_id: r for r in records}

        assert len(records) == 1
        assert by_id["login.avif"].kind == "avif"
        assert all(len(r.sha256) == 64 for r in records)

        out = root / "registry.json"
        write_registry(records, out)
        data = json.loads(out.read_text(encoding="utf-8"))
        assert data["schema"] == "sharnou.asset-registry.v1"
        assert data["project"] == "honour-war"
        assert data["engine"] == "SharnouEngine"
        assert len(data["assets"]) == 1

    print("PASS: asset registry scan, hashing, canonical IDs, and serialization.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
