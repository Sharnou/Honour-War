class_name HDAssetRuntime
extends Node3D

# Production asset bridge for Honour War.
# Art is authored in Blender, textured in Substance 3D Painter, exported as
# GLB/GLTF, and consumed here by Godot 4. Existing procedural meshes remain
# as a safe fallback until a production asset is present.

@export var hero_asset_root:String = "res://assets/3d/characters"
@export var pet_asset_root:String = "res://assets/3d/pets"
@export var monster_asset_root:String = "res://assets/3d/monsters"
@export var mvp_asset_root:String = "res://assets/3d/monsters"
@export var poll_interval:float = 0.25

var game:Node
var poll_elapsed:float = 0.0
var active_assets:Dictionary = {}
var attempted_paths:Dictionary = {}

func _ready() -> void:
	game = get_parent()
	set_process(true)

func _process(delta:float) -> void:
	poll_elapsed += delta
	if poll_elapsed < poll_interval:
		return
	poll_elapsed = 0.0
	if game == null or not is_instance_valid(game):
		game = get_parent()
	if game == null:
		return
	_sync_hero()
	_sync_pet()
	_sync_monsters()

func _sync_hero() -> void:
	var hero_visual:Node3D = game.get("hero_visual") as Node3D
	if hero_visual == null or not is_instance_valid(hero_visual):
		return
	var legacy:Node = game.get("legacy") as Node
	if legacy == null:
		return
	var hero_value:Variant = legacy.get("hero")
	if not hero_value is Dictionary:
		return
	var hero:Dictionary = hero_value
	var class_id:String = str(hero.get("class", "Warrior"))
	var path:String = hero_asset_root + "/hero_" + _stable_id(class_id) + ".glb"
	_replace_if_available("hero", hero_visual, path)

func _sync_pet() -> void:
	var pet_visual:Node3D = game.get("pet_visual") as Node3D
	if pet_visual == null or not is_instance_valid(pet_visual):
		return
	var legacy:Node = game.get("legacy") as Node
	if legacy == null:
		return
	var hero_value:Variant = legacy.get("hero")
	if not hero_value is Dictionary:
		return
	var hero:Dictionary = hero_value
	var pet_value:Variant = hero.get("pet", {})
	if not pet_value is Dictionary:
		return
	var species:String = str(pet_value.get("species", "Pet"))
	var path:String = pet_asset_root + "/pet_" + _stable_id(species) + ".glb"
	_replace_if_available("pet", pet_visual, path)

func _sync_monsters() -> void:
	var visuals:Variant = game.get("monster_visuals")
	if not visuals is Dictionary:
		return
	var legacy:Node = game.get("legacy") as Node
	if legacy == null:
		return
	var monsters_value:Variant = legacy.get("monsters")
	if not monsters_value is Array:
		return
	var monsters:Array = monsters_value
	for monster in monsters:
		if not monster is Dictionary:
			continue
		var id:String = str(monster.get("id", ""))
		if id.is_empty() or not visuals.has(id):
			continue
		var visual:Node3D = visuals[id] as Node3D
		if visual == null or not is_instance_valid(visual):
			continue
		var kind:String = str(monster.get("kind", "Monster"))
		var root:String = mvp_asset_root if kind == "MVP" else monster_asset_root
		var prefix:String = "mvp_" if kind == "MVP" else "monster_"
		var path:String = root + "/" + prefix + _stable_id(str(monster.get("name", "monster"))) + ".glb"
		_replace_if_available("monster:" + id, visual, path, id)

func _replace_if_available(key:String, current:Node3D, path:String, monster_id:String = "") -> void:
	if active_assets.has(key):
		var record:Variant = active_assets[key]
		if record is Dictionary:
			var existing:Node = record.get("node") as Node
			var existing_path:String = str(record.get("path", ""))
			if existing != null and is_instance_valid(existing) and existing_path == path:
				return
			if existing != null and is_instance_valid(existing):
				existing.queue_free()
		active_assets.erase(key)
	if attempted_paths.has(path) and not ResourceLoader.exists(path):
		return
	if not ResourceLoader.exists(path):
		attempted_paths[path] = true
		return
	var packed:PackedScene = load(path) as PackedScene
	if packed == null:
		attempted_paths[path] = true
		return
	var parent:Node = current.get_parent()
	if parent == null or not current.is_inside_tree():
		return
	var replacement:Node = packed.instantiate()
	if replacement == null or not replacement is Node3D:
		if replacement != null:
			replacement.queue_free()
		return
	parent.add_child(replacement)
	var replacement_3d:Node3D = replacement as Node3D
	replacement_3d.global_transform = current.global_transform
	replacement_3d.name = current.name + "_HDAsset"
	active_assets[key] = {"node":replacement,"path":path}
	if key == "hero":
		game.set("hero_visual", replacement_3d)
	elif key == "pet":
		game.set("pet_visual", replacement_3d)
	elif not monster_id.is_empty():
		var visuals:Variant = game.get("monster_visuals")
		if visuals is Dictionary:
			visuals[monster_id] = replacement_3d
	current.queue_free()

func _stable_id(value:String) -> String:
	var id:String = value.strip_edges().to_lower()
	id = id.replace(" ", "_")
	id = id.replace("-", "_")
	id = id.replace("'", "")
	return id
