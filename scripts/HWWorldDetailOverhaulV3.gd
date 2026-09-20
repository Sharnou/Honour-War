extends Node3D
## Honour War HD World Detail V3 - dense native 3D environment pass.
## Approved asset path: native Godot geometry / FBX / OBJ. No GLB/GLTF.
const Teleport=preload("res://scripts/TeleportSystem.gd")
const SCALE:=0.055
const OX:=365.0
const OY:=120.0
var legacy:Node
var root:Node3D
var last_map:=-999
var center:=Vector3.ZERO

func _ready()->void:
    process_priority=850
    legacy=get_parent().get_node_or_null("LegacyGame")
    call_deferred("_rebuild")

func _process(_d:float)->void:
    if legacy==null: legacy=get_parent().get_node_or_null("LegacyGame")
    if legacy==null:return
    var h:Variant=legacy.get("hero")
    if h is Dictionary:
        var m:=int((h as Dictionary).get("map_id",0))
        if m!=last_map:_rebuild()

func _rebuild()->void:
    if legacy==null:return
    var h:Variant=legacy.get("hero")
    var m:=int((h as Dictionary).get("map_id",0)) if h is Dictionary else 0
    last_map=m
    center=_world(Teleport.default_point(m))
    if root!=null and is_instance_valid(root):root.queue_free()
    var old:=get_parent().get_node_or_null("World3D")
    if old!=null:old.visible=false
    root=Node3D.new();root.name="HWHDWorldDetail_Map_%02d"%m;get_parent().add_child(root)
    _lighting(m);_ground(m);_roads(m)
    var kind:=str(Teleport.MAPS.get(m,{}).get("type","town"))
    if kind=="town":_town(m)
    elif kind=="field":_field(m)
    else:_dungeon(m)
    _identity(m);_micro(m)

func _lighting(m:int)->void:
    var cam:=get_parent().get_node_or_null("Camera3D") as Camera3D
    if cam==null:return
    var e:=Environment.new();e.background_mode=Environment.BG_COLOR;e.background_color=_sky(m)
    e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color=Color("fff1d2");e.ambient_light_energy=0.75
    e.tonemap_mode=Environment.TONE_MAPPER_ACES;e.tonemap_exposure=0.1;e.ssao_enabled=true;e.ssao_radius=2.0;e.ssao_intensity=1.3;e.glow_enabled=true;e.glow_intensity=0.55
    cam.environment=e
    var sun:=get_parent().get_node_or_null("HWHDWorldSun") as DirectionalLight3D
    if sun==null:sun=DirectionalLight3D.new();sun.name="HWHDWorldSun";get_parent().add_child(sun)
    sun.rotation_degrees=Vector3(-52,-34,0);sun.light_energy=1.35;sun.light_color=Color("fff0cf");sun.shadow_enabled=true;sun.directional_shadow_max_distance=90

func _ground(m:int)->void:
    var t:=_theme(m);var g:=_box(Vector3(92,0.16,68),center+Vector3(0,-0.1,0),t.ground);g.material_override=_mat(t.ground,0,0.95);root.add_child(g)
    for i in range(36):
        var p:=center+Vector3(_p(i,35),0.02,_p(i+100,25));var patch:=_box(Vector3(1.5+float(i%4),0.05,1.2+float(i%3)),p,t.variation);patch.rotation.y=float(i)*0.61;root.add_child(patch)
    for i in range(14):
        var a:=TAU*float(i)/14.0;var h:=0.3+float((i+m)%3)*0.18;var mound:=_box(Vector3(7,h,5),center+Vector3(cos(a)*31,h/2,sin(a)*23),t.earth);mound.rotation.y=-a;root.add_child(mound)

func _roads(m:int)->void:
    var t:=_theme(m);var kind:=str(Teleport.MAPS.get(m,{}).get("type","town"));var c:=t.road if kind=="town" else t.path
    _road(Vector3(8,0.14,54),center,c);_road(Vector3(66,0.14,6.5),center,c)
    if kind=="town":_road(Vector3(4.5,0.12,32),center+Vector3(-18,0,7),c);_road(Vector3(4.5,0.12,32),center+Vector3(18,0,7),c);_road(Vector3(48,0.12,4.4),center+Vector3(0,0,-10),c)
    for i in range(24):
        var z:float=-25+i*2.1;root.add_child(_box(Vector3(0.18,0.28,1.5),center+Vector3(-4.2,0.18,z),t.curb));root.add_child(_box(Vector3(0.18,0.28,1.5),center+Vector3(4.2,0.18,z),t.curb))

