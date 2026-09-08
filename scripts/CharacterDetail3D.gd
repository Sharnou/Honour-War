class_name CharacterDetail3D
extends Node3D

var last_hero:Node3D
var decorated:Dictionary={}
var elapsed:float=0.0

func _process(delta:float)->void:
	elapsed+=delta
	var game:Node=get_parent()
	if game==null:
		return
	var hero:Node3D=game.get("hero_visual") as Node3D
	if hero==null:
		return
	if hero!=last_hero:
		last_hero=hero
	_decorate_hero(hero,game)
	_animate(hero)

func _decorate_hero(hero:Node3D,game:Node)->void:
	var key:int=hero.get_instance_id()
	if decorated.has(key):
		return
	decorated[key]=true
	var class_id:String="Warrior"
	var legacy:Node=game.get_node_or_null("LegacyGame")
	if legacy!=null:
		var hero_value:Variant=legacy.get("hero")
		if hero_value is Dictionary:
			class_id=str(hero_value.get("class","Warrior"))
	if class_id=="Warrior":
		_add_armor(hero,Color("#b83d32"),Color("#e3b766"),true)
	elif class_id=="Mage":
		_add_robe(hero,Color("#6253d8"),Color("#8fe7ff"))
	elif class_id=="Archer":
		_add_armor(hero,Color("#3d7c52"),Color("#d8c17b"),false)
	elif class_id=="Thief":
		_add_cloak(hero,Color("#45264e"),Color("#b56af0"))
	elif class_id=="Acolyte":
		_add_robe(hero,Color("#f0efe6"),Color("#ffd873"))
	else:
		_add_armor(hero,Color("#236d8d"),Color("#d5a84b"),false)
	_add_face(hero)
	_add_belt_boots(hero)
	_add_class_mark(hero,class_id)

func _animate(hero:Node3D)->void:
	var breathing:float=sin(elapsed*2.1)*0.018
	var armor:Node3D=hero.get_node_or_null("DetailArmor") as Node3D
	if armor!=null:
		armor.rotation.z=breathing
	var cape:Node3D=hero.get_node_or_null("DetailCape") as Node3D
	if cape!=null:
		cape.rotation.x=sin(elapsed*1.8)*0.05

func _mesh_node(parent:Node3D,name:String,mesh:MeshInstance3D,pos:Vector3)->void:
	mesh.name=name
	mesh.position=pos
	parent.add_child(mesh)

func _mat(color:Color,metal:float=0.0,rough:float=0.65,emission:Color=Color(0,0,0,1))->StandardMaterial3D:
	var mat:StandardMaterial3D=StandardMaterial3D.new()
	mat.albedo_color=color
	mat.metallic=metal
	mat.roughness=rough
	if emission != Color(0,0,0,1):
		mat.emission_enabled=true
		mat.emission=emission
		mat.emission_energy_multiplier=2.4
	return mat

func _add_armor(hero:Node3D,base:Color,trim:Color,heavy:bool)->void:
	var group:Node3D=Node3D.new(); group.name="DetailArmor"; hero.add_child(group)
	var chest:MeshInstance3D=MeshInstance3D.new(); chest.mesh=BoxMesh.new(); chest.mesh.size=Vector3(0.78 if heavy else 0.68,0.62,0.48); chest.material_override=_mat(base,0.55,0.34); _mesh_node(group,"Chest",chest,Vector3(0,1.37,0.02))
	var plate_l:MeshInstance3D=MeshInstance3D.new(); plate_l.mesh=BoxMesh.new(); plate_l.mesh.size=Vector3(0.30,0.30,0.44); plate_l.material_override=_mat(trim,0.65,0.28); _mesh_node(group,"ShoulderL",plate_l,Vector3(-0.58,1.64,0))
	var plate_r:MeshInstance3D=MeshInstance3D.new(); plate_r.mesh=BoxMesh.new(); plate_r.mesh.size=Vector3(0.30,0.30,0.44); plate_r.material_override=_mat(trim,0.65,0.28); _mesh_node(group,"ShoulderR",plate_r,Vector3(0.58,1.64,0))

