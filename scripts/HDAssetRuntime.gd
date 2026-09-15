class_name HDAssetRuntime
extends Node3D

## Final Honour War HD asset bridge.
## Production assets are generated under res://assets/3d/generated and are
## selected by class progression / actor identity at runtime. Procedural actors
## remain a safe fallback when an asset is unavailable.

@export var hero_asset_root:String = "res://assets/3d/generated/characters"
@export var pet_asset_root:String = "res://assets/3d/generated/pets"
@export var monster_asset_root:String = "res://assets/3d/generated/monsters"
@export var poll_interval:float = 0.20

const TIERS:Array[String] = ["Foundation", "Specialization", "Advanced", "Mastery", "Transcendence"]

var game:Node3D
var legacy:Node
var poll_elapsed:float = 0.0
var active_assets:Dictionary = {}

func _ready()->void:
    game = get_parent() as Node3D
    set_process(true)

func _process(delta:float)->void:
    poll_elapsed += delta
    if game == null or not is_instance_valid(game):
        game = get_parent() as Node3D
    if game == null:
        return
    if poll_elapsed < poll_interval:
        return
    poll_elapsed = 0.0
    legacy = game.get_node_or_null("LegacyGame") as Node
    if legacy == null:
        return
    _sync_hero()
    _sync_pet()
    _sync_monsters()

func _sync_hero()->void:
    var current:Node3D = game.get("hero_visual") as Node3D
    if current == null or not is_instance_valid(current):
        return
    var value:Variant = legacy.get("hero")
    if not value is Dictionary:
        return
    var hero:Dictionary = value
    var class_id:String = str(hero.get("class", "Warrior"))
    var level:int = int(hero.get("level", 1))
    var tier:int = max(int(hero.get("class_tier", 0)), _tier_for_level(level))
    tier = clamp(tier, 0, TIERS.size() - 1)
    var tier_name:String = TIERS[tier]
    var class_dir:String = _safe_id(class_id)
    var candidates:Array[String] = [
        hero_asset_root + "/" + class_dir + "/" + tier_name + ".glb",
        hero_asset_root + "/" + class_dir + "/" + tier_name + ".gltf"
    ]
    if _replace_first_available("hero", current, candidates):
        var replacement:Node3D = game.get("hero_visual") as Node3D
        if replacement != null and is_instance_valid(replacement):
            replacement.set_meta("hw_production_asset", true)
            replacement.set_meta("hw_asset_tier", tier_name)
            replacement.set_meta("hw_asset_class", class_id)

func _sync_pet()->void:
    var current:Node3D = game.get("pet_visual") as Node3D
    if current == null or not is_instance_valid(current):
        return
    var value:Variant = legacy.get("hero")
    if not value is Dictionary:
        return
    var hero:Dictionary = value
    var class_id:String = str(hero.get("class", "Warrior"))
    var base:String = pet_asset_root + "/" + _safe_id(class_id) + "_pet"
    var candidates:Array[String] = [base + ".glb", base + ".gltf"]
    if _replace_first_available("pet", current, candidates):
        var replacement:Node3D = game.get("pet_visual") as Node3D
        if replacement != null and is_instance_valid(replacement):
            replacement.set_meta("hw_production_asset", true)
            replacement.set_meta("hw_asset_class", class_id)

func _sync_monsters()->void:
    var visuals_value:Variant = game.get("monster_visuals")
    if not visuals_value is Dictionary:
        return
    var monsters_value:Variant = legacy.get("monsters")
    if not monsters_value is Array:
        return
    var visuals:Dictionary = visuals_value
    var monsters:Array = monsters_value
    for monster_value in monsters:
        if not monster_value is Dictionary:
            continue
        var monster:Dictionary = monster_value
        var id:String = str(monster.get("id", ""))
        if id.is_empty() or not visuals.has(id):
            continue
        var current:Node3D = visuals[id] as Node3D
        if current == null or not is_instance_valid(current):
            continue
        var kind:String = str(monster.get("kind", "Monster"))
        var prefix:String = "mvp_" if kind == "MVP" else "monster_"
        var base:String = monster_asset_root + "/" + prefix + _safe_id(str(monster.get("name", "Monster")))
        var candidates:Array[String] = [base + ".glb", base + ".gltf"]
        _replace_first_available("monster:" + id, current, candidates, id)

func _replace_first_available(key:String, current:Node3D, paths:Array[String], monster_id:String = "")->bool:
    for path in paths:
        if ResourceLoader.exists(path):
            return _replace_if_available(key, current, path, monster_id)
    return false

func _replace_if_available(key:String, current:Node3D, path:String, monster_id:String = "")->bool:
    var active:Variant = active_assets.get(key, null)
    if active is Dictionary:
        var old_node:Node = active.get("node") as Node
        var old_path:String = str(active.get("path", ""))
        if old_node != null and is_instance_valid(old_node) and old_path == path:
            return true
        if old_node != null and is_instance_valid(old_node):
            old_node.queue_free()
        active_assets.erase(key)
    if current == null or not is_instance_valid(current) or current.get_parent() == null:
        return false
    var packed:PackedScene = load(path) as PackedScene
    if packed == null:
        return false
    var replacement:Node = packed.instantiate()
    if replacement == null or not replacement is Node3D:
        if replacement != null:
            replacement.queue_free()
        return false
    var parent:Node = current.get_parent()
    parent.add_child(replacement)
    var replacement_3d:Node3D = replacement as Node3D
    replacement_3d.global_transform = current.global_transform
    replacement_3d.name = current.name + "_HDAsset"
    replacement_3d.set_meta("hw_source_path", path)
    active_assets[key] = {"node": replacement_3d, "path": path}
    if key == "hero":
        game.set("hero_visual", replacement_3d)
    elif key == "pet":
        game.set("pet_visual", replacement_3d)
    elif not monster_id.is_empty():
        var visuals_value:Variant = game.get("monster_visuals")
        if visuals_value is Dictionary:
            visuals_value[monster_id] = replacement_3d
    current.queue_free()
    return true

func _tier_for_level(level:int)->int:
    if level >= 200:
        return 4
    if level >= 100:
        return 3
    if level >= 50:
        return 2
    if level >= 25:
        return 1
    return 0

func _safe_id(value:String)->String:
    var result:String = value.strip_edges()
    result = result.replace(" ", "_")
    result = result.replace("-", "_")
    result = result.replace("'", "")
    return result