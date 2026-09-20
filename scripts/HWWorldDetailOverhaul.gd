extends Node3D

## Honour War HD world-detail pass.
## Builds a distinct, readable environment for every registered map while
## keeping gameplay actors, combat and the existing save/progression systems.
const Teleport=preload("res://scripts/TeleportSystem.gd")
const WORLD_SCALE:float=0.055
const ORIGIN_X:float=365.0
const ORIGIN_Y:float=120.0

var legacy:Node
var root:Node3D
var last_map:int=-999
var seed_value:int=0
var center:Vector3=Vector3.ZERO

func _ready()->void:
	process_priority=850
	legacy=get_parent().get_node_or_null("LegacyGame")
	call_deferred("_rebuild")

func _process(_delta:float)->void:
	if legacy==null:
		legacy=get_parent().get_node_or_null("LegacyGame")
		return
	var value:Variant=legacy.get("hero")
	if value is Dictionary:
		var map_id:int=int((value as Dictionary).get("map_id",0))
		if map_id!=last_map:
			_rebuild()

func _rebuild()->void:
	if legacy==null: return
	var value:Variant=legacy.get("hero")
	var map_id:int=int((value as Dictionary).get("map_id",0)) if value is Dictionary else 0
	last_map=map_id
	seed_value=7919+map_id*104729
	center=_map_to_world(Teleport.default_point(map_id))
	if root!=null and is_instance_valid(root):
		root.queue_free()
	root=null
	_hide_old_environment()
	root=Node3D.new()
	root.name="HWHDWorldDetail_Map_%02d" % map_id
	get_parent().add_child(root)
	_build_sky_and_ground(map_id)
	_build_paths_and_boundaries(map_id)
	match str(Teleport.MAPS.get(map_id,{}).get("type","town")):
		"town": _build_town(map_id)
		"field": _build_field(map_id)
		"dungeon": _build_dungeon(map_id)
		_: _build_town(map_id)
	_build_small_details(map_id)
	_build_map_sign(map_id)

func _hide_old_environment()->void:
	var game:=get_parent()
	var old_env:Node=game.get_node_or_null("HDEnvironmentDirector/HDEnvironmentBackground")
	if old_env!=null: old_env.visible=false
	var world:Node=game.get_node_or_null("World3D")
	if world!=null: world.visible=false

func _build_sky_and_ground(map_id:int)->void:
	var ground_color:=_ground_color(map_id)
	var ground:=MeshInstance3D.new()
	ground.name="HDGround"
	var plane:=PlaneMesh.new()
	plane.size=Vector2(82.0,62.0)
	ground.mesh=plane
	ground.position=center+Vector3(0,-0.08,0)
	ground.material_override=_mat(ground_color,0.0,0.96)
	root.add_child(ground)
	var inner:=MeshInstance3D.new()
	inner.name="HDPlayableFloor"
	var inner_mesh:=PlaneMesh.new()
	inner_mesh.size=Vector2(58.0,44.0)
	inner.mesh=inner_mesh
	inner.position=center+Vector3(0,-0.035,0)
	inner.material_override=_mat(_lighten(ground_color,0.12),0.0,0.90)
	root.add_child(inner)
	# Distant perimeter blocks give the map a proper horizon without obscuring
	# the hero or reducing the usable play space.
	for i in 8:
		var ridge:=MeshInstance3D.new()
		var ridge_mesh:=CylinderMesh.new()
		ridge_mesh.top_radius=0.0
		ridge_mesh.bottom_radius=3.0+float((i+map_id)%3)*0.8
		ridge_mesh.height=4.0+float((i+map_id)%4)*0.7
		ridge.mesh=ridge_mesh
		var angle:=TAU*float(i)/8.0
		ridge.position=center+Vector3(cos(angle)*32.0,1.5,sin(angle)*24.0)
		ridge.material_override=_mat(_darken(ground_color,0.28),0.0,0.98)
		root.add_child(ridge)

