extends Node

## Final HD visual ownership pass.
## One authoritative authored GLB actor per hero/pet/monster is kept visible.
## Competing legacy visual generators and environment/light stacks are removed
## so the production presentation cannot duplicate or black out the world.

const GENERATED_ROOT:String = "res://assets/3d/generated"
const CHARACTER_PROFILES = preload("res://scripts/HWCharacterVisualProfiles.gd")
const WORLD_ACTOR_PROFILES = preload("res://scripts/HWWorldActorVisualProfiles.gd")
const POLL_INTERVAL:float = 0.08
const BASE_CLASS_BY_RANK:Dictionary = {
    "Knight":"Warrior", "Lord Knight":"Warrior", "Transcendent Knight":"Warrior", "War Emperor":"Warrior", "Berserker":"Warrior",
    "Wizard":"Mage", "High Wizard":"Mage", "Transcendent Wizard":"Mage", "Arcane Sovereign":"Mage", "Warlock":"Mage",
    "Ranger":"Archer", "Hunter":"Archer", "Sniper":"Archer", "Transcendent Ranger":"Archer", "Celestial Ranger":"Archer",
    "Assassin":"Thief", "Assassin Cross":"Thief", "Transcendent Assassin":"Thief", "Shadow Emperor":"Thief", "Rogue":"Thief",
    "Priest":"Acolyte", "High Priest":"Acolyte", "Transcendent Saint":"Acolyte", "Divine Saint":"Acolyte", "Monk":"Acolyte",
    "Blacksmith":"Merchant", "Mastersmith":"Merchant", "Transcendent Forge Master":"Merchant", "Forge Overlord":"Merchant", "Alchemist":"Merchant"
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
    "poring":"Poring", "goblin":"Goblin", "wolf":"Wolf", "skeleton":"Skeleton",
    "zombie":"Zombie", "orc":"Orc", "mantis":"Mantis", "golem":"Golem",
    "evil druid":"Evil_Druid", "bloody knight":"Bloody_Knight", "dragon":"Dragon"
}

var scene:Node3D
var game:Node3D
var legacy:Node
var elapsed:float = 0.0
var hero_path:String = ""
var pet_path:String = ""
var monster_paths:Dictionary = {}
var visual_cleanup_done:bool = false
var hero_profile_key:String = ""
var hero_motion_time:float = 0.0

func _ready()->void:
    process_priority = 3000
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("_bind")
    call_deferred("_force_single_world_environment")

func _process(delta:float)->void:
    elapsed += delta
    if elapsed < POLL_INTERVAL:
        return
    elapsed = 0.0
    _bind()
    if game == null or legacy == null:
        return
    _disable_competing_visual_passes()
    _force_single_world_environment()
    hero_motion_time += POLL_INTERVAL
    _sync_hero()
    _sync_pet()
    _sync_monsters()
    _sync_world_npcs()
    _sanitize_actor_root()
    _fit_camera()

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
    var disable_scene_names:Array[String] = [
        "HDAssetRuntime",
        "HDActorDetails",
        "HDVisualDirector",
        "HWRoleDrivenUpgradeRuntime",
        "HDEnvironmentDirector"
    ]
    for node_name:String in disable_scene_names:
        var node:Node = scene.get_node_or_null(node_name)
        if node != null:
            node.process_mode = Node.PROCESS_MODE_DISABLED
    var old_taskbar:Node = get_node_or_null("/root/HDMMOTaskbar")
    if old_taskbar != null:
        var hud:Control = old_taskbar.get_node_or_null("HonourWarFinalHUD") as Control
        if hud != null:
            for child:Node in hud.get_children():
                if child is PanelContainer:
                    var panel:Control = child as Control
                    if panel.position.x < 0.0 and panel.position.y < 0.0:
                        panel.visible = false

