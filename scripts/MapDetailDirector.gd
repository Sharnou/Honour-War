class_name MapDetailDirector
extends Node3D

var game:Node
var detail_root:Node3D
var last_map:int=-1

func _ready()->void:
	game=get_parent()
	call_deferred("_rebuild")

func _process(_delta:float)->void:
	if game==null: return
	var legacy:Node=game.get_node_or_null("LegacyGame")
	if legacy==null: return
	var value:Variant=legacy.get("hero")
	var map_id:int=int((value as Dictionary).get("map_id",0)) if value is Dictionary else 0
	if map_id!=last_map:
		_rebuild()

func _rebuild()->void:
	if game==null: return
	var legacy:Node=game.get_node_or_null("LegacyGame")
	if legacy==null: return
	var value:Variant=legacy.get("hero")
	last_map=int((value as Dictionary).get("map_id",0)) if value is Dictionary else 0
	if detail_root!=null: detail_root.queue_free()
	detail_root=Node3D.new()
	detail_root.name="HDMapDetails"
	game.add_child(detail_root)
	var center:=Vector3(12.925,0.0,12.65)
	_add_lanterns(center)
	_add_fences(center)
	_add_crystals(center)
	_add_map_marker(center)

func _add_lanterns(center:Vector3)->void:
	for p in [Vector3(-14,0,0),Vector3(14,0,0),Vector3(-14,0,13),Vector3(14,0,13),Vector3(-7,0,5),Vector3(7,0,5)]:
		var post:=MeshInstance3D.new()
		var mesh:=CylinderMesh.new()
		mesh.top_radius=0.07
		mesh.bottom_radius=0.11
		mesh.height=2.2
		post.mesh=mesh
		post.position=center+p+Vector3(0,1.1,0)
		post.material_override=_mat(Color("#40342c"),0.35,0.38)
		detail_root.add_child(post)
		var lamp:=MeshInstance3D.new()
		var sphere:=SphereMesh.new()
		sphere.radius=0.18
		sphere.height=0.36
		lamp.mesh=sphere
		lamp.position=post.position+Vector3(0,1.0,0)
		lamp.material_override=_mat(Color("#ffd56a"),0.0,0.22,true)
		detail_root.add_child(lamp)
		var light:=OmniLight3D.new()
		light.position=lamp.position
		light.light_color=Color("#ffd56a")
		light.light_energy=1.7
		light.omni_range=5.0
		detail_root.add_child(light)

func _add_fences(center:Vector3)->void:
	for z in [-7.0,30.0]:
		for i in 9:
			var post:=MeshInstance3D.new()
			var mesh:=BoxMesh.new()
			mesh.size=Vector3(0.16,1.25,0.16)
			post.mesh=mesh
			post.position=center+Vector3(-25.0+float(i)*6.2,0.62,z)
			post.material_override=_mat(Color("#5b4635"),0.0,0.82)
			detail_root.add_child(post)

func _add_crystals(center:Vector3)->void:
	for i in 10:
		var crystal:=MeshInstance3D.new()
		var mesh:=CylinderMesh.new()
		mesh.top_radius=0.0
		mesh.bottom_radius=0.18+float(i%3)*0.07
		mesh.height=0.7+float(i%4)*0.18
		crystal.mesh=mesh
		crystal.position=center+Vector3(-28.0+float((i*17)%56),0.45,-4.0+float((i*23)%30))
		crystal.rotation_degrees=Vector3(0.0,float(i*37),float(i%2)*7.0)
		crystal.material_override=_mat(Color("#6dcfff"),0.05,0.22,true)
		detail_root.add_child(crystal)

func _add_map_marker(center:Vector3)->void:
	var ring:=MeshInstance3D.new()
	var mesh:=TorusMesh.new()
	mesh.inner_radius=3.2
	mesh.outer_radius=3.27
	ring.mesh=mesh
	ring.position=center+Vector3(0,0.13,5.0)
	ring.rotation_degrees.x=90.0
	ring.material_override=_mat(Color("#d7b35c"),0.2,0.28,true)
	detail_root.add_child(ring)

func _mat(c:Color,m:float,r:float,emissive:bool=false)->StandardMaterial3D:
	var mat:=StandardMaterial3D.new()
	mat.albedo_color=c
	mat.metallic=m
	mat.roughness=r
	if emissive:
		mat.emission_enabled=true
		mat.emission=c
		mat.emission_energy_multiplier=1.8
	return mat
