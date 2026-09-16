extends Node

## Persists the active rental-only SS inside the normal hero save payload.
## This keeps rental state across restarts without creating a separate character slot.
const SYNC_INTERVAL:float = 2.0
var clock:float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("sync_from_hero")

func _process(delta:float) -> void:
	clock += delta
	if clock >= SYNC_INTERVAL:
		clock = 0.0
		sync_to_hero()

func sync_from_hero() -> void:
	var runtime:Node = get_node_or_null("/root/HWSSRentRuntime")
	var scene:Node = get_tree().current_scene
	if runtime == null or scene == null:
		return
	var legacy:Node = scene.get_node_or_null("LegacyGame")
	if legacy == null:
		return
	var hero_value:Variant = legacy.get("hero")
	if hero_value is Dictionary:
		runtime.call("sync_from_hero",hero_value)

func sync_to_hero() -> void:
	var runtime:Node = get_node_or_null("/root/HWSSRentRuntime")
	var scene:Node = get_tree().current_scene
	if runtime == null or scene == null:
		return
	var legacy:Node = scene.get_node_or_null("LegacyGame")
	if legacy == null:
		return
	var hero_value:Variant = legacy.get("hero")
	if not hero_value is Dictionary:
		return
	var hero:Dictionary = hero_value
	runtime.call("sync_to_hero",hero)
	legacy.set("hero",hero)
