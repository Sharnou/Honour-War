extends Node

## Map-aware HD world presentation layer.
## Visual only: never mutates authoritative combat, movement or inventory state.
const TELEPORT = preload("res://scripts/TeleportSystem.gd")

var scene_root:Node
var last_map_id:int = -1
var timer:float = 0.0

func _ready() -> void:
    process_priority = 860
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("_bind")

func _process(delta:float) -> void:
    timer += delta
    if timer < 0.25:
        return
    timer = 0.0
    if scene_root == null or not is_instance_valid(scene_root):
        _bind()
        return
    var hero_value:Variant = scene_root.get("hero")
    if not hero_value is Dictionary:
        var legacy:Node = scene_root.get_node_or_null("LegacyGame")
        hero_value = legacy.get("hero") if legacy != null else null
    if not hero_value is Dictionary:
        return
    var map_id:int = int((hero_value as Dictionary).get("map_id",0))
    if map_id != last_map_id:
        _rebuild(map_id)

func _bind() -> void:
    scene_root = get_tree().current_scene
    if scene_root == null:
        call_deferred("_bind")
        return
    var hero_value:Variant = scene_root.get("hero")
    if not hero_value is Dictionary:
        var legacy:Node = scene_root.get_node_or_null("LegacyGame")
        hero_value = legacy.get("hero") if legacy != null else null
    if hero_value is Dictionary:
        _rebuild(int((hero_value as Dictionary).get("map_id",0)))

func _rebuild(map_id:int) -> void:
    last_map_id = map_id
    if scene_root == null:
        return
    var content:Node3D = scene_root.get_node_or_null("HWHDContent") as Node3D
    if content == null:
        return
    var old:Node = content.get_node_or_null("HWMapTheme")
    if old != null:
        old.queue_free()
    var root := Node3D.new()
    root.name = "HWMapTheme"
    root.set_meta("map_id",map_id)
    content.add_child(root)
    var map_data:Dictionary = TELEPORT.MAPS.get(map_id,{})
    var map_name:String = str(map_data.get("name","Unknown"))
    var map_type:String = str(map_data.get("type","field"))
    if map_type == "town":
        _build_town(root,map_name,map_id)
    elif map_type == "dungeon":
        _build_dungeon(root,map_name,map_id)
    else:
        _build_field(root,map_name,map_id)

func _build_town(root:Node3D,map_name:String,map_id:int) -> void:
    var style:Dictionary = _theme_for(map_name)
    _build_plaza(root,style)
    for point in [
        Vector3(-15,0,-4),Vector3(-7,0,-5),Vector3(7,0,-5),Vector3(15,0,-4),
        Vector3(-15,0,11),Vector3(-7,0,14),Vector3(7,0,14),Vector3(15,0,11)
    ]:
        _build_house(root,point,style)
    if map_name.to_lower().contains("alberta") or map_name.to_lower().contains("izlude") or map_name.to_lower().contains("comodo"):
        _build_waterfront(root,style)
    elif map_name.to_lower().contains("morroc"):
        _build_desert_town(root,style)
    elif map_name.to_lower().contains("geffen"):
        _build_arcane_town(root,style)
    elif map_name.to_lower().contains("lutie"):
        _build_snow_town(root,style)
    elif map_name.to_lower().contains("umbala"):
        _build_jungle_town(root,style)
    else:
        _build_greenery(root,style)
    _label(root,map_name.to_upper(),Vector3(0,5.6,0),style.accent)

