extends Node3D

## Honour War native character detail V2.
## Adds original, high-density Godot geometry around the live gameplay actor.
## No GLB/GLTF assets are generated or attached by this layer.

var tracked:Node3D
var signature:String = ""
var elapsed:float = 0.0

func _process(delta:float) -> void:
    elapsed += delta
    var game := get_parent() as Node3D
    if game == null:
        return
    var hero := game.get("hero_visual") as Node3D
    if hero == null or not is_instance_valid(hero):
        return
    var cls := str(hero.get_meta("class", "Warrior"))
    var key := str(hero.get_instance_id()) + ":" + cls
    if tracked != hero or signature != key:
        tracked = hero
        signature = key
        _rebuild(hero, cls)
    _animate(hero)

func _rebuild(hero:Node3D, cls:String) -> void:
    var old := hero.get_node_or_null("HWCharacterDetailV2")
    if old != null:
        old.queue_free()
    var root := Node3D.new()
    root.name = "HWCharacterDetailV2"
    root.set_meta("hw_native_detail", true)
    hero.add_child(root)
    var p := _palette(cls)
    _body(root, p)
    _head(root, p)
    _limbs(root, p)
    _armor(root, p)
    _weapon(root, p, cls)
    _class_features(root, p, cls)

func _palette(cls:String)->Dictionary:
    match cls:
        "Mage": return {"main":Color("#4f49a8"),"dark":Color("#24254b"),"trim":Color("#9edcff"),"metal":Color("#b9c7d9"),"skin":Color("#d99b78"),"hair":Color("#302b48"),"leather":Color("#4d3329"),"glow":Color("#74dfff")}
        "Archer": return {"main":Color("#3f7957"),"dark":Color("#243e32"),"trim":Color("#d5bd78"),"metal":Color("#b6a47a"),"skin":Color("#dba07d"),"hair":Color("#3c2b22"),"leather":Color("#5a3a27"),"glow":Color("#9ce77d")}
        "Thief": return {"main":Color("#4b2859"),"dark":Color("#251b31"),"trim":Color("#c16ae8"),"metal":Color("#a99eb8"),"skin":Color("#d79b7b"),"hair":Color("#211b25"),"leather":Color("#34232d"),"glow":Color("#e17aff")}
        "Acolyte": return {"main":Color("#e9e4d7"),"dark":Color("#8d897e"),"trim":Color("#f6d875"),"metal":Color("#d7cba9"),"skin":Color("#dca17f"),"hair":Color("#6d523f"),"leather":Color("#72513a"),"glow":Color("#fff0a0")}
        "Merchant": return {"main":Color("#9a623a"),"dark":Color("#4a3025"),"trim":Color("#d8ad58"),"metal":Color("#c9b077"),"skin":Color("#dfa47e"),"hair":Color("#39271e"),"leather":Color("#5a3827"),"glow":Color("#7edfff")}
        _: return {"main":Color("#8f3030"),"dark":Color("#331c22"),"trim":Color("#e6c16b"),"metal":Color("#c7ccd4"),"skin":Color("#dfa17d"),"hair":Color("#2b2021"),"leather":Color("#503327"),"glow":Color("#ffd66e")}

func _body(r:Node3D,p:Dictionary)->void:
    _capsule(r,"TorsoCore",0.36,1.18,Vector3(0,1.08,0),p.dark,0.15,0.62)
    _capsule(r,"ChestVolume",0.47,0.92,Vector3(0,1.48,0),p.main,0.38,0.42)
    _box(r,"ChestPlate",Vector3(0.78,0.54,0.58),Vector3(0,1.48,0.08),p.main.lightened(0.08),0.55,0.32)
    _box(r,"ChestInset",Vector3(0.36,0.26,0.08),Vector3(0,1.52,0.36),p.trim,0.70,0.22)
    _torus(r,"Collar",0.27,0.055,Vector3(0,1.92,0),p.metal,0.65,0.24,Vector3.ZERO)
    _box(r,"WaistGuard",Vector3(0.84,0.16,0.54),Vector3(0,1.08,0),p.leather,0.10,0.68)
    _box(r,"Buckle",Vector3(0.17,0.18,0.08),Vector3(0,1.08,0.31),p.trim,0.72,0.20)