func _force_single_world_environment()->void:
    if scene == null:
        return
    var keep:WorldEnvironment = scene.get_node_or_null("HWFinalWorldEnvironment") as WorldEnvironment
    if keep == null:
        keep = WorldEnvironment.new()
        keep.name = "HWFinalWorldEnvironment"
        scene.add_child(keep)
    var env:Environment = keep.environment
    if env == null:
        env = Environment.new()
        keep.environment = env
    env.background_mode = Environment.BG_SKY
    var sky:Sky = env.sky
    if sky == null:
        sky = Sky.new()
        env.sky = sky
    var sky_mat:ProceduralSkyMaterial = sky.sky_material as ProceduralSkyMaterial
    if sky_mat == null:
        sky_mat = ProceduralSkyMaterial.new()
        sky.sky_material = sky_mat
    sky_mat.sky_top_color = Color("#25558a")
    sky_mat.sky_horizon_color = Color("#b8d7e6")
    sky_mat.ground_bottom_color = Color("#18251f")
    sky_mat.ground_horizon_color = Color("#788f80")
    env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    env.ambient_light_energy = 0.92
    env.ambient_light_sky_contribution = 0.84
    env.tonemap_mode = Environment.TONE_MAPPER_ACES
    env.tonemap_exposure = 0.88
    env.glow_enabled = true
    env.glow_intensity = 0.50
    env.glow_bloom = 0.10
    env.glow_hdr_threshold = 1.0
    env.ssao_enabled = true
    env.ssao_radius = 2.4
    env.ssao_intensity = 1.55
    env.fog_enabled = true
    env.fog_light_color = Color("#9eb7c7")
    env.fog_light_energy = 0.22
    env.fog_density = 0.0012
    env.fog_height = 8.0
    env.fog_height_density = 0.012

    for child:Node in scene.get_children():
        if child == self or child == keep:
            continue
        if child is WorldEnvironment or child is DirectionalLight3D:
            child.process_mode = Node.PROCESS_MODE_DISABLED
            child.queue_free()
        elif child is OmniLight3D and str(child.name) != "HDFill":
            child.process_mode = Node.PROCESS_MODE_DISABLED
            child.queue_free()
    var sun:DirectionalLight3D = scene.get_node_or_null("HWFinalSun") as DirectionalLight3D
    if sun == null:
        sun = DirectionalLight3D.new()
        sun.name = "HWFinalSun"
        scene.add_child(sun)
    sun.rotation_degrees = Vector3(-50.0,-32.0,0.0)
    sun.light_energy = 1.55
    sun.light_color = Color("#ffe6b7")
    sun.shadow_enabled = true
    sun.directional_shadow_max_distance = 140.0
    sun.light_angular_distance = 0.12
    var fill:DirectionalLight3D = scene.get_node_or_null("HWFinalFill") as DirectionalLight3D
    if fill == null:
        fill = DirectionalLight3D.new()
        fill.name = "HWFinalFill"
        scene.add_child(fill)
    fill.rotation_degrees = Vector3(-28.0,145.0,0.0)
    fill.light_energy = 0.42
    fill.light_color = Color("#9bcaff")
    fill.shadow_enabled = false

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
    if current != null and is_instance_valid(current) and str(current.get_meta("hw_final_asset_path","")) == path:
        current.visible = true
        _apply_emotion_motion(current,hero)
        return
    var replacement:Node3D = _instantiate_asset(path,"Hero",current)
    if replacement == null:
        return
    replacement.visible = true
    replacement.set_meta("hw_final_asset_path",path)
    replacement.set_meta("hw_final_class",class_id)
    replacement.set_meta("hw_final_role_owner",true)
    var visual_profile:Dictionary = CHARACTER_PROFILES.snapshot(hero)
    replacement.set_meta("hw_character_profile",visual_profile)
    replacement.set_meta("hw_progression_rank",str(visual_profile.get("rank","")))
    replacement.set_meta("hw_emotion",str(visual_profile.get("emotion","")))
    replacement.set_meta("hw_motion_language",str(visual_profile.get("motion","")))
    replacement.set_meta("hw_clothing",visual_profile.get("clothing",[]))
    hero_profile_key = str(visual_profile.get("class","")) + ":" + str(visual_profile.get("rank",""))
    replacement.scale = Vector3.ONE * 1.05
    game.set("hero_visual",replacement)
    hero_path = path
    _remove_other_actor_children(actor_root,replacement,"Hero")
    _play_idle(replacement)
    _apply_emotion_motion(replacement,hero)