func _build_field(root:Node3D,map_name:String,map_id:int) -> void:
    var style:Dictionary = _theme_for(map_name)
    for p in [
        Vector3(-24,0,-9),Vector3(-12,0,-6),Vector3(0,0,-10),Vector3(12,0,-7),Vector3(24,0,-9),
        Vector3(-26,0,9),Vector3(-14,0,16),Vector3(0,0,11),Vector3(15,0,17),Vector3(27,0,9)
    ]:
        _build_landmark(root,p,style)
    for i in range(12):
        var x:float = -28.0 + float((i*17)%56)
        var z:float = -12.0 + float((i*29)%30)
        if i % 3 == 0 and not map_name.to_lower().contains("desert"):
            _build_tree(root,Vector3(x,0,z),style)
        else:
            _build_rock_or_crystal(root,Vector3(x,0,z),style,i)
    if map_name.to_lower().contains("desert"):
        _build_dunes(root,style)
    if map_name.to_lower().contains("snow"):
        _build_snowbanks(root,style)
    if map_name.to_lower().contains("coast") or map_name.to_lower().contains("jungle"):
        _build_water_edge(root,style)
    _label(root,map_name.to_upper(),Vector3(0,4.8,0),style.accent)

func _build_dungeon(root:Node3D,map_name:String,map_id:int) -> void:
    var style:Dictionary = _theme_for(map_name)
    for x in [-22.0,-14.0,-6.0,6.0,14.0,22.0]:
        _build_column(root,Vector3(x,0,-8),style)
        _build_column(root,Vector3(x,0,18),style)
    for z in [-2.0,6.0,14.0]:
        _build_wall_segment(root,Vector3(-24,0,z),style)
        _build_wall_segment(root,Vector3(24,0,z),style)
    for x in [-18.0,-9.0,0.0,9.0,18.0]:
        _build_torch(root,Vector3(x,0,4),style)
    if map_name.to_lower().contains("ice"):
        _build_ice_crystals(root,style)
    elif map_name.to_lower().contains("tower") or map_name.to_lower().contains("clock"):
        _build_clockwork(root,style)
    elif map_name.to_lower().contains("ship"):
        _build_ship_deck(root,style)
    else:
        _build_ruins(root,style)
    _label(root,map_name.to_upper(),Vector3(0,6.5,4),style.accent)

func _theme_for(map_name:String) -> Dictionary:
    var key:String = map_name.to_lower()
    if key.contains("morroc") or key.contains("desert") or key.contains("ruins"):
        return {"wall":Color("#a47b55"),"roof":Color("#6b4d3a"),"ground":Color("#c49a5c"),"accent":Color("#efc36d"),"leaf":Color("#b47b42")}
    if key.contains("payon") or key.contains("forest") or key.contains("hidden"):
        return {"wall":Color("#72543f"),"roof":Color("#3f3028"),"ground":Color("#556b45"),"accent":Color("#d1a55f"),"leaf":Color("#4d8a56")}
    if key.contains("geffen") or key.contains("magic") or key.contains("tower"):
        return {"wall":Color("#67557e"),"roof":Color("#30294a"),"ground":Color("#4b4b66"),"accent":Color("#8ad8ff"),"leaf":Color("#6f75bd")}
    if key.contains("alberta") or key.contains("izlude") or key.contains("coast") or key.contains("ship"):
        return {"wall":Color("#796557"),"roof":Color("#394c60"),"ground":Color("#526e78"),"accent":Color("#79dfff"),"leaf":Color("#5d9586")}
    if key.contains("lutie") or key.contains("ice") or key.contains("snow"):
        return {"wall":Color("#92a8bd"),"roof":Color("#5e6f85"),"ground":Color("#d9e7ef"),"accent":Color("#a9e9ff"),"leaf":Color("#c6d9e7")}
    if key.contains("umbala") or key.contains("jungle"):
        return {"wall":Color("#5d6446"),"roof":Color("#2e3d2b"),"ground":Color("#40583f"),"accent":Color("#dbcc72"),"leaf":Color("#3d8b50")}
    if key.contains("juno") or key.contains("aldebaran") or key.contains("clock"):
        return {"wall":Color("#6b6f76"),"roof":Color("#30353d"),"ground":Color("#616873"),"accent":Color("#e0b35d"),"leaf":Color("#71866d")}
    return {"wall":Color("#8b6f58"),"roof":Color("#4b3940"),"ground":Color("#718060"),"accent":Color("#e7c278"),"leaf":Color("#4f8f5b")}

