from pathlib import Path
import re
import sys

ROOT=Path(__file__).resolve().parents[1]
ASSET_ROOT=ROOT/"assets"/"3d"/"generated"
CLASSES=["Warrior","Mage","Archer","Thief","Merchant","Acolyte"]
TIERS=["Foundation","Specialization","Advanced","Mastery","Transcendence"]
MONSTERS=["Bloody_Knight","Dragon","Evil_Druid","Goblin","Golem","Mantis","Orc","Poring","Skeleton","Wolf","Zombie"]
errors=[]; checks=0

# GitHub Actions Windows runners can default stdout to cp1252. Keep QA output
# Unicode-safe so visual-pipeline phrases such as Blender → Substance do not
# crash validation before the actual checks complete.
try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")
except (AttributeError, ValueError):
    pass


def check(ok:bool,message:str)->None:
    global checks
    checks+=1
    print(("PASS" if ok else "FAIL")+" :: "+message)
    if not ok: errors.append(message)

no_glbs=sorted(ASSET_ROOT.rglob("*.glb")) if ASSET_ROOT.is_dir() else []
check(not no_glbs,"Permanent HD GLB retirement: no .glb assets remain")
policy=ROOT/"docs"/"DAILY_HONOUR_WAR_NO_GLB_POLICY.md"
check(policy.is_file() and policy.stat().st_size>1200,"Permanent no-GLB daily upgrade policy")
if policy.is_file():
    policy_text=policy.read_text(encoding="utf-8")
    for phrase in ["HD GLB assets are permanently retired","must not regenerate","must not download","must not import","native Godot","Screenshot/"]:
        check(phrase in policy_text,"No-GLB policy: "+phrase)

role=ROOT/"docs"/"DAILY_HONOUR_WAR_VISUAL_UPGRADE_ROLE.md"
check(role.is_file() and role.stat().st_size>7000,"Permanent Daily Honour War visual role")
if role.is_file():
    text=role.read_text(encoding="utf-8")
    for phrase in ["Visual Fidelity Engineer","Art Director","full-body","Attack","Hit","Maps and world detail","native Godot 4.7.2 scenes/resources with Forward+","real character name","Swordsman","EQUIP","Character Status and Equipment are one combined window","Create New Character","Switch Characters","Options","Character age is never displayed"]:
        check(phrase in text,"Permanent role: "+phrase)

age_rules=ROOT/"docs"/"AGE_PROGRESSION_RULES.md"
check(age_rules.is_file() and age_rules.stat().st_size>2500,"Authoritative age progression rules")
if age_rules.is_file():
    age_text=age_rules.read_text(encoding="utf-8")
    for phrase in ["Starting age:** 18","3 accumulated online days","+0.5% effective core-stat growth","+1 percentage point refine-success bonus","+0.1 percentage point top-100 drop-rate bonus","floating world character display"]:
        check(phrase in age_text,"Age rules: "+phrase)

age_profile=ROOT/"data"/"character_visual_profiles"/"elder_veteran_adventurer.json"
check(age_profile.is_file() and age_profile.stat().st_size>3000,"Original elder veteran age-stage profile")
if age_profile.is_file():
    age_text=age_profile.read_text(encoding="utf-8")
    for phrase in ["\"display_age\": 68","\"age_range\": [60, 75]","no Ragnarok Online copy","idle","walk","talk","combat","hurt","victory","death"]:
        check(phrase in age_text,"Elder profile: "+phrase)

age_system=(ROOT/"scripts/OnlineAgeSystem.gd").read_text(encoding="utf-8")
for phrase in ["DEFAULT_STARTING_AGE:int = 18","DAYS_PER_YEAR:float = 3.0","STAT_GROWTH_PER_YEAR:float = 0.005","REFINE_SUCCESS_PER_YEAR:float = 0.01","TOP_100_DROP_PER_YEAR:float = 0.001","stat_growth_multiplier","refine_success_bonus","top_100_drop_bonus","hero[\"age\"]"]:
    check(phrase in age_system,"Age system: "+phrase)