func _town(m:int)->void:
    var t:=_theme(m);_disc(center+Vector3(0,0.12,5),6.8,t.stone);_fountain(center+Vector3(0,0.3,5),t.water)
    var ps=[Vector3(-15,0,-13),Vector3(0,0,-15),Vector3(15,0,-13),Vector3(-15,0,13),Vector3(15,0,13),Vector3(-27,0,1),Vector3(27,0,1)];var names=["INN","FORGE","GUILD","SHOP","BANK","HEAL","MARKET"]
    for i in range(ps.size()):_building(center+ps[i],t,names[i],i)
    for x in [-31.0,31.0]:root.add_child(_box(Vector3(1.3,4.5,48),center+Vector3(x,2.25,0),t.wall_dark))
    _gate(center+Vector3(0,0,-24),t.stone,Teleport.map_name(m));_gate(center+Vector3(0,0,25),t.stone,"FIELD")
    for i in range(12):var a:=TAU*float(i)/12.0;_tree(center+Vector3(cos(a)*28,0,sin(a)*20),t,i)
    _stall(center+Vector3(-8,0,9),t);_stall(center+Vector3(8,0,9),t);_banner(center+Vector3(-10,0,-5),t,"HONOUR");_banner(center+Vector3(10,0,-5),t,"WAR")

func _field(m:int)->void:
    var t:=_theme(m)
    for i in range(70):_grass(center+Vector3(_p(i+10,31),0,_p(i+100,23)),t,i)
    for i in range(34):_tree(center+Vector3(_p(i+220,31),0,_p(i+310,22)),t,i)
    for i in range(34):_rocks(center+Vector3(_p(i+410,28),0,_p(i+520,20)),t,i)
    for i in range(12):var z:float=-23+i*4.2;_fence(center+Vector3(-20,0,z),t.wood);_fence(center+Vector3(20,0,z),t.wood)
    _gate(center+Vector3(0,0,-24),t.stone,"ROAD TO "+Teleport.map_name(Teleport.town_for_field(m)).to_upper())

func _dungeon(m:int)->void:
    var t:=_theme(m);root.add_child(_box(Vector3(74,0.3,56),center+Vector3(0,-0.08,0),t.stone_dark))
    for i in range(28):_column(center+Vector3(_p(i+600,31),0,_p(i+700,21)),t.stone,2.5+float(i%4)*0.35)
    for i in range(28):_torch(center+Vector3(_p(i+800,29),0,_p(i+900,20)),t)
    for i in range(26):_crystal(center+Vector3(_p(i+1000,28),0,_p(i+1100,19)),t.magic,i)
    _arch(center+Vector3(0,0,-23),t.stone);_altar(center+Vector3(0,0,6),t)
    for i in range(18):_debris(center+Vector3(_p(i+1200,27),0,_p(i+1300,19)),t.stone_dark,i)

func _identity(m:int)->void:
    var n:=Teleport.map_name(m).to_lower();var t:=_theme(m)
    if n.find("desert")>=0 or n.find("morroc")>=0:
        for i in range(26):_cactus(center+Vector3(_p(i+1400,30),0,_p(i+1500,21)),t,i)
    elif n.find("coast")>=0 or n.find("izlude")>=0 or n.find("alberta")>=0:_water(t)
    elif n.find("forest")>=0 or n.find("jungle")>=0 or n.find("wilds")>=0 or n.find("payon")>=0:
        for i in range(26):_fern(center+Vector3(_p(i+1600,30),0,_p(i+1700,21)),t)
    elif n.find("snow")>=0 or n.find("ice")>=0 or n.find("lutie")>=0:
        for i in range(30):var s:=_sphere(t.snow,0.4+float(i%3)*0.12);s.position=center+Vector3(_p(i+1800,30),0.3,_p(i+1900,21));root.add_child(s)
    elif n.find("clock")>=0:
        for i in range(14):root.add_child(_torus(0.8+float(i%3)*0.2,0.08,center+Vector3(-26+i*4.0,1,-15+(i%3)*11),t.accent))
    elif n.find("ship")>=0:
        for i in range(11):root.add_child(_box(Vector3(0.3,4,0.3),center+Vector3(-20+i*4,2,18),t.wood_dark))

