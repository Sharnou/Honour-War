extends Node3D

## Stylized MMORPG readability pass. Designed for a cute, detailed fantasy look
## inspired by classic Ragnarok-like silhouettes while remaining original.
var game:Node3D
var hero_seen:Node3D
var pet_seen:Node3D
var monsters_seen:Dictionary={}

func _ready()->void:
    call_deferred("_bind")

func _process(_delta:float)->void:
    if game==null or not is_instance_valid(game):
        _bind()
        return
    _apply()

func _bind()->void:
    game=get_tree().current_scene as Node3D

func _apply()->void:
    if game==null: return
    var hero:Node3D=game.get("hero_visual") as Node3D
    if hero!=null and is_instance_valid(hero):
        hero.scale=Vector3.ONE*1.28
        hero_seen=hero
        _hero_detail(hero)
        _hero_lighting(hero)
    var pet:Node3D=game.get("pet_visual") as Node3D
    if pet!=null and is_instance_valid(pet):
        pet.scale=Vector3.ONE*1.12
        pet_seen=pet
        _pet_detail(pet)
    var visuals:Variant=game.get("monster_visuals")
    if visuals is Dictionary:
        for key in visuals.keys():
            var monster:Node3D=visuals[key] as Node3D
            if monster==null or not is_instance_valid(monster): continue
            var id:String=str(key)
            if not monsters_seen.has(id):
                monsters_seen[id]=true
                _detail_monster(monster,id)
            var scale_value:float=clamp(monster.scale.y,0.65,2.2)
            monster.scale=Vector3.ONE*max(1.0,scale_value*1.10)

func _hero_detail(hero:Node3D)->void:
    if hero.has_node("HW_AnimeDetails"): return
    var root:Node3D=Node3D.new()
    root.name="HW_AnimeDetails"
    hero.add_child(root)
    var legacy:Node=game.get_node_or_null("LegacyGame")
    var class_id:String="Warrior"
    if legacy!=null:
        var value:Variant=legacy.get("hero")
        if value is Dictionary: class_id=str((value as Dictionary).get("class","Warrior"))
    var skin:StandardMaterial3D=_mat(Color("#d9a07d"),0.0,0.48)
    var hair:StandardMaterial3D=_mat(_hair_color(class_id),0.0,0.42)
    var cloth:StandardMaterial3D=_mat(Color("#263040"),0.04,0.70)
    var metal:StandardMaterial3D=_mat(Color("#a4b0bb"),0.72,0.28)
    var accent:StandardMaterial3D=_mat(_class_color(class_id),0.28,0.35)
    var gold:StandardMaterial3D=_mat(Color("#d9bd69"),0.70,0.24)
    root.add_child(_sphere(skin,0.39,Vector3(0,2.28,-0.02)))
    var hair_cap:MeshInstance3D=_sphere(hair,0.45,Vector3(0,2.50,-0.01))
    hair_cap.scale=Vector3(1.06,0.66,1.03)
    root.add_child(hair_cap)
    root.add_child(_sphere(_mat(Color("#faf7ef")),0.058,Vector3(-0.13,2.31,-0.36)))
    root.add_child(_sphere(_mat(Color("#faf7ef")),0.058,Vector3(0.13,2.31,-0.36)))
    root.add_child(_sphere(_mat(Color("#4e79b6")),0.028,Vector3(-0.13,2.31,-0.405)))
    root.add_child(_sphere(_mat(Color("#4e79b6")),0.028,Vector3(0.13,2.31,-0.405)))
    root.add_child(_box(_mat(Color("#7e3c49")),Vector3(0.14,0.025,0.018),Vector3(0,2.13,-0.37)))
    root.add_child(_box(cloth,Vector3(0.72,0.52,0.38),Vector3(0,1.42,0.02)))
    root.add_child(_box(accent,Vector3(0.52,0.26,0.06),Vector3(0,1.60,-0.24)))
    root.add_child(_box(gold,Vector3(0.18,0.16,0.06),Vector3(0,1.18,-0.25)))
    for side in [-1.0,1.0]:
        var shoulder:MeshInstance3D=_sphere(accent,0.23,Vector3(side*0.50,1.68,0))
        shoulder.scale=Vector3(1.15,0.72,1.05)
        root.add_child(shoulder)
        root.add_child(_cyl(metal,0.15,0.48,Vector3(side*0.52,1.28,-0.01)))
        root.add_child(_sphere(skin,0.15,Vector3(side*0.54,1.00,-0.02)))
        var boot:MeshInstance3D=_box(metal,Vector3(0.32,0.20,0.50),Vector3(side*0.20,0.13,-0.10))
        root.add_child(boot)
    if class_id=="Warrior":
        root.add_child(_cyl(metal,0.40,0.10,Vector3(-0.72,1.25,0.10)))
        var sword:MeshInstance3D=_box(metal,Vector3(0.10,1.25,0.06),Vector3(0.78,1.52,0.02))
        sword.rotation_degrees.z=-12
        root.add_child(sword)
    elif class_id=="Mage":
        root.add_child(_cyl(gold,0.045,1.65,Vector3(0.82,1.50,0.0)))
        root.add_child(_sphere(accent,0.13,Vector3(0.82,2.32,0.0)))
    elif class_id=="Archer" or class_id=="Ranger":
        var bow:MeshInstance3D=_torus(accent,0.38,0.035)
        bow.position=Vector3(0.70,1.58,0.10)
        bow.rotation_degrees.x=90
        root.add_child(bow)
        root.add_child(_box(gold,Vector3(0.58,0.035,0.035),Vector3(0.70,1.58,-0.02)))
        for i in range(3): root.add_child(_cyl(gold,0.012,0.58,Vector3(-0.46+float(i)*0.04,1.55,0.24)))
    elif class_id=="Thief":
        root.add_child(_box(_mat(Color("#222735")),Vector3(0.48,0.15,0.06),Vector3(0,2.30,-0.37)))
        root.add_child(_cyl(accent,0.035,0.70,Vector3(0.88,1.26,-0.04)))
    elif class_id=="Acolyte":
        var halo:MeshInstance3D=_torus(gold,0.40,0.035)
        halo.position=Vector3(0,2.78,0)
        halo.rotation_degrees.x=90
        root.add_child(halo)
        root.add_child(_cyl(gold,0.045,1.35,Vector3(0.84,1.46,0)))
    elif class_id=="Merchant":
        root.add_child(_sphere(_mat(Color("#6f4a2d")),0.22,Vector3(0.60,1.08,0.18)))
        root.add_child(_box(gold,Vector3(0.40,0.07,0.36),Vector3(0.84,1.76,-0.04)))

