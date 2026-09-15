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

for cls in CHARACTERS:
    for tier in TIERS:
        path = ASSET_ROOT / "characters" / cls / f"{tier}.glb"
        check(path.is_file() and path.stat().st_size > 10000, f"Missing/invalid character asset: {path.relative_to(ROOT)}")

for monster in MONSTERS:
    path = ASSET_ROOT / "monsters" / f"monster_{monster}.glb"
    check(path.is_file() and path.stat().st_size > 10000, f"Missing/invalid monster asset: {path.relative_to(ROOT)}")

role_path = ROOT / "docs" / "DAILY_HONOUR_WAR_VISUAL_UPGRADE_ROLE.md"
check(role_path.is_file() and role_path.stat().st_size > 5000, "Permanent Daily Honour War visual role document is missing/invalid")
if role_path.is_file():
    role = role_path.read_text(encoding="utf-8")
    for phrase in [
        "Honour War Fantasy MMORPG Showcase.png",
        "Honour War Fantasy MMORPG Interface.png",
        "Visual Fidelity Engineer",
        "Art Director",
        "full-body",
        "Attack",
        "Hit",
        "Maps and world detail",
        "Blender → Substance 3D Painter → GLB/GLTF → Godot 4 Forward+",
    ]:
        check(phrase in role, f"Permanent visual role is missing required contract: {phrase}")

runtime = (ROOT / "scripts" / "HDAssetRuntime.gd").read_text(encoding="utf-8")
check('res://assets/3d/generated/characters' in runtime, "HD hero asset root is not configured")
check('res://assets/3d/generated/monsters' in runtime, "HD monster asset root is not configured")
check('hw_production_asset' in runtime and 'hw_source_path' in runtime, "Production asset metadata contract is missing")
check('_normalize_actor' in runtime and 'hero_target_height' in runtime, "HD actor framing normalization is missing")
check('process_priority = 100' in runtime, "HD asset runtime does not enforce authored transforms after procedural presentation")
check('_enforce_production_transforms' in runtime, "Authored production transform enforcement is missing")

guard = (ROOT / "scripts" / "HWPresentationGuard.gd").read_text(encoding="utf-8")
check('hw_production_asset' in guard and 'hw_source_path' in guard, "Presentation guard does not protect production assets")
check('HWClassIdentity' in guard, "Class identity marker is missing")
for prefix in ["hero_", "warrior_", "knight_"]:
    broad_delete = re.search(r"\.begins_with\(\s*[\"']" + re.escape(prefix) + r"[\"']\s*\)", guard)
    check(broad_delete is None, f"Presentation guard still contains broad {prefix} prefix deletion")

movement = (ROOT / "scripts" / "MovementStabilityFix.gd").read_text(encoding="utf-8")
game3d = (ROOT / "scripts" / "Game3D.gd").read_text(encoding="utf-8")
check('current=true' in movement or 'current = true' in movement, "MovementStabilityFix does not own the active camera")
check('camera.current = true' not in game3d and 'camera.make_current()' not in game3d, "Game3D attempts to take ownership of the active camera")

# Player identity / character-menu contract.
identity_path = ROOT / "scripts" / "HWPlayerIdentityUI.gd"
check(identity_path.is_file() and identity_path.stat().st_size > 6000, "Player identity UI script is missing/invalid")
if identity_path.is_file():
    identity = identity_path.read_text(encoding="utf-8")
    for phrase in [
        "real character name",
        "not _is_local(actor)",
        "party_member",
        "pvp_player",
        "KEY_ESCAPE",
        "CREATE NEW CHARACTER",
        "SWITCH CHARACTERS",
        "OPTIONS",
        "CHARACTER • STATUS + EQUIPMENT",
        "EQUIP",
    ]:
        check(phrase in identity, f"Player identity contract missing: {phrase}")
    check('actor.get("class", actor.get_meta' not in identity, "Invalid two-argument Object.get call remains in player identity UI")
    check('SAVE.load_game(current)' in identity, "Character switching does not use the existing save system")

main_scene = (ROOT / "Main3D.tscn").read_text(encoding="utf-8")
check('HWPlayerIdentityUI.gd' in main_scene, "Player identity UI is not integrated into Main3D")
check('[node name="HWPlayerIdentityUI" type="CanvasLayer" parent="."]' in main_scene, "Player identity CanvasLayer node is missing")
check('script = ExtResource("56")' in main_scene, "Player identity script resource is not wired")

project = (ROOT / "project.godot").read_text(encoding="utf-8")
check('config/name="Honour War"' in project or 'config/name="Honour-War"' in project, "Honour War project identity is missing")
check('4.7.2' in project, "Godot 4.7.2 is not declared in project metadata")
for ui_file in ["item_icons_atlas.svg", "skill_icons_atlas.svg"]:
    path = ASSET_ROOT / "ui" / ui_file
    check(path.is_file() and path.stat().st_size > 1000, f"Missing/invalid UI atlas: {path.relative_to(ROOT)}")

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
