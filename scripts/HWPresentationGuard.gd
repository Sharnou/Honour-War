extends Node3D

## Final presentation guard. Runs after all visual directors and enforces one
## authored hero/pet presentation, a single WorldEnvironment, and a readable
## perspective camera. Presentation cleanup never removes gameplay state.

const POLL:float = 0.20
var elapsed:float = 0.0
var scene:Node3D
var environment_ready:bool = false

func _ready()->void:
    process_priority = 32000
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("_guard")

func _process(delta:float)->void:
    elapsed += delta
    if elapsed < POLL:
        return
    elapsed = 0.0
    _guard()

func _guard()->void:
    _bind()
    if scene == null:
        return
    _disable_competing_passes()
    _ensure_single_environment()
    _clean_duplicate_actor_nodes()
    _repair_camera()

func _bind()->void:
    if scene == null or not is_instance_valid(scene):
        scene = get_tree().current_scene as Node3D

func _disable_competing_passes()->void:
    # These systems can legitimately exist for legacy/gameplay integration,
    # but the final presentation owner must be the only active visual stack.
    for name:String in [
        "HDProductionQualityDirector",
        "HWGeneratedAssetRuntime",
        "HWReadableActorDirector",
        "HWPrimitiveBeautyDirector",
        "HWVisualMaxDirector"
    ]:
        var node:Node = get_node_or_null("/root/" + name)
        if node != null and node != self:
            node.process_mode = Node.PROCESS_MODE_DISABLED
    for name:String in [
        "HDAssetRuntime",
        "HDVisualDirector",
        "HDEnvironmentDirector",
        "HWRoleDrivenUpgradeRuntime"
    ]:
        var node:Node = scene.get_node_or_null(name)
        if node != null:
            node.process_mode = Node.PROCESS_MODE_DISABLED

func _ensure_single_environment()->void:
    var keep:WorldEnvironment = scene.get_node_or_null("HWFinalWorldEnvironment") as WorldEnvironment
    if keep == null:
        keep = WorldEnvironment.new()
        keep.name = "HWFinalWorldEnvironment"
        scene.add_child(keep)
    if not environment_ready:
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
        sky_mat.sky_top_color = Color("#285b8f")
        sky_mat.sky_horizon_color = Color("#c0deeb")
        sky_mat.ground_bottom_color = Color("#19271f")
        sky_mat.ground_horizon_color = Color("#7f9788")
        env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
        env.ambient_light_energy = 0.64
        env.ambient_light_sky_contribution = 0.76
        env.tonemap_mode = Environment.TONE_MAPPER_ACES
        env.tonemap_exposure = 1.0
        env.glow_enabled = true
        env.glow_intensity = 0.68
        env.glow_bloom = 0.16
        env.glow_hdr_threshold = 1.05
        env.ssao_enabled = true
        env.ssao_radius = 1.4
        env.ssao_intensity = 1.65
        env.fog_enabled = true
        env.fog_light_color = Color("#a7bfcc")
        env.fog_light_energy = 0.20
        env.fog_density = 0.0022
        env.fog_height = 7.0
        env.fog_height_density = 0.012
        environment_ready = true

    _purge_world_environments(get_tree().root, keep)

func _purge_world_environments(node:Node,keep:WorldEnvironment)->void:
    if node == null or node == keep:
        return
    for child:Node in node.get_children().duplicate():
        if child == keep:
            continue
        if child is WorldEnvironment:
            child.process_mode = Node.PROCESS_MODE_DISABLED
            child.queue_free()
            continue
        _purge_world_environments(child,keep)

func _clean_duplicate_actor_nodes()->void:
    var game:Node3D = scene
    var actor_root:Node3D = game.get("actor_root") as Node3D
    if actor_root == null:
        return
    var hero:Node3D = game.get("hero_visual") as Node3D
    var pet:Node3D = game.get("pet_visual") as Node3D
    for child:Node in actor_root.get_children().duplicate():
        if child == hero or child == pet:
            continue
        var n:String = str(child.name).to_lower()
        if n == "hero" or n.begins_with("hero_") or n == "warrior" or n.begins_with("warrior_") or n == "knight" or n.begins_with("knight_"):
            child.visible = false
            child.queue_free()
    if hero != null and is_instance_valid(hero):
        hero.visible = true
    if pet != null and is_instance_valid(pet):
        pet.visible = true

func _repair_camera()->void:
    var camera:Camera3D = scene.get_node_or_null("Camera3D") as Camera3D
    if camera == null:
        return
    camera.projection = Camera3D.PROJECTION_PERSPECTIVE
    camera.fov = 52.0
    camera.near = 0.05
    camera.far = 700.0
    camera.current = true
