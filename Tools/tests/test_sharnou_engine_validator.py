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


def assert_ok(result: subprocess.CompletedProcess[str], label: str) -> None:
    if result.returncode != 0:
        print(result.stdout, end="")
        print(result.stderr, end="", file=sys.stderr)
        raise SystemExit(f"{label} failed")


def main() -> int:
    with tempfile.TemporaryDirectory(prefix="sharnou-engine-test-") as raw:
        root = Path(raw)

        avif = root / "image.avif"
        scene_gltf = root / "hero.gltf"
        scene_glb = root / "hero.glb"
        texture = root / "hero.ktx2"
        source_fbx = root / "hero.fbx"
        rejected_png = root / "rejected.png"
        missing = root / "missing.gltf"

        avif.write_bytes(
            bytes(4) + b"ftyp" + b"avif" + bytes(4) + b"avif" + bytes(32)
        )
        scene_gltf.write_text(
            '{"asset":{"version":"2.0"},"scene":0,"scenes":[{"nodes":[0]}],"nodes":[{"name":"root"}]}',
            encoding="utf-8",
        )
        scene_glb.write_bytes(b"glTF" + bytes(8))
        texture.write_bytes(b"\xABKTX 20\xBB\x0D\x0A\x1A\x0A" + bytes(32))
        source_fbx.write_bytes(b"FBX source fixture")
        rejected_png.write_bytes(b"PNG source fixture")

        assert_ok(run("validate", str(avif)), "AVIF runtime input")
        assert_ok(run("validate", str(scene_gltf)), "glTF runtime input")
        assert_ok(run("validate", str(scene_glb)), "GLB runtime input")
        assert_ok(run("validate", str(texture)), "KTX2 runtime input")
        assert_ok(run("validate", str(source_fbx)), "FBX source input")
        assert_ok(run("validate", str(rejected_png)), "registered source inspection input")

        missing_result = run("validate", str(missing))
        if missing_result.returncode == 0:
            raise SystemExit("missing asset was incorrectly accepted")

        self_test = run("--self-test")
        assert_ok(self_test, "SharnouEngine self-test")

        runtime_test = run("--runtime-test", "1")
        assert_ok(runtime_test, "SharnouEngine runtime test")

    print("PASS: SharnouEngine universal source-input validator contract.")
    print("PASS: glTF/GLB scene, KTX2 texture, and AVIF raster roles are accepted.")
    print("PASS: FBX/OBJ-style source inputs remain inspectable at the IDE intake boundary.")
    print("PASS: missing assets fail closed.")
    print("PASS: self-test and runtime-test commands pass.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