age_runtime=(ROOT/"scripts/OnlineAgeRuntime.gd").read_text(encoding="utf-8")
for phrase in ["age_stat_growth_percent","age_refine_success_bonus","age_top_100_drop_bonus","equipment","roundi(base_value*multiplier)"]:
    check(phrase in age_runtime,"Age runtime: "+phrase)

formula=(ROOT/"scripts/GameplayFormula.gd").read_text(encoding="utf-8")
for phrase in ["AGE_STAT_GROWTH_PER_YEAR:float = 0.005","AGE_REFINE_BONUS_PER_YEAR:float = 0.01","AGE_TOP_100_DROP_PER_YEAR:float = 0.001","age_stat_multiplier","age_refine_bonus","age_top_100_drop_bonus","top_100_drop_chance"]:
    check(phrase in formula,"Gameplay formula: "+phrase)

equipment=(ROOT/"scripts/EquipmentProgressionSystem.gd").read_text(encoding="utf-8")
for phrase in ["age_refine_success_bonus","refine_chance(current:int,age_refine_success_bonus","attempt_refine"]:
    check(phrase in equipment,"Equipment age refine: "+phrase)

loot=(ROOT/"scripts/LootProgressionSystem.gd").read_text(encoding="utf-8")
for phrase in ["top_100_drop_bonus","top_100_drop_chance","top_100_drop_bonus_percent"]:
    check(phrase in loot,"Loot age bonus: "+phrase)

identity_path=ROOT/"scripts/HWPlayerIdentityUI.gd"
check(identity_path.is_file() and identity_path.stat().st_size>6000,"Player identity UI exists")
if identity_path.is_file():
    identity=identity_path.read_text(encoding="utf-8")
    for phrase in ["real character name","party_member","pvp_player","KEY_ESCAPE","EQUIP","not _is_local(actor)"]:
        check(phrase in identity,"Identity UI: "+phrase)
    check("CREATE NEW CHARACTER" in identity or "Create New Character" in identity,"Identity UI: create character")
    check("SWITCH CHARACTERS" in identity or "Switch Characters" in identity,"Identity UI: switch characters")
    check("OPTIONS" in identity or "Options" in identity,"Identity UI: options")
    check("STATUS + EQUIPMENT" in identity or "Status + Equipment" in identity,"Identity UI: combined status/equipment")
    check("SAVE.load_game(current)" in identity,"Switch uses SaveSystem")
    check("hovered_actor" in identity and "_world_name_visible" in identity,"Identity UI: conditional hover/social name reveal")
    check('group == "enemy"' in identity,"Identity UI: player groups do not receive permanent HP/SP world bars")
    check("reveal_player_name_for_social" in identity,"Identity UI: explicit social/chat reveal hook")

source_dir=ROOT/"Screenshot"
check(source_dir.is_dir(),"Direct Screenshot visual source folder")
for source_name in [
    "ChatGPT Image Sep 7, 2026, 03_54_35 PM.png",
    "ChatGPT Image Sep 8, 2026, 12_13_55 AM.png",
    "ChatGPT Image Sep 8, 2026, 12_30_08 AM.png",
    "ChatGPT Image Sep 14, 2026, 02_17_52 PM.png",
    "ChatGPT Image Sep 15, 2026, 11_17_00 PM.png",
    "ChatGPT Image Sep 16, 2026, 12_22_47 AM.png",
    "ChatGPT Image Sep 18, 2026, 11_57_21 PM.png",
]:
    source_path=source_dir/source_name
    check(source_path.is_file() and source_path.stat().st_size>100000,"Direct visual source: "+source_name)

reference=ROOT/"docs"/"HONOUR_WAR_PRIMARY_VISUAL_REFERENCE.md"
check(reference.is_file() and reference.stat().st_size>1500,"Primary visual/UI reference note")
if reference.is_file():
    reference_text=reference.read_text(encoding="utf-8")
    for phrase in ["Screenshot/","ChatGPT Image Sep 7, 2026, 03_54_35 PM.png","ChatGPT Image Sep 8, 2026, 12_13_55 AM.png","ChatGPT Image Sep 8, 2026, 12_30_08 AM.png","ChatGPT Image Sep 14, 2026, 02_17_52 PM.png","ChatGPT Image Sep 15, 2026, 11_17_00 PM.png","ChatGPT Image Sep 16, 2026, 12_22_47 AM.png","ChatGPT Image Sep 18, 2026, 11_57_21 PM.png","direct visual source","Local character name is completely hidden","Remote character names are hidden by default","on mouse hover","party/PvP context","No permanent player HP/SP"]:
        check(phrase in reference_text,"Primary reference: "+phrase)

