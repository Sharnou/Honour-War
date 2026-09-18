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
@export var hero_target_height:float = 3.40
@export var monster_target_height:float = 2.40

const TIERS:Array[String] = ["Foundation", "Specialization", "Advanced", "Mastery", "Transcendence"]

var game:Node3D
var legacy:Node
var poll_elapsed:float = 0.0
var active_assets:Dictionary = {}

func _ready()->void:
    game = get_parent() as Node3D
    # Game3D performs its presentation update first. This bridge intentionally
    # runs later so authored GLB scale/grounding cannot be overwritten by the
    # procedural fallback animation pass.
    process_priority = 100
    set_process(true)

func _process(delta:float)->void:
    poll_elapsed += delta
    if game == null or not is_instance_valid(game):
        game = get_parent() as Node3D
    if game == null:
        return
    legacy = game.get_node_or_null("LegacyGame") as Node
    if legacy == null:
        return
    if poll_elapsed >= poll_interval:
        poll_elapsed = 0.0
        _sync_hero()
        _sync_pet()
        _sync_monsters()
    _enforce_production_transforms()

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
    # Hero scale and grounding are authored in the source GLB. Do not normalize
    # hero height at runtime; preserve the exact imported root transform.
    if _replace_first_available("hero", current, candidates, "", 0.0):
        var replacement:Node3D = game.get("hero_visual") as Node3D
        if replacement != null and is_instance_valid(replacement):
            replacement.set_meta("hw_production_asset", true)
            replacement.set_meta("hw_asset_tier", tier_name)
            replacement.set_meta("hw_asset_class", class_id)
            replacement.set_meta("hw_asset_height", 0.0)
            replacement.set_meta("hw_authored_scale", replacement.scale)
            replacement.set_meta("hw_ground_y", replacement.position.y)

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
            replacement.set_meta("hw_authored_scale", replacement.scale)
            replacement.set_meta("hw_ground_y", replacement.position.y)

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
        _replace_first_available("monster:" + id, current, candidates, id, monster_target_height)

func _replace_first_available(key:String, current:Node3D, paths:Array[String], monster_id:String = "", target_height:float = 0.0)->bool:
    for path in paths:
        if ResourceLoader.exists(path):
            return _replace_if_available(key, current, path, monster_id, target_height)
    return false

func _replace_if_available(key:String, current:Node3D, path:String, monster_id:String = "", target_height:float = 0.0)->bool:
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
    if target_height > 0.0:
        _normalize_actor(replacement_3d, target_height)
    replacement_3d.set_meta("hw_authored_scale", replacement_3d.scale)
    replacement_3d.set_meta("hw_ground_y", replacement_3d.position.y)
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

func _enforce_production_transforms()->void:
    for key in active_assets.keys():
        var active:Variant = active_assets.get(key, null)
        if not active is Dictionary:
            continue
        var node_value:Variant = active.get("node", null)
        if not is_instance_valid(node_value) or not node_value is Node3D:
            active_assets.erase(key)
            continue
        var node:Node3D = node_value as Node3D
        var authored_scale:Variant = node.get_meta("hw_authored_scale", null)
        if authored_scale is Vector3:
            node.scale = authored_scale
        if key == "hero" or key == "pet":
            var ground_y:Variant = node.get_meta("hw_ground_y", null)
            if ground_y is float or ground_y is int:
                node.position.y = float(ground_y)

func _normalize_actor(root:Node3D, target_height:float)->void:
    var bounds:AABB = _collect_mesh_bounds(root)
    if bounds.size.y <= 0.001:
        return
    var factor:float = target_height / bounds.size.y
    factor = clamp(factor, 0.55, 1.75)
    root.scale = root.scale * factor
    # Recalculate in root-local space; root.scale is deliberately applied here
    # so Blender exports with different origins still land their feet on y=0.
    var scaled_bounds:AABB = _collect_mesh_bounds(root)
    root.position.y -= scaled_bounds.position.y * root.scale.y

func _collect_mesh_bounds(root:Node3D)->AABB:
    var found:bool = false
    var result:AABB = AABB()
    var inverse:Transform3D = root.global_transform.affine_inverse()
    for node:Node in root.find_children("*", "MeshInstance3D", true, false):
        var mesh_instance:MeshInstance3D = node as MeshInstance3D
        if mesh_instance == null or mesh_instance.mesh == null:
            continue
        var local_bounds:AABB = mesh_instance.get_aabb()
        for i:int in 8:
            var corner:Vector3 = local_bounds.position + Vector3(
                local_bounds.size.x if (i & 1) != 0 else 0.0,
                local_bounds.size.y if (i & 2) != 0 else 0.0,
                local_bounds.size.z if (i & 4) != 0 else 0.0
            )
            var root_point:Vector3 = inverse * (mesh_instance.global_transform * corner)
            if not found:
                result = AABB(root_point, Vector3.ZERO)
                found = true
            else:
                result = result.merge(AABB(root_point, Vector3.ZERO))
    return result

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
