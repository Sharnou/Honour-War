class_name HDEquipmentVisualDriver
extends Node3D

## Converts equipped item data into visible world equipment for the fallback hero.
## Production GLB/GLTF characters remain authoritative and are not rebuilt.
var game:Node
var current_signature:String=""
var visual_root:Node3D

func _ready()->void:
    game=get_parent()
    set_process(true)

func _process(_delta:float)->void:
    if game==null: return
    var hero_visual:Node3D=game.get("hero_visual") as Node3D
    var legacy:Node=game.get("legacy") as Node
    if hero_visual==null or legacy==null: return
    if bool(hero_visual.get_meta("hw_production_asset",false)): return
    var value:Variant=legacy.get("hero")
    if not value is Dictionary: return
    var hero:Dictionary=value
    var equipment_value:Variant=hero.get("equipment",{})
    if not equipment_value is Dictionary: return
    var equipment:Dictionary=equipment_value
    var signature:String=""
    for slot in ["weapon","head","armor","garment","shoes","offhand"]:
        var item:Variant=equipment.get(slot,null)
        signature+=slot+":"+_item_name(item)+";"
    if signature==current_signature: return
    current_signature=signature
    _rebuild(hero_visual,equipment)

func _rebuild(hero:Node3D,equipment:Dictionary)->void:
    if visual_root!=null and is_instance_valid(visual_root):
        visual_root.queue_free()
    visual_root=Node3D.new()
    visual_root.name="HW_EquipmentVisuals"
    hero.add_child(visual_root)
    _add_weapon(visual_root,_item_name(equipment.get("weapon",null)))
    _add_headgear(visual_root,_item_name(equipment.get("head",null)))
    _add_armor(visual_root,_item_name(equipment.get("armor",null)))
    _add_garment(visual_root,_item_name(equipment.get("garment",null)))
    _add_shoes(visual_root,_item_name(equipment.get("shoes",null)))
    _add_offhand(visual_root,_item_name(equipment.get("offhand",null)))

func _item_name(value:Variant)->String:
    if value is Dictionary:
        return str(value.get("id",value.get("name","")))
    return str(value) if value!=null else ""

func _add_weapon(root:Node3D,name:String)->void:
    var lower:=name.to_lower()
    var mat:=_mat(Color("#bdc7d0"),0.80,0.22)
    var accent:=_mat(Color("#c98f3f"),0.35,0.30)
    if lower=="" or lower=="novice weapon": return
    if lower.contains("staff"):
        var staff:=_cyl(mat,0.055,1.55,Vector3(0.66,1.25,0),24)
        root.add_child(staff)
        var gem:=_sphere(accent,0.11,Vector3(0.66,2.05,0))
        root.add_child(gem)
    elif lower.contains("bow"):
        var bow:=_torus(accent,0.38,0.035)
        bow.rotation_degrees=Vector3(0,90,0)
        bow.position=Vector3(0.58,1.48,0)
        root.add_child(bow)
        var string:=_box(mat,Vector3(0.02,0.72,0.02),Vector3(0.58,1.48,0))
        root.add_child(string)
    elif lower.contains("mace") or lower.contains("hammer"):
        var handle:=_cyl(mat,0.055,1.0,Vector3(0.63,1.18,0),20)
        handle.rotation_degrees.z=-12.0
        root.add_child(handle)
        var head:=_box(accent,Vector3(0.28,0.22,0.24),Vector3(0.73,1.72,0))
        root.add_child(head)
    else:
        var blade:=_box(mat,Vector3(0.11,1.20,0.20),Vector3(0.67,1.50,0))
        blade.rotation_degrees.z=12.0
        root.add_child(blade)
        var guard:=_box(accent,Vector3(0.38,0.08,0.10),Vector3(0.66,0.95,0))
        root.add_child(guard)

func _add_headgear(root:Node3D,name:String)->void:
    var lower:=name.to_lower()
    if lower=="": return
    var metal:=_mat(Color("#9ca9b4"),0.82,0.24)
    var accent:=_mat(Color("#c8a75d"),0.45,0.28)
    if lower.contains("helm") or lower.contains("crown") or lower.contains("cap") or lower.contains("visor"):
        var helm:=_sphere(metal,0.43,Vector3(0,2.55,0))
        helm.scale=Vector3(1.04,0.62,1.02)
        root.add_child(helm)
    elif lower.contains("hood") or lower.contains("circlet") or lower.contains("halo"):
        var ring:=_torus(accent,0.35,0.035)
        ring.rotation_degrees.x=90.0
        ring.position=Vector3(0,2.53,0)
        root.add_child(ring)

func _add_armor(root:Node3D,name:String)->void:
    if name=="": return
    var heavy:bool=name.to_lower().contains("dragon") or name.to_lower().contains("emperor") or name.to_lower().contains("war")
    var metal:=_mat(Color("#66727f") if heavy else Color("#5a6571"),0.80,0.25)
    var plate:=_sphere(metal,0.52,Vector3(0,1.52,-0.08))
    plate.scale=Vector3(1.10,0.82,0.62)
    root.add_child(plate)

func _add_garment(root:Node3D,name:String)->void:
    if name=="": return
    var cape:=_box(_mat(Color("#2e3540"),0.12,0.78),Vector3(0.92,1.10,0.07),Vector3(0,1.48,0.34))
    cape.name="HW_VisibleGarment"
    root.add_child(cape)

func _add_shoes(root:Node3D,name:String)->void:
    if name=="": return
    var mat:=_mat(Color("#2a3038"),0.70,0.34)
    for x in [-0.20,0.20]:
        var boot:=_box(mat,Vector3(0.34,0.22,0.54),Vector3(x,0.10,-0.08))
        root.add_child(boot)

func _add_offhand(root:Node3D,name:String)->void:
    var lower:=name.to_lower()
    if lower=="" or lower.contains("novice") and not lower.contains("shield"): return
    var shield:=_cyl(_mat(Color("#8593a0"),0.78,0.25),0.43,0.09,Vector3(-0.70,1.22,0.06),32)
    shield.rotation_degrees.x=90.0
    root.add_child(shield)

func _mat(color:Color,metallic:float,roughness:float)->StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.albedo_color=color
    m.metallic=metallic
    m.roughness=roughness
    return m

func _cyl(mat:Material,radius:float,height:float,pos:Vector3,segments:int)->MeshInstance3D:
    var n:=MeshInstance3D.new()
    var m:=CylinderMesh.new()
    m.top_radius=radius
    m.bottom_radius=radius
    m.height=height
    m.radial_segments=segments
    n.mesh=m
    n.position=pos
    n.material_override=mat
    return n

func _sphere(mat:Material,radius:float,pos:Vector3)->MeshInstance3D:
    var n:=MeshInstance3D.new()
    var m:=SphereMesh.new()
    m.radius=radius
    m.height=radius*2.0
    n.mesh=m
    n.position=pos
    n.material_override=mat
    return n

func _box(mat:Material,size:Vector3,pos:Vector3)->MeshInstance3D:
    var n:=MeshInstance3D.new()
    var m:=BoxMesh.new()
    m.size=size
    n.mesh=m
    n.position=pos
    n.material_override=mat
    return n

func _torus(mat:Material,inner:float,width:float)->MeshInstance3D:
    var n:=MeshInstance3D.new()
    var m:=TorusMesh.new()
    m.inner_radius=inner
    m.outer_radius=inner+width
    n.mesh=m
    n.material_override=mat
    return n
