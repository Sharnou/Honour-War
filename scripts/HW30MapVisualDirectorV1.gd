extends Node3D
## Honour War HD 30-map visual content director V1.
## Adds map-specific landmarks/material cues for every registered map.
## Native Godot only; does not own gameplay state.

const Teleport=preload("res://scripts/TeleportSystem.gd")
var game:Node3D
var root:Node3D
var built_map:int=-1

func _ready()->void:
    game=get_parent() as Node3D
    process_priority=915
    call_deferred("_rebuild")

func _process(_delta:float)->void:
    if game==null: return
    var legacy:=game.get_node_or_null("LegacyGame")
    if legacy==null: return
    var h:Variant=legacy.get("hero")
    if not h is Dictionary: return
    var id:=int(h.get("map_id",0))
    if id!=built_map: _rebuild()

func _rebuild()->void:
    var legacy:=game.get_node_or_null("LegacyGame")
    if legacy==null: return
    var h:Variant=legacy.get("hero")
    if not h is Dictionary: return
    var id:=int(h.get("map_id",0))
    built_map=id
    if root!=null and is_instance_valid(root): root.queue_free()
    root=Node3D.new(); root.name="HW30MapVisual_"+str(id); game.add_child(root)
    var data:Dictionary=Teleport.MAPS.get(id,{})
    var center:=Vector3((float(data.get("spawn_x",600))-365.0)*0.055,0.0,(float(data.get("spawn_y",350))-120.0)*0.055)
    var accent:=_accent(id)
    _landmark(center,accent,Teleport.map_name(id))
    for i in range(10):
        var marker:=MeshInstance3D.new(); marker.name="MapDetail_%02d"%i
        var mesh:=CylinderMesh.new(); mesh.top_radius=0.03; mesh.bottom_radius=0.12; mesh.height=0.35+float((i+id)%4)*0.12; mesh.radial_segments=12
        marker.mesh=mesh
        marker.position=center+Vector3(float(i-5)*1.8,0.22,float((i*7+id*3)%9-4))
        marker.material_override=_mat(accent.lightened(float(i%3)*0.06),0.20,0.42)
        root.add_child(marker)

func _landmark(center:Vector3,c:Color,label:String)->void:
    var base:=MeshInstance3D.new(); var bm:=CylinderMesh.new(); bm.top_radius=1.2; bm.bottom_radius=1.45; bm.height=0.22; bm.radial_segments=32; base.mesh=bm; base.position=center+Vector3(0,0.11,0); base.material_override=_mat(c.darkened(0.25),0.30,0.40); root.add_child(base)
    var sp:=MeshInstance3D.new(); var sm:=SphereMesh.new(); sm.radius=0.38; sm.height=0.76; sm.radial_segments=24; sm.rings=16; sp.mesh=sm; sp.position=center+Vector3(0,0.78,0); sp.material_override=_mat(c,0.35,0.22); root.add_child(sp)
    var text:=Label3D.new(); text.text=label; text.font_size=14; text.outline_size=4; text.position=center+Vector3(0,1.35,0); text.modulate=c.lightened(0.30); root.add_child(text)

func _accent(id:int)->Color:
    if id in [3,13,23]: return Color("#d99a4b")
    if id in [8,15,28]: return Color("#b8efff")
    if id in [9,18,26,29]: return Color("#7fe39a")
    if id in [4,5,17,24,25]: return Color("#73cfff")
    if id in [7,16,27]: return Color("#e3b85d")
    if id in [10,11,14,19]: return Color("#a98ac7")
    return Color("#d8c078")

func _mat(c:Color,metal:float,rough:float)->StandardMaterial3D:
    var m:=StandardMaterial3D.new(); m.albedo_color=c; m.metallic=metal; m.roughness=rough; return m