func _build_paths_and_boundaries(map_id:int)->void:
	var kind:String=str(Teleport.MAPS.get(map_id,{}).get("type","town"))
	if kind=="town":
		_road(Vector3(0,0.03,0),Vector3(7.0,0.08,43.0),Color("#b59a73"))
		_road(Vector3(0,0.035,0),Vector3(48.0,0.08,6.0),Color("#b59a73"))
		_road(Vector3(0,0.04,-12),Vector3(40.0,0.08,3.5),Color("#c2aa80"))
	else:
		_road(Vector3(0,0.02,0),Vector3(4.0,0.06,42.0),Color("#8e7659"))
		_road(Vector3(0,0.025,0),Vector3(46.0,0.06,3.4),Color("#8e7659"))
	for side in [-1.0,1.0]:
		for i in 12:
			var post:=_box(Vector3(0.14,1.0,0.14),Vector3(side*(26.0+float(i%2)*1.2),0.5,-18.0+float(i)*3.2),_wood_color(map_id))
			post.name="BoundaryPost_%02d_%02d" % [int(side),i]
			root.add_child(post)

func _build_town(map_id:int)->void:
	var palette:Array[Color]=_town_palette(map_id)
	# Keep the hero plaza open. Buildings sit outside the combat/readability bubble.
	_build_plaza(palette[0],palette[1])
	var positions:Array[Vector3]=[
		Vector3(-11,0,-9),Vector3(11,0,-9),Vector3(-12,0,10),Vector3(12,0,10),
		Vector3(-21,0,-2),Vector3(21,0,-2)
	]
	for i in positions.size():
		_build_house(center+positions[i],palette[i%palette.size()],palette[(i+2)%palette.size()],i)
	for i in 10:
		var a:=TAU*float(i)/10.0
		_build_tree(center+Vector3(cos(a)*19.0,0,sin(a)*15.0),map_id,i)
	_build_market(center+Vector3(-15,0,5),palette[2],map_id)
	_build_market(center+Vector3(15,0,5),palette[3],map_id)
	_build_gate(center+Vector3(0,0,-18),palette[1],str(Teleport.MAPS[map_id]["name"]))
	_build_fountain(center+Vector3(0,0,4),palette[1])

func _build_field(map_id:int)->void:
	var base:=_ground_color(map_id)
	var field:=_mat(_lighten(base,0.08),0.0,0.98)
	for i in 34:
		var p:=_scatter(i,25.0,19.0)
		var tuft:=MeshInstance3D.new()
		var mesh:=CylinderMesh.new()
		mesh.top_radius=0.02
		mesh.bottom_radius=0.12+float(i%3)*0.04
		mesh.height=0.35+float(i%4)*0.12
		tuft.mesh=mesh
		tuft.position=center+p+Vector3(0,mesh.height*0.5,0)
		tuft.rotation_degrees.z=float(i*19%25)
		tuft.material_override=field
		root.add_child(tuft)
	for i in 16:
		_build_tree(center+_scatter(i+40,29.0,21.0),map_id,i)
	for i in 14:
		_build_rock(center+_scatter(i+80,24.0,18.0),0.25+float(i%4)*0.11,_rock_color(map_id))
	_build_field_ruins(map_id)
	_build_field_landmark(map_id)

func _build_dungeon(map_id:int)->void:
	var base:=_ground_color(map_id)
	var floor:=_mat(_lighten(base,0.05),0.0,0.96)
	var slab:=MeshInstance3D.new()
	var slab_mesh:=BoxMesh.new()
	slab_mesh.size=Vector3(62,0.20,46)
	slab.mesh=slab_mesh
	slab.position=center+Vector3(0,-0.1,0)
	slab.material_override=floor
	root.add_child(slab)
	for i in 26:
		var p:=_scatter(i+120,26.0,19.0)
		_build_column(center+p,_stone_color(map_id),1.6+float(i%4)*0.3)
	for i in 20:
		_build_crystal(center+_scatter(i+180,25.0,18.0),map_id,i)
	_build_dungeon_altar(map_id)
	_build_dungeon_arch(center+Vector3(0,0,-18),_stone_color(map_id))

func _build_small_details(map_id:int)->void:
	# Repeated micro-details make the map feel authored rather than blocky:
	# paving seams, flower beds, barrels, crates, benches, signs and lights.
	for i in 28:
		var p:=_scatter(i+240,22.0,17.0)
		var pebble:=_rock(center+p,0.08+float(i%4)*0.035,_rock_color(map_id))
		root.add_child(pebble)
	if str(Teleport.MAPS.get(map_id,{}).get("type",""))=="town":
		for i in 8:
			_build_lamp(center+Vector3(-18+float(i)*5.0,0,-5),map_id)
			_build_lamp(center+Vector3(-18+float(i)*5.0,0,16),map_id)
		for i in 7:
			_build_bench(center+Vector3(-15+float(i)*5.0,0,2.5),float(i%2)*0.25)
			_build_barrel(center+Vector3(-17+float(i)*5.5,0,7.5),map_id)

