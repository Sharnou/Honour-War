class_name HDHeroDetailDirector
extends Node3D

## Adds presentation detail to the fallback hero only.
## Production GLB/GLTF characters are left untouched except for removing world-space text labels.
var game:Node
var last_visual:Node3D

func _ready()->void:
    game=get_parent()
    set_process(true)

func _process(_delta:float)->void:
    if game==null: return
    var hero:Node3D=game.get("hero_visual") as Node3D
    if hero==null or not is_instance_valid(hero): return
    _strip_world_text(hero)
    if hero==last_visual: return
    last_visual=hero
    if bool(hero.get_meta("hw_production_asset",false)): return
    _build_detail(hero)

func _strip_world_text(root:Node)->void:
    _hide_label_nodes(root)

func _hide_label_nodes(node:Node)->void:
    for child in node.get_children():
        if child is Label3D:
            (child as Label3D).visible=false
        _hide_label_nodes(child)

func _build_detail(hero:Node3D)->void:
    if hero.has_meta("hw_detail_rig"): return
    hero.set_meta("hw_detail_rig",true)
    var class_id:String="Warrior"
    var legacy:Node=game.get("legacy") as Node
    if legacy!=null:
        var value:Variant=legacy.get("hero")
        if value is Dictionary:
            class_id=str(value.get("class","Warrior"))

    var skin:=_mat(Color("#c98f70"),0.05,0.72)
    var skin_light:=_mat(Color("#e0aa89"),0.02,0.66)
    var hair:=_mat(Color("#241c20"),0.0,0.78)
    var leather:=_mat(Color("#493023"),0.0,0.88)
    var metal:=_mat(Color("#9ca9b4"),0.78,0.28)
    var dark_metal:=_mat(Color("#303640"),0.72,0.25)
    var accent:=_mat(_class_color(class_id),0.32,0.32)
    var gold:=_mat(Color("#d7b45c"),0.62,0.28)

    var neck:=_cyl(skin,0.14,0.25,Vector3(0,2.03,0),24)
    neck.name="HW_Neck"
    hero.add_child(neck)
    var chest_plate:=_sphere(dark_metal,0.52,Vector3(0,1.50,-0.06))
    chest_plate.name="HW_ChestPlate"
    chest_plate.scale=Vector3(1.10,0.82,0.62)
    hero.add_child(chest_plate)
    var chest_inlay:=_box(accent,Vector3(0.38,0.12,0.05),Vector3(0,1.54,-0.38))
    chest_inlay.name="HW_ClassInlay"
    hero.add_child(chest_inlay)
    var belt:=_box(leather,Vector3(0.92,0.13,0.47),Vector3(0,1.03,-0.02))
    belt.name="HW_BeltDetail"
    hero.add_child(belt)
    var buckle:=_box(gold,Vector3(0.14,0.15,0.05),Vector3(0,1.04,-0.27))
    hero.add_child(buckle)

    var head:MeshInstance3D=hero.get_node_or_null("MeshInstance3D") as MeshInstance3D
    if head!=null:
        head.material_override=skin
    var hair_cap:=_sphere(hair,0.45,Vector3(0,2.48,-0.02))
    hair_cap.name="HW_HairDetail"
    hair_cap.scale=Vector3(1.05,0.68,1.0)
    hero.add_child(hair_cap)
    var brow_l:=_box(hair,Vector3(0.18,0.035,0.025),Vector3(-0.15,2.37,-0.36))
    var brow_r:=_box(hair,Vector3(0.18,0.035,0.025),Vector3(0.15,2.37,-0.36))
    hero.add_child(brow_l)
    hero.add_child(brow_r)
    var eye_white:=_mat(Color("#f3f0e9"),0.0,0.45)
    var eye_blue:=_mat(Color("#324f75"),0.0,0.25)
    for x in [-0.13,0.13]:
        var white:=_sphere(eye_white,0.055,Vector3(x,2.30,-0.355))
        var iris:=_sphere(eye_blue,0.026,Vector3(x,2.30,-0.383))
        hero.add_child(white)
        hero.add_child(iris)
    var nose:=_box(skin_light,Vector3(0.05,0.10,0.055),Vector3(0,2.22,-0.365))
    hero.add_child(nose)
    var mouth:=_box(_mat(Color("#7a3545"),0.0,0.55),Vector3(0.13,0.022,0.018),Vector3(0,2.13,-0.365))
    hero.add_child(mouth)

    for side in [-1.0,1.0]:
        var pauldron:=_sphere(accent,0.25,Vector3(side*0.52,1.66,0))
        pauldron.name="HW_Pauldron"
        pauldron.scale=Vector3(1.10,0.72,1.05)
        hero.add_child(pauldron)
        var forearm:=_cyl(dark_metal,0.14,0.50,Vector3(side*0.50,1.26,0),24)
        forearm.rotation_degrees.z=side*8.0
        forearm.name="HW_Gauntlet"
        hero.add_child(forearm)
        var glove:=_sphere(skin,0.15,Vector3(side*0.54,1.02,0))
        glove.name="HW_HandDetail"
        hero.add_child(glove)
        var knee:=_box(metal,Vector3(0.30,0.16,0.10),Vector3(side*0.20,0.55,-0.24))
        knee.name="HW_KneeGuard"
        hero.add_child(knee)
        var boot:=_box(dark_metal,Vector3(0.34,0.22,0.52),Vector3(side*0.20,0.08,-0.08))
        boot.name="HW_BootDetail"
        hero.add_child(boot)

    if class_id=="Warrior":
        var crest:=_box(gold,Vector3(0.22,0.18,0.06),Vector3(0,2.56,-0.31))
        hero.add_child(crest)
        var shield:=_cyl(metal,0.43,0.10,Vector3(-0.72,1.23,0.05),32)
        shield.name="HW_Shield"
        shield.rotation_degrees.x=90.0
        hero.add_child(shield)
    elif class_id=="Mage":
        var gem:=_sphere(_mat(Color("#8bdcff"),0.28,0.12),0.11,Vector3(0,2.58,-0.34))
        hero.add_child(gem)
    elif class_id=="Archer" or class_id=="Ranger":
        var quiver:=_box(leather,Vector3(0.20,0.60,0.18),Vector3(-0.48,1.35,0.24))
        quiver.rotation_degrees.z=-10.0
        hero.add_child(quiver)
        for i in range(3):
            var arrow:=_box(gold,Vector3(0.025,0.48,0.025),Vector3(-0.48+float(i)*0.035,1.46,0.24))
            hero.add_child(arrow)
    elif class_id=="Thief":
        var mask:=_box(dark_metal,Vector3(0.48,0.16,0.06),Vector3(0,2.31,-0.37))
        hero.add_child(mask)
    elif class_id=="Acolyte":
        var halo:=_torus(gold,0.42,0.035)
        halo.rotation_degrees.x=90.0
        halo.position=Vector3(0,2.75,0)
        hero.add_child(halo)
    elif class_id=="Merchant":
        var pouch:=_sphere(leather,0.22,Vector3(0.58,1.10,0.18))
        hero.add_child(pouch)

