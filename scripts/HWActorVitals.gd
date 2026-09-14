extends Node3D

## Screen-readable combat vitals. Uses billboarded 3D bars so health stays visible
## without nameplates. Hero gets HP/SP; monsters get HP; bosses get wider HP bars.
var game:Node3D
var legacy:Node
var hero_last:Node3D
var hero_hp_fill:MeshInstance3D
var hero_sp_fill:MeshInstance3D
var monster_bars:Dictionary={}
var timer:float=0.0

func _ready()->void:
    game=get_parent() as Node3D
    call_deferred("_bind")

func _process(delta:float)->void:
    timer+=delta
    if timer<0.08:
        return
    timer=0.0
    if legacy==null or not is_instance_valid(legacy):
        _bind()
        return
    _update_hero()
    _update_monsters()

func _bind()->void:
    if game==null:
        game=get_parent() as Node3D
    if game!=null:
        legacy=game.get_node_or_null("LegacyGame")

func _update_hero()->void:
    var hero:Node3D=game.get("hero_visual") as Node3D
    if hero==null or not is_instance_valid(hero):
        return
    if hero!=hero_last:
        hero_last=hero
        hero_hp_fill=null
        hero_sp_fill=null
        _remove_old_vitals(hero)
        _build_hero_bars(hero)
        _add_class_features(hero)
    var value:Variant=legacy.get("hero")
    if not value is Dictionary:
        return
    var data:Dictionary=value
    var hp:float=float(data.get("hp",0))
    var max_hp:float=max(1.0,float(data.get("max_hp",hp)))
    var sp:float=float(data.get("sp",0))
    var max_sp:float=max(1.0,float(data.get("max_sp",sp)))
    _set_fill(hero_hp_fill,hp/max_hp,1.11)
    _set_fill(hero_sp_fill,sp/max_sp,1.11)

func _build_hero_bars(hero:Node3D)->void:
    var root:Node3D=Node3D.new()
    root.name="HWVitals"
    root.position=Vector3(0,3.25,0)
    hero.add_child(root)
    var hp_bg:MeshInstance3D=_bar(Color("#241217"),Vector3(1.15,0.07,0.025))
    root.add_child(hp_bg)
    hero_hp_fill=_bar(Color("#d74d59"),Vector3(1.11,0.055,0.028))
    hero_hp_fill.position.z=-0.02
    root.add_child(hero_hp_fill)
    var sp_bg:MeshInstance3D=_bar(Color("#10192b"),Vector3(1.15,0.055,0.025))
    sp_bg.position.y=-0.13
    root.add_child(sp_bg)
    hero_sp_fill=_bar(Color("#4f8de1"),Vector3(1.11,0.045,0.028))
    hero_sp_fill.position=Vector3(-0.02,-0.13,-0.02)
    root.add_child(hero_sp_fill)

func _update_monsters()->void:
    var visuals:Variant=game.get("monster_visuals")
    var monsters_value:Variant=legacy.get("monsters")
    if not visuals is Dictionary or not monsters_value is Array:
        return
    var active:Dictionary={}
    for item in monsters_value as Array:
        if not item is Dictionary:
            continue
        var monster:Dictionary=item
        var id:String=str(monster.get("visual_id",monster.get("name","monster")))
        active[id]=true
        var visual:Node3D=visuals.get(id) as Node3D
        if visual==null or not is_instance_valid(visual):
            continue
        var entry:Dictionary=monster_bars.get(id,{})
        if entry.is_empty():
            entry=_build_monster_bar(visual,bool(monster.get("mvp",false)))
            monster_bars[id]=entry
        var fill:MeshInstance3D=entry.get("hp",null) as MeshInstance3D
        var width:float=float(entry.get("width",0.88))
        var hp:float=float(monster.get("hp",0))
        var max_hp:float=max(1.0,float(monster.get("max",hp)))
        _set_fill(fill,hp/max_hp,width)
    for id in monster_bars.keys():
        if not active.has(id):
            var old:Node=monster_bars[id].get("root",null) as Node
            if old!=null and is_instance_valid(old):
                old.queue_free()
            monster_bars.erase(id)

func _build_monster_bar(monster:Node3D,boss:bool)->Dictionary:
    var root:Node3D=Node3D.new()
    root.name="HWMonsterVitals"
    root.position=Vector3(0,2.35 if not boss else 2.75,0)
    monster.add_child(root)
    var width:float=0.88 if not boss else 1.31
    var bg:MeshInstance3D=_bar(Color("#210f15"),Vector3(width+0.04,0.065,0.025))
    root.add_child(bg)
    var fill:MeshInstance3D=_bar(Color("#cf4451"),Vector3(width,0.052,0.028))
    fill.position.z=-0.02
    root.add_child(fill)
    return {"root":root,"hp":fill,"width":width}

