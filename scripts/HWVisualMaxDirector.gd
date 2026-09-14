extends Node3D

## Honour War — Visual MAX pass.
## This is the runtime presentation layer for the current Godot prototype.
## It deliberately moves the scene away from primitive/blockout presentation:
## richer lighting, atmospheric depth, authored-looking modular architecture,
## readable fantasy silhouettes, materials, props, vegetation and VFX.
## Production GLB assets remain preferred when HWGeneratedAssetRuntime finds them.

var scene:Node3D
var world:Node3D
var actors:Node3D
var built_world:bool = false
var detailed_actors:Dictionary = {}
var last_hero_class:String = ""

func _ready() -> void:
    call_deferred("_bind_and_build")

func _process(_delta:float) -> void:
    if scene == null or not is_instance_valid(scene):
        _bind_and_build()
        return
    _hide_legacy_labels(scene)
    _upgrade_environment()
    _upgrade_hero()
    _upgrade_pet()
    _upgrade_monsters()

func _bind_and_build() -> void:
    scene = get_tree().current_scene as Node3D
    if scene == null:
        return
    world = scene.get_node_or_null("World3D") as Node3D
    actors = scene.get_node_or_null("Actors3D") as Node3D
    if world == null or actors == null:
        return
    _upgrade_environment()
    if not built_world:
        built_world = true
        _build_premium_town()
    _hide_legacy_labels(scene)

func _upgrade_environment() -> void:
    var env_node:WorldEnvironment = scene.get_node_or_null("HWVisualMaxEnvironment") as WorldEnvironment
    if env_node == null:
        env_node = WorldEnvironment.new()
        env_node.name = "HWVisualMaxEnvironment"
        scene.add_child(env_node)
    var env:Environment = env_node.environment
    if env == null:
        env = Environment.new()
        env_node.environment = env
    env.background_mode = Environment.BG_SKY
    var sky:Sky = env.sky
    if sky == null:
        sky = Sky.new()
        var sky_mat:ProceduralSkyMaterial = ProceduralSkyMaterial.new()
        sky_mat.sky_top_color = Color("#1c4f91")
        sky_mat.sky_horizon_color = Color("#bfe8ff")
        sky_mat.ground_bottom_color = Color("#18222c")
        sky_mat.ground_horizon_color = Color("#8aa8ad")
        sky_mat.sun_angle_max = 18.0
        sky_mat.sun_curve = 0.08
        sky.material = sky_mat
        env.sky = sky
    env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    env.ambient_light_energy = 0.95
    env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env.tonemap_exposure = 1.08
    env.glow_enabled = true
    env.glow_intensity = 1.15
    env.glow_bloom = 0.18
    env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
    env.ssao_enabled = true
    env.ssao_radius = 2.2
    env.ssao_intensity = 2.0
    env.ssil_enabled = true
    env.ssil_radius = 4.0
    env.ssil_intensity = 1.15
    env.fog_enabled = true
    env.fog_light_color = Color("#a8c6cf")
    env.fog_light_energy = 0.45
    env.fog_density = 0.006
    env.fog_height = 1.2
    env.fog_height_density = 0.018
    env.volumetric_fog_enabled = true
    env.volumetric_fog_density = 0.018
    env.volumetric_fog_albedo = Color("#b9d5dc")
    env.volumetric_fog_emission = Color("#29445a")
    env.volumetric_fog_emission_energy = 0.08
    env.volumetric_fog_length = 48.0
    var sun:DirectionalLight3D = scene.get_node_or_null("HWVisualMaxSun") as DirectionalLight3D
    if sun == null:
        sun = DirectionalLight3D.new()
        sun.name = "HWVisualMaxSun"
        scene.add_child(sun)
    sun.rotation_degrees = Vector3(-48.0,-28.0,0.0)
    sun.light_energy = 1.65
    sun.light_color = Color("#fff1d2")
    sun.shadow_enabled = true
    sun.directional_shadow_max_distance = 90.0
    sun.directional_shadow_fade_start = 0.78
    sun.shadow_bias = 0.025

func _build_premium_town() -> void:
    var root:Node3D = Node3D.new()
    root.name = "HW_PremiumTownArt"
    world.add_child(root)
    var center:Vector3 = Vector3(12.925,0.0,12.65)
    _stone_courtyard(root,center+Vector3(0,0.10,5.0))
    _grand_fountain(root,center+Vector3(0,0.15,5.0))
    _building(root,center+Vector3(-12,0,-7),"Inn",Color("#8b624a"),Color("#6d2f3b"),true)
    _building(root,center+Vector3(12,0,-7),"Guild",Color("#566a80"),Color("#324b72"),true)
    _building(root,center+Vector3(-12,0,13),"Forge",Color("#74533f"),Color("#4c3030"),false)
    _building(root,center+Vector3(12,0,13),"Academy",Color("#74658b"),Color("#4a376f"),true)
    _market_stalls(root,center)
    _street_lamps(root,center)
    _banners(root,center)
    _vegetation(root,center)
    _castle_horizon(root,center)
    _floating_landmark(root,center+Vector3(21,15,-12))

