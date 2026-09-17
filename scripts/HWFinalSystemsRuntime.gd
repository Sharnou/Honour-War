extends CanvasLayer

## Compatibility shell for an older prototype scene node.
## Honour War is permanently MMORPG/ARPG-only; cities are service/social hubs.
## This node deliberately performs no soldier, bank, tower-defense, barracks,
## production, guarded-bank or army gameplay. It only removes obsolete runtime
## state that may still be produced by the hidden legacy prototype node.

const RETIRED_KEYS:Array[String] = [
    "war_system", "soldiers", "soldier_production", "banks", "bank_territories",
    "tower_defense", "barracks", "guarded_banks", "city_building"
]

var game:Node3D
var legacy:Node
var scan_timer:float = 0.0

func _ready()->void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    game = get_parent() as Node3D
    call_deferred("_bind")

func _bind()->void:
    if game == null or not is_instance_valid(game):
        return
    legacy = game.get_node_or_null("LegacyGame")
    _sanitize_legacy_state()

func _process(delta:float)->void:
    scan_timer += delta
    if scan_timer < 0.5:
        return
    scan_timer = 0.0
    _sanitize_legacy_state()

func _sanitize_legacy_state()->void:
    if legacy == null or not is_instance_valid(legacy):
        if game != null and is_instance_valid(game):
            legacy = game.get_node_or_null("LegacyGame")
        if legacy == null:
            return
    var value:Variant = legacy.get("hero")
    if not value is Dictionary:
        return
    var hero:Dictionary = value
    for key in RETIRED_KEYS:
        hero.erase(key)
    # Remove any nested old city-war payload even when legacy save migration
    # hands it back through a generic compatibility dictionary.
    var compatibility_keys:Array[String] = ["city", "army", "defense", "production"]
    for key in compatibility_keys:
        if hero.has(key) and (str(key).to_lower().contains("war") or str(key).to_lower().contains("army")):
            hero.erase(key)

func is_retired_system()->bool:
    return true