func _pet_detail(pet:Node3D)->void:
    if pet.has_node("HW_PetDetails"): return
    var root:Node3D=Node3D.new()
    root.name="HW_PetDetails"
    pet.add_child(root)
    var value:Variant=game.get("legacy")
    var species:String=""
    if value is Node:
        var h:Variant=(value as Node).get("hero")
        if h is Dictionary:
            var p:Variant=(h as Dictionary).get("pet",{})
            if p is Dictionary: species=str((p as Dictionary).get("species",""))
    if species.to_lower().contains("falcon"):
        root.add_child(_sphere(_mat(Color("#7b5b3c")),0.12,Vector3(0.0,0.75,-0.28)))
        root.add_child(_sphere(_mat(Color("#d9bd69")),0.055,Vector3(-0.10,0.77,-0.37)))
        root.add_child(_sphere(_mat(Color("#d9bd69")),0.055,Vector3(0.10,0.77,-0.37)))
    elif species.to_lower().contains("wolf") or species.to_lower().contains("panther"):
        root.add_child(_sphere(_mat(Color("#5c6670")),0.10,Vector3(-0.18,0.88,-0.40)))
        root.add_child(_sphere(_mat(Color("#5c6670")),0.10,Vector3(0.18,0.88,-0.40)))

func _hero_lighting(hero:Node3D)->void:
    if hero.get_node_or_null("HW_ReadabilityLight")!=null: return
    var light:=OmniLight3D.new()
    light.name="HW_ReadabilityLight"
    light.position=Vector3(0,2.1,1.5)
    light.omni_range=5.0
    light.light_energy=0.72
    light.light_color=Color("#fff0d0")
    hero.add_child(light)