func _apply_emotion_motion(actor:Node3D, hero:Dictionary)->void:
    if actor == null or not is_instance_valid(actor):
        return
    var profile:Dictionary=CHARACTER_PROFILES.snapshot(hero)
    var class_id:String=str(profile.get("class","Warrior"))
    var t:float=hero_motion_time
    var sway:float=0.0
    var lean:float=0.0
    if class_id=="Warrior":
        sway=sin(t*2.2)*0.018
        lean=sin(t*1.6)*0.010
    elif class_id=="Mage":
        sway=sin(t*1.5)*0.025
        lean=sin(t*1.1)*0.012
    elif class_id=="Archer":
        sway=sin(t*2.8)*0.014
        lean=sin(t*2.0)*0.016
    elif class_id=="Thief":
        sway=sin(t*3.4)*0.030
        lean=sin(t*2.6)*0.022
    elif class_id=="Acolyte":
        sway=sin(t*1.25)*0.022
        lean=sin(t*0.9)*0.008
    elif class_id=="Merchant":
        sway=sin(t*2.0)*0.024
        lean=sin(t*1.7)*0.018
    actor.rotation.y=lean
    var visual_profile:Dictionary=actor.get_meta("hw_character_profile",profile)
    actor.set_meta("hw_character_profile",visual_profile)
    actor.set_meta("hw_progression_rank",GameDataClass.class_rank_for_hero(hero))
    actor.set_meta("hw_emotion",str(profile.get("emotion","")))
    actor.set_meta("hw_motion_language",str(profile.get("motion","")))
    var cape:Node=actor.find_child("Cape",true,false)
    if cape is Node3D:
        (cape as Node3D).rotation.z=sway
    var robe:Node=actor.find_child("WhiteRobe",true,false)
    if robe is Node3D:
        (robe as Node3D).rotation.z=sway*0.8
    var hat:Node=actor.find_child("WizardHat",true,false)
    if hat is Node3D:
        (hat as Node3D).rotation.z=sway*0.5
    var halo:Node=actor.find_child("DivineHalo",true,false)
    if halo is Node3D:
        (halo as Node3D).rotation.y=t*0.55
    var orb:Node=actor.find_child("ArcaneOrb",true,false)
    if orb is Node3D:
        (orb as Node3D).position.y=2.36+sin(t*2.2)*0.035
    var shadow:Node=actor.find_child("ShadowMask",true,false)
    if shadow is Node3D:
        (shadow as Node3D).rotation.z=lean
    var pouch:Node=actor.find_child("CoinPouch",true,false)
    if pouch is Node3D:
        (pouch as Node3D).rotation.z=sway
    var bow:Node=actor.find_child("Bow",true,false)
    if bow is Node3D:
        (bow as Node3D).rotation.z=sway*0.6

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
    if current != null and is_instance_valid(current) and str(current.get_meta("hw_final_asset_path","")) == path:
        current.visible = true
        _apply_pet_visual_motion(current,pet_value as Dictionary)
        return
    var replacement:Node3D = _instantiate_asset(path,"Pet",current)
    if replacement == null:
        return
    replacement.visible = true
    replacement.set_meta("hw_final_asset_path",path)
    replacement.set_meta("hw_final_pet_species",species)
    replacement.set_meta("hw_final_role_owner",true)
    var pet_profile:Dictionary=WORLD_ACTOR_PROFILES.pet_profile(pet_value as Dictionary)
    replacement.set_meta("hw_world_actor_profile",pet_profile)
    replacement.set_meta("hw_emotion",str(pet_profile.get("emotion","")))
    replacement.set_meta("hw_motion_language",str(pet_profile.get("motion","")))
    replacement.set_meta("hw_clothing",pet_profile.get("clothing",[]))
    replacement.scale = Vector3.ONE * 1.0
    game.set("pet_visual",replacement)
    pet_path = path
    _remove_other_actor_children(actor_root,replacement,"Pet")
    _play_idle(replacement)
    _apply_pet_visual_motion(replacement,pet_value as Dictionary)

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
        if str(current.get_meta("hw_final_asset_path","")) == path:
            current.visible = true
            _apply_monster_visual_motion(current,monster)
            continue
        var replacement:Node3D = _instantiate_asset(path,current.name,current)
        if replacement == null:
            continue
        replacement.visible = true
        replacement.set_meta("hw_final_asset_path",path)
        replacement.set_meta("hw_monster_key",key)
        replacement.set_meta("hw_final_role_owner",true)
        var monster_profile:Dictionary=WORLD_ACTOR_PROFILES.monster_profile(monster)
        replacement.set_meta("hw_world_actor_profile",monster_profile)
        replacement.set_meta("hw_emotion",str(monster_profile.get("emotion","")))
        replacement.set_meta("hw_motion_language",str(monster_profile.get("motion","")))
        replacement.set_meta("hw_clothing",monster_profile.get("clothing",[]))
        var mvp:bool = bool(monster.get("mvp",false))
        replacement.scale = Vector3.ONE * (1.25 if mvp else 1.0)
        visuals[key] = replacement
        monster_paths[key] = path
        _play_idle(replacement)
        _apply_monster_visual_motion(replacement,monster)
    for stale_key:Variant in monster_paths.keys():
        if not current_ids.has(str(stale_key)):
            monster_paths.erase(stale_key)

