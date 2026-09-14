extends Node

## Loads authored Blender GLBs under the stable gameplay actor nodes.
## Keeping the gameplay root alive means movement, combat, vitals and emotion
## systems can continue to reference the same hero/pet node after a visual swap.

const GENERATED_ROOT := "res://assets/3d/generated"
const POLL_INTERVAL := 1.0

var elapsed:float = 0.0
var loaded_paths:Dictionary = {}

func _ready() -> void:
    call_deferred("_sync")

func _process(delta:float) -> void:
    elapsed += delta
    if elapsed < POLL_INTERVAL:
        return
    elapsed = 0.0
    _sync()

func _sync() -> void:
    var scene_root:Node = get_tree().current_scene
    if scene_root == null:
        return
    _sync_hero(scene_root)
    _sync_pet(scene_root)

func _sync_hero(scene_root:Node) -> void:
    var actor := _find_hero_node(scene_root)
    var hero := _hero_data(scene_root)
    if actor == null or hero.is_empty():
        return
    var class_id := str(hero.get("class", "Warrior"))
    var level := int(hero.get("level", 1))
    var path := GENERATED_ROOT + "/characters/" + class_id + "/" + _tier_name(level) + ".glb"
    _attach_visual("hero", actor, path)

func _sync_pet(scene_root:Node) -> void:
    var actor := _find_pet_node(scene_root)
    var hero := _hero_data(scene_root)
    if actor == null or hero.is_empty():
        return
    var pet_value:Variant = hero.get("pet", {})
    if not pet_value is Dictionary:
        return
    var class_id := str(hero.get("class", "Warrior"))
    var species := str((pet_value as Dictionary).get("species", "Pet"))
    var candidates := [
        GENERATED_ROOT + "/pets/" + class_id + "_pet.glb",
        GENERATED_ROOT + "/pets/" + species + ".glb"
    ]
    for path in candidates:
        if ResourceLoader.exists(path):
            _attach_visual("pet", actor, path)
            return

func _attach_visual(key:String, actor:Node3D, path:String) -> void:
    if not ResourceLoader.exists(path):
        return
    var existing := actor.get_node_or_null("HW_GeneratedGLB")
    if existing != null and is_instance_valid(existing):
        if str(loaded_paths.get(key, "")) == path:
            return
        existing.queue_free()
    var packed := load(path) as PackedScene
    if packed == null:
        return
    var model := packed.instantiate()
    if model == null or not model is Node3D:
        if model != null:
            model.queue_free()
        return
    model.name = "HW_GeneratedGLB"
    actor.add_child(model)
    (model as Node3D).position = Vector3.ZERO
    (model as Node3D).rotation = Vector3.ZERO
    (model as Node3D).scale = Vector3.ONE
    for child in actor.get_children():
        if child == model:
            continue
        if child is MeshInstance3D:
            (child as MeshInstance3D).visible = false
    loaded_paths[key] = path

func _find_hero_node(scene_root:Node) -> Node3D:
    for path in ["Actors3D/Hero", "Hero", "World3D/Actors3D/Hero", "HDPresentationWorld/Hero"]:
        var node := scene_root.get_node_or_null(path) as Node3D
        if node != null:
            return node
    return null

func _find_pet_node(scene_root:Node) -> Node3D:
    for path in ["Actors3D/Pet", "Pet", "Actors3D/Pets/Pet", "HDPresentationWorld/Pet"]:
        var node := scene_root.get_node_or_null(path) as Node3D
        if node != null:
            return node
    return null

func _find_legacy(scene_root:Node) -> Node:
    for path in ["LegacyGame", "LegacyGame/CombatRuntime"]:
        var node := scene_root.get_node_or_null(path)
        if node != null:
            return node
    return null

func _hero_data(scene_root:Node) -> Dictionary:
    var legacy := _find_legacy(scene_root)
    if legacy == null:
        return {}
    var value:Variant = legacy.get("hero")
    if value is Dictionary:
        return value
    return {}

func _tier_name(level:int) -> String:
    if level >= 200:
        return "Transcendence"
    if level >= 100:
        return "Mastery"
    if level >= 50:
        return "Advanced"
    if level >= 25:
        return "Specialization"
    return "Foundation"
