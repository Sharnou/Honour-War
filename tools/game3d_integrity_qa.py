from pathlib import Path

REQUIRED_FUNCTIONS = (
    "_build_hud",
    "_map_to_world",
    "_update_monsters",
    "_update_hud",
    "_material",
    "_ring",
    "_create_hero",
    "_create_pet",
    "_create_monster",
)

GAME3D = Path("scripts/Game3D.gd")

if not GAME3D.is_file():
    raise SystemExit("Game3D integrity failure: scripts/Game3D.gd is missing")

source = GAME3D.read_text(encoding="utf-8")
missing = [name for name in REQUIRED_FUNCTIONS if "func " + name + "(" not in source]
if missing:
    raise SystemExit("Game3D integrity failure: missing functions: " + ", ".join(missing))

# This regression specifically guards against the 318-line truncation that
# previously removed the lower half of Game3D.gd.
if len(source.splitlines()) < 500:
    raise SystemExit(
        "Game3D integrity failure: source is unexpectedly short (" +
        str(len(source.splitlines())) + " lines)"
    )

print("Game3D integrity QA passed: " + str(len(source.splitlines())) + " lines; all required functions present.")
