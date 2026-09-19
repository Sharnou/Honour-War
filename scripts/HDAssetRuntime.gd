class_name HDAssetRuntime
extends Node3D

## Honour War production visual bridge.
## HD generated GLB assets were permanently retired from the project.
## Daily upgrades must NOT regenerate, download, import, or attach GLB assets.
## Gameplay visuals are supplied by the native Godot runtime scene/visual systems.
##
## The Screenshot/ folder remains the authoritative visual reference. Future
## visual work must improve native Godot geometry/material/VFX systems directly.

var game:Node3D
var legacy:Node
var audit_elapsed:float = 0.0

func _ready()->void:
    game = get_parent() as Node3D
    process_priority = 100
    set_process(true)
    call_deferred("_audit_runtime_geometry")

func _process(delta:float)->void:
    if game == null or not is_instance_valid(game):
        game = get_parent() as Node3D
    if game == null:
        return
    legacy = game.get_node_or_null("LegacyGame") as Node
    audit_elapsed += delta
    if audit_elapsed >= 0.25:
        audit_elapsed = 0.0
        _audit_runtime_geometry()

func _audit_runtime_geometry()->void:
    var scene_root:Node = get_tree().current_scene
    if scene_root == null:
        return
    var repaired:int = 0
    for node:Node in scene_root.find_children("*", "GeometryInstance3D", true, false):
        var geometry:GeometryInstance3D = node as GeometryInstance3D
        if geometry == null:
            continue
        if geometry is MeshInstance3D:
            var mesh_instance:MeshInstance3D = geometry as MeshInstance3D
            if mesh_instance.mesh == null:
                continue
            if mesh_instance.material_override == null:
                var has_material:bool = false
                for surface:int in mesh_instance.mesh.get_surface_count():
                    var material:Material = mesh_instance.get_surface_override_material(surface)
                    if material == null:
                        material = mesh_instance.mesh.surface_get_material(surface)
                    if material != null:
                        has_material = true
                        break
                if not has_material and mesh_instance.mesh.get_surface_count() == 0:
                    mesh_instance.material_override = _runtime_fallback_material()
                    repaired += 1
                else:
                    for surface:int in mesh_instance.mesh.get_surface_count():
                        var material:Material = mesh_instance.get_surface_override_material(surface)
                        if material == null:
                            material = mesh_instance.mesh.surface_get_material(surface)
                        if material == null:
                            mesh_instance.set_surface_override_material(surface, _runtime_fallback_material())
                            repaired += 1
        elif geometry is MultiMeshInstance3D:
            var multi:MultiMeshInstance3D = geometry as MultiMeshInstance3D
            if multi.multimesh != null and multi.multimesh.mesh != null and multi.material_override == null:
                var has_material:bool = false
                for surface:int in multi.multimesh.mesh.get_surface_count():
                    if multi.multimesh.mesh.surface_get_material(surface) != null:
                        has_material = true
                        break
                if not has_material:
                    multi.material_override = _runtime_fallback_material()
                    repaired += 1
    for node:Node in scene_root.find_children("*", "GPUParticles3D", true, false):
        var particles:GPUParticles3D = node as GPUParticles3D
        if particles == null:
            continue
        for pass_index:int in 4:
            var draw_mesh:Mesh = particles.get_draw_pass_mesh(pass_index)
            if draw_mesh == null:
                continue
            for surface:int in draw_mesh.get_surface_count():
                if draw_mesh.surface_get_material(surface) == null:
                    draw_mesh.surface_set_material(surface, _runtime_fallback_material())
                    repaired += 1
    if repaired > 0:
        scene_root.set_meta("hw_scene_null_materials_repaired", repaired)

func _runtime_fallback_material()->StandardMaterial3D:
    var fallback := StandardMaterial3D.new()
    fallback.albedo_color = Color("#9aa1aa")
    fallback.metallic = 0.15
    fallback.roughness = 0.58
    return fallback