func _build_plaza(stone:Color,accent:Color)->void:
	var base:=MeshInstance3D.new()
	var mesh:=CylinderMesh.new()
	mesh.top_radius=5.4
	mesh.bottom_radius=5.4
	mesh.height=0.20
	base.mesh=mesh
	base.position=center+Vector3(0,0.10,4)
	base.material_override=_mat(stone,0.0,0.72)
	root.add_child(base)
	for i in 16:
		var a:=TAU*float(i)/16.0
		var tile:=_box(Vector3(0.48,0.06,2.0),center+Vector3(cos(a)*3.8,0.22,4+sin(a)*3.8),_lighten(stone,0.08))
		tile.rotation.y=-a
		root.add_child(tile)

func _build_house(pos:Vector3,wall:Color,roof_color:Color,index:int)->void:
	var base:=_box(Vector3(5.2,3.1,4.3),pos+Vector3(0,1.55,0),wall)
	base.name="HDHouse_%02d" % index
	root.add_child(base)
	var roof:=MeshInstance3D.new()
	var rm:=PrismMesh.new()
	rm.size=Vector3(5.8,1.8,4.9)
	roof.mesh=rm
	roof.position=pos+Vector3(0,3.85,0)
	roof.material_override=_mat(roof_color,0.0,0.72)
	root.add_child(roof)
	var door:=_box(Vector3(0.9,1.75,0.10),pos+Vector3(0,0.86,2.18),Color("#3b2b24"))
	root.add_child(door)
	for side in [-1.0,1.0]:
		var window:=_box(Vector3(0.92,0.72,0.08),pos+Vector3(side*1.48,1.65,2.18),Color("#aeeaff"))
		root.add_child(window)
		var frame:=_box(Vector3(1.08,0.09,0.09),pos+Vector3(side*1.48,1.65,2.13),Color("#5c4633"))
		root.add_child(frame)
	var sign:=Label3D.new()
	sign.text=["INN","SHOP","FORGE","GUILD","BANK","HEAL"][index%6]
	sign.font_size=20
	sign.outline_size=5
	sign.modulate=Color("#ffe2a0")
	sign.position=pos+Vector3(0,3.0,2.35)
	root.add_child(sign)

func _build_market(pos:Vector3,accent:Color,map_id:int)->void:
	for side in [-1.0,1.0]:
		var table:=_box(Vector3(3.0,0.75,1.6),pos+Vector3(side*2.0,0.45,0),Color("#704a32"))
		root.add_child(table)
		var canopy:=_box(Vector3(3.5,0.12,2.1),pos+Vector3(side*2.0,2.45,0),accent)
		root.add_child(canopy)
		for x in [-1.35,1.35]:
			var post:=_box(Vector3(0.10,2.0,0.10),pos+Vector3(side*2.0+x*0.0,1.2,0.82),Color("#4b3628"))
			root.add_child(post)
		_build_crate(pos+Vector3(side*2.0,0.92,0.45),map_id,int(abs(side)*2))

func _build_gate(pos:Vector3,color:Color,map_name:String)->void:
	for side in [-1.0,1.0]:
		var pillar:=_box(Vector3(1.0,3.8,1.0),pos+Vector3(side*3.0,1.9,0),color)
		root.add_child(pillar)
	var beam:=_box(Vector3(7.0,0.75,1.0),pos+Vector3(0,3.65,0),color)
	root.add_child(beam)
	var label:=Label3D.new()
	label.text=map_name.to_upper()
	label.font_size=26
	label.outline_size=7
	label.modulate=Color("#ffe8b0")
	label.position=pos+Vector3(0,4.4,0)
	root.add_child(label)