func _micro(m:int)->void:
    var t:=_theme(m);var kind:=str(Teleport.MAPS.get(m,{}).get("type","town"))
    if kind=="town":
        for i in range(18):_bench(center+Vector3(-21+(i%9)*5.2,0,3+(i/9)*9),t.wood);_barrel(center+Vector3(-22+(i%9)*5.3,0,7+(i/9)*8),t.wood);_lamp(center+Vector3(-22+(i%9)*5.3,0,-5+(i/9)*25),t.light)
    else:
        for i in range(42):var p:=center+Vector3(_p(i+2000,31),0,_p(i+2100,22));if i%3==0:_crate(p,t.wood_dark);elif i%3==1:_barrel(p,t.wood);else:_rocks(p,t,i)

func _building(p:Vector3,t:Dictionary,label:String,index:int)->void:
    root.add_child(_box(Vector3(7.2,0.4,5.8),p+Vector3(0,0.2,0),t.foundation));root.add_child(_box(Vector3(6.7,3.6,5.3),p+Vector3(0,2,0),t.wall));root.add_child(_box(Vector3(6.1,0.65,5),p+Vector3(0,3.95,0),t.trim))
    var roof:=MeshInstance3D.new();var pm:=PrismMesh.new();pm.size=Vector3(7.5,2.3,6);roof.mesh=pm;roof.position=p+Vector3(0,5.25,0);roof.material_override=_mat(t.roof,0.05,0.72);root.add_child(roof);root.add_child(_box(Vector3(0.95,1.9,0.14),p+Vector3(0,1,2.67),t.wood_dark))
    for s in [-1.0,1.0]:var wp:=p+Vector3(s*1.8,2,2.68);root.add_child(_box(Vector3(1.15,0.9,0.12),wp,t.window));root.add_child(_box(Vector3(0.07,0.82,0.14),wp+Vector3(0,0,0.05),t.wood_dark));root.add_child(_box(Vector3(1.0,0.07,0.14),wp+Vector3(0,0,0.05),t.wood_dark))
    var l:=Label3D.new();l.text=label;l.font_size=24;l.outline_size=7;l.modulate=t.sign;l.position=p+Vector3(0,3.25,2.78);root.add_child(l);if index%2==0:root.add_child(_box(Vector3(0.65,1.8,0.65),p+Vector3(1.7,0.9,-1.2),t.stone_dark))

func _disc(p:Vector3,r:float,c:Color)->void:
    root.add_child(_cylinder(r,0.32,p,c))
    for i in range(24):var a:=TAU*float(i)/24.0;var q:=_box(Vector3(0.6,0.08,3),p+Vector3(cos(a)*4.5,0.24,sin(a)*4.5),c.lightened(0.08));q.rotation.y=-a;root.add_child(q)
func _fountain(p:Vector3,c:Color)->void:
    root.add_child(_cylinder(2.5,0.3,p,Color("b0a58f")));root.add_child(_cylinder(2,0.1,p+Vector3(0,0.22,0),c,true));root.add_child(_cylinder(1.2,1.5,p+Vector3(0,0.9,0),Color("d5d0c0")));root.add_child(_cylinder(0.22,2.2,p+Vector3(0,2,0),c,true))
func _gate(p:Vector3,c:Color,s:String)->void:
    root.add_child(_box(Vector3(1.5,5,1.6),p+Vector3(-4,2.5,0),c));root.add_child(_box(Vector3(1.5,5,1.6),p+Vector3(4,2.5,0),c));root.add_child(_box(Vector3(9.5,1.2,1.6),p+Vector3(0,4.45,0),c));var l:=Label3D.new();l.text=s.to_upper();l.font_size=26;l.outline_size=8;l.modulate=Color("fff1bd");l.position=p+Vector3(0,5.3,0);root.add_child(l)
