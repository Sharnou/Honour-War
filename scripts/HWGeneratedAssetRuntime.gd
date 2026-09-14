extends Node

## Runtime bridge for actual generated GLB production assets.
## It never replaces a live asset with a placeholder. Assets are loaded only when
## the expected GLB/GLTF is present in res://assets/3d/generated.

const GENERATED_ROOT := "res://assets/3d/generated"
const POLL_INTERVAL := 1.0

var elapsed := 0.0
var scene_root: Node
var replaced: Dictionary = {}

func _ready() -> void:
	call_deferred("_sync")

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed < POLL_INTERVAL:
		return
	elapsed = 0.0
	_sync()

func _sync() -> void:
	scene_root = get_tree().current_scene
	if scene_root == null:
		return
	_sync_hero()
	_sync_pet()

func _find_hero_node() -> Node3D:
	var candidates := [
		"Actors3D/Hero",
		"Hero",
		"World3D/Actors3D/Hero",
		"HDPresentationWorld/Hero"
	]
	for path in candidates:
		var node := scene_root.get_node_or_null(path) as Node3D
		if node != null:
			return node
	return null

func _find_legacy() -> Node:
	var candidates := ["LegacyGame", "LegacyGame/CombatRuntime"]
	for path in candidates:
		var node := scene_root.get_node_or_null(path)
		if node != null:
			return node
	return null

func _hero_data() -> Dictionary:
	var legacy := _find_legacy()
	if legacy == null:
		return {}
	var value: Variant = legacy.get("hero")
	if value is Dictionary:
		return value
	return {}

func _sync_hero() -> void:
	var hero_node := _find_hero_node()
	var hero := _hero_data()
	if hero_node == null or hero.is_empty():
		return
	var class_id := str(hero.get("class", "Warrior"))
	var level := int(hero.get("level", 1))
	var tier := _tier_name(level)
	var path := GENERATED_ROOT + "/characters/" + class_id + "/" + tier + ".glb"
	_replace("hero", hero_node, path)

func _sync_pet() -> void:
	var pet_node := _find_pet_node()
	var hero := _hero_data()
	if pet_node == null or hero.is_empty():
		return
	var pet_value: Variant = hero.get("pet", {})
	if not pet_value is Dictionary:
		return
	var class_id := str(hero.get("class", "Warrior"))
	var species := str(pet_value.get("species", "Pet"))
	var candidates := [
		GENERATED_ROOT + "/pets/" + class_id + "_pet.glb",
		GENERATED_ROOT + "/pets/" + species + ".glb"
	]
	for path in candidates:
		if ResourceLoader.exists(path):
			_replace("pet", pet_node, path)
			return

func _find_pet_node() -> Node3D:
	var candidates := [
		"Actors3D/Pet",
		"Pet",
		"Actors3D/Pets/Pet",
		"HDPresentationWorld/Pet"
	]
	for path in candidates:
		var node := scene_root.get_node_or_null(path) as Node3D
		if node != null:
			return node
	return null

func _tier_name(level: int) -> String:
	if level >= 200:
		return "Transcendence"
	if level >= 100:
		return "Mastery"
	if level >= 50:
		return "Advanced"
	if level >= 25:
		return "Specialization"
	return "Foundation"

func _replace(key: String, current: Node3D, path: String) -> void:
	if not ResourceLoader.exists(path):
		return
	var previous: Variant = replaced.get(key, {})
	if previous is Dictionary and str(previous.get("path", "")) == path:
		var old_node := previous.get("node") as Node
		if old_node != null and is_instance_valid(old_node):
			return

	var packed := load(path) as PackedScene
	if packed == null:
		return
	var parent := current.get_parent()
	if parent == null or not current.is_inside_tree():
		return
	var replacement := packed.instantiate()
	if replacement == null or not replacement is Node3D:
		if replacement != null:
			replacement.queue_free()
		return
	parent.add_child(replacement)
	var replacement_3d := replacement as Node3D
	replacement_3d.global_transform = current.global_transform
	replacement_3d.name = current.name + "_GeneratedGLB"
	replaced[key] = {"node": replacement_3d, "path": path}
	current.queue_free()
