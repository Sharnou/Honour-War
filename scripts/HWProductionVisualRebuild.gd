extends Node3D

## Honour War production visual rebuild.
## Native Godot runtime art only. Gameplay state remains in Game3D/CombatRuntime.
## The layer deliberately hides the old stacked world dressing so the final
## framebuffer contains one coherent medieval scene instead of overlapping
## primitive passes.

const WORLD_NAME:String = "HWProductionVisualWorld"
const HERO_DETAIL_NAME:String = "HWProductionHeroVisual"
const MONSTER_DETAIL_NAME:String = "HWProductionMonsterVisual"

var scene:Node3D
var world:Node3D
var actors:Node3D
var hero_visual:Node3D
var monster_visuals:Dictionary = {}
var built:bool = false
var elapsed:float = 0.0
var grass_tex:Texture2D
var dirt_tex:Texture2D
var stone_tex:Texture2D
var wood_tex:Texture2D
var roof_tex:Texture2D

func _ready() -> void:
    process_priority = 2000
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("_build_after_runtime")

func _build_after_runtime() -> void:
    for _i in range(3):
        await get_tree().process_frame
    scene = get_tree().current_scene as Node3D
    if scene == null:
        return
    _retire_old_world_dressing()
    _build_textures()
    _build_world()
    _bind_combat()
    _refresh_actors()
    built = true

func _process(delta:float) -> void:
    elapsed += delta
    if scene == null or not is_instance_valid(scene):
        scene = get_tree().current_scene as Node3D
        return
    if not built:
        return
    if fmod(elapsed,0.25) < delta:
        _refresh_actors()
    _animate_world()
    _animate_monsters()

func _retire_old_world_dressing() -> void:
    var old_world:Node3D = scene.get_node_or_null("World3D") as Node3D
    if old_world != null:
        # Keep World3D alive for combat VFX and future gameplay additions, but
        # hide only the geometry that existed before this rebuild.
        for child:Node in old_world.get_children():
            if child.name == "QualityDecor":
                child.visible = false
                continue
            child.visible = false
        old_world.set_meta("legacy_geometry_hidden_by_production_rebuild",true)

    for node_name:String in [
        "HDEnvironmentDirector",
        "HWHDDetailPassVNext",
        "HWMapDetailBoost",
        "HWPronteraReferenceDetail",
        "HWHDContent",
        "HDPresentationWorld"
    ]:
        var node:Node = scene.get_node_or_null(node_name)
        if node != null:
            node.visible = false

    # Existing actor roots remain authoritative; only their primitive MeshInstance
    # children are hidden when the production detail replacement is installed.
    actors = scene.get_node_or_null("Actors3D") as Node3D

func _noise_texture(seed_value:int,frequency:float,contrast:float)->Texture2D:
    var noise:=FastNoiseLite.new()
    noise.seed=seed_value
    noise.frequency=frequency
    noise.fractal_octaves=4
    noise.fractal_lacunarity=2.0
    noise.fractal_gain=0.55
    var tex:=NoiseTexture2D.new()
    tex.noise=noise
    tex.width=256
    tex.height=256
    tex.seamless=true
    tex.normalize=true
    tex.as_normal_map=false
    return tex

func _build_textures() -> void:
    grass_tex=_noise_texture(4812,0.045,1.0)
    dirt_tex=_noise_texture(9271,0.065,1.0)
    stone_tex=_noise_texture(1947,0.085,1.0)
    wood_tex=_noise_texture(7331,0.055,1.0)
    roof_tex=_noise_texture(2119,0.07,1.0)

func _mat(color:Color,roughness:float,metallic:float=0.0,texture:Texture2D=null)->StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.albedo_color=color
    m.roughness=roughness
    m.metallic=metallic
    m.specular_mode=BaseMaterial3D.SPECULAR_SCHLICK_GGX
    m.shading_mode=BaseMaterial3D.SHADING_MODE_PER_PIXEL
    if texture!=null:
        m.albedo_texture=texture
        m.uv1_scale=Vector3(5.0,5.0,5.0)
    return m

func _emissive(color:Color,energy:float)->StandardMaterial3D:
    var m:=_mat(color,0.28,0.05)
    m.emission_enabled=true
    m.emission=color
    m.emission_energy_multiplier=energy
    return m