func _stone_courtyard(root:Node3D,center:Vector3)->void:
    var mat:StandardMaterial3D=_mat(Color("#817a70"),0.0,0.72)
    for x in range(-9,10):
        for z in range(-4,5):
            var p:Vector3=center+Vector3(float(x)*0.95,0.0,float(z)*0.92)
            var tile:MeshInstance3D=_box(mat,Vector3(0.88,0.07,0.84),p)
            tile.rotation_degrees.y=float((x*17+z*11)%7)-3.0
            root.add_child(tile)
    var edge:StandardMaterial3D=_mat(Color("#554d46"),0.0,0.60)
    for x in range(-10,11):
        root.add_child(_box(edge,Vector3(0.82,0.18,0.34),center+Vector3(float(x)*0.9,-0.01,-4.8)))
        root.add_child(_box(edge,Vector3(0.82,0.18,0.34),center+Vector3(float(x)*0.9,-0.01,4.8)))

func _grand_fountain(root:Node3D,center:Vector3)->void:
    var stone:StandardMaterial3D=_mat(Color("#a9a39a"),0.05,0.55)
    var gold:StandardMaterial3D=_mat(Color("#d6b35c"),0.72,0.23)
    var water:StandardMaterial3D=_mat(Color("#4dc7ee"),0.12,0.10)
    root.add_child(_cyl(stone,4.2,0.28,center+Vector3(0,0.18,0),64))
    root.add_child(_cyl(water,3.6,0.06,center+Vector3(0,0.36,0),64))
    root.add_child(_cyl(stone,1.8,1.05,center+Vector3(0,0.72,0),48))
    root.add_child(_cyl(water,1.45,0.05,center+Vector3(0,1.27,0),48))
    for i in range(8):
        var a:float=TAU*float(i)/8.0
        var statue:Node3D=Node3D.new()
        statue.position=center+Vector3(cos(a)*2.9,0.55,sin(a)*2.9)
        root.add_child(statue)
        statue.add_child(_cyl(gold,0.08,0.75,Vector3(0,0.55,0)))
        statue.add_child(_sphere(gold,0.16,Vector3(0,0.98,0)))

func _building(root:Node3D,pos:Vector3,label:String,wall:Color,roof_color:Color,windows:bool)->void:
    var wall_m:StandardMaterial3D=_mat(wall,0.0,0.78)
    var wood:StandardMaterial3D=_mat(Color("#3e2922"),0.0,0.68)
    var roof_m:StandardMaterial3D=_mat(roof_color,0.05,0.62)
    var glass:StandardMaterial3D=_mat(Color("#72c8dc"),0.18,0.18)
    var door_m:StandardMaterial3D=_mat(Color("#5a3425"),0.0,0.56)
    root.add_child(_box(wall_m,Vector3(5.8,3.8,4.7),pos+Vector3(0,1.9,0),0.18))
    var roof:MeshInstance3D=_cone(roof_m,4.4,2.2,pos+Vector3(0,4.9,0),4)
    roof.rotation_degrees.y=45.0
    root.add_child(roof)
    root.add_child(_box(wood,Vector3(6.0,0.22,0.24),pos+Vector3(0,3.05,2.42),0.05))
    root.add_child(_box(wood,Vector3(0.22,3.3,0.24),pos+Vector3(-2.5,1.9,2.42),0.04))
    root.add_child(_box(wood,Vector3(0.22,3.3,0.24),pos+Vector3(2.5,1.9,2.42),0.04))
    root.add_child(_box(door_m,Vector3(1.15,2.1,0.12),pos+Vector3(0,1.05,2.42),0.08))
    if windows:
        for x in [-1.75,1.75]:
            root.add_child(_box(glass,Vector3(1.05,1.0,0.08),pos+Vector3(x,2.0,2.43),0.08))
            root.add_child(_box(wood,Vector3(1.15,0.08,0.10),pos+Vector3(x,2.0,2.50),0.02))
            root.add_child(_box(wood,Vector3(0.08,1.05,0.10),pos+Vector3(x,2.0,2.50),0.02))
    var sign:MeshInstance3D=_box(_mat(Color("#caa85a"),0.45,0.34),Vector3(1.4,0.55,0.08),pos+Vector3(0,3.0,2.66),0.08)
    root.add_child(sign)
    sign.name="HW_BuildingSign_"+label

