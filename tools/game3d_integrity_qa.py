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
INTERACTION = Path("scripts/HW3DInteractionDirector.gd")

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

if not INTERACTION.is_file():
    raise SystemExit("3D interaction integrity failure: scripts/HW3DInteractionDirector.gd is missing")

interaction = INTERACTION.read_text(encoding="utf-8")
required_interaction_tokens = (
    'get_nodes_in_group("player")',
    'get_nodes_in_group("remote_player")',
    'get_nodes_in_group("enemy")',
    "Area3D.new()",
    "CollisionShape3D.new()",
    "CapsuleShape3D.new()",
    "area.input_ray_pickable = true",
    "area.collision_layer = 1",
    "area.collision_mask = 0",
    'area.add_child(shape)',
    'actor.add_child(area)',
)
missing_interaction = [
    token for token in required_interaction_tokens if token not in interaction
]
if missing_interaction:
    raise SystemExit(
        "3D interaction integrity failure: missing hitbox contract: " +
        ", ".join(missing_interaction)
    )

# A pick target must be a physics object with a CollisionShape3D child. This
# guards against the invalid historical pattern of putting CollisionShape3D
# directly under a plain Node3D.
if "var shape := CollisionShape3D.new()" not in interaction:
    raise SystemExit("3D interaction integrity failure: no valid CollisionShape3D hitbox")
if "var capsule := CapsuleShape3D.new()" not in interaction:
    raise SystemExit("3D interaction integrity failure: no capsule ray-pick volume")

print(
    "Game3D + 3D interaction integrity QA passed: " +
    str(len(source.splitlines())) +
    " Game3D lines; player/remote-player/enemy Area3D ray-pick hitboxes are declared."
)