func _apply_pet_visual_motion(actor:Node3D,pet:Dictionary)->void:
    if actor==null or not is_instance_valid(actor):
        return
    var profile:Dictionary=WORLD_ACTOR_PROFILES.pet_profile(pet)
    actor.set_meta("hw_world_actor_profile",profile)
    actor.set_meta("hw_emotion",str(profile.get("emotion","")))
    actor.set_meta("hw_motion_language",str(profile.get("motion","")))
    var t:float=hero_motion_time
    if not actor.has_meta("hw_pet_base_y"):
        actor.set_meta("hw_pet_base_y",actor.position.y)
    actor.position.y=float(actor.get_meta("hw_pet_base_y",actor.position.y))
    actor.rotation.y=sin(t*2.0)*0.035
    if str(pet.get("species",""))=="Royal Falcon":
        actor.rotation.z=sin(t*5.0)*0.035
    elif str(pet.get("species",""))=="Night Panther":
        actor.rotation.y=sin(t*2.8)*0.05
    elif str(pet.get("species",""))=="Astral Sprite":
        actor.position.y=float(actor.get_meta("hw_pet_base_y",actor.position.y))+sin(t*2.2)*0.025
    elif str(pet.get("species",""))=="Blessed Poring":
        actor.scale=Vector3.ONE*(1.0+sin(t*3.5)*0.018)

func _apply_monster_visual_motion(actor:Node3D,monster:Dictionary)->void:
    if actor==null or not is_instance_valid(actor):
        return
    var profile:Dictionary=WORLD_ACTOR_PROFILES.monster_profile(monster)
    actor.set_meta("hw_world_actor_profile",profile)
    actor.set_meta("hw_emotion",str(profile.get("emotion","")))
    actor.set_meta("hw_motion_language",str(profile.get("motion","")))
    var t:float=hero_motion_time
    var mvp:bool=bool(monster.get("mvp",false))
    var rate:float=1.15 if mvp else 2.0
    var amp:float=0.018 if mvp else 0.012
    actor.rotation.y=sin(t*rate)*amp
    if mvp:
        actor.rotation.x=sin(t*0.65)*0.006

