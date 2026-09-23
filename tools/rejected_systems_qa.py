#!/usr/bin/env python3
"""Permanent Honour War exclusion contract."""
from __future__ import annotations
import re
import json
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "Source"
TOOL_DIR = ROOT / "tools"
VALIDATOR_FILES = frozenset({"rejected_systems_qa.py","validate_hd_assets.py","validate_art_generators.py","unreal_engine_contract_qa.py"})
ACTIVE_GENERATOR_FILES = ("tools/blender/honour_war_monster_assets.py","tools/blender/honour_war_production_assets.py","tools/blender/honour_war_visual_max_assets.py","tools/blender/build_ss_production_asset.py","tools/blender/run_visual_max_assets.py")
EXCLUDED_SYMBOLS = ("HonourWarSoldier","HonourWarIncomeBank","HonourWarDefenseTower","HonourWarBaseBuilding","SoldierWorkshop","SkillShrine","SpawnSoldierSquad","RegisterSoldierDeath","EnsureCommanderSquads","SetPlayerTarget","CanAttackPlayer","ReceivePlayerDamage","ServerUseSkillOnPlayer","ServerTryRefineEquipment","ServerTryMixCards","ServerTryUpgradeBasicSkill","BaseSight","TeamId","PartySlot","BuildSectionPanel","DefenseTower","IncomeBank","squad production")
EXCLUDED_TERMS = ("bpy.ops.export_scene.gltf","bpy.ops.wm.gltf_export","strategy/tower/army","guarded income bank","tower-defense","base sight overlay","building/construction UI")
RETIRED_ASSET_EXTENSIONS = frozenset({"."+"glb","."+"gltf"})
FORBIDDEN_ENGINE = "God"+"ot"
FORBIDDEN_GODOT_SUFFIXES = frozenset({"."+"gd","."+"tscn","."+"tres"})
FORBIDDEN_GENERATOR_TERMS = ("transformer",)
FORBIDDEN_CITY_FEATURES = ("Town"+" Hall","Black"+"smith","Mar"+"ket","Bar"+"racks","Magic"+" Tower","City"+" resources","City"+" upgrades")
FORBIDDEN_CITY_IDENTIFIERS = ("TownHall","Blacksmith","Market","Barracks","MagicTower","CityResource","CityUpgrade","CityService","ServiceImplementation","BuildingConnection","BuildingSkill","ConnectBuilding","ActivateBuilding","BuildingDependency","BuildMode","ConstructionMenu","ConstructionAction")
REMOVED_FILES = ("Source/HonourWar/HonourWarSoldier.h","Source/HonourWar/HonourWarSoldier.cpp","Source/HonourWar/HonourWarIncomeBank.h","Source/HonourWar/HonourWarIncomeBank.cpp","Source/HonourWar/HonourWarDefenseTower.h","Source/HonourWar/HonourWarDefenseTower.cpp","Source/HonourWar/HonourWarBaseBuilding.h","Source/HonourWar/HonourWarBaseBuilding.cpp","Source/HonourWar/HonourWarPlayerState.cpp.tmp")

def fail(message: str) -> None: raise SystemExit(f"EXCLUSION_QA_FAIL: {message}")
def scan(path: Path, markers) -> None:
    text = path.read_text(encoding="utf-8", errors="ignore")
    for marker in markers:
        if marker in text: fail(f"permanently rejected marker remains in {path.relative_to(ROOT)}: {marker}")
def check_validator_allowlist() -> None:
    actual = frozenset(p.name for p in TOOL_DIR.glob("*.py") if p.name in VALIDATOR_FILES)
    if actual != VALIDATOR_FILES: fail(f"validator exemption set changed unexpectedly: expected={sorted(VALIDATOR_FILES)} actual={sorted(actual)}")
def scan_runtime() -> None:
    if not SOURCE_DIR.is_dir(): fail("runtime Source directory is missing")
    for path in SOURCE_DIR.rglob("*"):
        if path.is_file() and path.suffix.lower() in {".h",".cpp",".py",".ini",".json"}: scan(path, EXCLUDED_SYMBOLS + EXCLUDED_TERMS + FORBIDDEN_CITY_FEATURES + FORBIDDEN_CITY_IDENTIFIERS + (FORBIDDEN_ENGINE,))
def scan_active_generators() -> None:
    for relative in ACTIVE_GENERATOR_FILES:
        path=ROOT/relative
        if not path.is_file(): fail(f"active generator is missing: {relative}")
        scan(path, EXCLUDED_SYMBOLS + EXCLUDED_TERMS + FORBIDDEN_CITY_FEATURES + FORBIDDEN_CITY_IDENTIFIERS + FORBIDDEN_GENERATOR_TERMS + (FORBIDDEN_ENGINE,))
        text=path.read_text(encoding="utf-8",errors="ignore").lower()
        for ext in RETIRED_ASSET_EXTENSIONS:
            if ext in text: fail(f"retired asset extension remains in active generator {relative}: {ext}")