func _detail_monster(monster:Node3D,id:String)->void:
    var root:Node3D=Node3D.new()
    root.name="HW_MonsterReadableDetail"
    monster.add_child(root)
    var n:String=id.to_lower()
    var eye:StandardMaterial3D=_mat(Color("#ff9b6d"),0.05,0.22)
    var dark:StandardMaterial3D=_mat(Color("#303944"),0.15,0.52)
    if n.contains("poring"):
        root.add_child(_sphere(eye,0.075,Vector3(-0.16,0.64,-0.38)))
        root.add_child(_sphere(eye,0.075,Vector3(0.16,0.64,-0.38)))
        root.add_child(_sphere(_mat(Color("#f3d0aa")),0.09,Vector3(0,0.88,-0.30)))
    elif n.contains("wolf"):
        _add_ears(root,dark)
        root.add_child(_sphere(eye,0.07,Vector3(-0.18,1.02,-0.34)))
        root.add_child(_sphere(eye,0.07,Vector3(0.18,1.02,-0.34)))
    elif n.contains("baphomet") or n.contains("horn") or n.contains("knight"):
        _horn(root,Vector3(-0.34,1.35,0),-28.0)
        _horn(root,Vector3(0.34,1.35,0),28.0)
        root.add_child(_sphere(eye,0.075,Vector3(-0.18,1.12,-0.35)))
        root.add_child(_sphere(eye,0.075,Vector3(0.18,1.12,-0.35)))
        root.add_child(_box(dark,Vector3(0.84,0.12,0.14),Vector3(0,0.82,-0.30)))
    else:
        root.add_child(_sphere(eye,0.06,Vector3(-0.18,1.00,-0.33)))
        root.add_child(_sphere(eye,0.06,Vector3(0.18,1.00,-0.33)))
        root.add_child(_box(dark,Vector3(0.70,0.12,0.12),Vector3(0,0.76,-0.28)))

func _add_ears(root:Node3D,mat:Material)->void:
    var l:MeshInstance3D=_box(mat,Vector3(0.20,0.32,0.12),Vector3(-0.30,1.30,0))
    l.rotation_degrees.z=-20
    root.add_child(l)
    var r:MeshInstance3D=_box(mat,Vector3(0.20,0.32,0.12),Vector3(0.30,1.30,0))
    r.rotation_degrees.z=20
    root.add_child(r)

func _horn(root:Node3D,pos:Vector3,angle:float)->void:
    var mesh:=CylinderMesh.new()
    mesh.top_radius=0.0
    mesh.bottom_radius=0.12
    mesh.height=0.58
    mesh.radial_segments=24
    var node:=MeshInstance3D.new()
    node.mesh=mesh
    node.position=pos
    node.rotation_degrees.z=angle
    node.material_override=_mat(Color("#5b463e"),0.10,0.68)
    root.add_child(node)

func _hair_color(class_id:String)->Color:
    match class_id:
        "Mage": return Color("#5d5b9a")
        "Archer", "Ranger": return Color("#65452f")
        "Thief": return Color("#22242f")
        "Acolyte": return Color("#b9a37c")
        "Merchant": return Color("#8c4f2e")
    return Color("#3d3030")

func _class_color(class_id:String)->Color:
    match class_id:
        "Mage": return Color("#8e73d9")
        "Archer", "Ranger": return Color("#5eaa72")
        "Thief": return Color("#d0649b")
        "Acolyte": return Color("#dfbf60")
        "Merchant": return Color("#5ba8c7")
    return Color("#cf8a3f")

func _mat(color:Color,metallic:float=0.0,roughness:float=0.50)->StandardMaterial3D:
    var material:=StandardMaterial3D.new()
    material.albedo_color=color
    material.metallic=metallic
    material.roughness=roughness
    return material

func _cyl(mat:Material,radius:float,height:float,pos:Vector3,segments:int=24)->MeshInstance3D:
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
    mesh.rings=20
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

func _torus(mat:Material,inner:float,offset:float)->MeshInstance3D:
    var node:=MeshInstance3D.new()
    var mesh:=TorusMesh.new()
    mesh.inner_radius=inner
    mesh.outer_radius=inner+offset
    mesh.rings=48
    mesh.ring_segments=12
    node.mesh=mesh
    node.material_override=mat
    return node
