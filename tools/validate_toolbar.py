from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
ICON = ROOT / "scripts" / "HWIconButton.gd"
HUD = ROOT / "scripts" / "HWPolishedInterfaceV2.gd"
VITALS = ROOT / "scripts" / "HWVitalsStartupNormalizer.gd"

failures = []

def require(path: Path) -> str:
    if not path.is_file():
        failures.append(f"missing: {path}")
        return ""
    return path.read_text(encoding="utf-8")

icon_text = require(ICON)
hud_text = require(HUD)
vitals_text = require(VITALS)

expected_icons = ["character", "pet", "skills", "inventory", "equipment", "refine", "map", "objectives", "system"]
for icon in expected_icons:
    if f'"{icon}":' not in icon_text:
        failures.append(f"icon case missing: {icon}")

# Godot 4 draw_circle(center, radius, color) has exactly three arguments.
for index, line in enumerate(icon_text.splitlines(), 1):
    if "draw_circle(" not in line:
        continue
    payload = line.split("draw_circle(", 1)[1].rsplit(")", 1)[0]
    if payload.count(",") != 2:
        failures.append(f"unsafe draw_circle argument count at icon line {index}: {line.strip()}")

mode_match = re.search(r"const MODES:Array\[String\]=\[(.*?)\]", hud_text, re.S)
if not mode_match:
    failures.append("MODES declaration missing")
else:
    declared = re.findall(r'"([a-z_]+)"', mode_match.group(1))
    for mode in expected_icons:
        if mode not in declared:
            failures.append(f"toolbar mode missing: {mode}")
        if f'"{mode}": _' not in hud_text:
            failures.append(f"toolbar renderer missing: _{mode}")

for required in ["_build", "_open_mode", "_equipment", "_refine", "_map", "_objectives", "_system", "_refresh_status"]:
    if f"func {required}" not in hud_text:
        failures.append(f"HUD function missing: {required}")

for required in ["hero[\"hp\"]", "hero[\"sp\"]", "_hw_vitals_initialized"]:
    if required not in vitals_text:
        failures.append(f"vitals normalization missing: {required}")

if failures:
    print("HONOUR WAR TOOLBAR STATIC QA: FAIL")
    for failure in failures:
        print(" -", failure)
    sys.exit(1)

print("HONOUR WAR TOOLBAR STATIC QA: PASS")
print(f"Verified {len(expected_icons)} toolbar icon modes and the one-time full-vitals initializer.")
