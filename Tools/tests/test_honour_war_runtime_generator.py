#!/usr/bin/env python3
from pathlib import Path
import importlib.util
import json
import tempfile

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location("runtime_generator", ROOT / "Tools" / "sharnou_honour_war_runtime_generator.py")
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC and SPEC.loader
SPEC.loader.exec_module(MODULE)


def main() -> int:
    with tempfile.TemporaryDirectory() as temp:
        root = Path(temp)
        catalog = root / "catalog.json"
        catalog.write_text(json.dumps({
            "characters": [{"id": "CHAR_TEST", "name": "Test Warrior", "class": "Warrior", "tier": 1, "gender": "male"}],
            "monsters": [], "maps": [], "equipment": [], "cards": [], "pets": [], "pet_equipment": []
        }), encoding="utf-8")
        output = root / "plan.json"
        import os
        old = os.getcwd()
        os.chdir(root)
        try:
            assert MODULE.main.__name__ == "main"
            # Invoke the public CLI entry through argv isolation.
            import sys
            old_argv = sys.argv
            sys.argv = ["generator", str(catalog), "--output", str(output)]
            try:
                assert MODULE.main() == 0
            finally:
                sys.argv = old_argv
        finally:
            os.chdir(old)

        plan = json.loads(output.read_text(encoding="utf-8"))
        assert plan["project"] == "honour-war"
        assert plan["engine"] == "SharnouEngine"
        assert plan["scene_count"] == 1
        scene = root / "assets/3d/generated/char_test.gltf"
        data = json.loads(scene.read_text(encoding="utf-8"))
        assert data["asset"]["version"] == "2.0"
        assert "KHR_texture_basisu" in data["extensionsUsed"]
        assert data["images"][0]["mimeType"] == "image/ktx2"
        assert data["buffers"][0]["byteLength"] == 42

    print("PASS: Honour War runtime generator emits valid glTF bootstrap scenes with KTX2 bindings.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
