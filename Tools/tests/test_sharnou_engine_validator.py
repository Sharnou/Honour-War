from __future__ import annotations

import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ENGINE = ROOT / "SharnouEngine.py"


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
        image = root / "image.avif"
        bad = root / "bad.gltf"

        image.write_bytes(
            bytes(4) + b"ftyp" + b"avif" + bytes(4) + b"avif" + bytes(32)
        )
        bad.write_text("retired format", encoding="utf-8")

        valid = run("validate", "--avif", str(image))
        if valid.returncode != 0:
            print(valid.stdout, end="")
            print(valid.stderr, end="", file=sys.stderr)
            raise SystemExit("valid AVIF asset contract failed")

        invalid = run("avif", str(bad))
        if invalid.returncode == 0:
            raise SystemExit("retired non-AVIF asset was incorrectly accepted")

        missing = run("avif", str(root / "missing.avif"))
        if missing.returncode == 0:
            raise SystemExit("missing asset was incorrectly accepted")

    print("PASS: SharnouEngine source validator contract.")
    print("PASS: AVIF/ISO-BMFF header validation.")
    print("PASS: GLTF/GLB/KTX2-style retired assets are rejected by extension.")
    print("PASS: invalid and missing assets fail closed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
