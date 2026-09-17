extends Node3D

## High-detail runtime art pass for Honour War.
## Visual-only: does not own gameplay, combat, inventory, networking or progression.
## Builds layered materials, architectural silhouettes, terrain tiling, vegetation,
## street dressing and cinematic daylight lighting around the existing world.

const ROOT_NAME := "HWHDHighDetailWorld"
var scene:Node3D
var root:Node3D

func _ready() -> void:
    process_priority = 1200
    call_deferred("_build")

func _build() -> void:
    scene = get_tree().current_scene as Node3D
    if scene == null:
        return
    root = scene.get_node_or_null(ROOT_NAME) as Node3D
    if root != null and bool(root.get_meta("built", false)):
        _upgrade_environment()
        return
    if root == null:
        root = Node3D.new()
        root.name = ROOT_NAME
        scene.add_child(root)
    _build_ground()
    _build_town()
    _build_field()
    _build_dungeon_approach()
    _upgrade_environment()
    root.set_meta("built", true)

func _mat(c:Color, rough:=0.72, metal:=0.0, emission:=Color(0,0,0), emission_energy:=0.0) -> StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.albedo_color=c
    m.roughness=rough
    m.metallic=metal
    m.specular_mode=BaseMaterial3D.SPECULAR_SCHLICK_GGX
    m.shading_mode=BaseMaterial3D.SHADING_MODE_PER_PIXEL
    if emission_energy > 0.0:
        m.emission_enabled=true
        m.emission=emission
        m.emission_energy_multiplier=emission_energy
    return m

func _box(parent:Node, name:String, size:Vector3, pos:Vector3, material:Material, bevel:=0.0) -> MeshInstance3D:
    var n:=MeshInstance3D.new()
    n.name=name
    var mesh:=BoxMesh.new()
    mesh.size=size
    n.mesh=mesh
    n.position=pos
    n.material_override=material
    parent.add_child(n)
    return n

func _cylinder(parent:Node, name:String, radius:float, height:float, pos:Vector3, material:Material, sides:=24) -> MeshInstance3D:
    var n:=MeshInstance3D.new()
    n.name=name
    var mesh:=CylinderMesh.new()
    mesh.top_radius=radius
    mesh.bottom_radius=radius
    mesh.height=height
    mesh.radial_segments=sides
    n.mesh=mesh
    n.position=pos
    n.material_override=material
    parent.add_child(n)
    return n

func _sphere(parent:Node, name:String, radius:float, pos:Vector3, material:Material) -> MeshInstance3D:
    var n:=MeshInstance3D.new()
    n.name=name
    var mesh:=SphereMesh.new()
    mesh.radius=radius
    mesh.height=radius*2.0
    mesh.radial_segments=24
    mesh.rings=12
    n.mesh=mesh
    n.position=pos
    n.material_override=material
    parent.add_child(n)
    return n

func _build_ground() -> void:
    var ground:=Node3D.new()
    ground.name="HDLayeredTerrain"
    root.add_child(ground)
    var grass_a:=_mat(Color("#4d7c4a"),0.96)
    var grass_b:=_mat(Color("#5f8e51"),0.94)
    var stone:=_mat(Color("#777b76"),0.88)
    var road:=_mat(Color("#5d554b"),0.92)
    for x in range(-7,8):
        for z in range(-2,10):
            var p:=Vector3(x*5.0, -0.12, z*5.0)
            _box(ground,"TerrainTile",Vector3(4.92,0.24,4.92),p,grass_a if (x+z)%2==0 else grass_b)
    _box(ground,"TownRoad",Vector3(12.0,0.08,72.0),Vector3(0,-0.01,8),road)
    for z in range(-3,15):
        _box(ground,"RoadStone",Vector3(11.7,0.11,0.16),Vector3(0,0.05,z*5.0-10),stone)

