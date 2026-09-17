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


def _top_level_argument_count(payload: str) -> int:
    """Count function-call arguments without counting nested commas.

    Godot calls such as draw_circle(Vector2(x,y), 15.0, Color("#0a1422"))
    contain commas inside nested Vector2/Color expressions. A raw comma count
    incorrectly reports these valid calls as having too many arguments.
    """
    depth = 0
    commas = 0
    in_string = False
    escaped = False
    for char in payload:
        if in_string:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == '"':
                in_string = False
            continue
        if char == '"':
            in_string = True
        elif char == '(':
            depth += 1
        elif char == ')':
            depth -= 1
        elif char == ',' and depth == 0:
            commas += 1
    return commas + 1 if payload.strip() else 0


def _draw_circle_argument_count(line: str) -> int | None:
    """Return the top-level draw_circle argument count from one source line."""
    marker = "draw_circle("
    start = line.find(marker)
    if start < 0:
        return None
    payload_start = start + len(marker)
    depth = 0
    in_string = False
    escaped = False
    payload_end = None
    for index in range(payload_start, len(line)):
        char = line[index]
        if in_string:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == '"':
                in_string = False
            continue
        if char == '"':
            in_string = True
        elif char == '(':
            depth += 1
        elif char == ')':
            if depth == 0:
                payload_end = index
                break
            depth -= 1
    if payload_end is None:
        return None
    return _top_level_argument_count(line[payload_start:payload_end])


# Regression coverage for the exact nested-call forms used by HWIconButton.
for sample in [
    'draw_circle(Vector2(x,y),15.0,Color("#0a1422"))',
    'draw_circle(Vector2(x,y-4),4.0,c)',
    'draw_circle(Vector2(x+10,y+11),3.5,c)',
]:
    if _draw_circle_argument_count(sample) != 3:
        failures.append(f"draw_circle parser regression: {sample}")

icon_text = require(ICON)
hud_text = require(HUD)
vitals_text = require(VITALS)

expected_icons = ["character", "pet", "skills", "inventory", "equipment", "refine", "map", "objectives", "system"]
for icon in expected_icons:
    if f'"{icon}":' not in icon_text:
        failures.append(f"icon case missing: {icon}")

# Godot 4 draw_circle(center, radius, color) has exactly three top-level arguments.
for index, line in enumerate(icon_text.splitlines(), 1):
    if "draw_circle(" not in line:
        continue
    count = _draw_circle_argument_count(line)
    if count != 3:
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