runtime=(ROOT/"scripts/HDAssetRuntime.gd").read_text(encoding="utf-8")
for phrase in ["HD generated GLB assets were permanently retired","Daily upgrades must NOT regenerate, download, import, or attach GLB assets","native Godot runtime scene/visual systems"]:
    check(phrase in runtime,"HD runtime retirement policy: "+phrase)

character_visual_spec = role if role.is_file() else None
if character_visual_spec:
    for phrase in ["Stylized 3D NPR","Vibrant anime cel-shading","Volumetric, chunky hair","Sharp triangular nose-profile shadow","porcelain complexion","matte, unreflective woven-fabric","supple textured brown leather","high-contrast brushed steel","Warm volumetric ambient sunlight","Soft lavender-tinted shadows","solid-grey presentation background","Isometric presentation perspective","Neural4D is an approved optional generation source","Neural4D GLB export is forbidden","FBX for rigged/animated characters","OBJ for approved static assets"]:
        check(phrase in text,"HD character visual specification: "+phrase)

guard=(ROOT/"scripts/HWPresentationGuard.gd").read_text(encoding="utf-8")
check("hw_production_asset" in guard and "hw_source_path" in guard,"Presentation guard protects production actors")

vitals_path=ROOT/"scripts"/"HWActorVitals.gd"
if vitals_path.is_file():
    vitals_text=vitals_path.read_text(encoding="utf-8")
    check("Player avatars never carry permanent HP/SP world bars." in vitals_text,"Vitals: permanent player bars disabled")
    check("_build_hero_bars(hero)" not in vitals_text,"Vitals: local hero no longer builds world HP/SP bars")
for prefix in ["hero_","warrior_","knight_"]:
    check(re.search(r"\.begins_with\(\s*[\"']"+re.escape(prefix)+r"[\"']\s*\)",guard) is None,"No broad "+prefix+" deletion")

movement=(ROOT/"scripts/MovementStabilityFix.gd").read_text(encoding="utf-8")
game3d=(ROOT/"scripts/Game3D.gd").read_text(encoding="utf-8")
check("current=true" in movement or "current = true" in movement,"Stable camera owner")
check("camera.current = true" not in game3d and "camera.make_current()" not in game3d,"Game3D does not compete for camera ownership")

main_scene=(ROOT/"Main3D.tscn").read_text(encoding="utf-8")
check("HWPlayerIdentityUI.gd" in main_scene,"Identity UI wired to Main3D")
check('[node name="HWPlayerIdentityUI" type="CanvasLayer" parent="."]' in main_scene,"Identity UI CanvasLayer present")

project=(ROOT/"project.godot").read_text(encoding="utf-8")
check('config/name="Honour War"' in project,"Project identity")
check('config/features=PackedStringArray("4.7")' in project,"Godot 4.7 project feature")
for atlas in ["item_icons_atlas.svg","skill_icons_atlas.svg"]:
    path=ASSET_ROOT/"ui"/atlas
    check(path.is_file() and path.stat().st_size>1000,"UI atlas "+atlas)

for path in ROOT.rglob("*"):
    if path.is_file() and path.suffix in {".gd",".tscn",".tres"}:
        data=path.read_text(encoding="utf-8",errors="ignore")
        check("<<<<<<<" not in data and ">>>>>>>" not in data and "=======" not in data,"No merge conflict: "+str(path.relative_to(ROOT)))

print(f"Visual contract QA: {checks-len(errors)}/{checks} checks passed")
if errors:
    print("Critical failures: "+str(len(errors)))
    sys.exit(1)
print("Honour War visual asset contract: PASS")