func _market_stalls(root:Node3D,center:Vector3)->void:
    var wood:StandardMaterial3D=_mat(Color("#6b4029"),0.0,0.70)
    var cloth_a:StandardMaterial3D=_mat(Color("#d64c43"),0.0,0.78)
    var cloth_b:StandardMaterial3D=_mat(Color("#e6c66a"),0.0,0.72)
    for side in [-1.0,1.0]:
        var p:Vector3=center+Vector3(side*7.0,0.0,6.0)
        root.add_child(_box(wood,Vector3(3.2,0.18,1.5),p+Vector3(0,1.05,0),0.05))
        for x in [-1.35,1.35]:
            root.add_child(_cyl(wood,0.10,2.1,p+Vector3(x,1.0,0),20))
        var awning:StandardMaterial3D=cloth_a if side<0 else cloth_b
        root.add_child(_box(awning,Vector3(3.6,0.10,1.7),p+Vector3(0,2.35,0),0.04))
        for x in range(-2,3):
            root.add_child(_sphere(_mat(Color("#d7a84c"),0.05,0.50),0.16,p+Vector3(float(x)*0.45,1.32,0.22)))

func _street_lamps(root:Node3D,center:Vector3)->void:
    var metal:StandardMaterial3D=_mat(Color("#252a32"),0.82,0.24)
    var warm:StandardMaterial3D=_emissive(Color("#ffd77b"),Color("#ffad38"),3.2)
    var points:Array[Vector3]=[
        center+Vector3(-5,0,1),center+Vector3(5,0,1),center+Vector3(-5,0,9),center+Vector3(5,0,9),
        center+Vector3(-16,0,5),center+Vector3(16,0,5)
    ]
    for p in points:
        root.add_child(_cyl(metal,0.09,3.4,p+Vector3(0,1.7,0),20))
        root.add_child(_sphere(warm,0.20,p+Vector3(0,3.45,0)))
        var arm:MeshInstance3D=_box(metal,Vector3(0.8,0.08,0.08),p+Vector3(0,3.25,0),0.02)
        root.add_child(arm)

func _banners(root:Node3D,center:Vector3)->void:
    var cloth:StandardMaterial3D=_mat(Color("#173d78"),0.0,0.66)
    var gold:StandardMaterial3D=_emissive(Color("#e4c86d"),Color("#8f6b25"),0.7)
    for x in [-9.0,9.0]:
        var pole:StandardMaterial3D=_mat(Color("#6b4a2e"),0.15,0.54)
        root.add_child(_cyl(pole,0.08,5.8,center+Vector3(x,2.9,-1.5),20))
        root.add_child(_box(cloth,Vector3(0.95,1.65,0.05),center+Vector3(x,2.8,-1.5),0.04))
        root.add_child(_sphere(gold,0.14,center+Vector3(x,4.9,-1.5)))

func _vegetation(root:Node3D,center:Vector3)->void:
    var trunk:StandardMaterial3D=_mat(Color("#553726"),0.0,0.88)
    var leaf:StandardMaterial3D=_mat(Color("#2e7650"),0.0,0.88)
    var leaf2:StandardMaterial3D=_mat(Color("#3f9360"),0.0,0.86)
    var flower:StandardMaterial3D=_emissive(Color("#f6c7dc"),Color("#5c2b45"),0.2)
    var spots:Array[Vector3]=[]
    for i in range(20):
        var x:float=-24.0+float((i*37)%480)*0.10
        var z:float=-8.0+float((i*53)%390)*0.10
        if abs(x-center.x)<18.0 and abs(z-center.z)<12.0:
            continue
        spots.append(Vector3(x,0,z))
    for p in spots:
        root.add_child(_cyl(trunk,0.22,2.7,p+Vector3(0,1.35,0),18))
        root.add_child(_sphere(leaf,1.15,p+Vector3(0,3.05,0)))
        root.add_child(_sphere(leaf2,0.72,p+Vector3(-0.55,3.65,0.10)))
        root.add_child(_sphere(leaf2,0.68,p+Vector3(0.55,3.55,-0.08)))
        for k in range(3):
            root.add_child(_sphere(flower,0.08,p+Vector3(-0.4+float(k)*0.4,0.08,0.32)))

func _castle_horizon(root:Node3D,center:Vector3)->void:
    var stone:StandardMaterial3D=_mat(Color("#a8b2bd"),0.12,0.54)
    var roof:StandardMaterial3D=_mat(Color("#3d4965"),0.15,0.44)
    var castle:Node3D=Node3D.new()
    castle.name="HW_DistantRoyalCastle"
    castle.position=center+Vector3(0,0,-27)
    root.add_child(castle)
    castle.add_child(_box(stone,Vector3(22,8,5),Vector3(0,4,0),0.12))
    for x in [-9.0,-4.5,0.0,4.5,9.0]:
        castle.add_child(_cyl(stone,2.0,13.0,Vector3(x,6.5,0),32))
        var cap:MeshInstance3D=_cone(roof,2.5,3.5,Vector3(x,14.7,0),8)
        castle.add_child(cap)
    castle.add_child(_box(_mat(Color("#536f8d"),0.0,0.42),Vector3(4.2,5.0,0.8),Vector3(0,2.5,2.7),0.08))

