class_name GraphicsQualityProfile
extends Node

## Hardware-aware quality profiles for Compatibility/OpenGL systems.

const PROFILES := {
    "low": {"shadow": false, "particles": 0.45, "effects": 0.45, "view_distance": 0.65, "resolution_scale": 0.75},
    "balanced": {"shadow": false, "particles": 0.70, "effects": 0.70, "view_distance": 0.85, "resolution_scale": 0.90},
    "high": {"shadow": true, "particles": 1.0, "effects": 1.0, "view_distance": 1.0, "resolution_scale": 1.0}
}

var active_profile := "balanced"

func set_profile(profile: String) -> void:
    if not PROFILES.has(profile):
        return
    active_profile = profile
    _apply(PROFILES[profile])

func get_profile() -> Dictionary:
    return PROFILES.get(active_profile, PROFILES["balanced"])

func _ready() -> void:
    set_profile(active_profile)

func _apply(profile: Dictionary) -> void:
    var root := get_tree().root
    if root == null:
        return
    root.set_meta("graphics_quality", active_profile)
    root.set_meta("graphics_profile", profile)
    RenderingServer.set_default_clear_color(Color("10131b"))
    var env := get_tree().current_scene
    if env != null:
        env.set_meta("particle_budget", profile["particles"])
        env.set_meta("effect_budget", profile["effects"])
        env.set_meta("view_distance_scale", profile["view_distance"])
