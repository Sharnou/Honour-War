extends Node3D

## Procedural HD environment authoring layer for all 30 Honour War maps.
## Every surface, prop and landmark is generated natively in Godot.
const Teleport=preload("res://scripts/TeleportSystem.gd")
const WORLD_SCALE:float=0.055
const ORIGIN_X:float=365.0
const ORIGIN_Y:float=120.0
var legacy:Node
var root:Node3D
var last_map:int=-999
var center:Vector3=Vector3.ZERO
var seed_value:int=0

func _ready()->void:
	process_priority=850
	legacy=get_parent().get_node_or_null("LegacyGame")
	call_deferred("_rebuild")

func _process(_delta:float)->void:
	if legacy==null:
		legacy=get_parent().get_node_or_null("LegacyGame")
		return
	var hero:Variant=legacy.get("hero")
	if hero is Dictionary:
		var map_id:int=int((hero as Dictionary).get("map_id",0))
		if map_id!=last_map:_rebuild()

func _rebuild()->void:
	if legacy==null:return
	var hero:Variant=legacy.get("hero")
	var map_id:int=int((hero as Dictionary).get("map_id",0)) if hero is Dictionary else 0
	last_map=map_id
	seed_value=7919+map_id*104729
	center=_map_to_world(Teleport.default_point(map_id))
	if root!=null and is_instance_valid(root):root.queue_free()
	_hide_old_world()
	root=Node3D.new();root.name="HWHDWorldDetail_Map_%02d"%map_id;get_parent().add_child(root)
	_build_ground(map_id);_build_roads(map_id)
	var kind:String=str(Teleport.MAPS.get(map_id,{}).get("type","town"))
	if kind=="town":_town(map_id)
	elif kind=="field":_field(map_id)
	else:_dungeon(map_id)
	_micro_details(map_id);_landmark_sign(map_id)

func _hide_old_world()->void:
	var env:Node=get_parent().get_node_or_null("HDEnvironmentDirector/HDEnvironmentBackground")
	if env!=null:env.visible=false
	var old:Node=get_parent().get_node_or_null("World3D")
	if old!=null:old.visible=false

func _build_ground(map_id:int)->void:
	var c:Color=_ground(map_id)
	root.add_child(_mesh_plane("HDGround",Vector2(82,62),center+Vector3(0,-0.08,0),c))
	root.add_child(_mesh_plane("HDPlayableFloor",Vector2(58,44),center+Vector3(0,-0.035,0),_light(c,0.10)))
	for i in 10:
		var a=TAU*float(i)/10.0
		root.add_child(_box(Vector3(3.5,3.0+float((i+map_id)%3),3.5),center+Vector3(cos(a)*33,1.5,sin(a)*25),_dark(c,0.22)))

func _build_roads(map_id:int)->void:
	var town:bool=str(Teleport.MAPS.get(map_id,{}).get("type",""))=="town"
	var road:Color=Color("#b8a27f") if town else Color("#796750")
	root.add_child(_box(Vector3(7,0.08,43),center+Vector3(0,0.03,0),road))
	root.add_child(_box(Vector3(48,0.08,6),center+Vector3(0,0.035,0),road))
	for i in 12:
		var z=-18+float(i)*3.2
		root.add_child(_box(Vector3(0.16,0.9,0.16),center+Vector3(-25,0.45,z),Color("#4b392c")))
		root.add_child(_box(Vector3(0.16,0.9,0.16),center+Vector3(25,0.45,z),Color("#4b392c")))

func _town(map_id:int)->void:
	var p:Array=_palette(map_id)
	_build_plaza(p[0],p[1])
	var positions:Array=[Vector3(-13,0,-11),Vector3(13,0,-11),Vector3(-14,0,12),Vector3(14,0,12),Vector3(-23,0,-2),Vector3(23,0,-2)]
	for i in positions.size():_house(center+positions[i],p[i%4],p[(i+2)%4],i)
	for i in 8:
		var a=TAU*float(i)/8.0
		_tree(center+Vector3(cos(a)*22,0,sin(a)*17),map_id,i)
	_market(center+Vector3(-17,0,5),p[2],map_id);_market(center+Vector3(17,0,5),p[3],map_id)
	_gate(center+Vector3(0,0,-18),p[1],str(Teleport.MAPS[map_id]["name"]))
	_fountain(center+Vector3(0,0,4),p[1])
	for i in 5:_lamp(center+Vector3(-10+float(i)*5,0,17),map_id)

