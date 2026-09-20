class_name HWMaterialIntegrityDirector
extends Node3D

## Runtime material/visual integrity guard.
## Repairs missing mesh-surface materials without replacing valid authored materials.
## It also adds conservative detail to otherwise unshaded fallback geometry.

@export var scan_interval:float=2.0
@export var repair_missing_materials:bool=true
@export var repair_empty_mesh_surfaces:bool=true

var _elapsed:float=0.0
var _repaired:int=0

func _ready()->void:
    call_deferred("_scan_and_repair")

func _process(delta:float)->void:
    _elapsed+=delta
    if _elapsed>=max(scan_interval,0.25):
        _elapsed=0.0
        _scan_and_repair()

func _scan_and_repair()->void:
    if not is_inside_tree():
        return
    _repaired=0
    var root:Node=get_tree().current_scene
    if root==null:
        root=get_parent()
    if root==null:
        return
    _walk(root)
    if _repaired>0:
        print("HW_MATERIAL_INTEGRITY: repaired %d missing/empty visual materials" % _repaired)

func _walk(node:Node)->void:
    if node is GeometryInstance3D:
        _repair_geometry(node as GeometryInstance3D)
    for child:Node in node.get_children():
        _walk(child)

func _repair_geometry(instance:GeometryInstance3D)->void:
    if instance.material_override==null and repair_missing_materials:
        # Do not manufacture an override when the mesh already has valid surfaces.
        var mesh:Mesh=instance.get("mesh") as Mesh
        if mesh==null:
            return
    var mesh:Mesh=instance.get("mesh") as Mesh
    if mesh==null:
        return
    var surface_count:int=mesh.get_surface_count()
    for surface:int in range(surface_count):
        var current:Material=mesh.surface_get_material(surface)
        if current!=null:
            continue
        if not repair_empty_mesh_surfaces:
            continue
        var fallback:=_make_fallback_material(str(instance.name),surface)
        mesh.surface_set_material(surface,fallback)
        _repaired+=1
    if instance.material_override==null and _has_no_surface_materials(mesh) and repair_missing_materials:
        instance.material_override=_make_fallback_material(str(instance.name),0)
        _repaired+=1

func _has_no_surface_materials(mesh:Mesh)->bool:
    if mesh.get_surface_count()==0:
        return false
    for surface:int in range(mesh.get_surface_count()):
        if mesh.surface_get_material(surface)!=null:
            return false
    return true

func _make_fallback_material(node_name:String,surface:int)->StandardMaterial3D:
    var material:=StandardMaterial3D.new()
    material.resource_name="HWAutoMaterial_%s_%d" % [node_name,surface]
    material.albedo_color=_fallback_color(node_name)
    material.metallic=0.05
    material.roughness=0.62
    material.cull_mode=BaseMaterial3D.CULL_BACK
    return material

func _fallback_color(node_name:String)->Color:
    var key:String=node_name.to_lower()
    if "hero" in key or "character" in key or "player" in key:
        return Color("#6b8fc4")
    if "monster" in key or "boss" in key:
        return Color("#9b5c55")
    if "tree" in key or "grass" in key or "leaf" in key:
        return Color("#5e8b52")
    if "road" in key or "ground" in key or "terrain" in key:
        return Color("#8a755c")
    if "water" in key:
        return Color("#4f83a6")
    if "stone" in key or "wall" in key:
        return Color("#777b82")
    if "gold" in key or "coin" in key:
        return Color("#c7a64a")
    return Color("#9aa1aa")
