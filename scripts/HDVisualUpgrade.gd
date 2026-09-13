class_name HDVisualUpgrade
extends Node3D

## Compatibility-safe HD presentation layer. Builds a complete readable hero
## and authored-looking town without requiring external GLB assets.
const CENTER:Vector3 = Vector3(12.925,0.0,12.65)
var root:Node3D

func _ready()->void:
    call_deferred("_build")

func _build()->void:
    var game:Node3D=get_parent() as Node3D
    if game==null: return
    var old_world:Node=game.get_node_or_null("World3D")
    if old_world!=null: old_world.visible=false
    var old_env:Node=game.get_node_or_null("HDEnvironmentDirector")
    if old_env!=null: old_env.visible=false
    root=Node3D.new(); root.name="HDPresentationWorld"; game.add_child(root)
    _build_ground(); _build_town()
    var actors:Node=game.get_node_or_null("Actors3D")
    if actors!=null:
        var hero:Node3D=actors.get_node_or_null("Hero") as Node3D
        if hero!=null:
            var legacy:Node2D=game.get_node_or_null("LegacyGame") as Node2D
            var hero_data:Dictionary={}
            if legacy!=null and legacy.get("hero") is Dictionary:
                hero_data=legacy.get("hero")
            _upgrade_hero(hero,str(hero_data.get("class","Warrior")))

func _mat(color:Color,roughness:float=0.68,metallic:float=0.0)->StandardMaterial3D:
    var m:=StandardMaterial3D.new(); m.albedo_color=color; m.roughness=roughness; m.metallic=metallic; return m

func _box(parent:Node3D,size:Vector3,pos:Vector3,mat:Material)->MeshInstance3D:
    var n:=MeshInstance3D.new(); var mesh:=BoxMesh.new(); mesh.size=size; n.mesh=mesh; n.position=pos; n.material_override=mat; parent.add_child(n); return n

func _cyl(parent:Node3D,radius:float,height:float,pos:Vector3,mat:Material,segments:int=32)->MeshInstance3D:
    var n:=MeshInstance3D.new(); var mesh:=CylinderMesh.new(); mesh.top_radius=radius; mesh.bottom_radius=radius; mesh.height=height; mesh.radial_segments=segments; n.mesh=mesh; n.position=pos; n.material_override=mat; parent.add_child(n); return n

func _sphere(parent:Node3D,radius:float,pos:Vector3,mat:Material,scale:Vector3=Vector3.ONE)->MeshInstance3D:
    var n:=MeshInstance3D.new(); var mesh:=SphereMesh.new(); mesh.radius=radius; mesh.height=radius*2.0; mesh.radial_segments=32; mesh.rings=18; n.mesh=mesh; n.position=pos; n.scale=scale; n.material_override=mat; parent.add_child(n); return n

func _build_ground()->void:
    var ground:=_mat(Color("#4D6946"),0.96); var road:=_mat(Color("#6B5646"),0.96); var stone:=_mat(Color("#968A76"),0.88)
    _box(root,Vector3(74,0.35,48),CENTER+Vector3(0,-0.20,0),ground)
    _box(root,Vector3(11,0.12,46),CENTER+Vector3(0,-0.02,0),road)
    _box(root,Vector3(72,0.12,7.2),CENTER+Vector3(0,-0.02,1),road)
    _box(root,Vector3(40,0.10,5),CENTER+Vector3(0,0.02,-10),stone)
    for x in range(-4,5): _box(root,Vector3(0.24,0.03,9.2),CENTER+Vector3(float(x)*1.95,0.055,-10),_mat(Color("#B8AA8C"),1.0))
    _cyl(root,6.3,0.22,CENTER+Vector3(0,0.12,5.5),stone,64)
    _cyl(root,3.0,0.11,CENTER+Vector3(0,0.29,5.5),_mat(Color("#5E9EB2"),0.18),64)

func _build_town()->void:
    var walls:Array[Material]=[_mat(Color("#B98261")),_mat(Color("#C6A373")),_mat(Color("#829B73")),_mat(Color("#81769A"))]
    var roofs:Array[Material]=[_mat(Color("#5B2830"),0.72),_mat(Color("#3D455E"),0.72),_mat(Color("#6A4B35"),0.75),_mat(Color("#314C3E"),0.75)]
    var points:Array[Vector3]=[CENTER+Vector3(-13,0,-6),CENTER+Vector3(13,0,-6),CENTER+Vector3(-13,0,14),CENTER+Vector3(13,0,14),CENTER+Vector3(-25,0,6),CENTER+Vector3(25,0,6)]
    for i in points.size(): _house(points[i],walls[i%4],roofs[i%4],i)
    _lamps(); _trees(); _gate(CENTER+Vector3(0,0,-17))

func _house(pos:Vector3,wall:Material,roof:Material,index:int)->void:
    var h:=Node3D.new(); h.name="TownHouse_%02d" % index; root.add_child(h)
    _box(h,Vector3(6.6,4.1,5.4),pos+Vector3(0,2.05,0),wall)
    var rm:=CylinderMesh.new(); rm.top_radius=0; rm.bottom_radius=4.5; rm.height=2.5; rm.radial_segments=6
    var r:=MeshInstance3D.new(); r.mesh=rm; r.position=pos+Vector3(0,5.15,0); r.material_override=roof; h.add_child(r)
    var trim:=_mat(Color("#E2CC9C"),0.55)
    _box(h,Vector3(5.7,0.18,0.16),pos+Vector3(0,3.72,2.73),trim)
    _box(h,Vector3(1.05,1.95,0.12),pos+Vector3(0,0.98,2.75),_mat(Color("#3B2922"),0.82))
    for sx in [-1.65,1.65]:
        _box(h,Vector3(1.15,1.05,0.10),pos+Vector3(sx,2.25,2.75),_mat(Color("#88C5D4"),0.18))
        _box(h,Vector3(0.10,1.05,0.12),pos+Vector3(sx,2.25,2.82),trim)
        _box(h,Vector3(1.15,0.10,0.12),pos+Vector3(sx,2.25,2.82),trim)
    _box(h,Vector3(1.6,0.5,0.10),pos+Vector3(0,3.50,2.82),_mat(Color("#6E4D2F"),0.75))