func _build_plaza(root:Node3D,style:Dictionary) -> void:
    for x in [-12.0,-6.0,0.0,6.0,12.0]:
        _box(root,"PlazaStone",Vector3(5.2,0.16,2.2),Vector3(x,0.08,2.5),_mat(style.ground,0.78))
    _build_fountain(root,Vector3(0,0,5.8),style)
    for x in [-14.0,14.0]:
        _build_lamp(root,Vector3(x,0,4),style)
        _build_lamp(root,Vector3(x,0,12),style)

func _build_house(root:Node3D,pos:Vector3,style:Dictionary) -> void:
    _box(root,"HouseBody",Vector3(5.2,3.0,4.0),pos+Vector3(0,1.5,0),_mat(style.wall,0.82))
    _box(root,"HouseRoof",Vector3(5.8,0.38,4.6),pos+Vector3(0,3.25,0),_mat(style.roof,0.88))
    _box(root,"Door",Vector3(0.9,1.7,0.10),pos+Vector3(0,0.85,2.05),_mat(Color("#30231f"),0.76))
    _box(root,"WindowL",Vector3(0.75,0.70,0.08),pos+Vector3(-1.45,1.65,2.04),_emission(style.accent,0.35))
    _box(root,"WindowR",Vector3(0.75,0.70,0.08),pos+Vector3(1.45,1.65,2.04),_emission(style.accent,0.35))

func _build_fountain(root:Node3D,pos:Vector3,style:Dictionary) -> void:
    _cyl(root,"FountainBase",1.9,0.35,pos+Vector3(0,0.18,0),_mat(style.wall,0.72))
    _cyl(root,"FountainWater",1.35,0.10,pos+Vector3(0,0.40,0),_emission(style.accent,0.55))
    _cyl(root,"FountainCore",0.24,1.8,pos+Vector3(0,1.15,0),_mat(style.wall,0.68))

func _build_greenery(root:Node3D,style:Dictionary) -> void:
    for p in [Vector3(-20,0,-5),Vector3(20,0,-5),Vector3(-20,0,16),Vector3(20,0,16)]:
        _build_tree(root,p,style)

func _build_desert_town(root:Node3D,style:Dictionary) -> void:
    for x in [-18.0,-10.0,10.0,18.0]:
        _box(root,"Awning",Vector3(3.4,0.12,2.0),Vector3(x,2.5,6),_mat(style.accent,0.62))
    for x in [-13.0,-4.0,4.0,13.0]:
        _build_pillar(root,Vector3(x,0,9),style)

func _build_arcane_town(root:Node3D,style:Dictionary) -> void:
    for p in [Vector3(-18,0,7),Vector3(18,0,7),Vector3(-14,0,-1),Vector3(14,0,-1)]:
        _build_crystal(root,p,style.accent)
    _build_pillar(root,Vector3(0,0,10),style)

func _build_snow_town(root:Node3D,style:Dictionary) -> void:
    for x in [-18.0,-9.0,9.0,18.0]:
        _build_snowbank(root,Vector3(x,0,8),style)
    _build_crystal(root,Vector3(0,0,10),style.accent)

func _build_jungle_town(root:Node3D,style:Dictionary) -> void:
    for x in [-18.0,-12.0,12.0,18.0]:
        _build_totem(root,Vector3(x,0,8),style)

func _build_waterfront(root:Node3D,style:Dictionary) -> void:
    _build_water_edge(root,style)
    for x in [-18.0,-9.0,0.0,9.0,18.0]:
        _build_dock(root,Vector3(x,0,12),style)

func _build_dunes(root:Node3D,style:Dictionary) -> void:
    for x in [-24.0,-12.0,0.0,12.0,24.0]:
        var dune := _sphere(root,"Dune",2.2,Vector3(x,0.65,18),_mat(style.ground,0.95))
        dune.scale = Vector3(2.0,0.45,1.1)
        root.add_child(dune)

