extends Node3D

## Connected warps: each town exposes nearby field/dungeon portals and every dungeon
## returns to its linked town. Interaction is click-friendly and also callable by HUDs.
const Teleport = preload("res://scripts/TeleportSystem.gd")

const CONNECTIONS:Dictionary = {
    0: [10, 11],
    1: [11, 14],
    2: [12, 16],
    3: [13, 19],
    4: [17, 10],
    5: [17, 19],
    6: [18, 17],
    7: [16, 12],
    8: [15, 18],
    9: [18, 13]
}

var game:Node3D
var legacy:Node
var warp_root:Node3D
var active_map:int=-1
var visual_cache:Dictionary={}
var pulse:float=0.0

func _ready()->void:
    game=get_parent() as Node3D
    call_deferred("_bind")

func _process(delta:float)->void:
    pulse+=delta
    if legacy==null or not is_instance_valid(legacy):
        _bind()
        return
    var value:Variant=legacy.get("hero")
    if not value is Dictionary:
        return
    var map_id:int=int((value as Dictionary).get("map_id",0))
    if map_id!=active_map:
        active_map=map_id
        _rebuild(map_id)
    _animate()

func _bind()->void:
    if game==null:
        game=get_parent() as Node3D
    if game==null:
        return
    legacy=game.get_node_or_null("LegacyGame")
    if warp_root==null:
        warp_root=Node3D.new()
        warp_root.name="HWWarpNetwork"
        game.add_child(warp_root)
    call_deferred("_refresh_map")

func _refresh_map()->void:
    if legacy==null:
        legacy=game.get_node_or_null("LegacyGame")
    if legacy==null:
        return
    var value:Variant=legacy.get("hero")
    if value is Dictionary:
        active_map=int((value as Dictionary).get("map_id",0))
        _rebuild(active_map)

func _rebuild(map_id:int)->void:
    if warp_root==null:
        return
    for child in warp_root.get_children():
        child.queue_free()
    visual_cache.clear()
    var links:Array=CONNECTIONS.get(map_id,[])
    if links.is_empty():
        var town:int=int(Teleport.MAPS.get(map_id,{}).get("entrance",-1))
        if town>=0:
            links=[town]
    for i in range(links.size()):
        var target:int=int(links[i])
        _create_warp(target,i,links.size())

func _create_warp(target_map:int,index:int,total:int)->void:
    var gate:Node3D=Node3D.new()
    gate.name="Warp_"+str(target_map)
    var angle:float=-PI*0.5+((float(index)-float(total-1)*0.5)*0.95)
    gate.position=Vector3(20.4+cos(angle)*5.8,0.06,8.2+sin(angle)*5.8)
    warp_root.add_child(gate)

    var ring:MeshInstance3D=MeshInstance3D.new()
    var ring_mesh:TorusMesh=TorusMesh.new()
    ring_mesh.inner_radius=0.82
    ring_mesh.outer_radius=0.91
    ring_mesh.rings=56
    ring_mesh.ring_segments=12
    ring.mesh=ring_mesh
    ring.rotation_degrees.x=90
    ring.material_override=_glow_material(_target_color(target_map))
    gate.add_child(ring)

    var arch:MeshInstance3D=MeshInstance3D.new()
    var arch_mesh:CylinderMesh=CylinderMesh.new()
    arch_mesh.top_radius=1.18
    arch_mesh.bottom_radius=1.18
    arch_mesh.height=0.16
    arch_mesh.radial_segments=48
    arch.mesh=arch_mesh
    arch.position.y=0.22
    arch.material_override=_stone_material()
    gate.add_child(arch)

    var label:Label3D=Label3D.new()
    label.text="WARP  →  "+Teleport.map_name(target_map)
    label.position=Vector3(0,1.55,0)
    label.font_size=22
    label.outline_size=7
    label.modulate=Color("#fff0b0")
    label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
    gate.add_child(label)
    visual_cache[target_map]=gate

func _animate()->void:
    for key in visual_cache.keys():
        var gate:Node3D=visual_cache[key] as Node3D
        if gate==null or not is_instance_valid(gate):
            continue
        var ring:MeshInstance3D=gate.get_child(0) as MeshInstance3D
        if ring!=null:
            var s:float=1.0+sin(pulse*2.0+float(int(key)))*0.08
            ring.scale=Vector3.ONE*s

func use_warp(target_map:int)->bool:
    if legacy==null:
        return false
    if not Teleport.MAPS.has(target_map):
        return false
    var command:String="@go "+str(target_map)
    if legacy.has_method("handle_command"):
        legacy.call("handle_command",command)
        return true
    return false

func _target_color(map_id:int)->Color:
    var data:Dictionary=Teleport.MAPS.get(map_id,{})
    var type:String=str(data.get("type","town"))
    if type=="dungeon":
        return Color("#8c6dff")
    return Color("#75d9a0")

func _glow_material(color:Color)->StandardMaterial3D:
    var m:StandardMaterial3D=StandardMaterial3D.new()
    m.albedo_color=color
    m.emission_enabled=true
    m.emission=color
    m.emission_energy_multiplier=1.7
    m.roughness=0.25
    return m

func _stone_material()->StandardMaterial3D:
    var m:StandardMaterial3D=StandardMaterial3D.new()
    m.albedo_color=Color("#6c6257")
    m.roughness=0.92
    return m
