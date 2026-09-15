extends Node

## Honour War authored-asset bridge.
## Keeps gameplay roots stable while preferring the Blender-generated GLB library.
## Base-class mapping keeps advanced class names on their correct visual family.

const GENERATED_ROOT := "res://assets/3d/generated"
const POLL_INTERVAL := 0.50

const BASE_CLASS_BY_RANK := {
    "Knight": "Warrior", "Berserker": "Warrior",
    "Wizard": "Mage", "Warlock": "Mage",
    "Ranger": "Archer", "Sniper": "Archer",
    "Assassin": "Thief", "Rogue": "Thief",
    "Priest": "Acolyte", "Monk": "Acolyte",
    "Blacksmith": "Merchant", "Alchemist": "Merchant",
}

const PET_ASSET_BY_SPECIES := {
    "Royal Falcon": "Falcon.glb",
    "Astral Sprite": "ArcaneOrb.glb",
    "Blessed Poring": "PoringAngel.glb",
    "Night Panther": "Panther.glb",
    "Merchant Companion": "Clockwork.glb",
    "Dire Wolf": "Wolf.glb",
}

var elapsed:float = 0.0
var loaded_paths:Dictionary = {}
var animation_time:float = 0.0

func _ready() -> void:
    call_deferred("_sync")

func _process(delta:float) -> void:
    animation_time += delta
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
    _sync_monsters(scene_root)

func _sync_hero(scene_root:Node) -> void:
    var actor := _find_hero_node(scene_root)
    var hero := _hero_data(scene_root)
    if actor == null or hero.is_empty():
        return
    var base_class := _base_class(str(hero.get("class", "Warrior")))
    var level := int(hero.get("level", 1))
    var tier := _tier_name(level)
    var candidates := [
        GENERATED_ROOT + "/characters/" + base_class + "/" + tier + ".glb",
        GENERATED_ROOT + "/heroes/" + base_class + ".glb",
    ]
    for path in candidates:
        if ResourceLoader.exists(path):
            _attach_visual("hero", actor, path)
            _start_animation(actor.get_node_or_null("HW_GeneratedGLB"), hero)
            return

func _sync_pet(scene_root:Node) -> void:
    var actor := _find_pet_node(scene_root)
    var hero := _hero_data(scene_root)
    if actor == null or hero.is_empty():
        return
    var pet_value:Variant = hero.get("pet", {})
    if not pet_value is Dictionary:
        return
    var class_id := _base_class(str(hero.get("class", "Warrior")))
    var species := str((pet_value as Dictionary).get("species", "Pet"))
    var candidates:Array[String] = []
    candidates.append(GENERATED_ROOT + "/pets/" + class_id + "_pet.glb")
    if PET_ASSET_BY_SPECIES.has(species):
        candidates.append(GENERATED_ROOT + "/pets/" + str(PET_ASSET_BY_SPECIES[species]))
    for path in candidates:
        if ResourceLoader.exists(path):
            _attach_visual("pet", actor, path)
            return

func _sync_monsters(scene_root:Node) -> void:
    var values:Variant = scene_root.get("monster_visuals")
    if not values is Dictionary:
        return
    var monsters:Dictionary = values
    for key in monsters.keys():
        var actor := monsters[key] as Node3D
        if actor == null or not is_instance_valid(actor):
            continue
        var family := _monster_family(str(key))
        if family == "":
            var display_name := str(actor.name)
            family = _monster_family(display_name)
        if family == "":
            continue
        var path := GENERATED_ROOT + "/monsters/monster_" + family + ".glb"
        _attach_visual("monster:" + str(key), actor, path)

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
    var model_3d := model as Node3D
    model_3d.position = Vector3.ZERO
    model_3d.rotation = Vector3.ZERO
    model_3d.scale = Vector3.ONE
    loaded_paths[key] = path

func _start_animation(model_value:Variant, hero:Dictionary) -> void:
    if model_value == null or not model_value is Node:
        return
    var state := "Idle"
    var legacy_pos := Vector2(float(hero.get("pos_x", 0.0)), float(hero.get("pos_y", 0.0)))
    var previous := hero.get("_hw_last_visual_pos", legacy_pos)
    if previous is Vector2 and legacy_pos.distance_to(previous as Vector2) > 0.8:
        state = "Walk"
    hero["_hw_last_visual_pos"] = legacy_pos
    var player := _find_animation_player(model_value as Node)
    if player != null:
        for candidate in [state, state.to_lower(), "idle", "Idle", "default"]:
            if player.has_animation(candidate):
                player.play(candidate)
                return
    var model_root := model_value as Node3D
    if model_root != null:
        model_root.position.y = sin(animation_time * 2.2) * 0.018

func _find_animation_player(node:Node)->AnimationPlayer:
    if node is AnimationPlayer:
        return node as AnimationPlayer
    for child in node.get_children():
        var found := _find_animation_player(child)
        if found != null:
            return found
    return null

func _find_hero_node(scene_root:Node)->Node3D:
    for path in ["Actors3D/Hero", "Hero", "World3D/Actors3D/Hero", "HDPresentationWorld/Hero"]:
        var node := scene_root.get_node_or_null(path) as Node3D
        if node != null:
            return node
    return null

func _find_pet_node(scene_root:Node)->Node3D:
    for path in ["Actors3D/Pet", "Pet", "Actors3D/Pets/Pet", "HDPresentationWorld/Pet"]:
        var node := scene_root.get_node_or_null(path) as Node3D
        if node != null:
            return node
    return null

func _find_legacy(scene_root:Node)->Node:
    for path in ["LegacyGame", "LegacyGame/CombatRuntime"]:
        var node := scene_root.get_node_or_null(path)
        if node != null:
            return node
    return null

func _hero_data(scene_root:Node)->Dictionary:
    var legacy := _find_legacy(scene_root)
    if legacy == null:
        return {}
    var value:Variant = legacy.get("hero")
    if value is Dictionary:
        return value
    return {}

func _base_class(class_id:String)->String:
    return str(BASE_CLASS_BY_RANK.get(class_id, class_id))

func _tier_name(level:int)->String:
    if level >= 200:
        return "Transcendence"
    if level >= 100:
        return "Mastery"
    if level >= 50:
        return "Advanced"
    if level >= 25:
        return "Specialization"
    return "Foundation"

func _monster_family(value:String)->String:
    var name := value.to_lower().replace("_", " ")
    var families := ["poring", "goblin", "wolf", "skeleton", "zombie", "orc", "mantis", "golem", "evil druid", "dragon", "bloody knight"]
    for family in families:
        if name.contains(family):
            return family.replace(" ", "_").capitalize()
    return ""
