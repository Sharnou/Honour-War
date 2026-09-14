extends Node3D

## Connected warps: towns expose both a field and dungeon route. Fields expose their
## town and a dungeon route. Dungeons always expose a return-to-town warp.
const Teleport = preload("res://scripts/TeleportSystem.gd")

const CONNECTIONS:Dictionary = {
    0:[20,10,11], 1:[21,11,14], 2:[22,12,16], 3:[23,13,19], 4:[24,17,10],
    5:[25,17,19], 6:[26,18,17], 7:[27,16,12], 8:[28,15,18], 9:[29,18,13],
    20:[0,10],21:[1,11],22:[2,12],23:[3,13],24:[4,17],25:[5,17],26:[6,18],27:[7,16],28:[8,15],29:[9,18]
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
    if game==null: game=get_parent() as Node3D
    if game==null: return
    legacy=game.get_node_or_null("LegacyGame")
    if warp_root==null:
        warp_root=Node3D.new()
        warp_root.name="HWWarpNetwork"
        game.add_child(warp_root)
    call_deferred("_refresh_map")

func _refresh_map()->void:
    if legacy==null: legacy=game.get_node_or_null("LegacyGame")
    if legacy==null: return
    var value:Variant=legacy.get("hero")
    if value is Dictionary:
        active_map=int((value as Dictionary).get("map_id",0))
        _rebuild(active_map)

func _rebuild(map_id:int)->void:
    if warp_root==null: return
    for child in warp_root.get_children(): child.queue_free()
    visual_cache.clear()
    var links:Array=CONNECTIONS.get(map_id,[])
    if links.is_empty():
        var town:int=Teleport.town_for_dungeon(map_id)
        if town<0: town=Teleport.town_for_field(map_id)
        if town>=0: links=[town]
    for i in range(links.size()): _create_warp(int(links[i]),i,links.size())

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

    var core:MeshInstance3D=MeshInstance3D.new()
    var core_mesh:CylinderMesh=CylinderMesh.new()
    core_mesh.top_radius=0.62
    core_mesh.bottom_radius=0.62
    core_mesh.height=0.08
    core.mesh=core_mesh
    core.position.y=0.08
    core.material_override=_glow_material(_target_color(target_map).darkened(0.30))
    gate.add_child(core)

    var label:Label3D=Label3D.new()
    label.text="WARP  →  "+Teleport.map_name(target_map)
    label.position=Vector3(0,1.55,0)
    label.font_size=22
    label.outline_size=7
    label.modulate=Color("#fff0b0")
    label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
    gate.add_child(label)

    var area:Area3D=Area3D.new()
    area.name="WarpInteraction"
    area.position.y=0.65
    area.input_ray_pickable=true
    var shape:CollisionShape3D=CollisionShape3D.new()
    var sphere:SphereShape3D=SphereShape3D.new()
    sphere.radius=1.15
    shape.shape=sphere
    area.add_child(shape)
    area.input_event.connect(_on_warp_input.bind(target_map))
    gate.add_child(area)
    visual_cache[target_map]=gate

func _on_warp_input(_camera:Node,_event:InputEvent,_position:Vector3,_normal:Vector3,target_map:int)->void:
    if _event is InputEventMouseButton:
        var mouse:InputEventMouseButton=_event as InputEventMouseButton
        if mouse.pressed and mouse.button_index==MOUSE_BUTTON_LEFT:
            use_warp(target_map)

func _animate()->void:
    for key in visual_cache.keys():
        var gate:Node3D=visual_cache[key] as Node3D
        if gate==null or not is_instance_valid(gate): continue
        var ring:MeshInstance3D=gate.get_node_or_null("MeshInstance3D") as MeshInstance3D
        if ring!=null:
            var s:float=1.0+sin(pulse*2.0+float(int(key)))*0.08
            ring.scale=Vector3.ONE*s

func use_warp(target_map:int)->bool:
    if legacy==null or not Teleport.MAPS.has(target_map): return false
    var command:String="@go "+str(target_map)
    if legacy.has_method("handle_command"):
        legacy.call("handle_command",command)
        return true
    return false

func _target_color(map_id:int)->Color:
    var type:String=str(Teleport.MAPS.get(map_id,{}).get("type","town"))
    if type=="dungeon": return Color("#8c6dff")
    if type=="field": return Color("#72b86c")
    return Color("#75d9d0")

func _glow_material(color:Color)->StandardMaterial3D:
    var m:StandardMaterial3D=StandardMaterial3D.new()
    m.albedo_color=color
    m.emission_enabled=true
    m.emission=color
    m.emission_energy_multiplier=1.7
    m.roughness=0.25
    return m