func _lamps()->void:
    var dark:=_mat(Color("#252A31"),0.60,0.55); var gold:=_mat(Color("#D9B75A"),0.30,0.72)
    for x in [-19.0,-7.0,7.0,19.0]:
        for z in [-1.0,9.5]:
            var p:=CENTER+Vector3(x,0,z)
            _cyl(root,0.09,2.9,p+Vector3(0,1.45,0),dark,24)
            _sphere(root,0.16,p+Vector3(0,3.0,0),gold,Vector3(1,1,0.75))

func _trees()->void:
    var trunk:=_mat(Color("#583D2C"),1.0); var leaf:=_mat(Color("#3B7A4E"),0.98)
    var pts:Array[Vector3]=[CENTER+Vector3(-29,0,-11),CENTER+Vector3(30,0,-10),CENTER+Vector3(-30,0,22),CENTER+Vector3(30,0,22),CENTER+Vector3(-34,0,5),CENTER+Vector3(34,0,7)]
    for p in pts:
        _cyl(root,0.32,2.8,p+Vector3(0,1.4,0),trunk,24)
        _sphere(root,1.55,p+Vector3(0,3.3,0),leaf,Vector3(1.2,1,1.15))
        _sphere(root,1.05,p+Vector3(0.9,3.8,0.2),leaf,Vector3(1,0.85,1))

func _gate(pos:Vector3)->void:
    var stone:=_mat(Color("#6B6B73"),0.84); var banner:=_mat(Color("#A6424E"),0.68)
    _box(root,Vector3(2.2,7.5,2.2),pos+Vector3(-4.5,3.75,0),stone)
    _box(root,Vector3(2.2,7.5,2.2),pos+Vector3(4.5,3.75,0),stone)
    _box(root,Vector3(11.2,1.5,2.2),pos+Vector3(0,7.0,0),stone)
    _box(root,Vector3(1.0,4.0,0.18),pos+Vector3(0,4.2,1.2),banner)

func _upgrade_hero(hero:Node3D,class_id:String)->void:
    for child in hero.get_children(): child.queue_free()
    var accent:=Color("#E6A242")
    match class_id:
        "Mage": accent=Color("#9C6FF0")
        "Archer": accent=Color("#6DBE77")
        "Thief": accent=Color("#E06AA7")
        "Acolyte": accent=Color("#F2D265")
        "Merchant": accent=Color("#69BDE0")
    var skin:=_mat(Color("#D69B78"),0.62); var cloth:=_mat(accent,0.52); var dark:=_mat(Color("#20252D"),0.70); var metal:=_mat(Color("#C2CBD4"),0.22,0.75); var gold:=_mat(Color("#E9C66A"),0.25,0.80); var hair:=_mat(Color("#2A242C"),0.50); var eye:=_mat(Color("#24314A"),0.30)
    _box(hero,Vector3(0.72,0.46,0.46),Vector3(0,1.02,0),dark)
    for x in [-0.21,0.21]:
        _box(hero,Vector3(0.25,0.72,0.30),Vector3(x,0.55,0),cloth)
        _box(hero,Vector3(0.31,0.22,0.48),Vector3(x,0.08,-0.08),dark)
        _box(hero,Vector3(0.28,0.15,0.34),Vector3(x,0.94,0),gold)
    _box(hero,Vector3(0.94,0.84,0.54),Vector3(0,1.50,0),cloth)
    _box(hero,Vector3(0.74,0.14,0.56),Vector3(0,1.88,0),gold)
    _cyl(hero,0.15,0.22,Vector3(0,2.04,0),skin,24)
    _sphere(hero,0.37,Vector3(0,2.35,0),skin,Vector3(0.92,1.0,0.88))
    _sphere(hero,0.40,Vector3(0,2.50,0.02),hair,Vector3(1.02,0.62,0.96))
    _box(hero,Vector3(0.12,0.25,0.18),Vector3(-0.34,2.34,0.02),hair)
    _box(hero,Vector3(0.12,0.25,0.18),Vector3(0.34,2.34,0.02),hair)
    for x in [-0.12,0.12]:
        _box(hero,Vector3(0.08,0.05,0.025),Vector3(x,2.36,-0.34),eye)
        _box(hero,Vector3(0.055,0.025,0.025),Vector3(x,2.28,-0.355),_mat(Color("#F5F3EA"),0.40))
    _box(hero,Vector3(0.06,0.10,0.05),Vector3(0,2.30,-0.35),_mat(Color("#C78168"),0.62))
    _box(hero,Vector3(0.14,0.025,0.025),Vector3(0,2.20,-0.355),_mat(Color("#743543"),0.46))
    for x in [-0.60,0.60]:
        _cyl(hero,0.16,0.72,Vector3(x,1.48,0),skin,28)
        _box(hero,Vector3(0.28,0.24,0.44),Vector3(x,1.78,0),cloth)
        _sphere(hero,0.15,Vector3(x,1.06,0),skin)
    _box(hero,Vector3(0.98,1.22,0.06),Vector3(0,1.45,0.34),dark)
    _box(hero,Vector3(0.09,1.18,0.13),Vector3(0.82,1.48,-0.05),metal)
    _box(hero,Vector3(0.30,0.07,0.12),Vector3(0.82,1.02,-0.05),gold)
