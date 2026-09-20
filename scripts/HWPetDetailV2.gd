extends Node3D

## Native HD pet detail layer. Keeps the live pet actor readable at gameplay distance.
## No external model format is required; all geometry is native Godot.

var tracked:Node3D
var signature:String=""
var elapsed:float=0.0

func _process(delta:float)->void:
    elapsed+=delta
    var game:=get_parent() as Node3D
    if game==null: return
    var pet:=game.get("pet_visual") as Node3D
    if pet==null or not is_instance_valid(pet): return
    var species:=str(pet.get_meta("species",""))
    if species.is_empty():
        var legacy:=game.get_node_or_null("LegacyGame")
        if legacy!=null:
            var value:Variant=legacy.get("hero")
            if value is Dictionary and value.get("pet",{}) is Dictionary:
                species=str((value.get("pet",{}) as Dictionary).get("species","Wolf Cub"))
    var key:=str(pet.get_instance_id())+":"+species
    if tracked!=pet or signature!=key:
        tracked=pet
        signature=key
        _rebuild(pet,species)
    _animate(pet)

func _rebuild(pet:Node3D,species:String)->void:
    var old:=pet.get_node_or_null("HWPetDetailV2")
    if old!=null: old.queue_free()
    var root:=Node3D.new()
    root.name="HWPetDetailV2"
    pet.add_child(root)
    match species:
        "Royal Falcon":
            _bird(root)
        "Astral Sprite":
            _sprite(root)
        "Blessed Poring":
            _poring(root)
        _:
            _wolf(root)

func _bird(r:Node3D)->void:
    var body:=_sphere(r,"Body",0.36,Vector3(0,0.03,0),Color("#9b7042"),0.05,0.64,28,16,Vector3(1.25,0.78,0.95))
    _sphere(r,"Head",0.27,Vector3(0,0.25,-0.24),Color("#b8864e"),0.02,0.60,24,14)
    _sphere(r,"EyeL",0.045,Vector3(-0.13,0.29,-0.46),Color("#18202b"),0,0.18,16,10)
    _sphere(r,"EyeR",0.045,Vector3(0.13,0.29,-0.46),Color("#18202b"),0,0.18,16,10)
    _sphere(r,"EyeGlowL",0.014,Vector3(-0.12,0.30,-0.495),Color.WHITE,0,0.12,10,8)
    _sphere(r,"EyeGlowR",0.014,Vector3(0.14,0.30,-0.495),Color.WHITE,0,0.12,10,8)
    _cone(r,"Beak",0.11,0.26,Vector3(0,0.23,-0.53),Color("#e0bd61"),0.02,0.46,Vector3(90,0,0))
    for side in [-1.0,1.0]:
        _box(r,"Wing"+str(side),Vector3(0.12,0.18,0.72),Vector3(side*0.32,0.02,0.05),Color("#d5b873"),0.10,0.50,Vector3(0,side*18.0,side*10.0))
        _box(r,"Tail"+str(side),Vector3(0.10,0.16,0.62),Vector3(side*0.10,0.02,0.48),Color("#725235"),0.02,0.72,Vector3(side*8.0,0,0))
    _ring(r,"PetAura",Color("#ffe18a"),0.54,0.035,Vector3(0,-0.27,0),Vector3(PI*0.5,0,0))

func _sprite(r:Node3D)->void:
    _sphere(r,"Core",0.48,Vector3(0,0,0),Color("#6bd6ff"),0.05,0.30,32,20)
    _sphere(r,"FaceGlow",0.25,Vector3(0,0,-0.34),Color("#b8f2ff"),0,0.20,24,16)
    for side in [-1.0,1.0]:
        _sphere(r,"Eye"+str(side),0.04,Vector3(side*0.10,0.04,-0.46),Color("#102333"),0,0.16,12,8)
    _ring(r,"Halo",Color("#b8f2ff"),0.60,0.04,Vector3(0,0,0),Vector3(PI*0.5,0,0))
    _ring(r,"Halo2",Color("#75dfff"),0.42,0.025,Vector3(0,0.02,0),Vector3(0,0,0))