func _build_fountain(pos:Vector3,color:Color)->void:
	var basin:=MeshInstance3D.new()
	var bm:=CylinderMesh.new()
	bm.top_radius=2.0
	bm.bottom_radius=2.0
	bm.height=0.28
	basin.mesh=bm
	basin.position=pos+Vector3(0,0.14,0)
	basin.material_override=_mat(color,0.15,0.55)
	root.add_child(basin)
	var water:=MeshInstance3D.new()
	var wm:=CylinderMesh.new()
	wm.top_radius=1.65
	wm.bottom_radius=1.65
	wm.height=0.08
	water.mesh=wm
	water.position=pos+Vector3(0,0.32,0)
	water.material_override=_mat(Color("#65d8ff"),0.1,0.18,true)
	root.add_child(water)
	var jet:=MeshInstance3D.new()
	var jm:=CylinderMesh.new()
	jm.top_radius=0.05
	jm.bottom_radius=0.10
	jm.height=1.7
	jet.mesh=jm
	jet.position=pos+Vector3(0,1.15,0)
	jet.material_override=_mat(Color("#b8f4ff"),0.0,0.10,true)
	root.add_child(jet)

func _build_tree(pos:Vector3,map_id:int,index:int)->void:
	var trunk:=_box(Vector3(0.35,2.6,0.35),pos+Vector3(0,1.3,0),Color("#5a3d2b"))
	root.add_child(trunk)
	var crown:=MeshInstance3D.new()
	var sm:=SphereMesh.new()
	sm.radius=1.45+float(index%3)*0.20
	sm.height=2.6+float(index%2)*0.35
	crown.mesh=sm
	crown.position=pos+Vector3(0,3.0,0)
	crown.material_override=_mat(_foliage_color(map_id),0.0,0.82)
	root.add_child(crown)
	for side in [-1.0,1.0]:
		var leaf:=MeshInstance3D.new()
		var lm:=SphereMesh.new()
		lm.radius=0.72
		lm.height=1.2
		leaf.mesh=lm
		leaf.position=pos+Vector3(side*0.8,3.0,0.2)
		leaf.material_override=_mat(_lighten(_foliage_color(map_id),0.08),0.0,0.84)
		root.add_child(leaf)

func _build_field_ruins(map_id:int)->void:
	var stone:=_stone_color(map_id)
	for i in 7:
		var p:=_scatter(i+310,17.0,13.0)
		_build_column(center+p,stone,1.0+float(i%3)*0.35)
	for i in 5:
		_build_crate(center+Vector3(-7+float(i)*3.5,0,6),map_id,i)

func _build_field_landmark(map_id:int)->void:
	var pos:=center+Vector3(0,0,-11)
	_build_gate(pos,_town_palette(map_id%10)[1],str(Teleport.MAPS[map_id]["name"]))
	for i in 6:
		_build_lamp(center+Vector3(-10+float(i)*4,0,-3),map_id)

func _build_column(pos:Vector3,color:Color,height:float)->void:
	var col:=MeshInstance3D.new()
	var mesh:=CylinderMesh.new()
	mesh.top_radius=0.35
	mesh.bottom_radius=0.48
	mesh.height=height
	col.mesh=mesh
	col.position=pos+Vector3(0,height*0.5,0)
	col.material_override=_mat(color,0.0,0.76)
	root.add_child(col)

func _build_crystal(pos:Vector3,map_id:int,index:int)->void:
	var c:=MeshInstance3D.new()
	var mesh:=CylinderMesh.new()
	mesh.top_radius=0.0
	mesh.bottom_radius=0.16+float(index%3)*0.08
	mesh.height=0.7+float(index%4)*0.20
	c.mesh=mesh
	c.position=pos+Vector3(0,mesh.height*0.5,0)
	c.rotation_degrees=Vector3(0,index*29,index%2*8)
	c.material_override=_mat(_crystal_color(map_id),0.05,0.16,true)
	root.add_child(c)

func _build_dungeon_altar(map_id:int)->void:
	var stone:=_stone_color(map_id)
	var pos:=center+Vector3(0,0,5)
	for r in [3.0,2.0,1.0]:
		var ring:=MeshInstance3D.new()
		var tm:=TorusMesh.new()
		tm.inner_radius=r-0.10
		tm.outer_radius=r
		ring.mesh=tm
		ring.rotation_degrees.x=90
		ring.position=pos+Vector3(0,0.12+3.0-r*0.08,0)
		ring.material_override=_mat(stone,0.15,0.42)
		root.add_child(ring)
	_build_crystal(pos+Vector3(0,0,0),map_id,9)

func _build_dungeon_arch(pos:Vector3,color:Color)->void:
	for side in [-1.0,1.0]:
		root.add_child(_box(Vector3(1.2,4.4,1.2),pos+Vector3(side*3.3,2.2,0),color))
	root.add_child(_box(Vector3(7.8,1.0,1.2),pos+Vector3(0,4.0,0),color))

