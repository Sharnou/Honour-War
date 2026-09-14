extends Node

## Honour War dynamic fantasy day/night environment controller.
## The cycle is deliberately controlled to preserve material readability:
## daytime never returns to the old whiteout, while nighttime increases only
## selected glow/emissive presentation against a darker environment.

@export_group("Required Node Linkages")
@export var sun_light:DirectionalLight3D
@export var world_environment:WorldEnvironment

@export_group("Cycle Timeline")
@export_range(0.0, 0.02, 0.0001) var time_speed:float = 0.0025
@export_range(0.0, 1.0, 0.001) var current_time:float = 0.25
@export var pause_cycle:bool = false

@export_group("Day Palette")
@export var day_sky_color:Color = Color("#244d7b")
@export var day_horizon_color:Color = Color("#a9c9d8")
@export var day_ground_color:Color = Color("#718b82")
@export var sunset_horizon_color:Color = Color("#d88755")

@export_group("Night Palette")
@export var night_sky_color:Color = Color("#0d1117")
@export var night_horizon_color:Color = Color("#263653")
@export var night_ground_color:Color = Color("#18211f")
@export var moon_light_color:Color = Color("#a1b5da")

var internal_clock:float = 0.25
var _base_sky_top:Color
var _base_sky_horizon:Color
var _base_ground_horizon:Color
var _base_ground_bottom:Color

func _ready()->void:
    internal_clock = fposmod(current_time, 1.0)
    call_deferred("_resolve_nodes")

func _process(delta:float)->void:
    if pause_cycle:
        return
    internal_clock = fposmod(internal_clock + delta * time_speed, 1.0)
    _update_environment_layer(internal_clock)

func _resolve_nodes()->void:
    var scene:Node = get_tree().current_scene
    if scene == null:
        return
    if sun_light == null:
        sun_light = scene.get_node_or_null("HWVisualMaxSun") as DirectionalLight3D
    if world_environment == null:
        world_environment = scene.get_node_or_null("HWVisualMaxEnvironment") as WorldEnvironment
    if sun_light == null:
        sun_light = scene.find_child("HWVisualMaxSun", true, false) as DirectionalLight3D
    if world_environment == null:
        world_environment = scene.find_child("HWVisualMaxEnvironment", true, false) as WorldEnvironment
    if world_environment != null and world_environment.environment != null:
        var sky:Sky = world_environment.environment.sky
        if sky != null and sky.sky_material is ProceduralSkyMaterial:
            var sky_mat:ProceduralSkyMaterial = sky.sky_material as ProceduralSkyMaterial
            _base_sky_top = sky_mat.sky_top_color
            _base_sky_horizon = sky_mat.sky_horizon_color
            _base_ground_horizon = sky_mat.ground_horizon_color
            _base_ground_bottom = sky_mat.ground_bottom_color
    _update_environment_layer(internal_clock)

func _update_environment_layer(time_percent:float)->void:
    if sun_light == null or world_environment == null:
        return
    var env:Environment = world_environment.environment
    if env == null:
        return

    # 0.25 = noon, 0.50 = sunset, 0.75 = midnight, 0.00 = sunrise.
    var sun_height:float = sin((time_percent - 0.25) * TAU)
    var day_factor:float = clamp((sun_height + 0.08) / 1.08, 0.0, 1.0)
    day_factor = smoothstep(0.0, 1.0, day_factor)
    var night_factor:float = 1.0 - day_factor
    var sunset_factor:float = 0.0
    if sun_height > -0.18 and sun_height < 0.32:
        sunset_factor = 1.0 - abs(sun_height - 0.07) / 0.25
        sunset_factor = clamp(sunset_factor, 0.0, 1.0)

    # Rotate around a stable tilted arc. The existing camera and gameplay nodes
    # do not depend on the sun transform, so this remains presentation-only.
    sun_light.rotation_degrees = Vector3(time_percent * 360.0 - 90.0, -25.0, 0.0)

    var day_energy:float = lerp(0.72, 1.02, day_factor)
    var night_energy:float = 0.24
    sun_light.light_energy = lerp(night_energy, day_energy, day_factor)
    var sunset_light:Color = Color("#f0ad76")
    sun_light.light_color = moon_light_color.lerp(sunset_light, sunset_factor).lerp(Color("#f6dfb5"), day_factor)
    sun_light.shadow_enabled = true
    sun_light.light_angular_distance = 0.35

    var sky:Sky = env.sky
    if sky != null and sky.sky_material is ProceduralSkyMaterial:
        var sky_mat:ProceduralSkyMaterial = sky.sky_material as ProceduralSkyMaterial
        var top:Color = night_sky_color.lerp(day_sky_color, day_factor)
        var horizon:Color = night_horizon_color.lerp(day_horizon_color, day_factor)
        horizon = horizon.lerp(sunset_horizon_color, sunset_factor * 0.75)
        sky_mat.sky_top_color = top
        sky_mat.sky_horizon_color = horizon
        sky_mat.ground_horizon_color = night_ground_color.lerp(day_ground_color, day_factor).lerp(sunset_horizon_color.darkened(0.35), sunset_factor * 0.25)
        sky_mat.ground_bottom_color = night_ground_color.lerp(Color("#1d2728"), day_factor)

    # Controlled exposure is a hard visual requirement. Night is darker, not
    # brighter; glow is increased only after the scene has darkened.
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env.tonemap_exposure = lerp(-0.92, -0.65, day_factor)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    env.ambient_light_energy = lerp(0.18, 0.36, day_factor)
    env.ambient_light_color = night_horizon_color.lerp(Color("#a8c4d1"), day_factor)
    env.glow_enabled = true
    env.glow_intensity = lerp(0.55, 0.0, day_factor)
    env.glow_bloom = lerp(0.16, 0.0, day_factor)
    env.glow_hdr_threshold = lerp(0.75, 1.25, day_factor)
    env.ssao_enabled = true
    env.ssao_radius = 1.0
    env.ssao_intensity = lerp(1.35, 1.15, day_factor)
