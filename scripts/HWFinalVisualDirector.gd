extends Node

## Final HD visual ownership pass.
## Prefers the authored Blender -> GLB/GLTF assets already shipped in the repo,
## removes competing procedural/asset passes that can duplicate actors, and keeps
## gameplay data roots intact. This is a presentation fix: no gameplay systems
## or saved-data fields are removed.

const GENERATED_ROOT:String = "res://assets/3d/generated"
const POLL_INTERVAL:float = 0.12
const BASE_CLASS_BY_RANK:Dictionary = {
    "Knight":"Warrior", "Berserker":"Warrior",
    "Wizard":"Mage", "Warlock":"Mage",
    "Ranger":"Archer", "Sniper":"Archer",
    "Assassin":"Thief", "Rogue":"Thief",
    "Priest":"Acolyte", "Monk":"Acolyte",
    "Blacksmith":"Merchant", "Alchemist":"Merchant"
}
const PET_ASSET_BY_SPECIES:Dictionary = {
    "Royal Falcon":"Falcon.glb",
    "Astral Sprite":"ArcaneOrb.glb",
    "Blessed Poring":"PoringAngel.glb",
    "Night Panther":"Panther.glb",
    "Merchant Companion":"Clockwork.glb",
    "Dire Wolf":"Wolf.glb"
}
const MONSTER_FAMILIES:Dictionary = {
    "poring":"Poring",
    "goblin":"Goblin",
    "wolf":"Wolf",
    "skeleton":"Skeleton",
    "zombie":"Zombie",
    "orc":"Orc",
    "mantis":"Mantis",
    "golem":"Golem",
    "evil druid":"Evil_Druid",
    "bloody knight":"Bloody_Knight",
    "dragon":"Dragon"
}

var scene:Node3D
var game:Node3D
var legacy:Node
var elapsed:float = 0.0
var hero_path:String = ""
var pet_path:String = ""
var monster_paths:Dictionary = {}

func _ready()->void:
    process_priority = 3000
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("_bind")

func _process(delta:float)->void:
    elapsed += delta
    if elapsed < POLL_INTERVAL:
        return
    elapsed = 0.0
    _bind()
    if game == null or legacy == null:
        return
    _disable_competing_visual_passes()
    _sync_hero()
    _sync_pet()
    _sync_monsters()

func _bind()->void:
    if scene == null or not is_instance_valid(scene):
        scene = get_tree().current_scene as Node3D
    if scene == null:
        return
    game = scene
    legacy = scene.get_node_or_null("LegacyGame")

func _disable_competing_visual_passes()->void:
    var autoload_names:Array[String] = [
        "HWGeneratedAssetRuntime",
        "HWReadableActorDirector",
        "HWPrimitiveBeautyDirector"
    ]
    for node_name:String in autoload_names:
        var node:Node = get_node_or_null("/root/" + node_name)
        if node != null:
            node.process_mode = Node.PROCESS_MODE_DISABLED
    var legacy_asset:Node = scene.get_node_or_null("HDAssetRuntime")
    if legacy_asset != null:
        legacy_asset.process_mode = Node.PROCESS_MODE_DISABLED
    var old_taskbar:Node = get_node_or_null("/root/HDMMOTaskbar")
    if old_taskbar != null:
        var hud:Control = old_taskbar.get_node_or_null("HonourWarFinalHUD") as Control
        if hud != null:
            for child:Node in hud.get_children():
                if child is PanelContainer:
                    var panel:Control = child as Control
                    if panel.position.x < 0.0 and panel.position.y < 0.0:
                        panel.visible = false

func _sync_hero()->void:
    var value:Variant = legacy.get("hero")
    if not value is Dictionary:
        return
    var hero:Dictionary = value
    var actor_root:Node3D = game.get("actor_root") as Node3D
    if actor_root == null:
        return
    var class_id:String = str(hero.get("class","Warrior"))
    var base_class:String = str(BASE_CLASS_BY_RANK.get(class_id,class_id))
    var tier:String = _tier_for_level(int(hero.get("level",1)))
    var path:String = GENERATED_ROOT + "/characters/" + base_class + "/" + tier + ".glb"
    if not ResourceLoader.exists(path):
        path = GENERATED_ROOT + "/characters/" + base_class + "/" + tier + ".gltf"
    if not ResourceLoader.exists(path):
        return
    var current:Node3D = game.get("hero_visual") as Node3D
    if current != null and is_instance_valid(current) and str(current.get_meta("hw_final_asset_path","") ) == path:
        _play_idle(current)
        return
    var replacement:Node3D = _instantiate_asset(path,"Hero",current)
    if replacement == null:
        return
    replacement.set_meta("hw_final_asset_path",path)
    replacement.set_meta("hw_final_class",class_id)
    replacement.scale = Vector3.ONE * 1.0
    game.set("hero_visual",replacement)
    hero_path = path
    _remove_other_actor_children(actor_root,replacement,"Hero")
    _play_idle(replacement)

