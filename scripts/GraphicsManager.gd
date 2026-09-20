extends Node

## Honour War graphics presets for Godot 4.7.x.
## F1 = Low, F2 = Medium, F3 = HD. HD keeps native-resolution temporal upscaling and full shadow/AO presentation.

signal preset_changed(preset_name:String)

enum Preset { LOW, MEDIUM, HD }

var current_preset:Preset = Preset.HD
var world_environment:WorldEnvironment
var sun_light:DirectionalLight3D

func _ready()->void:
    call_deferred("_resolve_scene_links")

func _unhandled_input(event:InputEvent)->void:
    if event.is_action_pressed("graphics_preset_low"):
        apply_preset(Preset.LOW)
    elif event.is_action_pressed("graphics_preset_med"):
        apply_preset(Preset.MEDIUM)
    elif event.is_action_pressed("graphics_preset_hd"):
        apply_preset(Preset.HD)

func _resolve_scene_links()->void:
    var scene:Node = get_tree().current_scene
    if scene == null:
        return
    world_environment = scene.find_child("HWVisualMaxEnvironment", true, false) as WorldEnvironment
    if world_environment == null:
        world_environment = scene.find_child("WorldEnvironment", true, false) as WorldEnvironment
    sun_light = scene.find_child("HWVisualMaxSun", true, false) as DirectionalLight3D
    if sun_light == null:
        sun_light = scene.find_child("Sun", true, false) as DirectionalLight3D
    apply_preset(Preset.HD)

func apply_preset(preset:Preset)->void:
    current_preset = preset
    var window:Window = get_window()
    if window != null:
        var compatibility := RenderingServer.get_current_rendering_method() == "gl_compatibility"
        match preset:
            Preset.LOW:
                window.scaling_3d_mode = 0
                window.scaling_3d_scale = 0.70
            Preset.MEDIUM:
                window.scaling_3d_mode = 0 if compatibility else 2
                window.scaling_3d_scale = 0.85
            Preset.HD:
                window.scaling_3d_mode = 0 if compatibility else 2
                window.scaling_3d_scale = 1.0

    if world_environment == null or world_environment.environment == null:
        preset_changed.emit(_preset_name())
        return

    var env:Environment = world_environment.environment
    match preset:
        Preset.LOW:
            env.ssao_enabled = false
            env.glow_enabled = false
            env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
            env.tonemap_exposure = -0.65
            if sun_light != null:
                sun_light.shadow_enabled = false
        Preset.MEDIUM:
            env.ssao_enabled = true
            env.ssao_radius = 1.5
            env.ssao_intensity = 1.0
            env.glow_enabled = false
            env.glow_intensity = 0.0
            env.glow_bloom = 0.0
            env.glow_hdr_threshold = 1.35
            env.tonemap_mode = Environment.TONE_MAPPER_ACES
            env.tonemap_exposure = -0.80
            if sun_light != null:
                sun_light.shadow_enabled = true
                sun_light.shadow_bias = 0.04
        Preset.HD:
            env.ssao_enabled = true
            env.ssao_radius = 2.2
            env.ssao_intensity = 1.15
            env.glow_enabled = true
            env.glow_intensity = 0.30
            env.glow_bloom = 0.06
            env.glow_hdr_threshold = 1.35
            env.tonemap_mode = Environment.TONE_MAPPER_ACES
            env.tonemap_exposure = -0.90
            if sun_light != null:
                sun_light.shadow_enabled = true
                sun_light.shadow_bias = 0.025

    preset_changed.emit(_preset_name())

func _preset_name()->String:
    match current_preset:
        Preset.LOW: return "LOW"
        Preset.MEDIUM: return "MEDIUM"
        _: return "HD"

func is_low()->bool: return current_preset == Preset.LOW
func is_medium()->bool: return current_preset == Preset.MEDIUM
func is_hd()->bool: return current_preset == Preset.HD