func _floating_landmark(root:Node3D,pos:Vector3)->void:
    var rock:StandardMaterial3D=_mat(Color("#596b72"),0.0,0.94)
    var grass:StandardMaterial3D=_mat(Color("#4b8054"),0.0,0.9)
    var island:Node3D=Node3D.new()
    island.name="HW_FloatingIsland"
    island.position=pos
    root.add_child(island)
    island.add_child(_sphere(rock,2.7,Vector3(0,0,0)))
    island.add_child(_sphere(grass,2.2,Vector3(0,0.8,0)))
    for x in [-1.0,0.0,1.0]:
        island.add_child(_cone(_mat(Color("#72838b"),0.0,0.96),0.32,2.4,Vector3(x*0.7,-1.8,0),6))

func _upgrade_hero() -> void:
    if scene == null or actors == null:
        return
    var hero:Node3D=scene.get("hero_visual") as Node3D
    if hero == null or not is_instance_valid(hero):
        return
    var generated:Node=hero.get_node_or_null("HW_GeneratedGLB")
    if generated != null:
        return
    if not hero.has_node("HW_MAX_CHARACTER"):
        _build_max_hero(hero)
    var legacy:Node=scene.get_node_or_null("LegacyGame")
    if legacy != null:
        var value:Variant=legacy.get("hero")
        if value is Dictionary:
            var cls:String=str((value as Dictionary).get("class","Warrior"))
            if cls!=last_hero_class:
                last_hero_class=cls
                _refresh_class_weapon(hero,cls)

func _build_max_hero(hero:Node3D)->void:
    var old_meshes:Array[Node]=[]
    for child in hero.get_children():
        if child is MeshInstance3D:
            old_meshes.append(child)
    for child in old_meshes:
        (child as MeshInstance3D).visible=false
    var root:Node3D=Node3D.new()
    root.name="HW_MAX_CHARACTER"
    hero.add_child(root)
    var skin:StandardMaterial3D=_mat(Color("#d59a76"),0.0,0.46)
    var cloth:StandardMaterial3D=_mat(Color("#171d29"),0.0,0.68)
    var metal:StandardMaterial3D=_mat(Color("#a9b5c0"),0.86,0.20)
    var darkmetal:StandardMaterial3D=_mat(Color("#3d4652"),0.78,0.25)
    var gold:StandardMaterial3D=_mat(Color("#d5b65d"),0.84,0.19)
    var hair:StandardMaterial3D=_mat(Color("#202532"),0.0,0.34)
    var red:StandardMaterial3D=_mat(Color("#7e2434"),0.0,0.58)
    root.add_child(_capsule(cloth,0.40,1.25,Vector3(0,1.12,0)))
    root.add_child(_box(darkmetal,Vector3(0.88,0.62,0.44),Vector3(0,1.55,-0.02),0.10))
    root.add_child(_box(metal,Vector3(0.62,0.12,0.05),Vector3(0,1.66,-0.25),0.03))
    root.add_child(_cyl(gold,0.44,0.11,Vector3(0,1.10,-0.03),32))
    root.add_child(_box(red,Vector3(0.15,0.75,0.08),Vector3(0,1.05,0.30),0.03))
    for side in [-1.0,1.0]:
        root.add_child(_sphere(metal,0.26,Vector3(side*0.52,1.73,0)))
        root.add_child(_capsule(darkmetal,0.16,0.72,Vector3(side*0.56,1.22,0)))
        root.add_child(_sphere(skin,0.16,Vector3(side*0.58,0.86,-0.02)))
        root.add_child(_capsule(darkmetal,0.20,0.58,Vector3(side*0.22,0.52,0)))
        root.add_child(_box(metal,Vector3(0.32,0.18,0.55),Vector3(side*0.22,0.16,-0.16),0.07))
    root.add_child(_cyl(skin,0.15,0.22,Vector3(0,2.02,0),24))
    root.add_child(_sphere(skin,0.41,Vector3(0,2.34,0)))
    var face:StandardMaterial3D=_mat(Color("#b97c62"),0.0,0.48)
    root.add_child(_box(face,Vector3(0.55,0.40,0.34),Vector3(0,2.30,-0.27),0.10))
    root.add_child(_sphere(hair,0.45,Vector3(0,2.55,0)))
    root.add_child(_box(hair,Vector3(0.54,0.22,0.42),Vector3(0,2.48,-0.25),0.09))
    var eye:StandardMaterial3D=_emissive(Color("#71cfff"),Color("#2d77b2"),1.0)
    for side in [-1.0,1.0]:
        root.add_child(_sphere(_mat(Color("#f8f2e8"),0.0,0.30),0.06,Vector3(side*0.13,2.34,-0.43)))
        root.add_child(_sphere(eye,0.032,Vector3(side*0.13,2.34,-0.47)))
    root.add_child(_box(red,Vector3(0.10,0.035,0.025),Vector3(0,2.18,-0.43),0.01))
    _add_cape(root,red)
    _add_class_gear(root)
    _add_hero_aura(root)