func _resolve_material(value:Variant,roughness:float=0.82,metallic:float=0.0)->Material:
    if value is Material:
        return value as Material
    if value is Color:
        return _mat(value as Color,roughness,metallic)
    return _mat(Color("#ffffff"),roughness,metallic)

func _box(parent:Node,name:String,size:Vector3,pos:Vector3,material_value:Variant)->MeshInstance3D:
    var n:=MeshInstance3D.new()
    n.name=name
    var mesh:=BoxMesh.new()
    mesh.size=size
    n.mesh=mesh
    n.position=pos
    n.material_override=_resolve_material(material_value)
    parent.add_child(n)
    return n

func _cylinder(parent:Node,name:String,radius:float,height:float,pos:Vector3,material_value:Variant,sides:int=28)->MeshInstance3D:
    var n:=MeshInstance3D.new()
    n.name=name
    var mesh:=CylinderMesh.new()
    mesh.top_radius=radius
    mesh.bottom_radius=radius
    mesh.height=height
    mesh.radial_segments=sides
    n.mesh=mesh
    n.position=pos
    n.material_override=_resolve_material(material_value)
    parent.add_child(n)
    return n

func _cone(parent:Node,name:String,radius:float,height:float,pos:Vector3,material_value:Variant)->MeshInstance3D:
    var n:=MeshInstance3D.new()
    n.name=name
    var mesh:=CylinderMesh.new()
    mesh.top_radius=0.02
    mesh.bottom_radius=radius
    mesh.height=height
    mesh.radial_segments=32
    n.mesh=mesh
    n.position=pos
    n.material_override=_resolve_material(material_value)
    parent.add_child(n)
    return n

func _sphere(parent:Node,name:String,radius:float,pos:Vector3,material_value:Variant,scale_value:=Vector3.ONE)->MeshInstance3D:
    var n:=MeshInstance3D.new()
    n.name=name
    var mesh:=SphereMesh.new()
    mesh.radius=radius
    mesh.height=radius*2.0
    mesh.radial_segments=28
    mesh.rings=18
    n.mesh=mesh
    n.position=pos
    n.scale=scale_value
    n.material_override=_resolve_material(material_value)
    parent.add_child(n)
    return n

func _ring(parent:Node,name:String,inner:float,outer:float,pos:Vector3,material_value:Variant)->MeshInstance3D:
    var n:=MeshInstance3D.new()
    n.name=name
    var mesh:=TorusMesh.new()
    mesh.inner_radius=inner
    mesh.outer_radius=outer
    mesh.rings=40
    mesh.ring_segments=12
    n.mesh=mesh
    n.position=pos
    n.rotation_degrees.x=90.0
    n.material_override=_resolve_material(material_value)
    parent.add_child(n)
    return n

func _build_world() -> void:
    world=Node3D.new()
    world.name=WORLD_NAME
    scene.add_child(world)

    var center:=Vector3(12.65,0.0,12.10)
    _build_ground(center)
    _build_main_road(center)
    _build_plaza(center+Vector3(0.0,0.02,6.0))
    _build_town_houses(center)
    _build_town_wall(center)
    _build_market(center)
    _build_gardens(center)
    _build_distant_landmarks(center)
    _build_daylight()

func _build_ground(center:Vector3)->void:
    var grass:=_mat(Color("#557e4e"),0.98,0.0,grass_tex)
    var grass_dark:=_mat(Color("#496f45"),1.0,0.0,grass_tex)
    # Large continuous floor: no floating gaps, no black void beneath the map.
    _box(world,"GroundCore",Vector3(140.0,0.42,110.0),center+Vector3(0.0,-0.21,0.0),grass)
    for x in range(-7,8):
        for z in range(-5,7):
            var tile_pos:=center+Vector3(float(x)*6.0,0.015,float(z)*6.0)
            _box(world,"GroundTile",Vector3(5.88,0.045,5.88),tile_pos,grass_dark if (x+z)%3==0 else grass)