func _build_lamp(pos:Vector3,map_id:int)->void:
	var post:=_box(Vector3(0.12,2.5,0.12),pos+Vector3(0,1.25,0),Color("#3d3532"))
	root.add_child(post)
	var glow:=_box(Vector3(0.34,0.34,0.34),pos+Vector3(0,2.65,0),_light_color(map_id))
	glow.material_override=_mat(_light_color(map_id),0.05,0.18,true)
	root.add_child(glow)
	var light:=OmniLight3D.new()
	light.position=pos+Vector3(0,2.65,0)
	light.light_color=_light_color(map_id)
	light.light_energy=0.55
	light.omni_range=4.0
	root.add_child(light)

func _build_bench(pos:Vector3,angle:float)->void:
	var seat:=_box(Vector3(2.0,0.16,0.52),pos+Vector3(0,0.72,0),Color("#704c34"))
	seat.rotation.y=angle
	root.add_child(seat)
	for side in [-0.7,0.7]:
		var leg:=_box(Vector3(0.12,0.7,0.12),pos+Vector3(side,0.35,0),Color("#45362b"))
		leg.rotation.y=angle
		root.add_child(leg)

func _build_barrel(pos:Vector3,map_id:int)->void:
	var b:=MeshInstance3D.new()
	var bm:=CylinderMesh.new()
	bm.top_radius=0.38
	bm.bottom_radius=0.42
	bm.height=0.75
	b.mesh=bm
	b.position=pos+Vector3(0,0.38,0)
	b.material_override=_mat(_wood_color(map_id),0.0,0.88)
	root.add_child(b)
	for y in [0.20,0.55]:
		var band:=MeshInstance3D.new()
		var tm:=TorusMesh.new()
		tm.inner_radius=0.39
		tm.outer_radius=0.43
		band.mesh=tm
		band.rotation_degrees.x=90
		band.position=pos+Vector3(0,y,0)
		band.material_override=_mat(Color("#493b35"),0.75,0.34)
		root.add_child(band)

func _build_crate(pos:Vector3,map_id:int,index:int)->void:
	var c:=_box(Vector3(0.8,0.65,0.8),pos+Vector3(0,0.33,0),_wood_color(map_id))
	c.rotation.y=float(index)*0.35
	root.add_child(c)

func _build_rock(pos:Vector3,radius:float,color:Color)->MeshInstance3D:
	var n:=MeshInstance3D.new()
	var m:=SphereMesh.new()
	m.radius=radius
	m.height=radius*1.4
	n.mesh=m
	n.position=pos+Vector3(0,radius*0.45,0)
	n.material_override=_mat(color,0.0,0.96)
	return n

func _map_sign(map_id:int)->String:
	return str(Teleport.MAPS.get(map_id,{"name":"Unknown"}).get("name","Unknown"))

func _build_map_sign(map_id:int)->void:
	var label:=Label3D.new()
	label.text="HONOUR WAR  •  "+_map_sign(map_id).to_upper()
	label.font_size=30
	label.outline_size=9
	label.modulate=Color("#ffe7ad")
	label.position=center+Vector3(0,6.0,-20)
	root.add_child(label)
	var sub:=Label3D.new()
	sub.text=str(Teleport.MAPS.get(map_id,{}).get("type","world")).to_upper()+"  •  HD WORLD"
	sub.font_size=16
	sub.outline_size=5
	sub.modulate=Color("#d7f2ff")
	sub.position=center+Vector3(0,5.3,-20)
	root.add_child(sub)

func _scatter(index:int,rx:float,rz:float)->Vector3:
	var n:int=seed_value+index*7919
	var x:float=fmod(abs(float(n*37%10000))/10000.0*2.0-1.0,2.0)*rx
	var z:float=fmod(abs(float(n*91%10000))/10000.0*2.0-1.0,2.0)*rz
	if abs(x)<2.5: x+=4.0 if x>=0 else -4.0
	if abs(z)<2.0: z+=3.0 if z>=0 else -3.0
	return Vector3(x,0,z)

func _road(pos:Vector3,size:Vector3,color:Color)->void:
	var n:=_box(size,pos,color)
	n.name="HDPath"
	root.add_child(n)

