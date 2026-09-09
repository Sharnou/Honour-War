class_name HDEnvironmentDirector
extends Node3D

## Production environment layer: low-poly 3D geometry, saturated hand-painted
## palette, strict 1x1 gameplay grid, and a diorama-style background.
const TILE_SIZE:float=0.055
const GRID_WIDTH:int=742
const GRID_HEIGHT:int=300
const ORIGIN_X:float=365.0
const ORIGIN_Y:float=120.0

var environment_root:Node3D

func _ready()->void:
    environment_root=Node3D.new()
    environment_root.name="HDEnvironmentBackground"
    add_child(environment_root)
    _build_terrain()
    _build_grid_accents()
    _build_backdrop()
    _build_town_set()

func _material(color:Color,roughness:float=0.88)->StandardMaterial3D:
    var material:=StandardMaterial3D.new()
    material.albedo_color=color
    material.roughness=roughness
    material.metallic=0.0
    return material

func _mesh_box(size:Vector3,pos:Vector3,color:Color)->MeshInstance3D:
    var node:=MeshInstance3D.new()
    var mesh:=BoxMesh.new()
    mesh.size=size
    node.mesh=mesh
    node.position=pos
    node.material_override=_material(color)
    return node

func _build_terrain()->void:
    var terrain:=_mesh_box(Vector3(70.0,0.30,43.0),Vector3(12.925,-0.20,12.65),Color("#304c36"))
    environment_root.add_child(terrain)
    # Three raised terrain shelves create depth without expensive terrain meshes.
    var shelves:Array[Vector3]=[Vector3(-13.0,0.20,-7.0),Vector3(28.0,0.15,-3.0),Vector3(-22.0,0.12,16.0)]
    for p in shelves:
        var shelf:=_mesh_box(Vector3(13.0,0.55,7.0),p,Color("#3d5d3b"))
        environment_root.add_child(shelf)

func _build_grid_accents()->void:
    # The simulation grid is 1x1 map units. Only every 10th tile is visualized
    # so the grid reads as an authored world detail instead of a debug overlay.
    var grid_root:=Node3D.new()
    grid_root.name="TileGridAccents"
    environment_root.add_child(grid_root)
    var mat:=_material(Color(0.78,0.70,0.45,0.14),1.0)
    mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
    for x in range(0,GRID_WIDTH,10):
        var line:=MeshInstance3D.new()
        var mesh:=BoxMesh.new()
        mesh.size=Vector3(TILE_SIZE*0.035,0.012,16.5)
        line.mesh=mesh
        line.position=Vector3(float(x)*TILE_SIZE-20.0,0.015,8.0)
        line.material_override=mat
        grid_root.add_child(line)
    for y in range(0,GRID_HEIGHT,10):
        var line:=MeshInstance3D.new()
        var mesh:=BoxMesh.new()
        mesh.size=Vector3(40.8,0.012,TILE_SIZE*0.035)
        line.mesh=mesh
        line.position=Vector3(0.0,0.016,float(y)*TILE_SIZE-6.6)
        line.material_override=mat
        grid_root.add_child(line)

func _build_backdrop()->void:
    var far:=_mesh_box(Vector3(92.0,13.0,0.8),Vector3(12.9,6.0,-10.8),Color("#38566b"))
    environment_root.add_child(far)
    var far2:=_mesh_box(Vector3(92.0,8.0,0.8),Vector3(12.9,3.0,34.0),Color("#49624e"))
    environment_root.add_child(far2)
    # Stylized distant hills are deliberately simple silhouettes.
    for i in range(9):
        var hill:=MeshInstance3D.new()
        var mesh:=CylinderMesh.new()
        mesh.top_radius=0.0
        mesh.bottom_radius=5.0+float(i%3)*1.5
        mesh.height=7.0+float(i%4)
        hill.mesh=mesh
        hill.position=Vector3(-28.0+float(i)*10.0,2.5,-10.0)
        hill.rotation_degrees.y=float(i*17)
        hill.material_override=_material(Color("#2e4850"))
        environment_root.add_child(hill)

func _build_town_set()->void:
    var building_positions:Array[Vector3]=[
        Vector3(-10.0,2.0,-4.0),Vector3(10.0,2.0,-4.0),Vector3(-11.0,2.0,13.5),Vector3(11.0,2.0,13.5),
        Vector3(-26.0,1.5,5.0),Vector3(28.0,1.5,5.0)
    ]
    for i in building_positions.size():
        _build_building(building_positions[i],i)
    _build_tree_cluster(Vector3(-29.0,0.0,-3.0),7)
    _build_tree_cluster(Vector3(30.0,0.0,17.0),8)
    _build_tree_cluster(Vector3(-30.0,0.0,23.0),5)

func _build_building(pos:Vector3,index:int)->void:
    var wall_color:Array[Color]=[Color("#a97858"),Color("#7e6b57"),Color("#9b6d4f"),Color("#64745d")]
    var roof_color:Array[Color]=[Color("#7c3432"),Color("#3d3c55"),Color("#5b3b34"),Color("#394b3e")]
    var base:=_mesh_box(Vector3(6.0,4.0,5.0),pos,wall_color[index%wall_color.size()])
    environment_root.add_child(base)
    var roof:=MeshInstance3D.new()
    var roof_mesh:=CylinderMesh.new()
    roof_mesh.top_radius=0.0
    roof_mesh.bottom_radius=4.2
    roof_mesh.height=2.5
    roof.mesh=roof_mesh
    roof.position=pos+Vector3(0.0,3.15,0.0)
    roof.material_override=_material(roof_color[index%roof_color.size()])
    environment_root.add_child(roof)
    # Doors/windows are thin painted geometry, keeping the low-poly contract.
    var door:=_mesh_box(Vector3(0.9,1.8,0.08),pos+Vector3(0.0,0.0,2.54),Color("#3b2923"))
    environment_root.add_child(door)
    for side in [-1.0,1.0]:
        var window:=_mesh_box(Vector3(1.15,0.95,0.08),pos+Vector3(side*1.65,1.25,2.54),Color("#8bd5d8"))
        environment_root.add_child(window)

func _build_tree_cluster(center:Vector3,count:int)->void:
    for i in count:
        var x:=center.x+float((i*17)%11)-5.0
        var z:=center.z+float((i*13)%9)-4.0
        var trunk:=MeshInstance3D.new()
        var trunk_mesh:=CylinderMesh.new()
        trunk_mesh.top_radius=0.18
        trunk_mesh.bottom_radius=0.35
        trunk_mesh.height=2.4+float(i%3)*0.35
        trunk.mesh=trunk_mesh
        trunk.position=Vector3(x,1.2,z)
        trunk.material_override=_material(Color("#51382b"))
        environment_root.add_child(trunk)
        var crown:=MeshInstance3D.new()
        var crown_mesh:=SphereMesh.new()
        crown_mesh.radius=1.25+float(i%2)*0.25
        crown_mesh.height=2.5
        crown.mesh=crown_mesh
        crown.position=Vector3(x,3.1+float(i%3)*0.2,z)
        crown.material_override=_material(Color("#2f6b45"))
        environment_root.add_child(crown)