func _field(map_id:int)->void:
	for i in 26:_grass(center+_scatter(i,26,19),map_id,i)
	for i in 13:_tree(center+_scatter(i+40,29,21),map_id,i)
	for i in 16:_rock(center+_scatter(i+90,24,18),0.22+float(i%4)*0.12,_stone(map_id))
	for i in 7:_ruin(center+_scatter(i+130,16,12),map_id,i)
	_gate(center+Vector3(0,0,-17),_palette(map_id%10)[1],str(Teleport.MAPS[map_id]["name"]))

func _dungeon(map_id:int)->void:
	var stone:Color=_stone(map_id)
	root.add_child(_box(Vector3(62,0.18,46),center+Vector3(0,-0.08,0),_light(_ground(map_id),0.04)))
	for i in 22:_column(center+_scatter(i+200,27,19),stone,1.7+float(i%4)*0.35)
	for i in 18:_crystal(center+_scatter(i+260,25,18),map_id,i)
	_altar(center+Vector3(0,0,5),map_id);_arch(center+Vector3(0,0,-18),stone)

func _micro_details(map_id:int)->void:
	for i in 34:_rock(center+_scatter(i+400,22,17),0.07+float(i%4)*0.035,_stone(map_id))
	if str(Teleport.MAPS.get(map_id,{}).get("type",""))=="town":
		for i in 7:
			_bench(center+Vector3(-15+float(i)*5,0,2.0),float(i%2)*0.25)
			_barrel(center+Vector3(-16+float(i)*5.4,0,7.5),map_id)
			_lamp(center+Vector3(-17+float(i)*5.6,0,-5),map_id)

func _build_plaza(stone:Color,accent:Color)->void:
	var base:=MeshInstance3D.new();var m:=CylinderMesh.new();m.top_radius=5.6;m.bottom_radius=5.6;m.height=0.22;base.mesh=m;base.position=center+Vector3(0,0.11,4);base.material_override=_mat(stone,0,0.70);root.add_child(base)
	for i in 16:
		var a=TAU*float(i)/16.0
		var tile=_box(Vector3(0.50,0.06,2.1),center+Vector3(cos(a)*3.9,0.24,4+sin(a)*3.9),_light(stone,0.08));tile.rotation.y=-a;root.add_child(tile)

func _house(pos:Vector3,wall:Color,roof:Color,index:int)->void:
	root.add_child(_box(Vector3(5.0,3.0,4.2),pos+Vector3(0,1.5,0),wall))
	var r:=MeshInstance3D.new();var rm:=PrismMesh.new();rm.size=Vector3(5.7,1.5,4.8);r.mesh=rm;r.position=pos+Vector3(0,3.75,0);r.material_override=_mat(roof,0,0.70);root.add_child(r)
	root.add_child(_box(Vector3(0.85,1.65,0.10),pos+Vector3(0,0.82,2.14),Color("#39291f")))
	for side in [-1.0,1.0]:root.add_child(_box(Vector3(0.9,0.68,0.08),pos+Vector3(side*1.45,1.62,2.15),Color("#a9e7ff")))
	var label:=Label3D.new();label.text=["INN","SHOP","FORGE","GUILD","BANK","HEAL"][index%6];label.font_size=18;label.outline_size=5;label.modulate=Color("#ffe1a0");label.position=pos+Vector3(0,2.95,2.3);root.add_child(label)