func _build_main_road(center:Vector3)->void:
    var dirt:=_mat(Color("#876f55"),0.96,0.0,dirt_tex)
    var stone:=_mat(Color("#9b9588"),0.90,0.0,stone_tex)
    _box(world,"NorthSouthRoad",Vector3(8.4,0.12,72.0),center+Vector3(0.0,0.11,4.0),dirt)
    _box(world,"EastWestRoad",Vector3(74.0,0.12,8.4),center+Vector3(0.0,0.12,4.0),dirt)
    for z in range(-5,15):
        _box(world,"RoadCobble",Vector3(7.4,0.08,0.62),center+Vector3(0.0,0.20,float(z)*3.4-13.0),stone)
    for x in range(-10,11):
        _box(world,"RoadCobbleEW",Vector3(0.62,0.08,7.4),center+Vector3(float(x)*3.4,0.20,4.0),stone)
    for side in [-1.0,1.0]:
        _cylinder(world,"RoadPost",0.10,0.65,center+Vector3(side*5.15,0.34,4.0),_mat(Color("#4f463e"),0.55,0.30),18)

func _build_plaza(center:Vector3)->void:
    var stone:=_mat(Color("#b0aa9a"),0.92,0.0,stone_tex)
    var dark:=_mat(Color("#7e786d"),0.96,0.0,stone_tex)
    var gold:=_mat(Color("#d7b45f"),0.42,0.30)
    _cylinder(world,"GrandPlaza",7.2,0.18,center,stone,48)
    for i in range(12):
        var a:=TAU*float(i)/12.0
        _box(world,"PlazaSpoke",Vector3(0.32,0.055,6.4),center+Vector3(cos(a)*3.2,0.15,sin(a)*3.2),dark).rotation.y=-a
    _cylinder(world,"FountainBase",2.4,0.35,center+Vector3(0,0.32,0),dark,48)
    _cylinder(world,"FountainWater",1.9,0.08,center+Vector3(0,0.54,0),_emissive(Color("#58b9db"),0.22),48)
    _cylinder(world,"FountainColumn",0.36,2.2,center+Vector3(0,1.42,0),stone,32)
    _sphere(world,"FountainCrown",0.62,center+Vector3(0,2.62,0),gold,Vector3(1.0,0.7,1.0))
    for i in range(8):
        var a:=TAU*float(i)/8.0
        _cylinder(world,"PlazaLamp",0.09,2.6,center+Vector3(cos(a)*6.0,1.3,sin(a)*6.0),_mat(Color("#3d4140"),0.46,0.70),18)
        _sphere(world,"PlazaLantern",0.18,center+Vector3(cos(a)*6.0,2.75,sin(a)*6.0),_emissive(Color("#ffd78e"),1.3))

func _build_house(pos:Vector3,index:int,wall:Material,timber:Material,roof:Material,door:Material,glass:Material)->void:
    var house:=Node3D.new()
    house.name="ProductionHouse_%02d"%index
    world.add_child(house)
    _box(house,"Wall",Vector3(6.8,4.2,5.6),pos+Vector3(0,2.1,0),wall)
    _box(house,"TimberH",Vector3(6.95,0.16,0.22),pos+Vector3(0,1.0,2.84),timber)
    _box(house,"TimberH2",Vector3(6.95,0.16,0.22),pos+Vector3(0,3.0,2.84),timber)
    for side in [-1.0,1.0]:
        _box(house,"Beam",Vector3(0.20,4.0,0.24),pos+Vector3(side*3.0,2.1,2.84),timber)
    _box(house,"Door",Vector3(1.05,2.1,0.18),pos+Vector3(0,1.05,2.89),door)
    for side in [-1.0,1.0]:
        _box(house,"WindowFrame",Vector3(1.55,1.35,0.12),pos+Vector3(side*1.95,2.35,2.90),timber)
        _box(house,"WindowGlass",Vector3(1.17,0.95,0.07),pos+Vector3(side*1.95,2.35,2.84),glass)
        _box(house,"CrossH",Vector3(1.18,0.08,0.10),pos+Vector3(side*1.95,2.35,2.78),timber)
        _box(house,"CrossV",Vector3(0.08,1.0,0.10),pos+Vector3(side*1.95,2.35,2.78),timber)
    _cone(house,"Roof",4.25,2.2,pos+Vector3(0,5.0,0),roof)
    _box(house,"RoofTrim",Vector3(7.1,0.12,0.14),pos+Vector3(0,4.08,2.94),timber)
    _cylinder(house,"Chimney",0.30,1.3,pos+Vector3(2.1,5.5,0.6),timber,20)
    _box(house,"ChimneyCap",Vector3(0.7,0.10,0.7),pos+Vector3(2.1,6.16,0.6),door)
    var lamp:=OmniLight3D.new()
    lamp.name="WindowLight"
    lamp.light_color=Color("#ffd38a")
    lamp.light_energy=0.22
    lamp.omni_range=4.0
    lamp.position=pos+Vector3(0,1.9,3.2)
    house.add_child(lamp)

