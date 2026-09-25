from pathlib import Path
import json

root = Path(__file__).resolve().parents[1]
engine = root / "Engine" / "SharnouEngine"

required = [
    engine / "CMakeLists.txt",
    engine / "CMakePresets.json",
    engine / "vcpkg.json",
    engine / "sharnou_engine.json",
    engine / "include/sharnou/Engine.h",
    engine / "include/sharnou/Win32Window.h",
    engine / "include/sharnou/D3D11Renderer.h",
    engine / "include/sharnou/HonourWarGame.h",
    engine / "src/main.cpp",
    engine / "src/Engine.cpp",
    engine / "src/Win32Window.cpp",
    engine / "src/D3D11Renderer.cpp",
    engine / "src/HonourWarGame.cpp",
]
missing = [str(p.relative_to(root)) for p in required if not p.exists()]
assert not missing, f"Missing Sharnou Engine files: {missing}"

cfg = json.loads((engine / "sharnou_engine.json").read_text())
assert cfg["engine"] == "Sharnou Engine"
assert cfg["development_ide"] == "Microsoft Visual Studio Community 2022"
assert cfg["language"] == "C++20"
assert cfg["build_system"] == "CMake"
assert cfg["package_manager"] == "vcpkg"
assert cfg["platform"] == "Windows 64-bit"
assert cfg["gameplay_style"] == "3D HD MMORPG/ARPG"

catalog = json.loads((root / "data/honour_war_content_catalog.json").read_text())
counts = catalog["counts"]
expected = {
    "characters": 70,
    "monsters": 256,
    "maps": 24,
    "equipment": 300,
    "items": 76,
    "cards": 300,
    "pets": 20,
    "pet_skills": 120,
    "pet_equipment": 100,
}
for key, value in expected.items():
    assert counts[key] == value, f"Unexpected {key}: {counts[key]}"

for p in root.glob("**/*"):
    if not p.is_file() or "Legacy/Unity" in p.as_posix():
        continue
    if p.suffix.lower() in {".cpp", ".h", ".hpp", ".cmake", ".ps1"}:
        text = p.read_text(errors="ignore")
        assert "UnityEngine" not in text
        assert "UCLASS" not in text
        assert "UFUNCTION" not in text

print("SHARNOU_ENGINE_QA_PASS engine=Sharnou Engine language=C++20 ide=Microsoft Visual Studio Community 2022")