func _build_snowbanks(root:Node3D,style:Dictionary) -> void:
    for x in [-24.0,-12.0,0.0,12.0,24.0]:
        _build_snowbank(root,Vector3(x,0,18),style)

func _build_water_edge(root:Node3D,style:Dictionary) -> void:
    _box(root,"WaterEdge",Vector3(58.0,0.10,4.0),Vector3(0,0.05,21),_emission(style.accent,0.45))

func _build_landmark(root:Node3D,pos:Vector3,style:Dictionary) -> void:
    _box(root,"FieldLandmark",Vector3(3.2,0.24,3.2),pos+Vector3(0,0.12,0),_mat(style.ground,0.82))
    _build_pillar(root,pos,style)

func _build_tree(root:Node3D,pos:Vector3,style:Dictionary) -> void:
    _cyl(root,"TreeTrunk",0.28,2.8,pos+Vector3(0,1.4,0),_mat(Color("#543b2b"),0.93))
    _sphere(root,"TreeCrown",1.45,pos+Vector3(0,3.0,0),_mat(style.leaf,0.92))

func _build_rock_or_crystal(root:Node3D,pos:Vector3,style:Dictionary,index:int) -> void:
    if index % 4 == 0:
        _build_crystal(root,pos,style.accent)
    else:
        var rock := _sphere(root,"FieldRock",0.75,pos+Vector3(0,0.45,0),_mat(style.wall,0.92))
        rock.scale = Vector3(1.4,0.75,1.05)
        root.add_child(rock)

func _build_crystal(root:Node3D,pos:Vector3,color:Color) -> void:
    var c := _cyl(root,"Crystal",0.16,1.2,pos+Vector3(0,0.65,0),_emission(color,1.25))
    c.rotation_degrees = Vector3(4.0,18.0,7.0)

func _build_column(root:Node3D,pos:Vector3,style:Dictionary) -> void:
    _cyl(root,"DungeonColumn",0.48,4.6,pos+Vector3(0,2.3,0),_mat(style.wall,0.76))
    _cyl(root,"ColumnCap",0.72,0.30,pos+Vector3(0,4.65,0),_mat(style.roof,0.65))

func _build_wall_segment(root:Node3D,pos:Vector3,style:Dictionary) -> void:
    _box(root,"DungeonWall",Vector3(1.0,4.0,6.0),pos+Vector3(0,2,0),_mat(style.wall,0.82))

func _build_torch(root:Node3D,pos:Vector3,style:Dictionary) -> void:
    _cyl(root,"TorchPost",0.08,1.8,pos+Vector3(0,0.9,0),_mat(Color("#302522"),0.72))
    var flame := _sphere("TorchFlame",0.18,pos+Vector3(0,1.9,0),_emission(style.accent,2.0))
    root.add_child(flame)
    var light := OmniLight3D.new()
    light.light_color = style.accent
    light.light_energy = 1.25
    light.omni_range = 4.2
    light.position = flame.position
    root.add_child(light)

func _build_ruins(root:Node3D,style:Dictionary) -> void:
    for x in [-15.0,0.0,15.0]:
        _build_crystal(root,Vector3(x,0,10),style.accent)
        _build_wall_segment(root,Vector3(x,0,17),style)

func _build_ice_crystals(root:Node3D,style:Dictionary) -> void:
    for x in [-16.0,-8.0,0.0,8.0,16.0]:
        _build_crystal(root,Vector3(x,0,10),style.accent)

func _build_clockwork(root:Node3D,style:Dictionary) -> void:
    for x in [-15.0,0.0,15.0]:
        _cyl(root,"GearPost",0.18,3.5,Vector3(x,1.75,10),_mat(style.roof,0.50,0.75))
        _build_crystal(root,Vector3(x,0,10),style.accent)