func _sync_world_npcs()->void:
    if scene==null:
        return
    var nodes:Array[Node]=get_tree().get_nodes_in_group("rent_npc")
    for npc:Node in nodes:
        if not npc is Node3D:
            continue
        var actor:Node3D=npc as Node3D
        var name_value:String=str(actor.get_meta("npc_name","Rent"))
        var job_value:String=str(actor.get_meta("class","Rental"))
        var profile:Dictionary=WORLD_ACTOR_PROFILES.npc_profile(name_value,job_value)
        actor.set_meta("hw_world_actor_profile",profile)
        actor.set_meta("hw_emotion",str(profile.get("emotion","")))
        actor.set_meta("hw_motion_language",str(profile.get("motion","")))
        actor.set_meta("hw_clothing",profile.get("clothing",[]))
        actor.rotation.y=sin(hero_motion_time*1.15)*0.025

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
        current.visible = false
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

func _sanitize_actor_root()->void:
    if visual_cleanup_done and game.get("hero_visual") != null and game.get("pet_visual") != null:
        # Re-run lightweight visibility checks, but do not rebuild valid authored actors.
        var hero:Node3D = game.get("hero_visual") as Node3D
        if hero != null and is_instance_valid(hero):
            hero.visible = true
        var pet:Node3D = game.get("pet_visual") as Node3D
        if pet != null and is_instance_valid(pet):
            pet.visible = true
        return
    var actor_root:Node3D = game.get("actor_root") as Node3D
    if actor_root == null:
        return
    var hero:Node3D = game.get("hero_visual") as Node3D
    var pet:Node3D = game.get("pet_visual") as Node3D
    for child:Node in actor_root.get_children():
        if hero != null and child == hero:
            continue
        if pet != null and child == pet:
            continue
        # Do not delete monsters; delete only unowned actor leftovers.
        var child_name:String = str(child.name)
        if child_name == "Hero" or child_name.begins_with("Hero_") or child_name == "Pet" or child_name.begins_with("Pet_"):
            child.queue_free()
    visual_cleanup_done = true

func _fit_camera()->void:
    var camera:Camera3D = scene.get_node_or_null("Camera3D") as Camera3D
    if camera == null:
        return
    camera.fov = 52.0
    camera.near = 0.05
    camera.far = 700.0

func _tier_for_level(level:int)->String:
    if level >= 200: return "Transcendence"
    if level >= 150: return "Mastery"
    if level >= 50: return "Advanced"
    if level >= 25: return "Specialization"
    return "Foundation"

func _monster_family(value:String)->String:
    var lower:String = value.to_lower().replace("_"," ")
    if lower.contains("bloody knight"): return "Bloody_Knight"
    if lower.contains("evil druid"): return "Evil_Druid"
    for family:Variant in MONSTER_FAMILIES.keys():
        var family_id:String = str(family)
        if family_id == "bloody knight" or family_id == "evil druid": continue
        if lower.contains(family_id): return str(MONSTER_FAMILIES[family])
    return ""

func _play_idle(root:Node)->void:
    var player:AnimationPlayer = _find_animation_player(root)
    if player == null:
        return
    var preferred:Array[String] = ["Idle","idle","Armature|Idle","default"]
    for name:String in preferred:
        if player.has_animation(name):
            player.play(name)
            player.advance(0.0)
            return
    var library:AnimationLibrary = player.get_animation_library("")
    if library == null:
        return
    var names:PackedStringArray = library.get_animation_list()
    if names.size() > 0:
        player.play(names[0])
        player.advance(0.0)

func _find_animation_player(node:Node)->AnimationPlayer:
    if node is AnimationPlayer:
        return node as AnimationPlayer
    for child:Node in node.get_children():
        var found:AnimationPlayer = _find_animation_player(child)
        if found != null:
            return found
    return null
