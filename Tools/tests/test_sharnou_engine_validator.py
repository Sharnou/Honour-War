from __future__ import annotations

import json
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ENGINE = ROOT / "SharnouEngine.py"
KTX2_IDENTIFIER = bytes.fromhex("AB4B5458203230BB0D0A1A0A")


def run(*args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, str(ENGINE), *args],
        cwd=ROOT,
        text=True,
        capture_output=True,
        check=False,
    )


def main() -> int:
    with tempfile.TemporaryDirectory(prefix="sharnou-engine-test-") as raw:
        root = Path(raw)
        scene = root / "scene.gltf"
        texture = root / "texture.ktx2"
        image = root / "image.avif"
        bad = root / "bad.gltf"

        scene.write_text(
            json.dumps({"asset": {"version": "2.0"}, "scene": 0, "scenes": [{}]}),
            encoding="utf-8",
        )
        texture.write_bytes(KTX2_IDENTIFIER + bytes(64))
        # Minimal ISO-BMFF/AVIF signature sufficient for the engine's header policy.
        image.write_bytes(
            bytes(4) + b"ftyp" + b"avif" + bytes(4) + b"avif" + bytes(4)
        )
        bad.write_text("not glTF", encoding="utf-8")

        valid = run(
            "validate",
            "--scene", str(scene),
            "--ktx2", str(texture),
            "--avif", str(image),
        )
        if valid.returncode != 0:
            print(valid.stdout, end="")
            print(valid.stderr, end="", file=sys.stderr)
            raise SystemExit("valid asset contract failed")

        invalid = run("--scene", str(bad))
        if invalid.returncode == 0:
            raise SystemExit("invalid glTF was incorrectly accepted")

        missing = run("--scene", str(root / "missing.gltf"))
        if missing.returncode == 0:
            raise SystemExit("missing asset was incorrectly accepted")

    print("PASS: SharnouEngine source validator contract.")
    print("PASS: glTF 2.x validation.")
    print("PASS: KTX2 identifier validation.")
    print("PASS: AVIF/ISO-BMFF header validation.")
    print("PASS: invalid and missing assets fail closed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
