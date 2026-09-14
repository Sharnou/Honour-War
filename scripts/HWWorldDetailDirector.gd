extends Node

## World-detail pass for the current runtime fallback.
## Adds authored-style architectural props and environmental depth while
## preserving any real GLB/GLTF assets loaded by the production pipeline.

const ROOT_NAME:String = "HW_AuthoredWorldDetail"
var scene_root:Node
var root:Node3D
var built:bool = false

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("_build")

func _process(_delta:float) -> void:
    if not built:
        _build()

func _build() -> void:
    scene_root = get_tree().current_scene
    if scene_root == null:
        return
    root = scene_root.get_node_or_null(ROOT_NAME) as Node3D
    if root == null:
        root = Node3D.new()
        root.name = ROOT_NAME
        scene_root.add_child(root)
    if root.get_meta("built",false):
        built = true
        return
    _add_fountain()
    _add_archways()
    _add_market_stalls()
    _add_trees()
    _add_banners()
    _add_crates_and_barrels()
    _add_water_channel()
    root.set_meta("built",true)
    built = true

func _mat(color:Color,roughness:float=0.8,metallic:float=0.0)->StandardMaterial3D:
    var material:StandardMaterial3D = StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = roughness
    material.metallic = metallic
    return material

func _emission(color:Color,energy:float)->StandardMaterial3D:
    var material:StandardMaterial3D = _mat(color,0.32,0.12)
    material.emission_enabled = true
    material.emission = color
    material.emission_energy_multiplier = energy
    return material

func _box(name:String,size:Vector3,pos:Vector3,material:Material)->MeshInstance3D:
    var node:MeshInstance3D = MeshInstance3D.new()
    node.name = name
    var mesh:BoxMesh = BoxMesh.new()
    mesh.size = size
    node.mesh = mesh
    node.position = pos
    node.material_override = material
    return node

func _cylinder(name:String,radius:float,height:float,pos:Vector3,material:Material)->MeshInstance3D:
    var node:MeshInstance3D = MeshInstance3D.new()
    node.name = name
    var mesh:CylinderMesh = CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = height
    mesh.radial_segments = 28
    node.mesh = mesh
    node.position = pos
    node.material_override = material
    return node

func _sphere(name:String,radius:float,pos:Vector3,material:Material)->MeshInstance3D:
    var node:MeshInstance3D = MeshInstance3D.new()
    node.name = name
    var mesh:SphereMesh = SphereMesh.new()
    mesh.radius = radius
    mesh.height = radius * 2.0
    mesh.radial_segments = 24
    mesh.rings = 14
    node.mesh = mesh
    node.position = pos
    node.material_override = material
    return node

func _add_fountain() -> void:
    var stone:StandardMaterial3D = _mat(Color("#b7b0a0"),0.72,0.02)
    var water:StandardMaterial3D = _emission(Color("#4aa4c4"),0.35)
    var base:MeshInstance3D = _cylinder("FountainBase",2.35,0.30,Vector3(0,0.15,6.0),stone)
    root.add_child(base)
    var basin:MeshInstance3D = _cylinder("FountainBasin",1.75,0.18,Vector3(0,0.38,6.0),water)
    root.add_child(basin)
    var pillar:MeshInstance3D = _cylinder("FountainPillar",0.32,2.10,Vector3(0,1.38,6.0),stone)
    root.add_child(pillar)
    var crown:MeshInstance3D = _sphere("FountainCrown",0.62,Vector3(0,2.46,6.0),stone)
    root.add_child(crown)
    var orb:MeshInstance3D = _sphere("FountainOrb",0.16,Vector3(0,2.98,6.0),water)
    root.add_child(orb)

func _add_archways() -> void:
    var stone:StandardMaterial3D = _mat(Color("#8f806e"),0.86,0.04)
    var trim:StandardMaterial3D = _mat(Color("#c4b18f"),0.64,0.18)
    var positions:Array[Vector3] = [Vector3(-18,2.8,-3),Vector3(18,2.8,-3),Vector3(-18,2.8,17),Vector3(18,2.8,17)]
    for index:int in positions.size():
        var p:Vector3 = positions[index]
        var left:MeshInstance3D = _box("Arch_%d_L" % index,Vector3(0.9,5.6,1.0),p+Vector3(-1.35,0,0),stone)
        var right:MeshInstance3D = _box("Arch_%d_R" % index,Vector3(0.9,5.6,1.0),p+Vector3(1.35,0,0),stone)
        var top:MeshInstance3D = _box("Arch_%d_T" % index,Vector3(3.6,0.8,1.0),p+Vector3(0,2.4,0),trim)
        root.add_child(left)
        root.add_child(right)
        root.add_child(top)

