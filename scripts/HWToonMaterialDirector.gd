extends Node3D

## Honour War anime/cel material bridge.
## Converts authored StandardMaterial3D surfaces to ToonShader.gdshader while
## preserving albedo, roughness, and normal textures when those maps exist.

const TOON_SHADER_PATH:String = "res://shaders/ToonShader.gdshader"
var shader:Shader
var processed:Dictionary = {}
var timer:float = 0.0
var forward_plus:bool = false

func _ready()->void:
    # The authored toon shader is a production Forward+ presentation feature.
    # Compatibility/headless QA uses Godot's dummy material backend; applying
    # instance-uniform shader materials there can trigger null-material queries
    # even though the authored StandardMaterial3D source is valid. Keep QA on
    # the original material path while preserving the full toon pipeline in
    # the actual Forward+ game.
    forward_plus = RenderingServer.get_current_rendering_method() == "forward_plus"
    if not forward_plus:
        return
    shader = load(TOON_SHADER_PATH) as Shader
    call_deferred("_scan_scene")

func _process(delta:float)->void:
    timer += delta
    if timer < 1.0:
        return
    timer = 0.0
    _scan_scene()

func _scan_scene()->void:
    if shader == null:
        return
    var scene:Node = get_tree().current_scene
    if scene == null:
        return
    _scan_node(scene)

func _scan_node(node:Node)->void:
    if node is MeshInstance3D:
        _convert_mesh(node as MeshInstance3D)
    for child in node.get_children():
        _scan_node(child)

func _convert_mesh(mesh:MeshInstance3D)->void:
    if mesh.get_meta("hw_toon_processed", false):
        return
    if mesh.mesh == null or mesh.mesh.get_surface_count() <= 0:
        return
    var surface_count:int = mesh.mesh.get_surface_count()
    for surface_index in range(surface_count):
        var source_material:Material = mesh.get_active_material(surface_index)
        if source_material == null:
            source_material = mesh.mesh.surface_get_material(surface_index)
        if source_material == null:
            continue
        if source_material is ShaderMaterial:
            var existing_shader:Shader = (source_material as ShaderMaterial).shader
            if existing_shader == shader:
                continue
        if not source_material is StandardMaterial3D:
            continue
        var source:StandardMaterial3D = source_material as StandardMaterial3D
        var toon:ShaderMaterial = ShaderMaterial.new()
        toon.shader = shader
        toon.set_shader_parameter("albedo", source.albedo_color)
        toon.set_shader_parameter("roughness", source.roughness)
        toon.set_shader_parameter("cuts", 3)
        toon.set_shader_parameter("wrap", 0.04)
        toon.set_shader_parameter("steepness", 55.0)
        toon.set_shader_parameter("specular_strength", 0.55)
        if source.albedo_texture != null:
            toon.set_shader_parameter("texture_albedo", source.albedo_texture)
            toon.set_shader_parameter("use_albedo_texture", true)
        if source.roughness_texture != null:
            toon.set_shader_parameter("texture_roughness", source.roughness_texture)
            toon.set_shader_parameter("use_roughness_texture", true)
        if source.normal_texture != null:
            toon.set_shader_parameter("texture_normal", source.normal_texture)
            toon.set_shader_parameter("use_normal_texture", true)
            toon.set_shader_parameter("normal_scale", source.normal_scale)
        mesh.set_surface_override_material(surface_index, toon)
    mesh.set_meta("hw_toon_processed", true)
