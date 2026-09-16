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
	var runtime:Node = get_node_or_null("/root/HWRentalService")
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
	var saved:Variant = hero.get("ss_rental",{})
	if saved is Dictionary and bool(saved.get("rented",false)):
		runtime.set("rented",true)
		var state:Variant = saved.get("state",{})
		if state is Dictionary:
			runtime.set("ss",state.duplicate(true))
		runtime.set("owner_character_age",maxi(18,int(hero.get("age",18))))

func sync_to_hero() -> void:
	var runtime:Node = get_node_or_null("/root/HWRentalService")
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
	var rented:bool = bool(runtime.get("rented"))
	if rented:
		hero["ss_rental"] = {"rented":true,"state":runtime.get("ss").duplicate(true)}
	else:
		hero["ss_rental"] = {"rented":false}
	legacy.set("hero",hero)
	if legacy.has_method("save_game"):
		legacy.call("save_game")