func _build_ship_deck(root:Node3D,style:Dictionary) -> void:
    for x in [-20.0,-10.0,0.0,10.0,20.0]:
        _cyl(root,"Mast",0.18,4.5,Vector3(x,2.25,10),_mat(style.roof,0.62))

func _build_pillar(root:Node3D,pos:Vector3,style:Dictionary) -> void:
    _cyl(root,"Pillar",0.22,2.4,pos+Vector3(0,1.2,0),_mat(style.roof,0.65))

func _build_snowbank(root:Node3D,pos:Vector3,style:Dictionary) -> void:
    var bank := _sphere(root,"Snowbank",1.6,pos+Vector3(0,0.55,0),_mat(style.ground,0.96))
    bank.scale = Vector3(1.9,0.65,1.1)
    root.add_child(bank)

func _build_totem(root:Node3D,pos:Vector3,style:Dictionary) -> void:
    _cyl(root,"Totem",0.22,2.8,pos+Vector3(0,1.4,0),_mat(style.roof,0.82))
    _sphere(root,"TotemHead",0.48,pos+Vector3(0,3.0,0),_mat(style.accent,0.58))

func _build_dock(root:Node3D,pos:Vector3,style:Dictionary) -> void:
    _box(root,"Dock",Vector3(6.0,0.25,1.3),pos+Vector3(0,0.18,0),_mat(style.roof,0.84))

func _build_lamp(root:Node3D,pos:Vector3,style:Dictionary) -> void:
    _cyl(root,"LampPost",0.08,2.4,pos+Vector3(0,1.2,0),_mat(Color("#3b3130"),0.68))
    var light_mesh := _sphere("Lamp",0.16,pos+Vector3(0,2.5,0),_emission(style.accent,1.15))
    root.add_child(light_mesh)
    var omni := OmniLight3D.new()
    omni.light_color = style.accent
    omni.light_energy = 0.65
    omni.omni_range = 3.5
    omni.position = light_mesh.position
    root.add_child(omni)

func _box(root:Node3D,name:String,size:Vector3,position:Vector3,material:Material)->void:
    var node:=MeshInstance3D.new()
    node.name=name
    var mesh:=BoxMesh.new()
    mesh.size=size
    node.mesh=mesh
    node.position=position
    node.material_override=material
    root.add_child(node)

func _cyl(root:Node3D,name:String,radius:float,height:float,position:Vector3,material:Material)->MeshInstance3D:
    var node:=MeshInstance3D.new()
    node.name=name
    var mesh:=CylinderMesh.new()
    mesh.top_radius=radius
    mesh.bottom_radius=radius
    mesh.height=height
    mesh.radial_segments=24
    node.mesh=mesh
    node.position=position
    node.material_override=material
    root.add_child(node)
    return node

func _sphere(root:Node3D,name:String,radius:float,position:Vector3,material:Material)->MeshInstance3D:
    var node:=MeshInstance3D.new()
    node.name=name
    var mesh:=SphereMesh.new()
    mesh.radius=radius
    mesh.height=radius*2.0
    mesh.radial_segments=24
    mesh.rings=12
    node.mesh=mesh
    node.position=position
    node.material_override=material
    root.add_child(node)
    return node

func _mat(color:Color,roughness:float=0.78,metallic:float=0.0)->StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.albedo_color=color
    m.roughness=roughness
    m.metallic=metallic
    m.shading_mode=BaseMaterial3D.SHADING_MODE_PER_PIXEL
    return m

func _emission(color:Color,energy:float)->StandardMaterial3D:
    var m:=_mat(color,0.35,0.0)
    m.emission_enabled=true
    m.emission=color
    m.emission_energy_multiplier=energy
    return m

func _label(root:Node3D,text:String,position:Vector3,color:Color)->void:
    var label:=Label3D.new()
    label.text=text
    label.font_size=28
    label.outline_size=8
    label.modulate=color
    label.position=position
    root.add_child(label)
