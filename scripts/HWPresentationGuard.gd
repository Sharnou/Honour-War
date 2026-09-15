extends Node3D

## Final presentation guard.
## Owns the final camera/environment while deliberately leaving the authored
## Blender -> GLB/GLTF asset runtime active. Gameplay roots are never removed.

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
    _ensure_class_identity()

func _bind()->void:
    if scene == null or not is_instance_valid(scene):
        scene = get_tree().current_scene as Node3D

func _disable_competing_passes()->void:
    # Keep the final environment owned by this guard. The authored asset bridge
    # MUST remain enabled; disabling it was the main cause of placeholder actors.
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

    # HDAssetRuntime is the authoritative class/monster GLB loader.
    # HDVisualDirector and HDEnvironmentDirector own competing environments,
    # so they remain disabled while this guard owns the final environment.
    for name:String in [
        "HDVisualDirector",
        "HDEnvironmentDirector"
    ]:
        var node:Node = scene.get_node_or_null(name)
        if node != null:
            node.process_mode = Node.PROCESS_MODE_DISABLED

    var hd_assets:Node = scene.get_node_or_null("HDAssetRuntime")
    if hd_assets != null:
        hd_assets.process_mode = Node.PROCESS_MODE_INHERIT

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
    var actor_root:Node3D = scene.get("actor_root") as Node3D
    if actor_root == null:
        return
    var hero:Node3D = scene.get("hero_visual") as Node3D
    var pet:Node3D = scene.get("pet_visual") as Node3D
    for child:Node in actor_root.get_children().duplicate():
        if child == hero or child == pet:
            continue
        # Never delete authored HD replacements. The old prefix-based cleanup
        # deleted Hero_HDAsset immediately after HDAssetRuntime loaded it.
        if bool(child.get_meta("hw_production_asset", false)):
            continue
        if child.has_meta("hw_source_path"):
            continue
        var n:String = str(child.name).to_lower()
        if n in ["hero", "warrior", "knight"]:
            child.visible = false
            child.queue_free()
    if hero != null and is_instance_valid(hero):
        hero.visible = true
    if pet != null and is_instance_valid(pet):
        pet.visible = true

func _ensure_class_identity()->void:
    var hero:Node3D = scene.get("hero_visual") as Node3D
    var legacy:Node = scene.get_node_or_null("LegacyGame")
    if hero == null or not is_instance_valid(hero) or legacy == null:
        return
    var value:Variant = legacy.get("hero")
    if not value is Dictionary:
        return
    var data:Dictionary = value
    var class_id:String = str(data.get("class", "Warrior"))
    var level:int = int(data.get("level", 1))
    var marker:Label3D = hero.get_node_or_null("HWClassIdentity") as Label3D
    if marker == null:
        marker = Label3D.new()
        marker.name = "HWClassIdentity"
        marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
        marker.no_depth_test = true
        marker.outline_size = 8
        marker.font_size = 32
        marker.pixel_size = 0.0028
        hero.add_child(marker)
    marker.text = class_id.to_upper() + "  •  LV " + str(level)
    marker.modulate = _class_color(class_id)
    marker.position = Vector3(0.0, 2.45, 0.0)

func _class_color(class_id:String)->Color:
    match class_id:
        "Mage": return Color("#8fc7ff")
        "Archer": return Color("#9fe7a7")
        "Thief": return Color("#d9a8ff")
        "Acolyte": return Color("#fff0a6")
        "Merchant": return Color("#ffbf78")
        _ : return Color("#ffcf70")

func _repair_camera()->void:
    var camera:Camera3D = scene.get_node_or_null("Camera3D") as Camera3D
    if camera == null:
        return
    camera.projection = Camera3D.PROJECTION_PERSPECTIVE
    camera.fov = 52.0
    camera.near = 0.05
    camera.far = 700.0
    camera.current = true