func _add_robe(hero:Node3D,robe:Color,glow:Color)->void:
	var group:Node3D=Node3D.new(); group.name="DetailArmor"; hero.add_child(group)
	var chest:MeshInstance3D=MeshInstance3D.new(); chest.mesh=SphereMesh.new(); chest.mesh.radius=0.58; chest.mesh.height=1.18; chest.material_override=_mat(robe,0.05,0.62); _mesh_node(group,"Robe",chest,Vector3(0,1.35,0))
	var sash:MeshInstance3D=MeshInstance3D.new(); sash.mesh=BoxMesh.new(); sash.mesh.size=Vector3(0.88,0.10,0.08); sash.material_override=_mat(glow,0.1,0.34,glow); _mesh_node(group,"Sash",sash,Vector3(0,1.20,0.40))

func _add_cloak(hero:Node3D,cloak:Color,trim:Color)->void:
	var group:Node3D=Node3D.new(); group.name="DetailArmor"; hero.add_child(group)
	var chest:MeshInstance3D=MeshInstance3D.new(); chest.mesh=BoxMesh.new(); chest.mesh.size=Vector3(0.62,0.72,0.42); chest.material_override=_mat(cloak,0.2,0.5); _mesh_node(group,"Leathers",chest,Vector3(0,1.35,0))
	var cape:MeshInstance3D=MeshInstance3D.new(); cape.name="DetailCape"; cape.mesh=BoxMesh.new(); cape.mesh.size=Vector3(0.92,1.10,0.08); cape.material_override=_mat(trim,0.05,0.72); cape.position=Vector3(0,1.35,-0.34); hero.add_child(cape)

func _add_belt_boots(hero:Node3D)->void:
	var belt:MeshInstance3D=MeshInstance3D.new(); belt.mesh=BoxMesh.new(); belt.mesh.size=Vector3(0.84,0.11,0.50); belt.material_override=_mat(Color("#6b472e"),0.05,0.8); _mesh_node(hero,"DetailBelt",belt,Vector3(0,1.05,0.02))
	for side in [-1.0,1.0]:
		var boot:MeshInstance3D=MeshInstance3D.new(); boot.mesh=BoxMesh.new(); boot.mesh.size=Vector3(0.25,0.55,0.30); boot.material_override=_mat(Color("#20232a"),0.25,0.75); _mesh_node(hero,"Boot",boot,Vector3(side*0.20,0.42,0.02))

func _add_face(hero:Node3D)->void:
	var eye_l:MeshInstance3D=MeshInstance3D.new(); eye_l.mesh=SphereMesh.new(); eye_l.mesh.radius=0.045; eye_l.mesh.height=0.09; eye_l.material_override=_mat(Color("#151821"),0.0,0.25); _mesh_node(hero,"EyeL",eye_l,Vector3(-0.14,2.30,0.35))
	var eye_r:MeshInstance3D=MeshInstance3D.new(); eye_r.mesh=SphereMesh.new(); eye_r.mesh.radius=0.045; eye_r.mesh.height=0.09; eye_r.material_override=_mat(Color("#151821"),0.0,0.25); _mesh_node(hero,"EyeR",eye_r,Vector3(0.14,2.30,0.35))

func _add_class_mark(hero:Node3D,class_id:String)->void:
	var color:Color=Color("#e8a34b")
	match class_id:
		"Mage": color=Color("#70c7ff")
		"Archer": color=Color("#8fe08f")
		"Thief": color=Color("#ff6fb0")
		"Acolyte": color=Color("#fff0a3")
		"Merchant": color=Color("#7ed7ff")
	var mark:MeshInstance3D=MeshInstance3D.new(); mark.mesh=SphereMesh.new(); mark.mesh.radius=0.10; mark.mesh.height=0.18; mark.material_override=_mat(color,0.1,0.2,color); _mesh_node(hero,"ClassMark",mark,Vector3(0,1.72,0.38))