func _build_town() -> void:
    var town:=Node3D.new()
    town.name="HDArchitecturalTown"
    root.add_child(town)
    var plaster:=_mat(Color("#c7b89b"),0.78)
    var timber:=_mat(Color("#513b2c"),0.62)
    var roof:=_mat(Color("#493a45"),0.66)
    var trim:=_mat(Color("#e5c87f"),0.42,0.12)
    var glass:=_mat(Color("#76b8d6"),0.22,0.15,Color("#5fbfe7"),0.12)
    var door:=_mat(Color("#30241e"),0.62)
    var positions=[Vector3(-10,0,-2),Vector3(10,0,-2),Vector3(-10,0,10),Vector3(10,0,10)]
    for i in range(positions.size()):
        _build_building(town,positions[i],plaster,timber,roof,trim,glass,door,i)

func _build_building(parent:Node,pos:Vector3,wall:Material,timber:Material,roof:Material,trim:Material,glass:Material,door:Material,index:int)->void:
    var b:=Node3D.new()
    b.name="HDHouse_%02d"%index
    parent.add_child(b)
    _box(b,"Wall",Vector3(7.0,4.4,5.4),pos+Vector3(0,2.2,0),wall)
    _box(b,"Roof",Vector3(7.6,0.45,6.0),pos+Vector3(0,4.55,0),roof)
    _box(b,"RoofRidge",Vector3(7.0,0.22,0.35),pos+Vector3(0,4.82,0),trim)
    _box(b,"Door",Vector3(1.05,2.0,0.12),pos+Vector3(0,1.0,2.76),door)
    for side in [-1.0,1.0]:
        _box(b,"WindowFrame",Vector3(1.65,1.45,0.10),pos+Vector3(side*2.15,2.45,2.76),timber)
        _box(b,"WindowGlass",Vector3(1.22,1.02,0.08),pos+Vector3(side*2.15,2.45,2.70),glass)
        _box(b,"WindowCrossH",Vector3(1.25,0.08,0.12),pos+Vector3(side*2.15,2.45,2.62),trim)
        _box(b,"WindowCrossV",Vector3(0.08,1.05,0.12),pos+Vector3(side*2.15,2.45,2.62),trim)
    for side in [-1.0,1.0]:
        _box(b,"TimberBeam",Vector3(0.18,4.25,0.20),pos+Vector3(side*3.25,2.25,2.70),timber)
    var lamp:=OmniLight3D.new()
    lamp.name="WarmWindowLight"
    lamp.light_color=Color("#ffd18a")
    lamp.light_energy=0.75
    lamp.omni_range=5.0
    lamp.position=pos+Vector3(0,2.0,2.4)
    b.add_child(lamp)

func _build_field() -> void:
    var field:=Node3D.new()
    field.name="HDVegetationAndProps"
    root.add_child(field)
    var trunk:=_mat(Color("#543b29"),0.92)
    var leaf1:=_mat(Color("#3f7a4d"),0.92)
    var leaf2:=_mat(Color("#5b9858"),0.90)
    var rock:=_mat(Color("#73766e"),0.98)
    var flower:=_mat(Color("#e7c8e9"),0.62)
    var spots=[Vector3(-27,0,-7),Vector3(27,0,-7),Vector3(-25,0,15),Vector3(25,0,15),Vector3(-18,0,20),Vector3(18,0,20),Vector3(-32,0,8),Vector3(32,0,8)]
    for i in range(spots.size()):
        var p:Vector3=spots[i]
        _cylinder(field,"TreeTrunk",0.42,3.8,p+Vector3(0,1.9,0),trunk,20)
        _sphere(field,"TreeCrownA",1.7,p+Vector3(0,4.0,0),leaf1 if i%2==0 else leaf2)
        _sphere(field,"TreeCrownB",1.25,p+Vector3(0.9,4.7,0.2),leaf2 if i%2==0 else leaf1)
        _sphere(field,"TreeCrownC",1.1,p+Vector3(-0.8,4.45,-0.3),leaf1)
    for i in range(18):
        var x:float=-34.0+float((i*17)%68)
        var z:float=-4.0+float((i*23)%30)
        var p:=Vector3(x,0,z)
        var r:=_sphere(field,"Rock",0.45,p+Vector3(0,0.35,0),rock)
        r.scale=Vector3(1.35,0.65,1.0)
        _sphere(field,"Flower",0.10,p+Vector3(0.45,0.18,0.25),flower)