func _tree(p:Vector3,t:Dictionary,i:int)->void:
    var h:=2.8+float(i%4)*0.45;root.add_child(_cylinder(0.45,h,p+Vector3(0,h/2,0),t.wood_dark))
    for j in range(3):var c:=_sphere(t.foliage if j==0 else t.foliage_light,1.35-float(j)*0.16);c.position=p+Vector3((j-1)*0.65,h+0.65+j*0.35,0);c.scale=Vector3(1.2,0.85,1);root.add_child(c)
func _grass(p:Vector3,t:Dictionary,i:int)->void:
    for j in range(5):var b:=_box(Vector3(0.08,0.45+(j%3)*0.12,0.1),p+Vector3((j-2)*0.12,0.25,(j%2)*0.08),t.grass);b.rotation.z=-0.2+j*0.1;root.add_child(b)
func _rocks(p:Vector3,t:Dictionary,i:int)->void:
    for j in range(3):var r:=_sphere(t.stone,0.35+((i+j)%4)*0.13);r.position=p+Vector3(j*0.38,0.28,(j%2)*0.3);r.scale=Vector3(1+j*0.2,0.65+j*0.1,0.8);root.add_child(r)
func _fence(p:Vector3,c:Color)->void:root.add_child(_box(Vector3(0.18,1.4,0.18),p+Vector3(0,0.7,0),c));root.add_child(_box(Vector3(2.7,0.12,0.12),p+Vector3(0,0.95,0),c))
func _stall(p:Vector3,t:Dictionary)->void:
    root.add_child(_box(Vector3(4.2,0.7,2.2),p+Vector3(0,0.35,0),t.wood));root.add_child(_box(Vector3(4.6,0.14,2.6),p+Vector3(0,2.35,0),t.banner));for x in [-1.8,1.8]:root.add_child(_box(Vector3(0.16,2.2,0.16),p+Vector3(x,1.2,-1),t.wood_dark));_crate(p+Vector3(-0.9,0.85,0.2),t.wood_dark);_crate(p+Vector3(0.9,0.85,0.2),t.wood_dark)
func _banner(p:Vector3,t:Dictionary,s:String)->void:
    root.add_child(_box(Vector3(0.1,3,0.1),p+Vector3(0,1.5,0),t.wood_dark));root.add_child(_box(Vector3(1.1,1.6,0.08),p+Vector3(0,2.1,0),t.banner));var l:=Label3D.new();l.text=s;l.font_size=16;l.outline_size=5;l.modulate=t.sign;l.position=p+Vector3(0,2.05,0.08);root.add_child(l)
func _bench(p:Vector3,c:Color)->void:root.add_child(_box(Vector3(2,0.18,0.55),p+Vector3(0,0.72,0),c));root.add_child(_box(Vector3(0.18,0.72,0.18),p+Vector3(-0.72,0.36,0),c));root.add_child(_box(Vector3(0.18,0.72,0.18),p+Vector3(0.72,0.36,0),c))
func _barrel(p:Vector3,c:Color)->void:root.add_child(_cylinder(0.42,0.85,p+Vector3(0,0.42,0),c));root.add_child(_torus(0.43,0.035,p+Vector3(0,0.2,0),Color("4a3528")));root.add_child(_torus(0.43,0.035,p+Vector3(0,0.62,0),Color("4a3528")))
func _lamp(p:Vector3,c:Color)->void:
    root.add_child(_cylinder(0.1,2.6,p+Vector3(0,1.3,0),Color("353238")));var g:=_sphere(c,0.22);g.position=p+Vector3(0,2.62,0);g.material_override=_mat(c,0,0.16,true);root.add_child(g);var l:=OmniLight3D.new();l.position=g.position;l.light_color=c;l.light_energy=1.6;l.omni_range=5.5;root.add_child(l)