func _build_town_houses(center:Vector3)->void:
    var wall:=_mat(Color("#d1c4a8"),0.82,0.0,stone_tex)
    var wall2:=_mat(Color("#c2b497"),0.85,0.0,stone_tex)
    var timber:=_mat(Color("#5d402c"),0.78,0.0,wood_tex)
    var roof:=_mat(Color("#5a4146"),0.72,0.0,roof_tex)
    var door:=_mat(Color("#34271f"),0.80,0.0,wood_tex)
    var glass:=_mat(Color("#78b9d1"),0.20,0.10)
    var positions:Array[Vector3]=[
        center+Vector3(-12,0,-7),
        center+Vector3(12,0,-7),
        center+Vector3(-12,0,18),
        center+Vector3(12,0,18),
        center+Vector3(-22,0,5),
        center+Vector3(22,0,5)
    ]
    for i in range(positions.size()):
        _build_house(positions[i],i,wall if i%2==0 else wall2,timber,roof,door,glass)

func _build_town_wall(center:Vector3)->void:
    var stone:=_mat(Color("#7b7c77"),0.92,0.0,stone_tex)
    var dark:=_mat(Color("#4c4741"),0.86,0.05,stone_tex)
    _box(world,"TownWallBack",Vector3(68.0,3.6,1.1),center+Vector3(0,1.8,29.0),stone)
    for x in [-30.0,-15.0,15.0,30.0]:
        _cylinder(world,"WallTower",2.0,6.0,center+Vector3(x,3.0,29.0),stone,32)
        _cone(world,"TowerRoof",2.35,1.7,center+Vector3(x,6.85,29.0),dark)
    _box(world,"GateArch",Vector3(10.5,5.5,1.8),center+Vector3(0,2.75,29.0),stone)
    _box(world,"GateVoid",Vector3(4.2,4.3,1.95),center+Vector3(0,2.15,28.15),_mat(Color("#273128"),0.99))
    _box(world,"GateDoorL",Vector3(2.0,4.0,0.22),center+Vector3(-1.05,2.0,28.05),dark)
    _box(world,"GateDoorR",Vector3(2.0,4.0,0.22),center+Vector3(1.05,2.0,28.05),dark)

func _build_market(center:Vector3)->void:
    var timber:=_mat(Color("#654531"),0.80,0.0,wood_tex)
    var cloth_a:=_mat(Color("#a74d54"),0.82)
    var cloth_b:=_mat(Color("#4e6b84"),0.82)
    var gold:=_mat(Color("#d9bb69"),0.40,0.28)
    for i in range(4):
        var p:=center+Vector3(-7.5+float(i%2)*15.0,0,0.4+float(i/2)*9.0)
        _box(world,"StallCounter",Vector3(4.0,1.05,1.35),p+Vector3(0,0.54,0),timber)
        _box(world,"StallRoof",Vector3(4.4,0.18,2.8),p+Vector3(0,3.0,0),cloth_a if i%2==0 else cloth_b)
        for side in [-1.0,1.0]:
            _cylinder(world,"StallPost",0.10,3.0,p+Vector3(side*1.8,1.5,-1.15),timber,18)
        for j in range(5):
            _sphere(world,"Goods",0.13,p+Vector3(-1.15+float(j)*0.56,1.45,-0.68),gold,Vector3(1.0,0.75,1.0))