func _market(pos:Vector3,accent:Color,map_id:int)->void:
	for side in [-1.0,1.0]:
		root.add_child(_box(Vector3(3,0.72,1.5),pos+Vector3(side*2,0.36,0),Color("#6c472f")))
		root.add_child(_box(Vector3(3.5,0.12,2.0),pos+Vector3(side*2,2.35,0),accent))
		for z in [-0.8,0.8]:root.add_child(_box(Vector3(0.10,2.0,0.10),pos+Vector3(side*2,1.15,z),Color("#493528")))
		_crate(pos+Vector3(side*2,0.85,0.4),map_id)

func _gate(pos:Vector3,color:Color,name:String)->void:
	root.add_child(_box(Vector3(1,3.8,1),pos+Vector3(-3,1.9,0),color));root.add_child(_box(Vector3(1,3.8,1),pos+Vector3(3,1.9,0),color));root.add_child(_box(Vector3(7,0.75,1),pos+Vector3(0,3.65,0),color))
	var l:=Label3D.new();l.text=name.to_upper();l.font_size=25;l.outline_size=7;l.modulate=Color("#ffe7ad");l.position=pos+Vector3(0,4.4,0);root.add_child(l)

func _fountain(pos:Vector3,color:Color)->void:
	var b:=MeshInstance3D.new();var bm:=CylinderMesh.new();bm.top_radius=2;bm.bottom_radius=2;bm.height=0.3;b.mesh=bm;b.position=pos+Vector3(0,0.15,0);b.material_override=_mat(color,0.15,0.5);root.add_child(b)
	var w:=MeshInstance3D.new();var wm:=CylinderMesh.new();wm.top_radius=1.65;wm.bottom_radius=1.65;wm.height=0.08;w.mesh=wm;w.position=pos+Vector3(0,0.34,0);w.material_override=_mat(Color("#58d8ff"),0.05,0.12,true);root.add_child(w)
	root.add_child(_box(Vector3(0.16,1.5,0.16),pos+Vector3(0,1.05,0),Color("#bcefff")))

func _tree(pos:Vector3,map_id:int,index:int)->void:
	root.add_child(_box(Vector3(0.34,2.5,0.34),pos+Vector3(0,1.25,0),Color("#593d2a")))
	var n:=MeshInstance3D.new();var sm:=SphereMesh.new();sm.radius=1.35+float(index%3)*0.18;sm.height=2.5;n.mesh=sm;n.position=pos+Vector3(0,3,0);n.material_override=_mat(_foliage(map_id),0,0.82);root.add_child(n)
	root.add_child(_box(Vector3(0.9,0.18,0.9),pos+Vector3(0,1.9,0),_dark(_foliage(map_id),0.12)))

func _grass(pos:Vector3,map_id:int,index:int)->void:
	var n:=MeshInstance3D.new();var m:=CylinderMesh.new();m.top_radius=0.02;m.bottom_radius=0.14;m.height=0.35+float(index%4)*0.1;n.mesh=m;n.position=pos+Vector3(0,m.height*0.5,0);n.material_override=_mat(_light(_foliage(map_id),0.12),0,0.95);root.add_child(n)

func _ruin(pos:Vector3,map_id:int,index:int)->void:
	var h=1.2+float(index%3)*0.5;root.add_child(_box(Vector3(1.2,h,1.2),pos+Vector3(0,h*0.5,0),_stone(map_id)))

func _column(pos:Vector3,color:Color,h:float)->void:
	var n:=MeshInstance3D.new();var m:=CylinderMesh.new();m.top_radius=0.34;m.bottom_radius=0.48;m.height=h;n.mesh=m;n.position=pos+Vector3(0,h*0.5,0);n.material_override=_mat(color,0,0.74);root.add_child(n)

func _crystal(pos:Vector3,map_id:int,index:int)->void:
	var n:=MeshInstance3D.new();var m:=CylinderMesh.new();m.top_radius=0;m.bottom_radius=0.17+float(index%3)*0.07;m.height=0.7+float(index%4)*0.2;n.mesh=m;n.position=pos+Vector3(0,m.height*0.5,0);n.rotation_degrees=Vector3(0,index*29,index%2*8);n.material_override=_mat(_crystal_color(map_id),0.1,0.14,true);root.add_child(n)

