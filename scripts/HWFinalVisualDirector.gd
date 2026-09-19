extends Node

## Native final visual director.
## Generated HD GLB actors were permanently retired. This director no longer
## loads, downloads, imports, or attaches GLB assets. It keeps the final runtime
## environment stable and lets Game3D/HWHDWorldContentDirector own native actors.

var scene:Node3D
var elapsed:float=0.0

func _ready()->void:
    process_priority=3000
    process_mode=Node.PROCESS_MODE_ALWAYS
    call_deferred("_bind")

func _process(delta:float)->void:
    elapsed+=delta
    if elapsed<0.25:
        return
    elapsed=0.0
    _bind()
    _ensure_runtime_visuals()

func _bind()->void:
    scene=get_tree().current_scene as Node3D
    if scene==null:
        return

func _ensure_runtime_visuals()->void:
    if scene==null or not is_instance_valid(scene):
        return
    var camera:=scene.get_node_or_null("Camera3D") as Camera3D
    if camera!=null:
        camera.current=true
        camera.cull_mask=0xFFFFFFFF
        camera.near=0.05
        camera.far=700.0
    var env_node:=scene.get_node_or_null("HWFinalNativeEnvironment") as WorldEnvironment
    if env_node==null:
        env_node=WorldEnvironment.new()
        env_node.name="HWFinalNativeEnvironment"
        scene.add_child(env_node)
    var env:=env_node.environment
    if env==null:
        env=Environment.new()
        env_node.environment=env
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#6f9bb5")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#c5d8e2")
    env.ambient_light_energy=0.72
    env.tonemap_mode=Environment.TONE_MAPPER_ACES
    env.tonemap_exposure=0.0
    env.fog_enabled=false
    if camera!=null:
        camera.environment=env
    var world:=scene.get_world_3d()
    if world!=null:
        world.environment=env
        world.fallback_environment=env
    var sun:=scene.get_node_or_null("HWFinalNativeSun") as DirectionalLight3D
    if sun==null:
        sun=DirectionalLight3D.new()
        sun.name="HWFinalNativeSun"
        scene.add_child(sun)
    sun.rotation_degrees=Vector3(-52.0,-28.0,0.0)
    sun.light_energy=1.15
    sun.light_color=Color("#ffe8c2")
    sun.shadow_enabled=true
    sun.directional_shadow_max_distance=90.0