func _add_market_stalls() -> void:
    var wood:StandardMaterial3D = _mat(Color("#684d39"),0.92,0.0)
    var cloth:StandardMaterial3D = _mat(Color("#b58f68"),0.74,0.0)
    var goods:StandardMaterial3D = _mat(Color("#8d6f4b"),0.78,0.0)
    var positions:Array[Vector3] = [Vector3(-7,0,-4),Vector3(7,0,-4),Vector3(-11,0,12),Vector3(11,0,12)]
    for index:int in positions.size():
        var p:Vector3 = positions[index]
        var table:MeshInstance3D = _box("Market_%d_Table" % index,Vector3(3.8,0.28,1.55),p+Vector3(0,1.05,0),wood)
        var roof:MeshInstance3D = _box("Market_%d_Canopy" % index,Vector3(4.2,0.12,2.8),p+Vector3(0,2.85,0),cloth)
        roof.rotation_degrees.z = -3.0 if index%2==0 else 3.0
        root.add_child(table)
        root.add_child(roof)
        for side:float in [-1.0,1.0]:
            var post:MeshInstance3D = _box("Market_%d_Post" % index,Vector3(0.14,2.6,0.14),p+Vector3(side*1.6,1.9,0),wood)
            root.add_child(post)
        for item_index:int in range(3):
            var item:MeshInstance3D = _sphere("Market_%d_Goods" % index,0.18,p+Vector3(-1.15+float(item_index)*0.95,1.34,0),goods)
            root.add_child(item)

func _add_trees() -> void:
    var trunk:StandardMaterial3D = _mat(Color("#4f3b2d"),0.98,0.0)
    var leaves:StandardMaterial3D = _mat(Color("#4f7e50"),0.95,0.0)
    var positions:Array[Vector3] = [
        Vector3(-24,0,-10),Vector3(24,0,-10),Vector3(-27,0,5),Vector3(27,0,5),
        Vector3(-23,0,20),Vector3(23,0,20),Vector3(-13,0,24),Vector3(13,0,24)
    ]
    for index:int in positions.size():
        var p:Vector3 = positions[index]
        var tree_trunk:MeshInstance3D = _cylinder("TreeTrunk_%d" % index,0.28,2.4,p+Vector3(0,1.2,0),trunk)
        var crown:MeshInstance3D = _sphere("TreeCrown_%d" % index,1.45,p+Vector3(0,3.15,0),leaves)
        crown.scale = Vector3(1.0,1.18,1.0)
        root.add_child(tree_trunk)
        root.add_child(crown)

func _add_banners() -> void:
    var pole:StandardMaterial3D = _mat(Color("#40392f"),0.5,0.48)
    var cloth:StandardMaterial3D = _mat(Color("#8d2731"),0.82,0.0)
    var positions:Array[Vector3] = [Vector3(-15,3.7,-1),Vector3(15,3.7,-1),Vector3(-15,3.7,15),Vector3(15,3.7,15)]
    for index:int in positions.size():
        var p:Vector3 = positions[index]
        var mast:MeshInstance3D = _cylinder("BannerMast_%d" % index,0.055,4.6,p+Vector3(0,-1.2,0),pole)
        var flag:MeshInstance3D = _box("Banner_%d" % index,Vector3(1.25,1.8,0.045),p+Vector3(0.66,0.1,0),cloth)
        flag.rotation_degrees.y = 5.0 if index%2==0 else -5.0
        root.add_child(mast)
        root.add_child(flag)

func _add_crates_and_barrels() -> void:
    var wood:StandardMaterial3D = _mat(Color("#6f533a"),0.94,0.0)
    var iron:StandardMaterial3D = _mat(Color("#4a4d4c"),0.48,0.65)
    var positions:Array[Vector3] = [Vector3(-8,0,15),Vector3(-7,0,15.7),Vector3(8,0,15),Vector3(9,0,15.7)]
    for index:int in positions.size():
        var p:Vector3 = positions[index]
        var crate:MeshInstance3D = _box("Crate_%d" % index,Vector3(0.9,0.9,0.9),p+Vector3(0,0.45,0),wood)
        root.add_child(crate)
        if index%2==0:
            var barrel:MeshInstance3D = _cylinder("Barrel_%d" % index,0.42,0.9,p+Vector3(1.05,0.45,0),iron)
            root.add_child(barrel)

func _add_water_channel() -> void:
    var water:StandardMaterial3D = _emission(Color("#2f89a8"),0.24)
    var bank:StandardMaterial3D = _mat(Color("#9a8c76"),0.88,0.0)
    var channel:MeshInstance3D = _box("WaterChannel",Vector3(32.0,0.08,1.05),Vector3(0,0.045,21.0),water)
    var bank_a:MeshInstance3D = _box("WaterBank_A",Vector3(32.0,0.16,0.28),Vector3(0,0.10,20.42),bank)
    var bank_b:MeshInstance3D = _box("WaterBank_B",Vector3(32.0,0.16,0.28),Vector3(0,0.10,21.58),bank)
    root.add_child(channel)
    root.add_child(bank_a)
    root.add_child(bank_b)