func _box(size:Vector3,pos:Vector3,color:Color)->MeshInstance3D:
	var n:=MeshInstance3D.new()
	var m:=BoxMesh.new()
	m.size=size
	n.mesh=m
	n.position=pos
	n.material_override=_mat(color,0.0,0.90)
	return n

func _mat(color:Color,metallic:float,roughness:float,emissive:bool=false)->StandardMaterial3D:
	var m:=StandardMaterial3D.new()
	m.albedo_color=color
	m.metallic=metallic
	m.roughness=roughness
	if emissive:
		m.emission_enabled=true
		m.emission=color
		m.emission_energy_multiplier=1.5
	return m

func _town_palette(map_id:int)->Array[Color]:
	var palettes:Array[Array[Color]]=[
		[Color("#d8c3a5"),Color("#5a3340"),Color("#d7a95c"),Color("#6c91b5")],
		[Color("#b99672"),Color("#344b57"),Color("#d9a84e"),Color("#567b55")],
		[Color("#b7b5bd"),Color("#4d3e6b"),Color("#d2a84d"),Color("#6e9ec0")],
		[Color("#c7a77c"),Color("#70462f"),Color("#d9b15c"),Color("#7d8e9e")],
		[Color("#b7d0d0"),Color("#35627b"),Color("#f0c65e"),Color("#6aa5b7")],
		[Color("#b18a68"),Color("#4f6b7b"),Color("#d9b05e"),Color("#6f9b6a")],
		[Color("#9a8b6e"),Color("#385c52"),Color("#d3a24d"),Color("#4c8b82")],
		[Color("#b8b28c"),Color("#4b6a52"),Color("#dfbd61"),Color("#789a62")],
		[Color("#d9dfe4"),Color("#4d6b8a"),Color("#f0d06b"),Color("#8cc4e2")],
		[Color("#a99575"),Color("#513e58"),Color("#d8a850"),Color("#71865c")]
	]
	return palettes[map_id%10]

func _ground_color(map_id:int)->Color:
	if map_id>=20 and map_id<30:
		return [Color("#52734d"),Color("#3f6b43"),Color("#68794b"),Color("#c49a54"),Color("#4d7b75"),Color("#6d8560"),Color("#416b43"),Color("#6f8152"),Color("#d9e5ea"),Color("#466d4b")][map_id-20]
	if map_id>=10:
		return [Color("#3a3f4a"),Color("#3b333a"),Color("#3d394e"),Color("#4a3a34"),Color("#403936"),Color("#42505c"),Color("#4a4140"),Color("#3a4348"),Color("#263f31"),Color("#3f3436")][map_id-10]
	return Color("#53694f")

func _foliage_color(map_id:int)->Color:
	return [Color("#2d7148"),Color("#3d7440"),Color("#396a59"),Color("#6d7134"),Color("#2f7474"),Color("#3d7651"),Color("#3a7145"),Color("#668044"),Color("#7394a4"),Color("#35683e")][map_id%10]

func _crystal_color(map_id:int)->Color:
	return [Color("#6edcff"),Color("#91b7ff"),Color("#b98dff"),Color("#ff9c69"),Color("#6fe6e4"),Color("#69c9ff"),Color("#77ffb1"),Color("#b8e66e"),Color("#bdefff"),Color("#ff75d0")][map_id%10]

func _light_color(map_id:int)->Color:
	return [Color("#ffd477"),Color("#ffe0a0"),Color("#d8c2ff"),Color("#ffb86b"),Color("#a9eaff"),Color("#ffd48b"),Color("#9fffe4"),Color("#f3e39b"),Color("#d9f6ff"),Color("#ffc2ef")][map_id%10]

func _stone_color(map_id:int)->Color:
	return _town_palette(map_id%10)[0].darkened(0.30)

func _rock_color(map_id:int)->Color:
	return _stone_color(map_id).darkened(0.15)

func _wood_color(map_id:int)->Color:
	return Color("#5b3c29").lightened(float(map_id%3)*0.05)

func _darken(c:Color,amount:float)->Color:
	return c.darkened(amount)

func _lighten(c:Color,amount:float)->Color:
	return c.lightened(amount)

func _map_to_world(p:Vector2)->Vector3:
	return Vector3((p.x-ORIGIN_X)*WORLD_SCALE,0,(p.y-ORIGIN_Y)*WORLD_SCALE)