func _add_cape(root:Node3D,mat:Material)->void:
    var cape:MeshInstance3D=_box(mat,Vector3(0.88,1.45,0.08),Vector3(0,1.34,0.38),0.08)
    cape.rotation_degrees.x=-8.0
    root.add_child(cape)
    for x in [-0.34,0.0,0.34]:
        root.add_child(_sphere(_mat(Color("#d0b15c"),0.72,0.22),0.06,Vector3(x,1.98,0.31)))

func _add_class_gear(root:Node3D)->void:
    var legacy:Node=scene.get_node_or_null("LegacyGame")
    var cls:String="Warrior"
    if legacy!=null:
        var value:Variant=legacy.get("hero")
        if value is Dictionary: cls=str((value as Dictionary).get("class","Warrior"))
    var accent:Color=_class_color(cls)
    var am:StandardMaterial3D=_mat(accent,0.38,0.28)
    var gold:StandardMaterial3D=_mat(Color("#d6b45e"),0.75,0.22)
    if cls=="Mage":
        root.add_child(_cyl(gold,0.05,1.70,Vector3(0.86,1.50,0),24))
        root.add_child(_sphere(am,0.15,Vector3(0.86,2.35,0)))
        root.add_child(_torus(am,0.48,0.035,Vector3(0,2.86,0)))
    elif cls=="Archer" or cls=="Ranger":
        var bow:MeshInstance3D=_torus(am,0.44,0.045,Vector3(0.75,1.55,0.08))
        bow.rotation_degrees.x=90.0
        root.add_child(bow)
        root.add_child(_box(gold,Vector3(0.75,0.025,0.025),Vector3(0.75,1.55,-0.01),0.01))
        for i in range(4):
            root.add_child(_cyl(gold,0.012,0.65,Vector3(-0.52+float(i)*0.035,1.55,0.22),12))
    elif cls=="Thief":
        root.add_child(_box(am,Vector3(0.56,0.13,0.06),Vector3(0,2.30,-0.45),0.02))
        root.add_child(_box(gold,Vector3(0.08,0.75,0.04),Vector3(0.84,1.25,-0.08),0.02))
        root.add_child(_box(gold,Vector3(0.08,0.75,0.04),Vector3(-0.84,1.25,-0.08),0.02))
    elif cls=="Acolyte":
        root.add_child(_torus(gold,0.43,0.04,Vector3(0,2.84,0)))
        root.add_child(_cyl(gold,0.05,1.42,Vector3(0.84,1.45,0),24))
    elif cls=="Merchant":
        root.add_child(_box(am,Vector3(0.60,0.34,0.40),Vector3(0.78,1.72,-0.02),0.06))
        root.add_child(_box(gold,Vector3(0.12,0.12,0.12),Vector3(0.90,1.72,-0.24),0.02))
    else:
        root.add_child(_box(am,Vector3(0.10,1.30,0.07),Vector3(0.82,1.52,0),0.03))
        root.add_child(_box(gold,Vector3(0.34,0.08,0.07),Vector3(0.82,0.86,0),0.02))

func _add_hero_aura(root:Node3D)->void:
    var aura:GPUParticles3D=GPUParticles3D.new()
    aura.name="HW_HeroMagicDust"
    aura.amount=18
    aura.lifetime=1.8
    aura.local_coords=false
    aura.position=Vector3(0,1.3,0)
    var process:ParticleProcessMaterial=ParticleProcessMaterial.new()
    process.emission_shape=ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
    process.emission_sphere_radius=0.65
    process.direction=Vector3(0,1,0)
    process.initial_velocity_min=0.15
    process.initial_velocity_max=0.42
    process.gravity=Vector3(0,0.18,0)
    process.scale_min=0.025
    process.scale_max=0.055
    aura.process_material=process
    var quad:QuadMesh=QuadMesh.new()
    quad.size=Vector2(0.08,0.08)
    quad.material=_emissive(Color("#e8d27b"),Color("#8d6d2c"),2.0)
    aura.draw_pass_1=quad
    root.add_child(aura)

func _refresh_class_weapon(hero:Node3D,cls:String)->void:
    var root:Node3D=hero.get_node_or_null("HW_MAX_CHARACTER") as Node3D
    if root==null: return
    var old:Node=root.get_node_or_null("HW_ClassGear")
    if old!=null: old.queue_free()
    var gear:Node3D=Node3D.new()
    gear.name="HW_ClassGear"
    root.add_child(gear)
    var accent:StandardMaterial3D=_mat(_class_color(cls),0.45,0.25)
    if cls=="Mage":
        gear.add_child(_cyl(accent,0.05,1.7,Vector3(0.86,1.5,0),24))
        gear.add_child(_sphere(accent,0.15,Vector3(0.86,2.35,0)))
    elif cls=="Archer" or cls=="Ranger":
        var bow:MeshInstance3D=_torus(accent,0.44,0.045,Vector3(0.75,1.55,0.08))
        bow.rotation_degrees.x=90.0
        gear.add_child(bow)
    elif cls=="Thief":
        gear.add_child(_box(accent,Vector3(0.56,0.13,0.06),Vector3(0,2.30,-0.45),0.02))
    elif cls=="Acolyte":
        gear.add_child(_torus(accent,0.43,0.04,Vector3(0,2.84,0)))
    elif cls=="Merchant":
        gear.add_child(_box(accent,Vector3(0.60,0.34,0.40),Vector3(0.78,1.72,-0.02),0.06))
    else:
        gear.add_child(_box(accent,Vector3(0.10,1.30,0.07),Vector3(0.82,1.52,0),0.03))