func _sync_pet()->void:
    var value:Variant = legacy.get("hero")
    if not value is Dictionary:
        return
    var hero:Dictionary = value
    var pet_value:Variant = hero.get("pet",{})
    if not pet_value is Dictionary:
        return
    var actor_root:Node3D = game.get("actor_root") as Node3D
    if actor_root == null:
        return
    var species:String = str((pet_value as Dictionary).get("species",""))
    var path:String = GENERATED_ROOT + "/pets/" + str(PET_ASSET_BY_SPECIES.get(species,"Wolf.glb"))
    if not ResourceLoader.exists(path):
        return
    var current:Node3D = game.get("pet_visual") as Node3D
    if current != null and is_instance_valid(current) and str(current.get_meta("hw_final_asset_path","") ) == path:
        _play_idle(current)
        return
    var replacement:Node3D = _instantiate_asset(path,"Pet",current)
    if replacement == null:
        return
    replacement.set_meta("hw_final_asset_path",path)
    replacement.set_meta("hw_final_pet_species",species)
    replacement.scale = Vector3.ONE * 0.95
    game.set("pet_visual",replacement)
    pet_path = path
    _remove_other_actor_children(actor_root,replacement,"Pet")
    _play_idle(replacement)

func _sync_monsters()->void:
    var visuals_value:Variant = game.get("monster_visuals")
    if not visuals_value is Dictionary:
        return
    var monsters_value:Variant = legacy.get("monsters")
    if not monsters_value is Array:
        return
    var visuals:Dictionary = visuals_value
    var current_ids:Dictionary = {}
    for monster_value:Variant in monsters_value as Array:
        if not monster_value is Dictionary:
            continue
        var monster:Dictionary = monster_value
        var key:String = str(monster.get("visual_id",monster.get("name","monster")))
        current_ids[key] = true
        if not visuals.has(key):
            continue
        var current:Node3D = visuals[key] as Node3D
        if current == null or not is_instance_valid(current):
            continue
        var family:String = _monster_family(str(monster.get("name","Monster")))
        if family.is_empty():
            continue
        var path:String = GENERATED_ROOT + "/monsters/monster_" + family + ".glb"
        if not ResourceLoader.exists(path):
            continue
        if str(current.get_meta("hw_final_asset_path","") ) == path:
            _play_idle(current)
            continue
        var replacement:Node3D = _instantiate_asset(path,current.name,current)
        if replacement == null:
            continue
        replacement.set_meta("hw_final_asset_path",path)
        replacement.set_meta("hw_monster_key",key)
        var mvp:bool = bool(monster.get("mvp",false))
        replacement.scale = Vector3.ONE * (1.25 if mvp else 1.0)
        visuals[key] = replacement
        monster_paths[key] = path
        _play_idle(replacement)
    for stale_key:Variant in monster_paths.keys():
        if not current_ids.has(str(stale_key)):
            monster_paths.erase(stale_key)

func _instantiate_asset(path:String,node_name:String,current:Node3D)->Node3D:
    if game == null or path.is_empty() or not ResourceLoader.exists(path):
        return null
    var actor_root:Node3D = game.get("actor_root") as Node3D
    if actor_root == null:
        return null
    var packed:PackedScene = load(path) as PackedScene
    if packed == null:
        return null
    var model:Node = packed.instantiate()
    if model == null or not model is Node3D:
        if model != null:
            model.queue_free()
        return null
    var replacement:Node3D = model as Node3D
    replacement.name = node_name
    actor_root.add_child(replacement)
    if current != null and is_instance_valid(current):
        replacement.global_transform = current.global_transform
        current.queue_free()
    else:
        replacement.position = Vector3.ZERO
    return replacement

func _remove_other_actor_children(actor_root:Node3D,keep:Node3D,prefix:String)->void:
    for child:Node in actor_root.get_children():
        if child == keep:
            continue
        var n:String = str(child.name)
        if n == prefix or n.begins_with(prefix + "_"):
            child.queue_free()

func _tier_for_level(level:int)->String:
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
    var lower:String = value.to_lower().replace("_"," ")
    if lower.contains("bloody knight"):
        return "Bloody_Knight"
    if lower.contains("evil druid"):
        return "Evil_Druid"
    for family:Variant in MONSTER_FAMILIES.keys():
        var family_id:String = str(family)
        if family_id == "bloody knight" or family_id == "evil druid":
            continue
        if lower.contains(family_id):
            return str(MONSTER_FAMILIES[family])
    return ""

func _play_idle(root:Node)->void:
    var player:AnimationPlayer = _find_animation_player(root)
    if player == null:
        return
    var preferred:Array[String] = ["Idle","idle","Armature|Idle","default"]
    for name:String in preferred:
        if player.has_animation(name):
            player.play(name)
            return
    var library:AnimationLibrary = player.get_animation_library("")
    if library == null:
        return
    var names:PackedStringArray = library.get_animation_list()
    if names.size() > 0:
        player.play(names[0])

func _find_animation_player(node:Node)->AnimationPlayer:
    if node is AnimationPlayer:
        return node as AnimationPlayer
    for child:Node in node.get_children():
        var found:AnimationPlayer = _find_animation_player(child)
        if found != null:
            return found
    return null
