extends Node

## Final HD visual ownership pass. One authored GLB actor is kept visible per role.
const GameDataClass = preload("res://scripts/GameData.gd")
const CHARACTER_PROFILES = preload("res://scripts/HWCharacterVisualProfiles.gd")
const WORLD_ACTOR_PROFILES = preload("res://scripts/HWWorldActorVisualProfiles.gd")
const GENERATED_ROOT:String = "res://assets/3d/generated"
const POLL_INTERVAL:float = 0.08
const PET_ASSET_BY_SPECIES:Dictionary={"Royal Falcon":"Falcon.glb","Astral Sprite":"ArcaneOrb.glb","Blessed Poring":"PoringAngel.glb","Night Panther":"Panther.glb","Merchant Companion":"Clockwork.glb","Dire Wolf":"Wolf.glb"}
const MONSTER_FAMILIES:Dictionary={"poring":"Poring","goblin":"Goblin","wolf":"Wolf","skeleton":"Skeleton","zombie":"Zombie","orc":"Orc","mantis":"Mantis","golem":"Golem","evil druid":"Evil_Druid","bloody knight":"Bloody_Knight","dragon":"Dragon"}

var scene:Node3D
var game:Node3D
var legacy:Node
var elapsed:float=0.0
var motion_time:float=0.0
var cleanup_done:bool=false

func _ready()->void:
    process_priority=3000
    process_mode=Node.PROCESS_MODE_ALWAYS
    call_deferred("_bind")
    call_deferred("_force_environment")

func _process(delta:float)->void:
    elapsed+=delta
    motion_time+=delta
    if elapsed<POLL_INTERVAL: return
    elapsed=0.0
    _bind()
    if game==null or legacy==null: return
    _disable_competing_passes()
    _force_environment()
    _sync_hero()
    _sync_pet()
    _sync_monsters()
    _sync_npcs()
    _fit_camera()

func _bind()->void:
    if scene==null or not is_instance_valid(scene): scene=get_tree().current_scene as Node3D
    if scene!=null:
        game=scene
        legacy=scene.get_node_or_null("LegacyGame")

func _disable_competing_passes()->void:
    for node_name:String in ["HWGeneratedAssetRuntime","HDAssetRuntime","HWReadableActorDirector","HWPrimitiveBeautyDirector"]:
        var node:Node=get_node_or_null("/root/"+node_name)
        if node!=null: node.process_mode=Node.PROCESS_MODE_DISABLED

func _force_environment()->void:
    if scene==null:
        return

    # HDVisualDirector is the single owner of production lighting. Do not add a
    # second WorldEnvironment or sun: stacked environments/lights were causing
    # washed-out HDR frames and reducing authored GLB material contrast.
    var hd:Node=scene.get_node_or_null("HDVisualDirector")
    var env_node:WorldEnvironment=null
    if hd!=null:
        env_node=hd.get_node_or_null("WorldEnvironment") as WorldEnvironment
    if env_node==null:
        env_node=scene.get_node_or_null("WorldEnvironment") as WorldEnvironment
    if env_node==null:
        env_node=scene.get_node_or_null("HWFinalWorldEnvironment") as WorldEnvironment
    if env_node==null:
        env_node=WorldEnvironment.new()
        env_node.name="HWFinalWorldEnvironment"
        scene.add_child(env_node)

    var env:Environment=env_node.environment
    if env==null:
        env=Environment.new()
        env_node.environment=env

    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#6f9bb5")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#c5d8e2")
    env.ambient_light_energy=0.44
    env.tonemap_mode=Environment.TONE_MAPPER_ACES
    env.tonemap_exposure=-0.45
    env.tonemap_white=1.15
    env.fog_enabled=true
    env.fog_light_color=Color("#8ca9bd")
    env.fog_light_energy=0.10
    env.fog_density=0.0018
    env.fog_height=1.5
    env.fog_height_density=0.006

    # Forward+ post effects remain authored by HDVisualDirector. Tighten them
    # here so bright materials retain detail without a white bloom wash.
    if RenderingServer.get_current_rendering_method()=="forward_plus":
        env.ssao_enabled=true
        env.ssao_radius=1.6
        env.ssao_intensity=1.05
        env.ssil_enabled=true
        env.ssil_radius=3.0
        env.ssil_intensity=0.50
        env.glow_enabled=true
        env.glow_intensity=0.20
        env.glow_bloom=0.035
        env.glow_hdr_threshold=1.55
        env.sdfgi_enabled=true
        env.sdfgi_energy=0.58
    else:
        env.ssao_enabled=false
        env.ssil_enabled=false
        env.glow_enabled=false
        env.sdfgi_enabled=false
        env.volumetric_fog_enabled=false

    var sun:DirectionalLight3D=null
    if hd!=null:
        sun=hd.get_node_or_null("HDSun") as DirectionalLight3D
    if sun==null:
        sun=scene.get_node_or_null("HWFinalSun") as DirectionalLight3D
    if sun==null:
        sun=scene.get_node_or_null("HWSunKey") as DirectionalLight3D
    if sun==null:
        sun=DirectionalLight3D.new()
        sun.name="HWFinalSun"
        scene.add_child(sun)
    sun.rotation_degrees=Vector3(-50.0,-35.0,0.0)
    sun.light_energy=0.88
    sun.light_color=Color("#ffe8c2")
    sun.shadow_enabled=true
    sun.directional_shadow_max_distance=90.0
    sun.directional_shadow_fade_start=0.80
    sun.light_angular_distance=0.18
    sun.shadow_bias=0.035
    sun.shadow_normal_bias=0.85

    var rim:DirectionalLight3D=null
    if hd!=null:
        rim=hd.get_node_or_null("HDRim") as DirectionalLight3D
    if rim!=null:
        rim.light_energy=0.10
        rim.light_color=Color("#79b9e4")
        rim.shadow_enabled=false