func _build_gardens(center:Vector3)->void:
    var soil:=_mat(Color("#5c3d2a"),0.99,0.0,dirt_tex)
    var green:=_mat(Color("#4f8a55"),0.98,0.0,grass_tex)
    var flower:=_mat(Color("#e5b96f"),0.72,0.0)
    var trunk:=_mat(Color("#60442e"),0.98,0.0,wood_tex)
    for p:Vector3 in [
        center+Vector3(-28,0,-8),
        center+Vector3(28,0,-8),
        center+Vector3(-29,0,18),
        center+Vector3(29,0,18),
        center+Vector3(-20,0,34),
        center+Vector3(20,0,34)
    ]:
        _box(world,"GardenBed",Vector3(4.6,0.16,3.2),p+Vector3(0,0.08,0),soil)
        for j in range(5):
            _sphere(world,"GardenPlant",0.22,p+Vector3(-1.6+float(j)*0.8,0.32,0.0),green,Vector3(1.0,0.72,1.0))
            _sphere(world,"GardenFlower",0.075,p+Vector3(-1.6+float(j)*0.8,0.56,0.18),flower)
    # Trees stay at the perimeter so the player/hero never gets buried under a
    # giant canopy in the gameplay frame.
    var tree_points:Array[Vector3]=[
        center+Vector3(-37,0,-12),center+Vector3(37,0,-12),
        center+Vector3(-40,0,5),center+Vector3(40,0,5),
        center+Vector3(-38,0,24),center+Vector3(38,0,24),
        center+Vector3(-27,0,39),center+Vector3(27,0,39)
    ]
    for i in range(tree_points.size()):
        var p:Vector3=tree_points[i]
        _cylinder(world,"TreeTrunk",0.32,3.4,p+Vector3(0,1.7,0),trunk,24)
        _sphere(world,"TreeCrown",1.55,p+Vector3(0,4.0,0),green,Vector3(1.0,0.72,1.0))
        _sphere(world,"TreeCrownSmall",1.0,p+Vector3(0.95,4.45,0.30),green,Vector3(1.0,0.7,1.0))

func _build_distant_landmarks(center:Vector3)->void:
    var stone:=_mat(Color("#80827e"),0.94,0.02,stone_tex)
    var roof:=_mat(Color("#55464f"),0.76,0.0,roof_tex)
    for x in [-28.0,28.0]:
        _box(world,"GuildHall",Vector3(9.0,6.0,8.0),center+Vector3(x,3.0,12.0),stone)
        _cone(world,"GuildRoof",5.6,2.6,center+Vector3(x,7.3,12.0),roof)

func _build_daylight() -> void:
    var env_node:=WorldEnvironment.new()
    env_node.name="HWProductionVisualEnvironment"
    var env:=Environment.new()
    env.background_mode=Environment.BG_SKY
    var sky:=Sky.new()
    var sky_mat:=ProceduralSkyMaterial.new()
    sky_mat.sky_top_color=Color("#5c82ad")
    sky_mat.sky_horizon_color=Color("#dce9ee")
    sky_mat.ground_bottom_color=Color("#31433b")
    sky_mat.ground_horizon_color=Color("#91a28d")
    sky.sky_material=sky_mat
    env.sky=sky
    env.ambient_light_source=Environment.AMBIENT_SOURCE_SKY
    env.ambient_light_energy=0.90
    env.ambient_light_sky_contribution=0.78
    env.tonemap_mode=Environment.TONE_MAPPER_ACES
    env.tonemap_exposure=0.10
    env.tonemap_white=1.10
    env.fog_enabled=false
    env.glow_enabled=true
    env.glow_intensity=0.22
    env.glow_bloom=0.03
    scene.add_child(env_node)
    env_node.environment=env

    var sun:=DirectionalLight3D.new()
    sun.name="HWProductionVisualSun"
    sun.rotation_degrees=Vector3(-52.0,-32.0,0.0)
    sun.light_energy=1.00
    sun.light_color=Color("#fff1d3")
    sun.shadow_enabled=true
    sun.directional_shadow_max_distance=120.0
    sun.shadow_bias=0.03
    sun.shadow_normal_bias=1.0
    scene.add_child(sun)

func _find_hero()->Node3D:
    var value:Variant=scene.get("hero_visual")
    if value is Node3D and is_instance_valid(value):
        return value as Node3D
    return scene.get_node_or_null("Actors3D/Hero") as Node3D

func _hide_actor_meshes(actor:Node3D)->void:
    if actor==null or not is_instance_valid(actor):
        return
    for node:Node in actor.find_children("*","MeshInstance3D",true,false):
        if node is MeshInstance3D:
            (node as MeshInstance3D).visible=false
    for node:Node in actor.find_children("*","OmniLight3D",true,false):
        if node is OmniLight3D:
            (node as OmniLight3D).light_energy=0.0