func _head(r:Node3D,p:Dictionary)->void:
    _cylinder(r,"Neck",0.14,0.24,Vector3(0,1.96,0),p.skin,0.0,0.72)
    _sphere(r,"Head",0.405,Vector3(0,2.31,0),p.skin,0.02,0.72,32,20)
    _sphere(r,"HairMass",0.455,Vector3(0,2.51,-0.025),p.hair,0.02,0.58,32,20,Vector3(1.08,0.70,1.04))
    _sphere(r,"HairFringe",0.275,Vector3(0,2.39,0.315),p.hair,0.02,0.52,28,16,Vector3(1.5,0.52,0.48))
    _sphere(r,"EarL",0.075,Vector3(-0.39,2.31,0),p.skin,0.0,0.78,20,12)
    _sphere(r,"EarR",0.075,Vector3(0.39,2.31,0),p.skin,0.0,0.78,20,12)
    _sphere(r,"EyeL",0.052,Vector3(-0.145,2.33,0.355),Color("#18202b"),0.0,0.18,20,12)
    _sphere(r,"EyeR",0.052,Vector3(0.145,2.33,0.355),Color("#18202b"),0.0,0.18,20,12)
    _sphere(r,"EyeHighlightL",0.017,Vector3(-0.13,2.345,0.395),Color.WHITE,0.0,0.12,12,8)
    _sphere(r,"EyeHighlightR",0.017,Vector3(0.16,2.345,0.395),Color.WHITE,0.0,0.12,12,8)
    _box(r,"Nose",Vector3(0.07,0.10,0.12),Vector3(0,2.26,0.39),p.skin.darkened(0.05),0.0,0.72)
    _box(r,"Mouth",Vector3(0.14,0.025,0.035),Vector3(0,2.17,0.365),Color("#8b4d4a"),0.0,0.55)

func _limbs(r:Node3D,p:Dictionary)->void:
    for side in [-1.0,1.0]:
        _capsule(r,"Arm"+str(side),0.155,0.68,Vector3(side*0.56,1.38,0),p.main,0.15,0.56,Vector3(0,0,side*0.14))
        _sphere(r,"Glove"+str(side),0.17,Vector3(side*0.61,1.02,0.01),p.leather,0.08,0.62,24,14)
        _box(r,"Cuff"+str(side),Vector3(0.22,0.18,0.32),Vector3(side*0.59,1.10,0),p.trim,0.35,0.38)
        _sphere(r,"Shoulder"+str(side),0.255,Vector3(side*0.55,1.68,0),p.metal,0.62,0.30,24,16,Vector3(1.22,0.72,1.10))
        _capsule(r,"Leg"+str(side),0.18,0.74,Vector3(side*0.22,0.40,0),p.dark,0.15,0.62)
        _box(r,"Boot"+str(side),Vector3(0.33,0.24,0.54),Vector3(side*0.22,0.10,0.08),p.leather,0.18,0.58)
        _box(r,"BootTrim"+str(side),Vector3(0.34,0.08,0.55),Vector3(side*0.22,0.22,0.08),p.trim,0.42,0.42)
        _box(r,"HipGuard"+str(side),Vector3(0.20,0.40,0.40),Vector3(side*0.47,0.88,0.02),p.main.darkened(0.08),0.35,0.48)
        _box(r,"KneeGuard"+str(side),Vector3(0.30,0.18,0.32),Vector3(side*0.22,0.63,0.20),p.trim,0.62,0.28)

func _armor(r:Node3D,p:Dictionary)->void:
    for y in [1.25,1.42,1.60]:
        _box(r,"ArmorRidge"+str(y),Vector3(0.88,0.055,0.045),Vector3(0,y,0.31),p.trim,0.55,0.30)

func _weapon(r:Node3D,p:Dictionary,cls:String)->void:
    if cls=="Archer":
        _torus(r,"Bow",0.40,0.045,Vector3(0.70,1.72,0.06),p.trim,0.45,0.38,Vector3(0,PI*0.5,0))
        _box(r,"BowGrip",Vector3(0.10,0.28,0.10),Vector3(0.70,1.72,0.08),p.leather,0.1,0.72)
        _box(r,"Quiver",Vector3(0.24,0.68,0.20),Vector3(-0.48,1.36,-0.20),p.leather,0.05,0.72)
    elif cls=="Mage" or cls=="Acolyte":
        _cylinder(r,"Staff",0.055,1.75,Vector3(0.68,1.35,0.08),p.leather,0.0,0.76)
        _sphere(r,"StaffGem",0.15,Vector3(0.68,2.27,0.08),p.glow,0.12,0.18,28,18)
        _torus(r,"StaffHalo",0.22,0.025,Vector3(0.68,2.27,0.08),p.trim,0.18,0.20,Vector3(PI*0.5,0,0))
    else:
        _cylinder(r,"WeaponGrip",0.055,0.44,Vector3(0.69,1.14,0.08),p.leather,0.0,0.70)
        _box(r,"WeaponGuard",Vector3(0.46,0.07,0.10),Vector3(0.69,1.36,0.08),p.trim,0.7,0.20)
        _box(r,"WeaponBlade",Vector3(0.13,1.15,0.12),Vector3(0.69,1.90,0.08),p.metal,0.78,0.18)
        _box(r,"BladeInset",Vector3(0.035,0.88,0.02),Vector3(0.69,1.90,0.145),p.glow,0.35,0.18)