func _sync_hero()->void:
    var value:Variant=legacy.get("hero")
    if not value is Dictionary: return
    var hero:Dictionary=value
    var root:Node3D=game.get("actor_root") as Node3D
    if root==null: return
    var class_id:String=str(hero.get("class","Warrior"))
    var tier:String=_tier_for_level(int(hero.get("level",1)))
    var path:String=GENERATED_ROOT+"/characters/"+class_id+"/"+tier+".glb"
    if not ResourceLoader.exists(path): return
    var current:Node3D=game.get("hero_visual") as Node3D
    if current!=null and is_instance_valid(current) and str(current.get_meta("hw_final_asset_path",""))==path:
        current.visible=true; _animate_actor(current,hero); return
    var replacement:Node3D=_instantiate(path,"Hero",current)
    if replacement==null: return
    replacement.set_meta("hw_final_asset_path",path)
    replacement.set_meta("hw_final_role_owner",true)
    replacement.set_meta("hw_character_profile",CHARACTER_PROFILES.snapshot(hero))
    replacement.scale=Vector3.ONE*1.05
    game.set("hero_visual",replacement)
    _remove_duplicates(root,replacement,"Hero")
    _play_idle(replacement)
    _animate_actor(replacement,hero)

func _sync_pet()->void:
    var value:Variant=legacy.get("hero")
    if not value is Dictionary: return
    var hero:Dictionary=value
    var pet:Variant=hero.get("pet",{})
    if not pet is Dictionary: return
    var species:String=str((pet as Dictionary).get("species","Dire Wolf"))
    var file:String=str(PET_ASSET_BY_SPECIES.get(species,"Wolf.glb"))
    var path:String=GENERATED_ROOT+"/pets/"+file
    if not ResourceLoader.exists(path): return
    var current:Node3D=game.get("pet_visual") as Node3D
    if current!=null and is_instance_valid(current) and str(current.get_meta("hw_final_asset_path",""))==path:
        current.visible=true; _animate_pet(current,pet as Dictionary); return
    var replacement:Node3D=_instantiate(path,"Pet",current)
    if replacement==null: return
    replacement.set_meta("hw_final_asset_path",path)
    replacement.set_meta("hw_final_role_owner",true)
    replacement.set_meta("hw_world_actor_profile",WORLD_ACTOR_PROFILES.pet_profile(pet as Dictionary))
    game.set("pet_visual",replacement)
    _play_idle(replacement)
    _animate_pet(replacement,pet as Dictionary)