func _build_hero_detail(actor:Node3D)->void:
    if actor.get_node_or_null(HERO_DETAIL_NAME)!=null:
        return
    _hide_actor_meshes(actor)
    var root:=Node3D.new()
    root.name=HERO_DETAIL_NAME
    actor.add_child(root)

    var class_id:String=str(actor.get_meta("class","Warrior"))
    var accent:Color=_class_accent(class_id)
    var dark:Color=accent.darkened(0.60)
    var steel:=_mat(Color("#566575"),0.38,0.72)
    var leather:=_mat(Color("#593b2b"),0.86,0.0,wood_tex)
    var cloth:=_mat(Color("#202832"),0.92,0.0)
    var skin:=_mat(Color("#dca987"),0.86,0.0)
    var hair:=_mat(Color("#2b2630"),0.76,0.0,wood_tex)

    _capsule_mesh(root,"LegL",0.19,0.78,Vector3(-0.23,0.47,0),dark)
    _capsule_mesh(root,"LegR",0.19,0.78,Vector3(0.23,0.47,0),dark)
    _box(root,"BootL",Vector3(0.34,0.26,0.58),Vector3(-0.23,0.11,-0.06),leather)
    _box(root,"BootR",Vector3(0.34,0.26,0.58),Vector3(0.23,0.11,-0.06),leather)
    _capsule_mesh(root,"Torso",0.40,1.10,Vector3(0,1.22,0),cloth)
    _box(root,"ChestArmor",Vector3(0.82,0.66,0.52),Vector3(0,1.50,-0.06),steel)
    _box(root,"WaistCloth",Vector3(0.94,0.24,0.58),Vector3(0,1.03,0),accent.darkened(0.25))
    _box(root,"Belt",Vector3(0.98,0.12,0.62),Vector3(0,1.12,-0.02),leather)
    _box(root,"Buckle",Vector3(0.16,0.16,0.08),Vector3(0,1.13,-0.33),_mat(Color("#e1c36d"),0.30,0.72))
    _capsule_mesh(root,"ArmL",0.16,0.72,Vector3(-0.60,1.39,0),accent)
    _capsule_mesh(root,"ArmR",0.16,0.72,Vector3(0.60,1.39,0),accent)
    _sphere(root,"GloveL",0.17,Vector3(-0.62,1.02,0),leather)
    _sphere(root,"GloveR",0.17,Vector3(0.62,1.02,0),leather)
    _sphere(root,"ShoulderL",0.25,Vector3(-0.58,1.68,0),steel,Vector3(1.18,0.72,1.10))
    _sphere(root,"ShoulderR",0.25,Vector3(0.58,1.68,0),steel,Vector3(1.18,0.72,1.10))
    _cylinder(root,"Neck",0.15,0.24,Vector3(0,1.92,0),skin,20)
    _sphere(root,"Head",0.41,Vector3(0,2.30,0),skin,Vector3(1.0,1.08,0.95))
    _sphere(root,"Hair",0.47,Vector3(0,2.50,-0.02),hair,Vector3(1.10,0.72,1.02))
    _sphere(root,"Fringe",0.28,Vector3(0,2.38,0.32),hair,Vector3(1.45,0.50,0.50))
    var eye:=_mat(Color("#18232c"),0.32,0.0)
    _sphere(root,"EyeL",0.060,Vector3(-0.14,2.32,0.37),eye)
    _sphere(root,"EyeR",0.060,Vector3(0.14,2.32,0.37),eye)
    _sphere(root,"EyeSpecL",0.019,Vector3(-0.125,2.34,0.405),_mat(Color.WHITE,0.28))
    _sphere(root,"EyeSpecR",0.019,Vector3(0.155,2.34,0.405),_mat(Color.WHITE,0.28))
    _sphere(root,"Nose",0.040,Vector3(0,2.23,0.40),skin)
    _ring(root,"ContactRing",0.72,0.77,Vector3(0,0.05,0),_emissive(accent,0.45))

    var weapon:=Node3D.new()
    weapon.name="Weapon"
    root.add_child(weapon)
    if class_id=="Mage":
        _cylinder(weapon,"Staff",0.055,1.95,Vector3(0.64,1.30,0),leather,18)
        _sphere(weapon,"StaffGem",0.16,Vector3(0.64,2.31,0),_emissive(accent,1.2))
    elif class_id=="Archer":
        var bow:=_ring(weapon,"Bow",0.34,0.06,Vector3(0.67,1.60,0),accent)
        bow.rotation_degrees.y=90.0
    else:
        _box(weapon,"Blade",Vector3(0.12,1.35,0.20),Vector3(0.68,1.34,0),steel).rotation_degrees.z=12.0
        _box(weapon,"Guard",Vector3(0.58,0.08,0.09),Vector3(0.67,0.70,0),_mat(Color("#e0c26c"),0.28,0.68))

    match class_id:
        "Mage":
            _ring(root,"Mantle",0.58,0.08,Vector3(0,1.58,0),accent)
        "Archer":
            _box(root,"Quiver",Vector3(0.24,0.76,0.20),Vector3(-0.47,1.32,0.16),leather).rotation_degrees.z=-14.0
        "Thief":
            _box(root,"Scarf",Vector3(1.02,0.13,0.24),Vector3(0,1.82,0.26),Color("#3a1d42"))
        "Acolyte":
            _ring(root,"Halo",0.36,0.055,Vector3(0,2.82,0),_emissive(Color("#ffe899"),0.7))
        "Merchant":
            _box(root,"Satchel",Vector3(0.36,0.42,0.28),Vector3(-0.64,1.20,0.05),leather)