func _upgrade_pet() -> void:
    var pet:Node3D=scene.get("pet_visual") as Node3D
    if pet==null or not is_instance_valid(pet): return
    if pet.has_node("HW_MAX_PET"): return
    for child in pet.get_children():
        if child is MeshInstance3D:
            (child as MeshInstance3D).visible=false
    var root:Node3D=Node3D.new()
    root.name="HW_MAX_PET"
    pet.add_child(root)
    var species:String="Pet"
    var legacy:Node=scene.get_node_or_null("LegacyGame")
    if legacy!=null:
        var hv:Variant=legacy.get("hero")
        if hv is Dictionary:
            var pv:Variant=(hv as Dictionary).get("pet",{})
            if pv is Dictionary: species=str((pv as Dictionary).get("species","Pet"))
    if species.to_lower().contains("falcon"):
        _build_falcon(root)
    elif species.to_lower().contains("wolf") or species.to_lower().contains("panther"):
        _build_beast(root)
    elif species.to_lower().contains("poring"):
        _build_poring(root)
    else:
        _build_arcane_pet(root)

func _build_falcon(root:Node3D)->void:
    var feather:StandardMaterial3D=_mat(Color("#8c603b"),0.0,0.72)
    var light:StandardMaterial3D=_mat(Color("#d9c48a"),0.0,0.64)
    root.add_child(_sphere(feather,0.34,Vector3(0,0.75,0)))
    root.add_child(_sphere(light,0.23,Vector3(0,1.05,-0.02)))
    for side in [-1.0,1.0]:
        var wing:MeshInstance3D=_box(feather,Vector3(0.10,0.12,1.10),Vector3(side*0.42,0.72,0),0.04)
        wing.rotation_degrees.y=side*24.0
        root.add_child(wing)
    root.add_child(_cone(light,0.13,0.30,Vector3(0,1.06,-0.27),4))
    root.add_child(_sphere(_emissive(Color("#f4c94e"),Color("#a66d18"),1.2),0.045,Vector3(-0.10,1.11,-0.25)))
    root.add_child(_sphere(_emissive(Color("#f4c94e"),Color("#a66d18"),1.2),0.045,Vector3(0.10,1.11,-0.25)))

func _build_beast(root:Node3D)->void:
    var fur:StandardMaterial3D=_mat(Color("#4f5965"),0.0,0.92)
    var dark:StandardMaterial3D=_mat(Color("#202731"),0.18,0.64)
    var eye:StandardMaterial3D=_emissive(Color("#ffb35d"),Color("#8f2e21"),2.2)
    root.add_child(_sphere(fur,0.52,Vector3(0,0.68,0)))
    root.add_child(_sphere(dark,0.34,Vector3(0,0.90,-0.40)))
    for side in [-1.0,1.0]:
        root.add_child(_box(dark,Vector3(0.18,0.32,0.15),Vector3(side*0.27,1.13,-0.25),0.04))
        root.add_child(_sphere(eye,0.055,Vector3(side*0.12,1.02,-0.67)))
        root.add_child(_capsule(dark,0.13,0.48,Vector3(side*0.28,0.34,-0.10)))

func _build_poring(root:Node3D)->void:
    var pink:StandardMaterial3D=_mat(Color("#ee82b2"),0.0,0.34)
    var light:StandardMaterial3D=_mat(Color("#ffd5e4"),0.0,0.30)
    root.add_child(_sphere(pink,0.54,Vector3(0,0.66,0)))
    root.add_child(_sphere(light,0.15,Vector3(0,0.95,-0.37)))
    for side in [-1.0,1.0]:
        root.add_child(_sphere(_emissive(Color("#44243a"),Color("#1b1020"),0.6),0.065,Vector3(side*0.17,0.75,-0.46)))
    root.add_child(_cone(_mat(Color("#d6b45e"),0.75,0.22),0.18,0.36,Vector3(0,1.22,0),4))

