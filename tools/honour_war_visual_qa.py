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

# 1. Authored Blender -> GLB production assets.
for cls in CHARACTERS:
    for tier in TIERS:
        path = ASSET_ROOT / "characters" / cls / f"{tier}.glb"
        check(path.is_file() and path.stat().st_size > 10000, f"Missing/invalid character asset: {path.relative_to(ROOT)}")

for monster in MONSTERS:
    path = ASSET_ROOT / "monsters" / f"monster_{monster}.glb"
    check(path.is_file() and path.stat().st_size > 10000, f"Missing/invalid monster asset: {path.relative_to(ROOT)}")

# 2. Runtime must expose the production asset roots and protect loaded assets.
runtime = (ROOT / "scripts" / "HDAssetRuntime.gd").read_text(encoding="utf-8")
check('res://assets/3d/generated/characters' in runtime, "HD hero asset root is not configured")
check('res://assets/3d/generated/monsters' in runtime, "HD monster asset root is not configured")
check('hw_production_asset' in runtime and 'hw_source_path' in runtime, "Production asset metadata contract is missing")
check('_normalize_actor' in runtime and 'hero_target_height' in runtime, "HD actor framing normalization is missing")

# 3. Presentation guard must protect production actors and expose class identity.
guard = (ROOT / "scripts" / "HWPresentationGuard.gd").read_text(encoding="utf-8")
check('hw_production_asset' in guard and 'hw_source_path' in guard, "Presentation guard does not protect production assets")
check('HWClassIdentity' in guard, "Class identity marker is missing")
# Actual broad deletion is prohibited; legitimate identifiers such as hero_visual are fine.
for prefix in ["hero_", "warrior_", "knight_"]:
    broad_delete = re.search(r"\.begins_with\(\s*[\"']" + re.escape(prefix) + r"[\"']\s*\)", guard)
    check(broad_delete is None, f"Presentation guard still contains broad {prefix} prefix deletion")

# 4. Camera ownership contract: the movement script is the active camera owner.
movement = (ROOT / "scripts" / "MovementStabilityFix.gd").read_text(encoding="utf-8")
game3d = (ROOT / "scripts" / "Game3D.gd").read_text(encoding="utf-8")
check('current=true' in movement or 'current = true' in movement, "MovementStabilityFix does not own the active camera")
check('camera.current = true' not in game3d and 'camera.make_current()' not in game3d, "Game3D attempts to take ownership of the active camera")

# 5. Project/UI contract.
project = (ROOT / "project.godot").read_text(encoding="utf-8")
check('config/name="Honour War"' in project or 'config/name="Honour-War"' in project, "Honour War project identity is missing")
check('4.7.2' in project, "Godot 4.7.2 is not declared in project metadata")
for ui_file in ["item_icons_atlas.svg", "skill_icons_atlas.svg"]:
    path = ASSET_ROOT / "ui" / ui_file
    check(path.is_file() and path.stat().st_size > 1000, f"Missing/invalid UI atlas: {path.relative_to(ROOT)}")

# 6. Repository hygiene.
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