func _capsule_mesh(parent:Node,name:String,radius:float,height:float,pos:Vector3,material_value:Variant)->MeshInstance3D:
    var n:=MeshInstance3D.new()
    n.name=name
    var mesh:=CapsuleMesh.new()
    mesh.radius=radius
    mesh.height=height
    mesh.radial_segments=24
    mesh.rings=10
    n.mesh=mesh
    n.position=pos
    n.material_override=_resolve_material(material_value,0.86,0.03)
    parent.add_child(n)
    return n

func _class_accent(class_id:String)->Color:
    match class_id:
        "Mage": return Color("#7669dc")
        "Archer": return Color("#5fae6c")
        "Thief": return Color("#a35bd1")
        "Acolyte": return Color("#d6ba63")
        "Merchant": return Color("#bd7548")
    return Color("#5d81ba")

func _refresh_actors()->void:
    if scene==null:
        return
    hero_visual=_find_hero()
    if hero_visual!=null and is_instance_valid(hero_visual):
        _build_hero_detail(hero_visual)

    var visuals:Variant=scene.get("monster_visuals")
    if visuals is Dictionary:
        for key:Variant in (visuals as Dictionary).keys():
            var actor_value:Variant=(visuals as Dictionary)[key]
            if not is_instance_valid(actor_value) or not actor_value is Node3D:
                continue
            var actor:Node3D=actor_value as Node3D
            _build_monster_detail(actor,str(key))