func _crate(p:Vector3,c:Color)->void:root.add_child(_box(Vector3(0.9,0.8,0.9),p+Vector3(0,0.4,0),c))
func _column(p:Vector3,c:Color,h:float)->void:root.add_child(_cylinder(0.48,h,p+Vector3(0,h/2,0),c));root.add_child(_cylinder(0.66,0.18,p+Vector3(0,h+0.09,0),c.lightened(0.1)))
func _torch(p:Vector3,t:Dictionary)->void:root.add_child(_box(Vector3(0.14,1.5,0.14),p+Vector3(0,0.75,0),t.stone));var f:=_sphere(t.fire,0.25);f.position=p+Vector3(0,1.62,0);f.material_override=_mat(t.fire,0,0.12,true);root.add_child(f)
func _crystal(p:Vector3,c:Color,i:int)->void:var x:=_cylinder(0.2+(i%3)*0.05,0.9+(i%4)*0.22,p+Vector3(0,0.55,0),c,true);x.rotation_degrees=Vector3((i%2)*10,i*23,(i%3)*6);root.add_child(x)
func _altar(p:Vector3,t:Dictionary)->void:
    root.add_child(_box(Vector3(5,0.45,5),p+Vector3(0,0.22,0),t.stone));root.add_child(_box(Vector3(3.8,0.55,3.8),p+Vector3(0,0.72,0),t.stone.lightened(0.08)));for i in range(8):var a:=TAU*float(i)/8.0;_crystal(p+Vector3(cos(a)*2,0,sin(a)*2),t.magic,i)
func _arch(p:Vector3,c:Color)->void:root.add_child(_box(Vector3(1.5,5.2,1.6),p+Vector3(-3.6,2.6,0),c));root.add_child(_box(Vector3(1.5,5.2,1.6),p+Vector3(3.6,2.6,0),c));root.add_child(_box(Vector3(8.7,1.4,1.6),p+Vector3(0,4.9,0),c))
func _debris(p:Vector3,c:Color,i:int)->void:var x:=_box(Vector3(0.7+(i%3)*0.25,0.4+(i%2)*0.3,0.7),p+Vector3(0,0.2,0),c);x.rotation_degrees=Vector3(0,i*37,(i%2)*8);root.add_child(x)
func _water(t:Dictionary)->void:
    var w:=_box(Vector3(32,0.2,13),center+Vector3(0,-0.02,23),t.water);w.material_override=_mat(t.water,0,0.1,true);root.add_child(w);for x in range(-14,15,4):root.add_child(_box(Vector3(3.2,0.22,0.7),center+Vector3(x,0.12,18),t.wood_dark))
func _cactus(p:Vector3,t:Dictionary,i:int)->void:root.add_child(_cylinder(0.18,1.5+(i%3)*0.4,p+Vector3(0,0.8,0),t.cactus));if i%2==0:root.add_child(_cylinder(0.1,0.75,p+Vector3(0.38,1.05,0),t.cactus))
func _fern(p:Vector3,t:Dictionary)->void:
    for j in range(5):var x:=_box(Vector3(0.08,0.9,0.18),p+Vector3(0,0.45,0),t.foliage_light);x.rotation_degrees=Vector3(0,j*72,-22+j*10);root.add_child(x)
func _road(size:Vector3,p:Vector3,c:Color)->void:root.add_child(_box(size,p,c))
func _box(size:Vector3,p:Vector3,c:Color)->MeshInstance3D:
    var n:=MeshInstance3D.new();var m:=BoxMesh.new();m.size=size;n.mesh=m;n.position=p;n.material_override=_mat(c,0,0.78);return n
func _sphere(c:Color,r:float)->MeshInstance3D:
    var n:=MeshInstance3D.new();var m:=SphereMesh.new();m.radius=r;m.height=r*2;n.mesh=m;n.material_override=_mat(c,0,0.72);return n
func _cylinder(r:float,h:float,p:Vector3,c:Color,glow:bool=false)->MeshInstance3D:
    var n:=MeshInstance3D.new();var m:=CylinderMesh.new();m.top_radius=r;m.bottom_radius=r*1.08;m.height=h;n.mesh=m;n.position=p;n.material_override=_mat(c,0,0.42 if glow else 0.78,glow);return n