func _altar(pos:Vector3,map_id:int)->void:
	root.add_child(_box(Vector3(5,0.35,5),pos+Vector3(0,0.18,0),_stone(map_id)))
	for i in 8:_crystal(pos+Vector3(cos(TAU*i/8.0)*2.0,0,sin(TAU*i/8.0)*2.0),map_id,i)

func _arch(pos:Vector3,color:Color)->void:
	root.add_child(_box(Vector3(1.2,4.4,1.2),pos+Vector3(-3.3,2.2,0),color));root.add_child(_box(Vector3(1.2,4.4,1.2),pos+Vector3(3.3,2.2,0),color));root.add_child(_box(Vector3(7.8,1,1.2),pos+Vector3(0,4,0),color))

func _bench(pos:Vector3,angle:float)->void:
	var n:=_box(Vector3(2,0.16,0.52),pos+Vector3(0,0.72,0),Color("#704a32"));n.rotation.y=angle;root.add_child(n)
func _barrel(pos:Vector3,map_id:int)->void:root.add_child(_box(Vector3(0.72,0.75,0.72),pos+Vector3(0,0.38,0),_wood(map_id)))
func _lamp(pos:Vector3,map_id:int)->void:
	root.add_child(_box(Vector3(0.12,2.4,0.12),pos+Vector3(0,1.2,0),Color("#383334")))
	var g:=_box(Vector3(0.34,0.34,0.34),pos+Vector3(0,2.55,0),_light_color(map_id));g.material_override=_mat(_light_color(map_id),0,0.12,true);root.add_child(g)
	var l:=OmniLight3D.new();l.position=pos+Vector3(0,2.55,0);l.light_color=_light_color(map_id);l.light_energy=0.45;l.omni_range=4;root.add_child(l)
func _crate(pos:Vector3,map_id:int)->void:root.add_child(_box(Vector3(0.8,0.65,0.8),pos+Vector3(0,0.32,0),_wood(map_id)))

func _rock(pos:Vector3,r:float,color:Color)->MeshInstance3D:
	var n:=MeshInstance3D.new();var m:=SphereMesh.new();m.radius=r;m.height=r*1.4;n.mesh=m;n.position=pos+Vector3(0,r*0.45,0);n.material_override=_mat(color,0,0.96);return n

func _landmark_sign(map_id:int)->void:
	var l:=Label3D.new();l.text="HONOUR WAR  •  "+str(Teleport.MAPS[map_id]["name"]).to_upper();l.font_size=28;l.outline_size=8;l.modulate=Color("#ffe6aa");l.position=center+Vector3(0,6,-20);root.add_child(l)
	var s:=Label3D.new();s.text=str(Teleport.MAPS[map_id]["type"]).to_upper()+"  •  HD WORLD";s.font_size=15;s.outline_size=5;s.modulate=Color("#d8f4ff");s.position=center+Vector3(0,5.25,-20);root.add_child(s)

func _scatter(index:int,rx:float,rz:float)->Vector3:
	var n:int=seed_value+index*7919
	var x:float=(float(abs(n*37)%10000)/5000.0-1.0)*rx
	var z:float=(float(abs(n*91)%10000)/5000.0-1.0)*rz
	if abs(x)<3:x+=4 if x>=0 else -4
	if abs(z)<2:z+=3 if z>=0 else -3
	return Vector3(x,0,z)

func _mesh_plane(name:String,size:Vector2,pos:Vector3,c:Color)->MeshInstance3D:
	var n:=MeshInstance3D.new();n.name=name;var m:=PlaneMesh.new();m.size=size;n.mesh=m;n.position=pos;n.material_override=_mat(c,0,0.94);return n
func _box(size:Vector3,pos:Vector3,c:Color)->MeshInstance3D:
	var n:=MeshInstance3D.new();var m:=BoxMesh.new();m.size=size;n.mesh=m;n.position=pos;n.material_override=_mat(c,0,0.90);return n
