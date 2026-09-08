class_name PetDetail3D
extends Node3D

var last_pet:Node3D
var decorated:Dictionary={}
var elapsed:float=0.0

func _process(delta:float)->void:
	elapsed+=delta
	var game:Node=get_parent()
	if game==null:
		return
	var pet:Node3D=game.get("pet_visual") as Node3D
	if pet==null:
		return
	if pet!=last_pet:
		last_pet=pet
	_decorate(pet,game)
	var flap:float=sin(elapsed*7.5)*0.18
	var wings:Node3D=pet.get_node_or_null("DetailWings") as Node3D
	if wings!=null:
		wings.rotation.z=flap
	var tail:Node3D=pet.get_node_or_null("DetailTail") as Node3D
	if tail!=null:
		tail.rotation.z=sin(elapsed*4.0)*0.08

func _decorate(pet:Node3D,game:Node)->void:
	var key:int=pet.get_instance_id()
	if decorated.has(key):
		return
	decorated[key]=true
	var species:String="Pet"
	var legacy:Node=game.get_node_or_null("LegacyGame")
	if legacy!=null:
		var hero_value:Variant=legacy.get("hero")
		if hero_value is Dictionary:
			var pet_value:Variant=hero_value.get("pet",{})
			if pet_value is Dictionary:
				species=str(pet_value.get("species","Pet"))
	if species=="Royal Falcon":
		_falcon(pet)
	elif species=="Astral Sprite":
		_sprite(pet)
	elif species=="Blessed Poring":
		_poring(pet)
	else:
		_wolf(pet)
	_add_eyes(pet)

func _mat(c:Color,metal:float=0.0,rough:float=0.65,glow:bool=false)->StandardMaterial3D:
	var m:StandardMaterial3D=StandardMaterial3D.new()
	m.albedo_color=c
	m.metallic=metal
	m.roughness=rough
	if glow:
		m.emission_enabled=true
		m.emission=c
		m.emission_energy_multiplier=2.6
	return m

func _part(parent:Node3D,name:String,mesh:MeshInstance3D,pos:Vector3)->void:
	mesh.name=name
	mesh.position=pos
	parent.add_child(mesh)

func _falcon(pet:Node3D)->void:
	var wings:Node3D=Node3D.new(); wings.name="DetailWings"; pet.add_child(wings)
	for side in [-1.0,1.0]:
		var w:MeshInstance3D=MeshInstance3D.new(); w.mesh=BoxMesh.new(); w.mesh.size=Vector3(0.12,0.18,1.05); w.material_override=_mat(Color("#c9a15e"),0.1,0.7); _part(wings,"Wing",w,Vector3(side*0.36,0.02,0))
	var beak:MeshInstance3D=MeshInstance3D.new(); beak.mesh=BoxMesh.new(); beak.mesh.size=Vector3(0.10,0.10,0.24); beak.material_override=_mat(Color("#e6b347"),0.3,0.35); _part(pet,"Beak",beak,Vector3(0,0.05,0.36))
	var tail:MeshInstance3D=MeshInstance3D.new(); tail.name="DetailTail"; tail.mesh=BoxMesh.new(); tail.mesh.size=Vector3(0.18,0.16,0.65); tail.material_override=_mat(Color("#8b673d"),0.05,0.8); tail.position=Vector3(0,0,-0.52); pet.add_child(tail)

func _sprite(pet:Node3D)->void:
	var wings:Node3D=Node3D.new(); wings.name="DetailWings"; pet.add_child(wings)
	for side in [-1.0,1.0]:
		var wing:MeshInstance3D=MeshInstance3D.new(); wing.mesh=SphereMesh.new(); wing.mesh.radius=0.48; wing.mesh.height=0.18; wing.scale=Vector3(1.3,0.55,0.55); wing.material_override=_mat(Color("#6bcfff"),0.05,0.35,true); _part(wings,"Wing",wing,Vector3(side*0.42,0,0))
	var halo:MeshInstance3D=MeshInstance3D.new(); halo.mesh=SphereMesh.new(); halo.mesh.radius=0.62; halo.mesh.height=0.08; halo.scale=Vector3(1.0,1.0,0.28); halo.material_override=_mat(Color("#d7f7ff"),0.0,0.25,true); _part(pet,"Halo",halo,Vector3(0,0.18,0))

func _poring(pet:Node3D)->void:
	var crown:MeshInstance3D=MeshInstance3D.new(); crown.mesh=SphereMesh.new(); crown.mesh.radius=0.18; crown.mesh.height=0.38; crown.material_override=_mat(Color("#ffd86b"),0.1,0.3,true); _part(pet,"Crown",crown,Vector3(0,0.52,0))
	var wing_group:Node3D=Node3D.new(); wing_group.name="DetailWings"; pet.add_child(wing_group)
	for side in [-1.0,1.0]:
		var wing:MeshInstance3D=MeshInstance3D.new(); wing.mesh=SphereMesh.new(); wing.mesh.radius=0.24; wing.mesh.height=0.10; wing.scale=Vector3(1.4,0.5,0.5); wing.material_override=_mat(Color("#fff4fa"),0.0,0.55); _part(wing_group,"Wing",wing,Vector3(side*0.44,0.10,0))

func _wolf(pet:Node3D)->void:
	var ear_l:MeshInstance3D=MeshInstance3D.new(); ear_l.mesh=CylinderMesh.new(); ear_l.mesh.top_radius=0.0; ear_l.mesh.bottom_radius=0.16; ear_l.mesh.height=0.38; ear_l.material_override=_mat(Color("#404754"),0.0,0.85); ear_l.position=Vector3(-0.28,0.50,0.12); pet.add_child(ear_l)
	var ear_r:MeshInstance3D=MeshInstance3D.new(); ear_r.mesh=CylinderMesh.new(); ear_r.mesh.top_radius=0.0; ear_r.mesh.bottom_radius=0.16; ear_r.mesh.height=0.38; ear_r.material_override=_mat(Color("#404754"),0.0,0.85); ear_r.position=Vector3(0.28,0.50,0.12); pet.add_child(ear_r)
	var tail:MeshInstance3D=MeshInstance3D.new(); tail.name="DetailTail"; tail.mesh=CapsuleMesh.new(); tail.mesh.radius=0.12; tail.mesh.height=0.8; tail.material_override=_mat(Color("#505866"),0.0,0.85); tail.position=Vector3(0,0.25,-0.64); tail.rotation_degrees.x=55.0; pet.add_child(tail)

func _add_eyes(pet:Node3D)->void:
	for side in [-1.0,1.0]:
		var eye:MeshInstance3D=MeshInstance3D.new(); eye.mesh=SphereMesh.new(); eye.mesh.radius=0.055; eye.mesh.height=0.11; eye.material_override=_mat(Color("#fff2aa"),0.0,0.25,true); _part(pet,"Eye",eye,Vector3(side*0.14,0.22,0.35))