func _build_arcane_pet(root:Node3D)->void:
    var orb:StandardMaterial3D=_emissive(Color("#65d6ff"),Color("#1c6c9a"),2.0)
    var ring:StandardMaterial3D=_emissive(Color("#b9f2ff"),Color("#2b8baa"),1.4)
    root.add_child(_sphere(orb,0.45,Vector3(0,0.72,0)))
    root.add_child(_torus(ring,0.60,0.035,Vector3(0,0.72,0)))
    root.add_child(_torus(ring,0.72,0.025,Vector3(0,0.72,0)))

func _upgrade_monsters() -> void:
    var visuals:Variant=scene.get("monster_visuals")
    if not visuals is Dictionary: return
    for key in visuals.keys():
        var monster:Node3D=visuals[key] as Node3D
        if monster==null or not is_instance_valid(monster): continue
        if monster.has_node("HW_MAX_MONSTER"): continue
        _build_max_monster(monster,str(key))

func _build_max_monster(monster:Node3D,id:String)->void:
    for child in monster.get_children():
        if child is MeshInstance3D:
            (child as MeshInstance3D).visible=false
    var root:Node3D=Node3D.new()
    root.name="HW_MAX_MONSTER"
    monster.add_child(root)
    var n:String=id.to_lower()
    if n.contains("poring"):
        _build_monster_poring(root)
    elif n.contains("wolf"):
        _build_monster_wolf(root)
    elif n.contains("baphomet") or n.contains("horn"):
        _build_monster_horned(root)
    elif n.contains("knight") or n.contains("bloody"):
        _build_monster_knight(root)
    else:
        _build_monster_generic(root)

func _build_monster_poring(root:Node3D)->void:
    root.add_child(_sphere(_mat(Color("#d9577d"),0.0,0.34),0.58,Vector3(0,0.62,0)))
    root.add_child(_sphere(_mat(Color("#ffb5cf"),0.0,0.30),0.18,Vector3(0,0.95,-0.38)))
    for side in [-1.0,1.0]:
        root.add_child(_sphere(_emissive(Color("#321827"),Color("#100a12"),0.8),0.07,Vector3(side*0.18,0.72,-0.50)))

func _build_monster_wolf(root:Node3D)->void:
    var fur:StandardMaterial3D=_mat(Color("#59636e"),0.0,0.92)
    var dark:StandardMaterial3D=_mat(Color("#252d37"),0.12,0.66)
    root.add_child(_sphere(fur,0.70,Vector3(0,0.82,0)))
    root.add_child(_sphere(dark,0.45,Vector3(0,1.05,-0.55)))
    for side in [-1.0,1.0]:
        root.add_child(_cone(dark,0.22,0.55,Vector3(side*0.34,1.52,-0.22),4))
        root.add_child(_sphere(_emissive(Color("#ff8d55"),Color("#5e1e22"),2.0),0.08,Vector3(side*0.17,1.15,-0.90)))
        root.add_child(_capsule(dark,0.17,0.70,Vector3(side*0.38,0.38,-0.22)))
        root.add_child(_capsule(dark,0.17,0.70,Vector3(side*0.38,0.38,0.22)))

func _build_monster_horned(root:Node3D)->void:
    var armor:StandardMaterial3D=_mat(Color("#4b3e47"),0.68,0.34)
    var horn:StandardMaterial3D=_mat(Color("#7b5a43"),0.05,0.72)
    var eye:StandardMaterial3D=_emissive(Color("#ff3f45"),Color("#8d1721"),3.0)
    root.add_child(_capsule(armor,0.72,1.60,Vector3(0,1.05,0)))
    root.add_child(_sphere(armor,0.58,Vector3(0,2.12,0)))
    for side in [-1.0,1.0]:
        root.add_child(_cone(horn,0.28,1.05,Vector3(side*0.40,2.68,0),8))
        root.add_child(_sphere(eye,0.09,Vector3(side*0.18,2.15,-0.54)))
        root.add_child(_capsule(armor,0.22,0.95,Vector3(side*0.82,1.20,0)))
        root.add_child(_box(horn,Vector3(0.16,0.70,0.16),Vector3(side*0.28,0.42,-0.28),0.04))

func _build_monster_knight(root:Node3D)->void:
    var steel:StandardMaterial3D=_mat(Color("#4d5965"),0.88,0.22)
    var blood:StandardMaterial3D=_mat(Color("#741d2b"),0.18,0.34)
    var black:StandardMaterial3D=_mat(Color("#171b23"),0.52,0.28)
    root.add_child(_capsule(black,0.68,1.55,Vector3(0,1.05,0)))
    root.add_child(_box(steel,Vector3(1.15,0.70,0.62),Vector3(0,1.60,-0.04),0.10))
    root.add_child(_sphere(black,0.55,Vector3(0,2.18,0)))
    root.add_child(_box(steel,Vector3(1.02,0.42,0.50),Vector3(0,2.18,-0.34),0.08))
    root.add_child(_box(blood,Vector3(0.10,1.60,0.10),Vector3(0.90,1.45,0),0.03))
    root.add_child(_box(steel,Vector3(0.22,1.55,0.12),Vector3(0.98,1.55,0),0.03))
    root.add_child(_emissive_mesh(root,Color("#ff3b3b"),Vector3(0.0,2.22,-0.57),0.07))

