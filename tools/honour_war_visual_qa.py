from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
ASSET_ROOT = ROOT / "assets" / "3d" / "generated"
CLASSES = ["Warrior", "Mage", "Archer", "Thief", "Merchant", "Acolyte"]
TIERS = ["Foundation", "Specialization", "Advanced", "Mastery", "Transcendence"]
MONSTERS = ["Bloody_Knight", "Dragon", "Evil_Druid", "Goblin", "Golem", "Mantis", "Orc", "Poring", "Skeleton", "Wolf", "Zombie"]
errors = []
checks = 0

def check(ok: bool, message: str) -> None:
    global checks
    checks += 1
    if not ok:
        errors.append(message)
        print("FAIL :: " + message)
    else:
        print("PASS :: " + message)

for cls in CLASSES:
    for tier in TIERS:
        path = ASSET_ROOT / "characters" / cls / f"{tier}.glb"
        check(path.is_file() and path.stat().st_size > 10000, f"Character GLB {cls}/{tier}")

for monster in MONSTERS:
    path = ASSET_ROOT / "monsters" / f"monster_{monster}.glb"
    check(path.is_file() and path.stat().st_size > 10000, f"Monster GLB {monster}")

role = ROOT / "docs" / "DAILY_HONOUR_WAR_VISUAL_UPGRADE_ROLE.md"
check(role.is_file() and role.stat().st_size > 5000, "Permanent Daily Honour War visual role")
if role.is_file():
    text = role.read_text(encoding="utf-8")
    for phrase in ["Visual Fidelity Engineer", "Art Director", "full-body", "Attack", "Hit", "Maps and world detail", "Blender → Substance 3D Painter → GLB/GLTF → Godot 4 Forward+", "real character name", "Swordsman", "EQUIP", "CHARACTER • STATUS + EQUIPMENT", "CREATE NEW CHARACTER", "SWITCH CHARACTERS", "OPTIONS"]:
        check(phrase in text, "Permanent role: " + phrase)

runtime = (ROOT / "scripts" / "HDAssetRuntime.gd").read_text(encoding="utf-8")
for phrase in ["res://assets/3d/generated/characters", "res://assets/3d/generated/monsters", "hw_production_asset", "hw_source_path", "_normalize_actor", "hero_target_height", "process_priority = 100", "_enforce_production_transforms"]:
    check(phrase in runtime, "HD runtime: " + phrase)

guard = (ROOT / "scripts" / "HWPresentationGuard.gd").read_text(encoding="utf-8")
check("hw_production_asset" in guard and "hw_source_path" in guard, "Presentation guard protects production actors")
for prefix in ["hero_", "warrior_", "knight_"]:
    check(re.search(r"\.begins_with\(\s*[\"']" + re.escape(prefix) + r"[\"']\s*\)", guard) is None, "No broad " + prefix + " deletion")

movement = (ROOT / "scripts" / "MovementStabilityFix.gd").read_text(encoding="utf-8")
game3d = (ROOT / "scripts" / "Game3D.gd").read_text(encoding="utf-8")
check("current=true" in movement or "current = true" in movement, "Stable camera owner")
check("camera.current = true" not in game3d and "camera.make_current()" not in game3d, "Game3D does not compete for camera ownership")

identity_path = ROOT / "scripts" / "HWPlayerIdentityUI.gd"
check(identity_path.is_file() and identity_path.stat().st_size > 6000, "Player identity UI exists")
if identity_path.is_file():
    identity = identity_path.read_text(encoding="utf-8")
    for phrase in ["real character name", "party_member", "pvp_player", "KEY_ESCAPE", "CREATE NEW CHARACTER", "SWITCH CHARACTERS", "OPTIONS", "CHARACTER • STATUS + EQUIPMENT", "EQUIP", "not _is_local(actor)"]:
        check(phrase in identity, "Identity UI: " + phrase)
    check('actor.get("class", actor.get_meta' not in identity, "No invalid two-argument Object.get")
    check("SAVE.load_game(current)" in identity, "Switch uses SaveSystem")

main_scene = (ROOT / "Main3D.tscn").read_text(encoding="utf-8")
check('HWPlayerIdentityUI.gd' in main_scene, "Identity UI wired to Main3D")
check('[node name="HWPlayerIdentityUI" type="CanvasLayer" parent="."]' in main_scene, "Identity UI CanvasLayer present")
check('script = ExtResource("56")' in main_scene, "Identity UI script resource present")

project = (ROOT / "project.godot").read_text(encoding="utf-8")
check('config/name="Honour War"' in project, "Project identity")
check('config/features=PackedStringArray("4.7")' in project, "Godot 4.7 project feature")
for atlas in ["item_icons_atlas.svg", "skill_icons_atlas.svg"]:
    path = ASSET_ROOT / "ui" / atlas
    check(path.is_file() and path.stat().st_size > 1000, "UI atlas " + atlas)

for path in ROOT.rglob("*"):
    if path.is_file() and path.suffix in {".gd", ".tscn", ".tres"}:
        data = path.read_text(encoding="utf-8", errors="ignore")
        check("<<<<<<<" not in data and ">>>>>>>" not in data and "=======" not in data, "No merge conflict: " + str(path.relative_to(ROOT)))

print(f"Visual contract QA: {checks - len(errors)}/{checks} checks passed")
if errors:
    print("Critical failures: " + str(len(errors)))
    sys.exit(1)
print("Honour War visual asset contract: PASS")