func _poring(r:Node3D)->void:
    _sphere(r,"Body",0.55,Vector3(0,0,0),Color("#ef8fb8"),0.02,0.55,32,20,Vector3(1.12,0.88,1.05))
    for side in [-1.0,1.0]:
        _sphere(r,"Eye"+str(side),0.055,Vector3(side*0.13,0.10,-0.49),Color("#30202b"),0,0.18,16,10)
        _sphere(r,"EyeHi"+str(side),0.016,Vector3(side*0.11,0.12,-0.535),Color.WHITE,0,0.12,10,8)
    _box(r,"Mouth",Vector3(0.16,0.025,0.03),Vector3(0,0.01,-0.545),Color("#9b405d"),0,0.58)
    _cone(r,"Crown",0.18,0.36,Vector3(0,0.56,0),Color("#e4c45d"),0.65,0.25)
    _ring(r,"PetAura",Color("#ffd0e6"),0.64,0.03,Vector3(0,-0.42,0),Vector3(PI*0.5,0,0))

func _wolf(r:Node3D)->void:
    _sphere(r,"Body",0.50,Vector3(0,0.16,0),Color("#68747e"),0.08,0.66,32,20,Vector3(1.20,0.78,1.45))
    _sphere(r,"Chest",0.32,Vector3(0,0.20,-0.34),Color("#8b959b"),0.02,0.72,24,16,Vector3(1.0,1.0,0.75))
    _sphere(r,"Head",0.34,Vector3(0,0.44,-0.48),Color("#78838a"),0.04,0.62,28,18)
    for side in [-1.0,1.0]:
        _cone(r,"Ear"+str(side),0.15,0.34,Vector3(side*0.18,0.72,-0.45),Color("#4e5961"),0.06,0.60)
        _sphere(r,"Eye"+str(side),0.045,Vector3(side*0.12,0.48,-0.77),Color("#e7c35b"),0.05,0.20,16,10)
        _sphere(r,"Paw"+str(side),0.15,Vector3(side*0.26,-0.10,-0.28),Color("#4e5961"),0.05,0.72,20,12)
    _sphere(r,"Snout",0.22,Vector3(0,0.38,-0.77),Color("#505b63"),0.02,0.70,22,14,Vector3(1.0,0.75,0.80))
    _sphere(r,"Nose",0.06,Vector3(0,0.39,-0.94),Color("#22272c"),0.10,0.28,16,10)
    _box(r,"Tail",Vector3(0.16,0.16,0.72),Vector3(0.0,0.32,0.66),Color("#56616a"),0.04,0.68,Vector3(-25,0,0))

func _animate(pet:Node3D)->void:
    var root:=pet.get_node_or_null("HWPetDetailV2") as Node3D
    if root==null: return
    root.rotation.z=sin(elapsed*4.5)*0.035

func _mat(c:Color,metal:float,rough:float)->StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.albedo_color=c
    m.metallic=metal
    m.roughness=rough
    return m

func _sphere(parent:Node3D,n:String,radius:float,pos:Vector3,c:Color,metal:float,rough:float,segments:int,rings:int,scale:Vector3=Vector3.ONE)->MeshInstance3D:
    var x:=MeshInstance3D.new(); x.name=n
    var m:=SphereMesh.new(); m.radius=radius; m.height=radius*2.0; m.radial_segments=segments; m.rings=rings
    x.mesh=m; x.position=pos; x.scale=scale; x.material_override=_mat(c,metal,rough); parent.add_child(x); return x

func _box(parent:Node3D,n:String,size:Vector3,pos:Vector3,c:Color,metal:float,rough:float,rot:Vector3=Vector3.ZERO)->MeshInstance3D:
    var x:=MeshInstance3D.new(); x.name=n
    var m:=BoxMesh.new(); m.size=size
    x.mesh=m; x.position=pos; x.rotation_degrees=rot; x.material_override=_mat(c,metal,rough); parent.add_child(x); return x

func _cone(parent:Node3D,n:String,radius:float,height:float,pos:Vector3,c:Color,metal:float,rough:float,rot:Vector3=Vector3.ZERO)->MeshInstance3D:
    var x:=MeshInstance3D.new(); x.name=n
    var m:=CylinderMesh.new(); m.top_radius=0.0; m.bottom_radius=radius; m.height=height
    x.mesh=m; x.position=pos; x.rotation_degrees=rot; x.material_override=_mat(c,metal,rough); parent.add_child(x); return x

func _ring(parent:Node3D,n:String,c:Color,inner:float,outer:float,pos:Vector3,rot:Vector3)->MeshInstance3D:
    var x:=MeshInstance3D.new(); x.name=n
    var m:=TorusMesh.new(); m.inner_radius=inner; m.outer_radius=inner+outer; m.rings=32; m.ring_segments=10
    x.mesh=m; x.position=pos; x.rotation=rot; x.material_override=_mat(c,0.10,0.28); parent.add_child(x); return x