func _class_features(r:Node3D,p:Dictionary,cls:String)->void:
    match cls:
        "Mage":
            _torus(r,"MageMantle",0.60,0.07,Vector3(0,1.55,0),p.trim,0.18,0.35,Vector3(PI*0.5,0,0))
            _sphere(r,"MageCrownGem",0.10,Vector3(0,2.76,0.04),p.glow,0.12,0.16,24,14)
        "Thief":
            _box(r,"ThiefScarf",Vector3(0.90,0.12,0.18),Vector3(0,1.84,0.28),p.trim,0.12,0.64)
            _box(r,"ThiefCloak",Vector3(0.92,1.15,0.08),Vector3(0,1.42,-0.38),p.dark,0.05,0.70)
        "Archer":
            _box(r,"ArcherChestSash",Vector3(0.72,0.09,0.09),Vector3(0,1.40,0.32),p.trim,0.18,0.44)
        "Acolyte":
            _torus(r,"HolyHalo",0.34,0.045,Vector3(0,2.77,0),p.glow,0.10,0.18,Vector3(PI*0.5,0,0))
        "Merchant":
            _box(r,"MerchantSatchel",Vector3(0.38,0.42,0.26),Vector3(-0.62,1.20,0.06),p.leather,0.05,0.76)
        _:
            _box(r,"WarriorCrest",Vector3(0.16,0.34,0.08),Vector3(0,2.73,0.02),p.trim,0.72,0.20)
            _box(r,"WarriorBeltPlate",Vector3(0.28,0.26,0.08),Vector3(0,1.08,0.37),p.trim,0.72,0.22)

func _animate(hero:Node3D)->void:
    var root:=hero.get_node_or_null("HWCharacterDetailV2") as Node3D
    if root==null:
        return
    root.rotation.z=sin(elapsed*2.0)*0.012
    var gem:=root.get_node_or_null("StaffGem") as Node3D
    if gem!=null:
        gem.scale=Vector3.ONE*(1.0+sin(elapsed*3.2)*0.06)

func _mat(color:Color,metal:float,rough:float)->StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.albedo_color=color
    m.metallic=metal
    m.roughness=rough
    return m

func _capsule(parent:Node3D,n:String,r:float,h:float,pos:Vector3,color:Color,metal:float,rough:float,rot:Vector3=Vector3.ZERO)->void:
    var x:=MeshInstance3D.new()
    x.name=n
    var m:=CapsuleMesh.new()
    m.radius=r
    m.height=h
    m.radial_segments=24
    m.rings=10
    x.mesh=m
    x.position=pos
    x.rotation=rot
    x.material_override=_mat(color,metal,rough)
    parent.add_child(x)

func _sphere(parent:Node3D,n:String,r:float,pos:Vector3,color:Color,metal:float,rough:float,segments:int=24,rings:int=16,scale:Vector3=Vector3.ONE)->void:
    var x:=MeshInstance3D.new()
    x.name=n
    var m:=SphereMesh.new()
    m.radius=r
    m.height=r*2.0
    m.radial_segments=segments
    m.rings=rings
    x.mesh=m
    x.position=pos
    x.scale=scale
    x.material_override=_mat(color,metal,rough)
    parent.add_child(x)

func _box(parent:Node3D,n:String,size:Vector3,pos:Vector3,color:Color,metal:float,rough:float,rot:Vector3=Vector3.ZERO)->void:
    var x:=MeshInstance3D.new()
    x.name=n
    var m:=BoxMesh.new()
    m.size=size
    x.mesh=m
    x.position=pos
    x.rotation=rot
    x.material_override=_mat(color,metal,rough)
    parent.add_child(x)

func _cylinder(parent:Node3D,n:String,r:float,h:float,pos:Vector3,color:Color,metal:float,rough:float,rot:Vector3=Vector3.ZERO)->void:
    var x:=MeshInstance3D.new()
    x.name=n
    var m:=CylinderMesh.new()
    m.top_radius=r
    m.bottom_radius=r*1.08
    m.height=h
    m.radial_segments=24
    x.mesh=m
    x.position=pos
    x.rotation=rot
    x.material_override=_mat(color,metal,rough)
    parent.add_child(x)

func _torus(parent:Node3D,n:String,inner:float,outer:float,pos:Vector3,color:Color,metal:float,rough:float,rot:Vector3)->void:
    var x:=MeshInstance3D.new()
    x.name=n
    var m:=TorusMesh.new()
    m.inner_radius=inner
    m.outer_radius=inner+outer
    m.rings=40
    m.ring_segments=12
    x.mesh=m
    x.position=pos
    x.rotation=rot
    x.material_override=_mat(color,metal,rough)
    parent.add_child(x)