func _class_color(class_id:String)->Color:
    match class_id:
        "Mage": return Color("#9d75e8")
        "Archer": return Color("#65a96e")
        "Ranger": return Color("#65a96e")
        "Thief": return Color("#d66c9e")
        "Acolyte": return Color("#dfc25e")
        "Merchant": return Color("#5faacb")
    return Color("#c98c3e")

func _mat(color:Color,metallic:float,roughness:float)->StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.albedo_color=color
    m.metallic=metallic
    m.roughness=roughness
    return m

func _cyl(mat:Material,radius:float,height:float,pos:Vector3,segments:int)->MeshInstance3D:
    var node:=MeshInstance3D.new()
    var mesh:=CylinderMesh.new()
    mesh.top_radius=radius
    mesh.bottom_radius=radius
    mesh.height=height
    mesh.radial_segments=segments
    node.mesh=mesh
    node.position=pos
    node.material_override=mat
    return node

func _sphere(mat:Material,radius:float,pos:Vector3)->MeshInstance3D:
    var node:=MeshInstance3D.new()
    var mesh:=SphereMesh.new()
    mesh.radius=radius
    mesh.height=radius*2.0
    mesh.radial_segments=32
    mesh.rings=18
    node.mesh=mesh
    node.position=pos
    node.material_override=mat
    return node

func _box(mat:Material,size:Vector3,pos:Vector3)->MeshInstance3D:
    var node:=MeshInstance3D.new()
    var mesh:=BoxMesh.new()
    mesh.size=size
    node.mesh=mesh
    node.position=pos
    node.material_override=mat
    return node

func _torus(mat:Material,inner:float,outer_offset:float)->MeshInstance3D:
    var node:=MeshInstance3D.new()
    var mesh:=TorusMesh.new()
    mesh.inner_radius=inner
    mesh.outer_radius=inner+outer_offset
    node.mesh=mesh
    node.material_override=mat
    return node