func _set_fill(fill:MeshInstance3D,ratio:float,width:float)->void:
    if fill==null or not is_instance_valid(fill):
        return
    var r:float=clamp(ratio,0.0,1.0)
    fill.scale.x=r
    fill.position.x=-width*(1.0-r)*0.5

func _bar(color:Color,size:Vector3)->MeshInstance3D:
    var node:MeshInstance3D=MeshInstance3D.new()
    var mesh:BoxMesh=BoxMesh.new()
    mesh.size=size
    node.mesh=mesh
    node.material_override=_bar_material(color)
    return node

func _bar_material(color:Color)->StandardMaterial3D:
    var m:StandardMaterial3D=StandardMaterial3D.new()
    m.albedo_color=color
    m.roughness=0.28
    m.metallic=0.05
    m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
    m.billboard_mode=BaseMaterial3D.BILLBOARD_ENABLED
    return m

func _remove_old_vitals(hero:Node3D)->void:
    var old:Node=hero.get_node_or_null("HWVitals")
    if old!=null:
        old.queue_free()

func _add_class_features(hero:Node3D)->void:
    if hero.has_node("HWClassIdentity"):
        return
    var data:Variant=legacy.get("hero")
    if not data is Dictionary:
        return
    var class_id:String=str((data as Dictionary).get("class","Warrior"))
    var root:Node3D=Node3D.new()
    root.name="HWClassIdentity"
    hero.add_child(root)
    var accent:Color=_class_color(class_id)
    var gold:StandardMaterial3D=_mat(Color("#d7b45c"))
    var accent_mat:StandardMaterial3D=_mat(accent)
    root.add_child(_sphere(accent_mat,0.19,Vector3(-0.52,1.67,0)))
    root.add_child(_sphere(accent_mat,0.19,Vector3(0.52,1.67,0)))
    if class_id=="Archer" or class_id=="Ranger":
        for i in range(3):
            root.add_child(_cyl(gold,0.015,0.72,Vector3(-0.48+float(i)*0.045,1.55,0.24)))
    elif class_id=="Mage":
        root.add_child(_sphere(accent_mat,0.11,Vector3(0,2.60,-0.34)))
    elif class_id=="Acolyte":
        var halo:MeshInstance3D=_torus(gold,0.36,0.035)
        halo.position=Vector3(0,2.72,0)
        halo.rotation_degrees.x=90
        root.add_child(halo)
    elif class_id=="Thief":
        root.add_child(_box(_mat(Color("#252b34")),Vector3(0.46,0.13,0.05),Vector3(0,2.31,-0.36)))

func _class_color(class_id:String)->Color:
    match class_id:
        "Mage": return Color("#9c70ec")
        "Archer", "Ranger": return Color("#64af73")
        "Thief": return Color("#d6679c")
        "Acolyte": return Color("#e3c460")
        "Merchant": return Color("#5db1cf")
    return Color("#d58e3f")

func _mat(color:Color)->StandardMaterial3D:
    var m:StandardMaterial3D=StandardMaterial3D.new()
    m.albedo_color=color
    m.roughness=0.38
    m.metallic=0.25
    return m

func _sphere(mat:Material,radius:float,pos:Vector3)->MeshInstance3D:
    var node:MeshInstance3D=MeshInstance3D.new()
    var mesh:SphereMesh=SphereMesh.new()
    mesh.radius=radius
    mesh.height=radius*2.0
    mesh.radial_segments=32
    mesh.rings=18
    node.mesh=mesh
    node.position=pos
    node.material_override=mat
    return node

func _cyl(mat:Material,radius:float,height:float,pos:Vector3)->MeshInstance3D:
    var node:MeshInstance3D=MeshInstance3D.new()
    var mesh:CylinderMesh=CylinderMesh.new()
    mesh.top_radius=radius
    mesh.bottom_radius=radius
    mesh.height=height
    mesh.radial_segments=20
    node.mesh=mesh
    node.position=pos
    node.material_override=mat
    return node

func _box(mat:Material,size:Vector3,pos:Vector3)->MeshInstance3D:
    var node:MeshInstance3D=MeshInstance3D.new()
    var mesh:BoxMesh=BoxMesh.new()
    mesh.size=size
    node.mesh=mesh
    node.position=pos
    node.material_override=mat
    return node

func _torus(mat:Material,inner:float,offset:float)->MeshInstance3D:
    var node:MeshInstance3D=MeshInstance3D.new()
    var mesh:TorusMesh=TorusMesh.new()
    mesh.inner_radius=inner
    mesh.outer_radius=inner+offset
    mesh.rings=48
    mesh.ring_segments=12
    node.mesh=mesh
    node.material_override=mat
    return node