func _build_monster_generic(root:Node3D)->void:
    var body:StandardMaterial3D=_mat(Color("#56606a"),0.12,0.84)
    var eye:StandardMaterial3D=_emissive(Color("#ffb55c"),Color("#7a2c1f"),2.0)
    root.add_child(_capsule(body,0.62,1.40,Vector3(0,0.95,0)))
    root.add_child(_sphere(body,0.50,Vector3(0,1.95,0)))
    for side in [-1.0,1.0]:
        root.add_child(_sphere(eye,0.07,Vector3(side*0.17,1.98,-0.47)))
        root.add_child(_capsule(body,0.18,0.80,Vector3(side*0.72,1.05,0)))

func _hide_legacy_labels(node:Node)->void:
    for child in node.get_children():
        if child is Label3D:
            (child as Label3D).visible=false
        if child.get_child_count()>0:
            _hide_legacy_labels(child)

func _class_color(cls:String)->Color:
    match cls:
        "Mage": return Color("#8d73e6")
        "Archer", "Ranger": return Color("#55b978")
        "Thief": return Color("#db5b9b")
        "Acolyte": return Color("#e1c15e")
        "Merchant": return Color("#5cb5d8")
    return Color("#d18b3e")

func _mat(color:Color,metallic:float=0.0,roughness:float=0.55)->StandardMaterial3D:
    var m:StandardMaterial3D=StandardMaterial3D.new()
    m.albedo_color=color
    m.metallic=metallic
    m.roughness=roughness
    return m

func _emissive(color:Color,emission:Color,energy:float)->StandardMaterial3D:
    var m:StandardMaterial3D=_mat(color,0.05,0.24)
    m.emission_enabled=true
    m.emission=emission
    m.emission_energy_multiplier=energy
    return m

func _box(mat:Material,size:Vector3,pos:Vector3,bevel_amount:float=0.05)->MeshInstance3D:
    var n:MeshInstance3D=MeshInstance3D.new()
    var mesh:BoxMesh=BoxMesh.new()
    mesh.size=size
    n.mesh=mesh
    n.position=pos
    n.material_override=mat
    if bevel_amount>0.0:
        var b:BevelMesh=BevelMesh.new()
        b.size=size
        b.material=mat
        b.bevel=bevel_amount
        b.bevel_segments=3
        n.mesh=b
    return n

func _sphere(mat:Material,radius:float,pos:Vector3)->MeshInstance3D:
    var n:MeshInstance3D=MeshInstance3D.new()
    var mesh:SphereMesh=SphereMesh.new()
    mesh.radius=radius
    mesh.height=radius*2.0
    mesh.radial_segments=32
    mesh.rings=20
    n.mesh=mesh
    n.position=pos
    n.material_override=mat
    return n

func _capsule(mat:Material,radius:float,height:float,pos:Vector3)->MeshInstance3D:
    var n:MeshInstance3D=MeshInstance3D.new()
    var mesh:CapsuleMesh=CapsuleMesh.new()
    mesh.radius=radius
    mesh.height=height
    mesh.radial_segments=24
    mesh.rings=8
    n.mesh=mesh
    n.position=pos
    n.material_override=mat
    return n

func _cyl(mat:Material,radius:float,height:float,pos:Vector3,segments:int=32)->MeshInstance3D:
    var n:MeshInstance3D=MeshInstance3D.new()
    var mesh:CylinderMesh=CylinderMesh.new()
    mesh.top_radius=radius
    mesh.bottom_radius=radius
    mesh.height=height
    mesh.radial_segments=segments
    n.mesh=mesh
    n.position=pos
    n.material_override=mat
    return n

func _cone(mat:Material,radius:float,height:float,pos:Vector3,segments:int=32)->MeshInstance3D:
    var n:MeshInstance3D=MeshInstance3D.new()
    var mesh:CylinderMesh=CylinderMesh.new()
    mesh.top_radius=0.0
    mesh.bottom_radius=radius
    mesh.height=height
    mesh.radial_segments=segments
    n.mesh=mesh
    n.position=pos
    n.material_override=mat
    return n

func _torus(mat:Material,inner:float,offset:float,pos:Vector3)->MeshInstance3D:
    var n:MeshInstance3D=MeshInstance3D.new()
    var mesh:TorusMesh=TorusMesh.new()
    mesh.inner_radius=inner
    mesh.outer_radius=inner+offset
    mesh.rings=48
    mesh.ring_segments=12
    n.mesh=mesh
    n.position=pos
    n.material_override=mat
    return n

func _emissive_mesh(root:Node3D,color:Color,pos:Vector3,size:float)->MeshInstance3D:
    var n:MeshInstance3D=_sphere(_emissive(color,color,3.0),size,pos)
    root.add_child(n)
    return n