func _sync_monsters()->void:
    var value:Variant=game.get("monster_visuals")
    var monsters:Variant=legacy.get("monsters")
    if not value is Dictionary or not monsters is Array: return
    var visuals:Dictionary=value
    for monster_value:Variant in monsters as Array:
        if not monster_value is Dictionary: continue
        var monster:Dictionary=monster_value
        var key:String=str(monster.get("visual_id",monster.get("name","Monster")))
        if not visuals.has(key): continue
        var current:Node3D=visuals[key] as Node3D
        if current==null or not is_instance_valid(current): continue
        var family:String=_monster_family(str(monster.get("name","")))
        if family.is_empty(): continue
        var path:String=GENERATED_ROOT+"/monsters/monster_"+family+".glb"
        if not ResourceLoader.exists(path): continue
        if str(current.get_meta("hw_final_asset_path",""))!=path:
            var replacement:Node3D=_instantiate(path,current.name,current)
            if replacement!=null:
                replacement.set_meta("hw_final_asset_path",path)
                replacement.set_meta("hw_final_role_owner",true)
                replacement.set_meta("hw_world_actor_profile",WORLD_ACTOR_PROFILES.monster_profile(monster))
                visuals[key]=replacement
                _play_idle(replacement)
                current=replacement
        current.visible=true
        current.rotation.y=sin(motion_time*1.5)*0.015

func _sync_npcs()->void:
    for npc:Node in get_tree().get_nodes_in_group("rent_npc"):
        if npc is Node3D:
            var actor:Node3D=npc as Node3D
            actor.set_meta("hw_world_actor_profile",WORLD_ACTOR_PROFILES.npc_profile(str(actor.get_meta("npc_name","Rent")),str(actor.get_meta("class","Rental"))))

func _instantiate(path:String,node_name:String,current:Node3D)->Node3D:
    var root:Node3D=game.get("actor_root") as Node3D
    if root==null: return null
    var packed:PackedScene=load(path) as PackedScene
    if packed==null: return null
    var model:Node=packed.instantiate()
    if model==null or not model is Node3D:
        if model!=null: model.queue_free()
        return null
    var actor:Node3D=model as Node3D
    actor.name=node_name
    root.add_child(actor)
    if current!=null and is_instance_valid(current):
        actor.global_transform=current.global_transform
        current.visible=false
        current.queue_free()
    return actor

func _remove_duplicates(root:Node3D,keep:Node3D,prefix:String)->void:
    for child:Node in root.get_children():
        if child==keep: continue
        var n:String=str(child.name)
        if n==prefix or n.begins_with(prefix+"_"): child.queue_free()
    cleanup_done=true

func _animate_actor(actor:Node3D,hero:Dictionary)->void:
    var profile:Dictionary=CHARACTER_PROFILES.snapshot(hero)
    actor.set_meta("hw_character_profile",profile)
    actor.set_meta("hw_progression_rank",GameDataClass.class_rank_for_hero(hero))
    actor.set_meta("hw_emotion",str(profile.get("emotion","")))
    actor.set_meta("hw_motion_language",str(profile.get("motion","")))
    actor.rotation.z=sin(motion_time*1.4)*0.008

func _animate_pet(actor:Node3D,pet:Dictionary)->void:
    actor.set_meta("hw_emotion",str(WORLD_ACTOR_PROFILES.pet_profile(pet).get("emotion","")))
    if not actor.has_meta("hw_pet_base_y"): actor.set_meta("hw_pet_base_y",actor.position.y)
    actor.position.y=float(actor.get_meta("hw_pet_base_y",actor.position.y))+sin(motion_time*2.0)*0.025

func _play_idle(root:Node)->void:
    var player:AnimationPlayer=_find_animation_player(root)
    if player==null: return
    for name:String in ["Idle","idle","Armature|Idle","default"]:
        if player.has_animation(name): player.play(name); return
    var lib:AnimationLibrary=player.get_animation_library("")
    if lib!=null and lib.get_animation_list().size()>0: player.play(lib.get_animation_list()[0])

func _find_animation_player(node:Node)->AnimationPlayer:
    if node is AnimationPlayer: return node as AnimationPlayer
    for child:Node in node.get_children():
        var found:AnimationPlayer=_find_animation_player(child)
        if found!=null: return found
    return null

func _tier_for_level(level:int)->String:
    if level>=200: return "Transcendence"
    if level>=150: return "Mastery"
    if level>=50: return "Advanced"
    if level>=25: return "Specialization"
    return "Foundation"

func _monster_family(value:String)->String:
    var lower:String=value.to_lower().replace("_"," ")
    for key:Variant in MONSTER_FAMILIES.keys():
        if lower.contains(str(key)): return str(MONSTER_FAMILIES[key])
    return ""

func _fit_camera()->void:
    if scene==null: return
    var camera:Camera3D=scene.get_node_or_null("Camera3D") as Camera3D
    if camera!=null:
        camera.fov=52.0
        camera.near=0.05
        camera.far=700.0