func _mat(c:Color,metal:float,rough:float,glow:bool=false)->StandardMaterial3D:
	var m:=StandardMaterial3D.new();m.albedo_color=c;m.metallic=metal;m.roughness=rough
	if glow:m.emission_enabled=true;m.emission=c;m.emission_energy_multiplier=1.4
	return m
func _palette(map_id:int)->Array:
	var k:int=map_id%10
	match k:
		0:return [Color("#d8c3a5"),Color("#5a3340"),Color("#d7a95c"),Color("#6c91b5")]
		1:return [Color("#b99672"),Color("#344b57"),Color("#d9a84e"),Color("#567b55")]
		2:return [Color("#b7b5bd"),Color("#4d3e6b"),Color("#d2a84d"),Color("#6e9ec0")]
		3:return [Color("#c7a77c"),Color("#70462f"),Color("#d9b15c"),Color("#7d8e9e")]
		4:return [Color("#b7d0d0"),Color("#35627b"),Color("#f0c65e"),Color("#6aa5b7")]
		5:return [Color("#b18a68"),Color("#4f6b7b"),Color("#d9b05e"),Color("#6f9b6a")]
		6:return [Color("#9a8b6e"),Color("#385c52"),Color("#d3a24d"),Color("#4c8b82")]
		7:return [Color("#b8b28c"),Color("#4b6a52"),Color("#dfbd61"),Color("#789a62")]
		8:return [Color("#d9dfe4"),Color("#4d6b8a"),Color("#f0d06b"),Color("#8cc4e2")]
		_:return [Color("#a99575"),Color("#513e58"),Color("#d8a850"),Color("#71865c")]
func _ground(map_id:int)->Color:
	if map_id>=20:
		var f:Array=[Color("#52734d"),Color("#3f6b43"),Color("#68794b"),Color("#c49a54"),Color("#4d7b75"),Color("#6d8560"),Color("#416b43"),Color("#6f8152"),Color("#d9e5ea"),Color("#466d4b")];return f[(map_id-20)%10]
	if map_id>=10:
		var d:Array=[Color("#3a3f4a"),Color("#3b333a"),Color("#3d394e"),Color("#4a3a34"),Color("#403936"),Color("#42505c"),Color("#4a4140"),Color("#3a4348"),Color("#263f31"),Color("#3f3436")];return d[(map_id-10)%10]
	return Color("#53694f")
func _foliage(map_id:int)->Color:
	var a:Array=[Color("#2d7148"),Color("#3d7440"),Color("#396a59"),Color("#6d7134"),Color("#2f7474"),Color("#3d7651"),Color("#3a7145"),Color("#668044"),Color("#7394a4"),Color("#35683e")];return a[map_id%10]
func _crystal_color(map_id:int)->Color:
	var a:Array=[Color("#6edcff"),Color("#91b7ff"),Color("#b98dff"),Color("#ff9c69"),Color("#6fe6e4"),Color("#69c9ff"),Color("#77ffb1"),Color("#b8e66e"),Color("#bdefff"),Color("#ff75d0")];return a[map_id%10]
func _light_color(map_id:int)->Color:
	var a:Array=[Color("#ffd477"),Color("#ffe0a0"),Color("#d8c2ff"),Color("#ffb86b"),Color("#a9eaff"),Color("#ffd48b"),Color("#9fffe4"),Color("#f3e39b"),Color("#d9f6ff"),Color("#ffc2ef")];return a[map_id%10]
func _stone(map_id:int)->Color:return _palette(map_id%10)[0].darkened(0.30)
func _wood(map_id:int)->Color:return Color("#5b3c29").lightened(float(map_id%3)*0.05)
func _dark(c:Color,a:float)->Color:return c.darkened(a)
func _light(c:Color,a:float)->Color:return c.lightened(a)
func _map_to_world(p:Vector2)->Vector3:return Vector3((p.x-ORIGIN_X)*WORLD_SCALE,0,(p.y-ORIGIN_Y)*WORLD_SCALE)
