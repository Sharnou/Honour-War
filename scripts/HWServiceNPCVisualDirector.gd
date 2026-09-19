extends Node

const TeleportSystemClass = preload("res://scripts/TeleportSystemClass.gd")3D

## Town service NPC presentation. Fixed MMORPG service NPCs only; no player ownership/building.
const Profiles=preload("res://scripts/HWWorldActorVisualProfiles.gd")
var item_shop:Node3D
var elapsed:float=0.0
var last_map:int=-1

func _ready()->void:
    process_priority=2400
    call_deferred("_sync")

func _process(delta:float)->void:
    elapsed+=delta
    var scene:Node=get_tree().current_scene
    if scene==null:
        return
    var legacy:Node=scene.get_node_or_null("LegacyGame")
    if legacy==null:
        return
    var hero_value:Variant=legacy.get("hero")
    if not hero_value is Dictionary:
        return
    var map_id:int=int((hero_value as Dictionary).get("map_id",0))
    if map_id!=last_map:
        last_map=map_id
        _sync()
    if item_shop!=null and is_instance_valid(item_shop):
        item_shop.rotation.y=sin(elapsed*1.25)*0.018
        var apron:Node=item_shop.get_node_or_null("Apron")
        if apron is Node3D:
            (apron as Node3D).rotation.z=sin(elapsed*2.0)*0.012

func _sync()->void:
    var scene:Node=get_tree().current_scene
    if scene==null:
        return
    var legacy:Node=scene.get_node_or_null("LegacyGame")
    if legacy==null:
        return
    var hero_value:Variant=legacy.get("hero")
    if not hero_value is Dictionary:
        return
    var map_id:int=int((hero_value as Dictionary).get("map_id",0))
    var town_data:Dictionary=TeleportSystemClass.MAPS.get(map_id,{})
    if str(town_data.get("type",""))!="town":
        _hide()
        return
    _show_or_create(scene)

func _show_or_create(scene:Node)->void:
    if item_shop==null or not is_instance_valid(item_shop):
        item_shop=Node3D.new()
        item_shop.name="ItemShopNPC"
        item_shop.add_to_group("service_npc")
        item_shop.set_meta("npc_name","Item Shop")
        item_shop.set_meta("job","Merchant")
        var profile:Dictionary=Profiles.npc_profile("Item Shop","Merchant")
        item_shop.set_meta("hw_world_actor_profile",profile)
        item_shop.set_meta("hw_emotion",profile["emotion"])
        item_shop.set_meta("hw_motion_language",profile["motion"])
        item_shop.set_meta("hw_clothing",profile["clothing"])
        scene.add_child(item_shop)
        _build_item_shop_body()
    item_shop.visible=true
    item_shop.position=Vector3(-6.0,0.0,-7.0)

func _hide()->void:
    if item_shop!=null and is_instance_valid(item_shop):
        item_shop.visible=false

func _mat(color:Color,rough:float=0.7,metal:float=0.0)->StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.albedo_color=color
    m.roughness=rough
    m.metallic=metal
    return m

func _mesh_box(parent:Node,name:String,size:Vector3,pos:Vector3,mat:Material)->MeshInstance3D:
    var n:=MeshInstance3D.new()
    n.name=name
    var mesh:=BoxMesh.new()
    mesh.size=size
    n.mesh=mesh
    n.position=pos
    n.material_override=mat
    parent.add_child(n)
    return n

func _mesh_cylinder(parent:Node,name:String,radius:float,height:float,pos:Vector3,mat:Material)->MeshInstance3D:
    var n:=MeshInstance3D.new()
    n.name=name
    var mesh:=CylinderMesh.new()
    mesh.top_radius=radius
    mesh.bottom_radius=radius
    mesh.height=height
    mesh.radial_segments=20
    n.mesh=mesh
    n.position=pos
    n.material_override=mat
    parent.add_child(n)
    return n

func _mesh_sphere(parent:Node,name:String,radius:float,pos:Vector3,mat:Material)->MeshInstance3D:
    var n:=MeshInstance3D.new()
    n.name=name
    var mesh:=SphereMesh.new()
    mesh.radius=radius
    mesh.height=radius*2.0
    mesh.radial_segments=20
    mesh.rings=10
    n.mesh=mesh
    n.position=pos
    n.material_override=mat
    parent.add_child(n)
    return n

func _build_item_shop_body()->void:
    var skin:=_mat(Color("#d7a27c"),0.82)
    var vest:=_mat(Color("#2d5a78"),0.66)
    var shirt:=_mat(Color("#eee5d2"),0.78)
    var leather:=_mat(Color("#5a3b29"),0.72)
    var gold:=_mat(Color("#d7b75e"),0.38,0.22)
    var red:=_mat(Color("#8c403c"),0.70)
    _mesh_cylinder(item_shop,"Body",0.43,1.25,Vector3(0,0.78,0),shirt)
    _mesh_box(item_shop,"MerchantVest",Vector3(0.72,0.92,0.30),Vector3(0,0.88,0.04),vest)
    _mesh_box(item_shop,"Apron",Vector3(0.68,0.74,0.12),Vector3(0,0.62,0.20),leather)
    _mesh_box(item_shop,"Belt",Vector3(0.82,0.10,0.34),Vector3(0,0.54,0.02),gold)
    _mesh_sphere(item_shop,"Head",0.31,Vector3(0,1.62,0),skin)
    _mesh_cylinder(item_shop,"ShopHat",0.38,0.12,Vector3(0,1.91,0),red)
    _mesh_box(item_shop,"CoinPouch",Vector3(0.18,0.22,0.18),Vector3(0.45,0.62,0.04),gold)
    _mesh_box(item_shop,"TradeBook",Vector3(0.20,0.30,0.06),Vector3(-0.43,0.98,0.25),gold)
    var label:=Label3D.new()
    label.name="ShopLabel"
    label.text="ITEM SHOP\nBuy • Sell"
    label.position=Vector3(0,2.45,0)
    label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
    label.pixel_size=0.004
    label.modulate=Color("#ffe0a0")
    item_shop.add_child(label)