func _build_monster_detail(actor:Node3D,id:String)->void:
    var detail_name:=MONSTER_DETAIL_NAME
    var root:=actor.get_node_or_null(detail_name) as Node3D
    if root!=null:
        monster_visuals[id]=root
        return
    _hide_actor_meshes(actor)
    root=Node3D.new()
    root.name=detail_name
    actor.add_child(root)
    var name_lower:=id.to_lower()
    var c:=Color("#7f8e9b")
    if name_lower.contains("poring"): c=Color("#ec92b8")
    elif name_lower.contains("goblin"): c=Color("#6e9e68")
    elif name_lower.contains("wolf"): c=Color("#657989")
    elif name_lower.contains("skeleton"): c=Color("#d0c5aa")
    elif name_lower.contains("zombie"): c=Color("#6b866f")
    elif name_lower.contains("orc"): c=Color("#4f744b")
    elif name_lower.contains("mantis"): c=Color("#72a552")
    elif name_lower.contains("golem"): c=Color("#868b91")
    elif name_lower.contains("dragon"): c=Color("#a9525f")
    elif name_lower.contains("druid"): c=Color("#5e6f91")
    var body:=_capsule_mesh(root,"Body",0.46,1.16,Vector3(0,0.76,0),c)
    body.scale=Vector3(1.0,1.0,0.82)
    _sphere(root,"Head",0.40,Vector3(0,1.52,0),c.lightened(0.08),Vector3(1.08,0.95,0.98))
    var eye:=_emissive(Color("#ffd45a"),1.2)
    _sphere(root,"EyeL",0.065,Vector3(-0.14,1.56,0.36),eye)
    _sphere(root,"EyeR",0.065,Vector3(0.14,1.56,0.36),eye)
    if name_lower.contains("wolf"):
        _sphere(root,"Snout",0.24,Vector3(0,1.40,0.43),c.darkened(0.18),Vector3(1.0,0.8,1.25))
        _cone(root,"EarL",0.18,0.48,Vector3(-0.23,1.93,0),c.darkened(0.12))
        _cone(root,"EarR",0.18,0.48,Vector3(0.23,1.93,0),c.darkened(0.12))
    elif name_lower.contains("golem"):
        _box(root,"Shoulder",Vector3(1.16,0.32,0.74),Vector3(0,1.18,0),c.darkened(0.10))
        _box(root,"Core",Vector3(0.28,0.42,0.10),Vector3(0,1.20,-0.40),_emissive(Color("#77d8e4"),1.0))
    elif name_lower.contains("dragon"):
        _cone(root,"Crown",0.32,0.72,Vector3(0,2.05,0),c.darkened(0.18))
        _box(root,"WingL",Vector3(0.08,1.18,1.25),Vector3(-0.70,1.30,0.05),c.darkened(0.12))
        _box(root,"WingR",Vector3(0.08,1.18,1.25),Vector3(0.70,1.30,0.05),c.darkened(0.12))
    _ring(root,"ContactRing",0.52,0.57,Vector3(0,0.04,0),_emissive(c,0.32))
    monster_visuals[id]=root

func _animate_world()->void:
    if world==null or not is_instance_valid(world):
        return
    var water:=world.get_node_or_null("GrandPlaza/GrandFountainWater") as Node3D
    if water!=null:
        water.scale=Vector3.ONE*(1.0+sin(elapsed*1.8)*0.015)

func _animate_monsters()->void:
    for id in monster_visuals.keys():
        var root_value:Variant=monster_visuals[id]
        if not is_instance_valid(root_value) or not root_value is Node3D:
            monster_visuals.erase(id)
            continue
        var root:Node3D=root_value as Node3D
        var phase:=elapsed*5.0+float(abs(hash(str(id)))%100)*0.01
        root.position.y=sin(phase)*0.035
        root.rotation.z=sin(phase*0.85)*0.02

func _bind_combat()->void:
    var combat:=scene.get_node_or_null("LegacyGame/CombatRuntime")
    if combat==null:
        combat=scene.get_node_or_null("CombatRuntime")
    if combat==null:
        return
    if combat.has_signal("hero_attack_landed") and not combat.hero_attack_landed.is_connected(_on_hero_attack):
        combat.hero_attack_landed.connect(_on_hero_attack)

func _on_hero_attack(target:Dictionary,damage:int,critical:bool)->void:
    var id:=str(target.get("id",""))
    var actor_value:Variant=(scene.get("monster_visuals")[id] if scene.get("monster_visuals") is Dictionary and (scene.get("monster_visuals") as Dictionary).has(id) else null)
    if not is_instance_valid(actor_value) or not actor_value is Node3D:
        return
    var actor:Node3D=actor_value as Node3D
    var fx:=_ring(world,"CombatHit",0.16,0.28,actor.global_position+Vector3(0,0.85,0),_emissive(Color("#ffe18a"),2.4))
    fx.scale=Vector3.ONE*(1.0+(0.35 if critical else 0.0))
    var tween:=create_tween()
    tween.tween_property(fx,"scale",Vector3.ONE*1.8,0.22)
    tween.tween_callback(fx.queue_free)
    if damage>0:
        var label:=Label3D.new()
        label.text=str(damage)
        label.font_size=36 if not critical else 44
        label.outline_size=8
        label.modulate=Color("#ffe9a3") if critical else Color.WHITE
        label.position=actor.global_position+Vector3(0,1.15,0)
        world.add_child(label)
        var label_tween:=create_tween()
        label_tween.tween_property(label,"position:y",label.position.y+0.8,0.40)
        label_tween.tween_callback(label.queue_free)
