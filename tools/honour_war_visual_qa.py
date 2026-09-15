from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
ASSET_ROOT = ROOT / "assets" / "3d" / "generated"
CHARACTERS = ["Warrior", "Mage", "Archer", "Thief", "Merchant", "Acolyte"]
TIERS = ["Foundation", "Specialization", "Advanced", "Mastery", "Transcendence"]
MONSTERS = ["Bloody_Knight", "Dragon", "Evil_Druid", "Goblin", "Golem", "Mantis", "Orc", "Poring", "Skeleton", "Wolf", "Zombie"]

errors = []
checks = []

def check(ok, message):
    checks.append((ok, message))
    if not ok:
        errors.append(message)

# Production character contract: every class has every progression tier.
for cls in CHARACTERS:
    for tier in TIERS:
        path = ASSET_ROOT / "characters" / cls / f"{tier}.glb"
        check(path.is_file() and path.stat().st_size > 10000, f"Missing/invalid character asset: {path.relative_to(ROOT)}")

# Production monster contract: every named monster has a distinct GLB.
for monster in MONSTERS:
    path = ASSET_ROOT / "monsters" / f"monster_{monster}.glb"
    check(path.is_file() and path.stat().st_size > 10000, f"Missing/invalid monster asset: {path.relative_to(ROOT)}")

runtime = (ROOT / "scripts" / "HDAssetRuntime.gd").read_text(encoding="utf-8")
check('hero_asset_root:String = "res://assets/3d/generated/characters"' in runtime, "HD hero asset root is not configured")
check('monster_asset_root:String = "res://assets/3d/generated/monsters"' in runtime, "HD monster asset root is not configured")
check('hw_production_asset' in runtime and 'hw_source_path' in runtime, "Production asset metadata contract is missing")
check('replacement_3d.name = current.name + "_HDAsset"' in runtime, "HD replacement node naming contract is missing")

# Guard must not purge production actors.
guard = (ROOT / "scripts" / "HWPresentationGuard.gd").read_text(encoding="utf-8")
check('hw_production_asset' in guard and 'hw_source_path' in guard, "Presentation guard does not protect production assets")
check('"hero_"' not in guard, "Presentation guard still contains broad hero_ prefix deletion")
check('"warrior_"' not in guard, "Presentation guard still contains broad warrior_ prefix deletion")
check('"knight_"' not in guard, "Presentation guard still contains broad knight_ prefix deletion")
check('HWClassIdentity' in guard, "Class identity marker is missing")

# Camera must remain the sole movement/camera owner.
movement = (ROOT / "scripts" / "MovementStabilityFix.gd").read_text(encoding="utf-8")
game3d = (ROOT / "scripts" / "Game3D.gd").read_text(encoding="utf-8")
check('current=true' in movement or 'current = true' in movement, "MovementStabilityFix does not own the active camera")
check('Do not follow the hero here' in game3d, "Game3D camera ownership warning is missing")

# Visual pipeline contract.
project = (ROOT / "project.godot").read_text(encoding="utf-8")
check('config/name="Honour War"' in project or 'config/name="Honour-War"' in project, "Honour War project identity is missing")
check('4.7.2' in project, "Godot 4.7.2 is not declared in project metadata")

# UI asset contract.
for ui_file in ["item_icons_atlas.svg", "skill_icons_atlas.svg"]:
    path = ASSET_ROOT / "ui" / ui_file
    check(path.is_file() and path.stat().st_size > 1000, f"Missing/invalid UI atlas: {path.relative_to(ROOT)}")

# Detect accidental unresolved Godot merge markers in scripts/scenes.
for path in ROOT.rglob("*"):
    if path.is_file() and path.suffix in {".gd", ".tscn", ".tres", ".godot"}:
        try:
            text = path.read_text(encoding="utf-8", errors="ignore")
        except Exception:
            continue
        check("<<<<<<<" not in text and ">>>>>>>" not in text and "=======" not in text,
              f"Merge-conflict marker detected: {path.relative_to(ROOT)}")

for ok, message in checks:
    print(("PASS" if ok else "FAIL") + " :: " + message)

print(f"Visual contract QA: {len(checks) - len(errors)}/{len(checks)} checks passed")
if errors:
    print("Critical visual contract failures:")
    for error in errors:
        print(" - " + error)
    sys.exit(1)
print("Honour War visual asset contract: PASS")