func _build_dungeon_approach() -> void:
    var d:=Node3D.new()
    d.name="HDDungeonApproach"
    root.add_child(d)
    var stone:=_mat(Color("#3e4650"),0.84,0.05)
    var moss:=_mat(Color("#4e765e"),0.94)
    for side in [-1.0,1.0]:
        _cylinder(d,"AncientPillar",0.55,5.5,Vector3(side*4.0,2.75,23),stone,28)
        _cylinder(d,"PillarCap",0.85,0.38,Vector3(side*4.0,5.55,23),stone,28)
        _sphere(d,"Moss",0.52,Vector3(side*4.0,5.75,23),moss)
    _box(d,"AncientLintel",Vector3(9.0,0.8,0.9),Vector3(0,5.25,23),stone)
    var portal_mat:=_mat(Color("#7b6cff"),0.24,0.05,Color("#6e5cff"),2.0)
    var portal:=_cylinder(d,"PortalCore",2.0,0.12,Vector3(0,2.8,22.5),portal_mat,48)
    portal.rotation_degrees.x=90.0

func _upgrade_environment() -> void:
    var env_node:=scene.get_node_or_null("HWFinalWorldEnvironment") as WorldEnvironment
    if env_node==null:
        env_node=WorldEnvironment.new()
        env_node.name="HWFinalWorldEnvironment"
        scene.add_child(env_node)
    var env:=env_node.environment
    if env==null:
        env=Environment.new()
        env_node.environment=env
    env.background_mode=Environment.BG_SKY
    var sky:=env.sky
    if sky==null:
        sky=Sky.new()
        env.sky=sky
    var sky_mat:=sky.sky_material as ProceduralSkyMaterial
    if sky_mat==null:
        sky_mat=ProceduralSkyMaterial.new()
        sky.sky_material=sky_mat
    sky_mat.sky_top_color=Color("#214d82")
    sky_mat.sky_horizon_color=Color("#d7e8ef")
    sky_mat.ground_bottom_color=Color("#1c2921")
    sky_mat.ground_horizon_color=Color("#76907e")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_SKY
    env.ambient_light_energy=0.95
    env.ambient_light_sky_contribution=0.82
    env.tonemap_mode=Environment.TONE_MAPPER_ACES
    env.tonemap_exposure=0.85
    env.ssao_enabled=true
    env.ssao_radius=2.4
    env.ssao_intensity=1.55
    env.glow_enabled=true
    env.glow_intensity=0.48
    env.glow_bloom=0.10
    env.glow_hdr_threshold=1.15
    env.fog_enabled=true
    env.fog_light_color=Color("#b7ccd1")
    env.fog_light_energy=0.16
    env.fog_density=0.0012
    env.fog_height=10.0
    env.fog_height_density=0.008
    var sun:=scene.get_node_or_null("HWFinalSun") as DirectionalLight3D
    if sun==null:
        sun=DirectionalLight3D.new()
        sun.name="HWFinalSun"
        scene.add_child(sun)
    sun.rotation_degrees=Vector3(-48,-30,0)
    sun.light_energy=1.55
    sun.light_color=Color("#ffe7bd")
    sun.shadow_enabled=true
    sun.directional_shadow_max_distance=140.0
    sun.light_angular_distance=0.12
    sun.shadow_bias=0.02
    sun.shadow_normal_bias=1.0
    var fill:=scene.get_node_or_null("HWFinalFill") as DirectionalLight3D
    if fill==null:
        fill=DirectionalLight3D.new()
        fill.name="HWFinalFill"
        scene.add_child(fill)
    fill.rotation_degrees=Vector3(-25,145,0)
    fill.light_energy=0.48
    fill.light_color=Color("#a7c9ff")
    fill.shadow_enabled=false
