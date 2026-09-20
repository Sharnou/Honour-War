extends Node3D

## Honour War anime/cel material bridge.
## Converts authored StandardMaterial3D surfaces to ToonShader.gdshader while
## preserving albedo, roughness, and normal textures when those maps exist.

const TOON_SHADER_PATH:String = "res://shaders/ToonShader.gdshader"
const MATERIAL_GUARD_INTERVAL:float = 0.15
var shader:Shader
var processed:Dictionary = {}
var timer:float = 0.0
var forward_plus:bool = false
var fallback_material:StandardMaterial3D

func _ready()->void:
    # Deterministic EXE gameplay smoke validates rules, not toon conversion.
    # Avoid renderer material churn during its forced shutdown path.
    if "--qa-smoke-test" in OS.get_cmdline_args():
        set_process(false)
        return
    forward_plus = RenderingServer.get_current_rendering_method() == "forward_plus"
    if not forward_plus:
        return
    shader = load(TOON_SHADER_PATH) as Shader
    fallback_material = _create_fallback_material()
    call_deferred("_scan_scene")
    set_process(false)

func _process(_delta:float)->void:
    pass

func _scan_scene()->void:
    var scene:Node = get_tree().current_scene
    if scene == null:
        return
    _ensure_material_integrity(scene)
    if shader == null:
        return
    _scan_node(scene)

func _create_fallback_material()->StandardMaterial3D:
    var fallback:StandardMaterial3D = StandardMaterial3D.new()
    fallback.albedo_color = Color("#9aa1aa")
    fallback.metallic = 0.15
    fallback.roughness = 0.58
    return fallback

func _fallback_material()->StandardMaterial3D:
    if fallback_material == null:
        fallback_material = _create_fallback_material()
    return fallback_material

func _ensure_material_integrity(root:Node)->void:
    if root == null or not is_instance_valid(root):
        return
    for node in root.find_children("*", "MeshInstance3D", true, false):
        var mesh_instance:MeshInstance3D = node as MeshInstance3D
        if mesh_instance == null or not is_instance_valid(mesh_instance):
            continue
        var source_mesh:Mesh = mesh_instance.mesh
        if source_mesh == null or source_mesh.get_surface_count() <= 0:
            continue
        for surface_index in range(source_mesh.get_surface_count()):
            var active:Material = mesh_instance.get_active_material(surface_index)
            if active == null:
                active = source_mesh.surface_get_material(surface_index)
            if active == null:
                mesh_instance.set_surface_override_material(surface_index, _fallback_material())
    for node in root.find_children("*", "MultiMeshInstance3D", true, false):
        var multi:MultiMeshInstance3D = node as MultiMeshInstance3D
        if multi == null or not is_instance_valid(multi):
            continue
        if multi.multimesh == null or multi.multimesh.mesh == null:
            continue
        var base_mesh:Mesh = multi.multimesh.mesh
        var material:Material = multi.material_override
        if material == null and base_mesh.get_surface_count() > 0:
            material = base_mesh.surface_get_material(0)
        if material == null:
            multi.material_override = _fallback_material()
    for node in root.find_children("*", "GeometryInstance3D", true, false):
        var geometry:GeometryInstance3D = node as GeometryInstance3D
        if geometry == null or not is_instance_valid(geometry):
            continue
        if geometry is MeshInstance3D or geometry is MultiMeshInstance3D:
            continue
        if geometry.material_override == null:
            geometry.material_override = _fallback_material()

func _scan_node(node:Node)->void:
    if node is MeshInstance3D:
        _convert_mesh(node as MeshInstance3D)
    for child in node.get_children():
        _scan_node(child)

func _convert_mesh(mesh:MeshInstance3D)->void:
    if mesh == null or not is_instance_valid(mesh):
        return
    if mesh.get_meta("hw_toon_processed", false):
        return
    var source_mesh:Mesh = mesh.mesh
    if source_mesh == null or source_mesh.get_surface_count() <= 0:
        return
    var surface_count:int = source_mesh.get_surface_count()
    for surface_index in range(surface_count):
        var source_material:Material = mesh.get_active_material(surface_index)
        if source_material == null:
            source_material = source_mesh.surface_get_material(surface_index)
        if source_material == null:
            mesh.set_surface_override_material(surface_index, _fallback_material())
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
        if toon.shader == null:
            mesh.set_surface_override_material(surface_index, _fallback_material())
            continue
        mesh.set_surface_override_material(surface_index, toon)
    mesh.set_meta("hw_toon_processed", true)