def scan_non_validator_tooling() -> None:
    for path in TOOL_DIR.rglob("*.py"):
        if path.name in VALIDATOR_FILES: continue
        scan(path, EXCLUDED_SYMBOLS + EXCLUDED_TERMS + FORBIDDEN_CITY_FEATURES + FORBIDDEN_GENERATOR_TERMS + (FORBIDDEN_ENGINE,))
        text=path.read_text(encoding="utf-8",errors="ignore").lower()
        for ext in RETIRED_ASSET_EXTENSIONS:
            if ext in text: fail(f"retired asset extension remains in tool {path.relative_to(ROOT)}: {ext}")
def check_removed_files() -> None:
    for relative in REMOVED_FILES:
        if (ROOT/relative).exists(): fail(f"rejected file remains: {relative}")
TEXT_SCAN_ROOTS = ("Source", "tools", "data", "Config", "Build", "Content")
TEXT_SUFFIXES = frozenset({".h", ".hpp", ".cpp", ".c", ".cc", ".py", ".ini", ".json", ".csv", ".md", ".txt", ".uasset", ".umap"})

def scan_active_project_data() -> None:
    """Reject prohibited city systems in active project/data/generation surfaces."""
    for relative in TEXT_SCAN_ROOTS:
        base = ROOT / relative
        if not base.exists():
            continue
        for path in base.rglob("*"):
            if not path.is_file() or path.suffix.lower() not in TEXT_SUFFIXES:
                continue
            if relative == "tools" and path.name in VALIDATOR_FILES:
                continue
            scan(path, FORBIDDEN_CITY_FEATURES + FORBIDDEN_CITY_IDENTIFIERS + EXCLUDED_SYMBOLS + EXCLUDED_TERMS)

def check_no_forbidden_artifacts() -> None:
    for path in ROOT.rglob("*"):
        if ".git" in path.parts: continue
        rel=path.relative_to(ROOT)
        low=str(rel).lower()
        if path.is_dir() and path.name.lower()=="."+"godot": fail(f"forbidden Godot directory remains: {rel}")
        if path.is_file():
            name=path.name.lower(); suffix=path.suffix.lower()
            if name=="project."+"godot" or suffix in FORBIDDEN_GODOT_SUFFIXES: fail(f"forbidden Godot artifact remains: {rel}")
            if suffix in RETIRED_ASSET_EXTENSIONS: fail(f"rejected GLB/GLTF asset remains: {rel}")
        if any(term.lower() in low for term in ("townhall","blacksmith","market","barracks","magictower","cityresource","cityupgrade","cityservice","serviceimplementation","buildingconnection","buildingskill","connectbuilding","activatebuilding","buildingdependency","buildmode","constructionmenu","constructionaction")): fail(f"rejected city-building/service asset path remains: {rel}")
def check_city_monster_exclusion() -> None:
    world=ROOT/"Source"/"HonourWar"/"HonourWarWorldDirector.cpp"
    if not world.is_file(): fail("HonourWarWorldDirector.cpp is missing")
    text=world.read_text(encoding="utf-8")
    if "FVector2D(Slot.Location.X,Slot.Location.Y).Size()<7800.0f" not in text: fail("permanent city monster exclusion radius is missing")
    catalog=ROOT/"data"/"honour_war_content_catalog.json"
    if catalog.is_file():
        try:
            entries=json.loads(catalog.read_text(encoding="utf-8"))["monsters"]
        except (OSError,KeyError,json.JSONDecodeError) as exc:
            fail(f"monster catalog cannot be read: {exc}")
        for entry in entries:
            loc=entry.get("location",{})
            x=float(loc.get("x",0.0)); y=float(loc.get("y",0.0))
            if (x*x+y*y)**0.5<7800.0:
                fail(f"monster catalog entry remains inside city exclusion radius: {entry.get('id','unknown')} {x},{y}")
        return
    match=re.search(r"const FVector MonsterLocations\[\]\s*=\s*\{(.*?)\};",text,re.S)
    if not match: fail("monster location array is missing")
    for xyz in re.findall(r"FVector\(([-+]?\d+(?:\.\d+)?),([-+]?\d+(?:\.\d+)?),",match.group(1)):
        x,y=map(float,xyz)
        if (x*x+y*y)**0.5<7800.0: fail(f"monster spawn remains inside city exclusion radius: {x},{y}")
def check_world_director_city_systems_absent() -> None:
    world=ROOT/"Source"/"HonourWar"/"HonourWarWorldDirector.cpp"
    if not world.is_file(): fail("HonourWarWorldDirector.cpp is missing")
    text=world.read_text(encoding="utf-8",errors="ignore")
    for marker in FORBIDDEN_CITY_IDENTIFIERS:
        if marker.lower() in text.lower(): fail(f"rejected city/service identifier remains in World Director: {marker}")

def main() -> int:
    check_validator_allowlist(); scan_runtime(); scan_active_generators(); scan_non_validator_tooling(); scan_active_project_data(); check_removed_files(); check_no_forbidden_artifacts(); check_city_monster_exclusion(); check_world_director_city_systems_absent()
    print("EXCLUSION_QA_PASS: Unreal-only; Godot, GLB/GLTF, soldier systems, and rejected city-building systems are permanently excluded from runtime and generation surfaces.")
    return 0
if __name__ == "__main__": raise SystemExit(main())
