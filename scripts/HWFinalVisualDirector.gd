extends Node

## Native final visual director.
## Keeps the live MMORPG world readable and prevents competing camera/lighting
## directors from producing unstable or overexposed/blank runtime frames.

var scene:Node3D
var elapsed:float = 0.0

func _ready() -> void:
    process_priority = 3000
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("_bind")

func _process(delta:float) -> void:
    elapsed += delta
    if elapsed < 0.25:
        return
    elapsed = 0.0
    _bind()
    _ensure_runtime_visuals()

func _bind() -> void:
    scene = get_tree().current_scene as Node3D
    if scene == null:
        return

func _ensure_runtime_visuals() -> void:
    if scene == null or not is_instance_valid(scene):
        return

    var camera:Camera3D = scene.get_node_or_null("Camera3D") as Camera3D
    if camera == null:
        camera = scene.get_viewport().get_camera_3d()
    if camera != null:
        camera.current = true
        camera.cull_mask = 0xFFFFFFFF
        camera.near = 0.05
        camera.far = 700.0

    var world_root:Node3D = scene.get_node_or_null("World3D") as Node3D
    if world_root != null:
        world_root.visible = true

    var hero_value:Variant = scene.get("hero_visual")
    if hero_value is Node3D and is_instance_valid(hero_value):
        (hero_value as Node3D).visible = true

    var env_node:WorldEnvironment = scene.get_node_or_null("WorldEnvironment") as WorldEnvironment
    if env_node == null:
        env_node = WorldEnvironment.new()
        env_node.name = "WorldEnvironment"
        scene.add_child(env_node)
    var env:Environment = env_node.environment
    if env == null:
        env = Environment.new()
        env_node.environment = env

    env.background_mode = Environment.BG_COLOR
    env.background_color = Color("#6f9bb5")
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color("#c3d5df")
    env.ambient_light_energy = 0.55
    env.reflected_light_source = Environment.REFLECTION_SOURCE_BG
    env.tonemap_mode = Environment.TONE_MAPPER_ACES
    env.tonemap_exposure = -0.35
    env.tonemap_white = 1.15
    env.fog_enabled = false
    env.glow_enabled = false

    var world:World3D = scene.get_world_3d()
    if world != null:
        world.environment = env
        world.fallback_environment = env
    if camera != null:
        camera.environment = env

    var sun:DirectionalLight3D = scene.get_node_or_null("HWFinalNativeSun") as DirectionalLight3D
    if sun == null:
        sun = DirectionalLight3D.new()
        sun.name = "HWFinalNativeSun"
        scene.add_child(sun)
    sun.rotation_degrees = Vector3(-52.0, -28.0, 0.0)
    sun.light_energy = 0.88
    sun.light_color = Color("#ffe8c2")
    sun.shadow_enabled = true
    sun.directional_shadow_max_distance = 90.0
    sun.directional_shadow_fade_start = 0.82
    sun.light_angular_distance = 0.16

    # One deliberate daylight sun is used for final presentation. Older passes
    # may create their own DirectionalLight3D nodes; leaving them energized at
    # the same time causes washed-out frames and renderer-dependent output.
    for child:Node in scene.get_children():
        if child is DirectionalLight3D and child != sun:
            (child as DirectionalLight3D).light_energy = 0.0
            (child as DirectionalLight3D).shadow_enabled = false
