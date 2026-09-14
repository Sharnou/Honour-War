extends Node3D

## Honour War Visual MAX runtime-safe replacement for Godot 4.2.
## Authored GLB assets are preferred; this director only supplies environment
## presentation and removes obsolete 3D labels.

var scene:Node3D
var environment_ready:bool=false
var timer:float=0.0

func _ready()->void:
    call_deferred("_bind")

func _process(delta:float)->void:
    timer += delta
    if timer < 0.5:
        return
    timer = 0.0
    _bind()
    if scene==null:
        return
    _hide_labels(scene)
    _ensure_environment()

func _bind()->void:
    if scene==null or not is_instance_valid(scene):
        scene=get_tree().current_scene as Node3D

func _ensure_environment()->void:
    if environment_ready or scene==null:
        return
    var env_node:WorldEnvironment=scene.get_node_or_null("HWVisualMaxEnvironment") as WorldEnvironment
    if env_node==null:
        env_node=WorldEnvironment.new()
        env_node.name="HWVisualMaxEnvironment"
        scene.add_child(env_node)
    var env:Environment=env_node.environment
    if env==null:
        env=Environment.new()
        env_node.environment=env
    env.background_mode=Environment.BG_SKY
    var sky:Sky=env.sky
    if sky==null:
        sky=Sky.new()
        env.sky=sky
    var sky_mat:ProceduralSkyMaterial=sky.sky_material as ProceduralSkyMaterial
    if sky_mat==null:
        sky_mat=ProceduralSkyMaterial.new()
        sky.sky_material=sky_mat
    sky_mat.sky_top_color=Color("#163f75")
    sky_mat.sky_horizon_color=Color("#c8ecff")
    sky_mat.ground_bottom_color=Color("#18202a")
    sky_mat.ground_horizon_color=Color("#89a8b7")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_SKY
    env.ambient_light_energy=1.0
    env.tonemap_mode=Environment.TONE_MAPPER_FILMIC
    env.tonemap_exposure=1.08
    env.glow_enabled=true
    env.glow_intensity=0.75
    var sun:DirectionalLight3D=scene.get_node_or_null("HWVisualMaxSun") as DirectionalLight3D
    if sun==null:
        sun=DirectionalLight3D.new()
        sun.name="HWVisualMaxSun"
        scene.add_child(sun)
    sun.rotation_degrees=Vector3(-48.0,-25.0,0.0)
    sun.light_energy=1.45
    sun.light_color=Color("#ffe9c1")
    sun.shadow_enabled=true
    sun.directional_shadow_max_distance=100.0
    environment_ready=true

func _hide_labels(node:Node)->void:
    for child in node.get_children():
        if child is Label3D:
            (child as Label3D).visible=false
        if child.get_child_count()>0:
            _hide_labels(child)