func _torus(outer:float,inner:float,p:Vector3,c:Color)->MeshInstance3D:
    var n:=MeshInstance3D.new();var m:=TorusMesh.new();m.inner_radius=max(0.01,outer-inner);m.outer_radius=outer;n.mesh=m;n.position=p;n.material_override=_mat(c,0.2,0.28);return n
func _mat(c:Color,metal:float,rough:float,glow:bool=false)->StandardMaterial3D:
    var m:=StandardMaterial3D.new();m.albedo_color=c;m.metallic=metal;m.roughness=rough
    if glow:m.emission_enabled=true;m.emission=c;m.emission_energy_multiplier=2.5
    return m
func _theme(id:int)->Dictionary:
    var n:=Teleport.map_name(id).to_lower();var t:Dictionary={"ground":Color("5d7147"),"variation":Color("7f8d58"),"earth":Color("4f5f3d"),"road":Color("a18a6b"),"path":Color("806d56"),"curb":Color("706454"),"stone":Color("a99e8d"),"stone_dark":Color("4c4744"),"foundation":Color("746351"),"wall":Color("b98f67"),"wall_dark":Color("5d5148"),"trim":Color("d1b48a"),"roof":Color("6a3f36"),"wood":Color("815b3e"),"wood_dark":Color("4b3327"),"window":Color("82c9dc"),"water":Color("3b9fbd"),"foliage":Color("315f3b"),"foliage_light":Color("5f8a45"),"grass":Color("6e9848"),"magic":Color("73dfff"),"fire":Color("ff9a45"),"light":Color("ffd878"),"accent":Color("d5ad5d"),"banner":Color("9b3c3c"),"sign":Color("fff0b2"),"cactus":Color("4f8d4e"),"snow":Color("dbe7ef")}
    if n.find("geffen")>=0:t.wall=Color("8a6fc0");t.trim=Color("c0a5e5");t.accent=Color("b7a3ff")
    elif n.find("morroc")>=0 or n.find("desert")>=0:t.ground=Color("c39a60");t.variation=Color("e0b97a");t.wall=Color("c28b58");t.roof=Color("70462f");t.cactus=Color("3f7540")
    elif n.find("coast")>=0 or n.find("izlude")>=0 or n.find("alberta")>=0:t.ground=Color("5c805d");t.water=Color("2e9fc5");t.roof=Color("405f73")
    elif n.find("forest")>=0 or n.find("payon")>=0:t.foliage=Color("234d36");t.foliage_light=Color("4f8147")
    elif n.find("jungle")>=0 or n.find("wilds")>=0:t.ground=Color("385b3c");t.foliage=Color("173f2e")
    elif n.find("snow")>=0 or n.find("ice")>=0 or n.find("lutie")>=0:t.ground=Color("b7cbd6");t.variation=Color("e1ebf0");t.road=Color("9eacb3");t.roof=Color("5f6f7e");t.snow=Color("f5fbff")
    elif n.find("umbala")>=0:t.wall=Color("9b6d46");t.roof=Color("4c723c");t.banner=Color("5f8f48")
    elif n.find("clock")>=0:t.stone=Color("716f68");t.stone_dark=Color("35383a");t.accent=Color("d3a64d")
    elif n.find("ship")>=0:t.stone_dark=Color("27383c");t.wood=Color("75492f");t.wood_dark=Color("3e291f")
    elif n.find("sewer")>=0 or n.find("catacomb")>=0:t.stone=Color("666c69");t.stone_dark=Color("282b2c");t.magic=Color("7de5a7")
    return t
func _sky(id:int)->Color:
    var n:=Teleport.map_name(id).to_lower()
    if n.find("snow")>=0 or n.find("ice")>=0:return Color("b8c9d5")
    if n.find("desert")>=0 or n.find("morroc")>=0:return Color("e2c28e")
    if Teleport.is_dungeon(id):return Color("2e3640")
    return Color("8fb0c0")
func _p(i:int,e:float)->float:return (float((i*97+17)%1000)/1000.0*2.0-1.0)*e
func _world(p:Vector2)->Vector3:return Vector3((p.x-OX)*SCALE,0,(p.y-OY)*SCALE)
