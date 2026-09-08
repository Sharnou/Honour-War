class_name CharacterDetail3D
extends Node3D

var last_hero:Node3D
var decorated:Dictionary={}
var elapsed:float=0.0
var equipment_signature:String=""

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
		equipment_signature=""
	_decorate_hero(hero,game)
	_sync_equipment(hero,game)
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

func _sync_equipment(hero:Node3D,game:Node)->void:
	var legacy:Node=game.get_node_or_null("LegacyGame")
	if legacy==null:
		return
	var hero_value:Variant=legacy.get("hero")
	if not hero_value is Dictionary:
		return
	var data:Dictionary=hero_value
	var equipment_value:Variant=data.get("equipment",{})
	if not equipment_value is Dictionary:
		return
	var equipment:Dictionary=equipment_value
	var signature:=JSON.stringify(equipment)
	if signature==equipment_signature:
		return
	equipment_signature=signature
	var old:Node=hero.get_node_or_null("EquippedVisuals")
	if old!=null:
		old.queue_free()
	var group:Node3D=Node3D.new()
	group.name="EquippedVisuals"
	hero.add_child(group)
	for slot in EquipmentSystem.SLOTS:
		var item_name:=str(equipment.get(slot,""))
		if item_name=="":
			continue
		_add_equipped_piece(group,slot,item_name)

func _add_equipped_piece(group:Node3D,slot:String,item_name:String)->void:
	var catalog:=ItemDatabase.all()
	var data:Dictionary=catalog.get(EquipmentSystem.base_item_name(item_name),{})
	var glowing:bool=bool(data.get("glowing",false))
	var rarity:=str(data.get("rarity","Common"))
	var base_color:=_item_color(item_name,slot)
	var trim_color:=Color("#f4d47a") if rarity in ["Legendary","MVP"] else Color("#c7d0dc")
	if glowing:
		trim_color=Color("#9cf6ff")
		base_color=base_color.lightened(0.12)
	match slot:
		"weapon": _make_weapon(group,item_name,base_color,trim_color,glowing)
		"shield": _make_shield(group,item_name,base_color,trim_color,glowing)
		"head_upper": _make_head_upper(group,item_name,base_color,trim_color,glowing)
		"head_middle": _make_head_middle(group,item_name,base_color,trim_color,glowing)
		"head_lower": _make_head_lower(group,item_name,base_color,trim_color,glowing)
		"armor": _make_armor_piece(group,item_name,base_color,trim_color,glowing)
		"garment": _make_garment(group,item_name,base_color,trim_color,glowing)
		"shoes": _make_shoes(group,item_name,base_color,trim_color,glowing)
		"accessory_1": _make_accessory(group,item_name,base_color,trim_color,glowing,-0.34)
		"accessory_2": _make_accessory(group,item_name,base_color,trim_color,glowing,0.34)

func _item_color(item_name:String,slot:String)->Color:
	if item_name.find("Dragon")>=0: return Color("#c94b3f")
	if item_name.find("Shadow")>=0 or item_name.find("Assassin")>=0: return Color("#5a2a70")
	if item_name.find("Astral")>=0 or item_name.find("Arcane")>=0: return Color("#3f72d4")
	if item_name.find("Celestial")>=0 or item_name.find("Heaven")>=0: return Color("#e2d6a1")
	if item_name.find("War Emperor")>=0: return Color("#9a302e")
	if item_name.find("Arsenal")>=0 or item_name.find("Forge")>=0: return Color("#2e7191")
	if slot=="weapon": return Color("#aeb9c7")
	if slot.begins_with("head"): return Color("#6b78a8")
	return Color("#586879")

func _material(color:Color,metal:float=0.2,rough:float=0.55,glowing:bool=false)->StandardMaterial3D:
	var mat:StandardMaterial3D=StandardMaterial3D.new()
	mat.albedo_color=color
	mat.metallic=metal
	mat.roughness=rough
	if glowing:
		mat.emission_enabled=true
		mat.emission=Color("#72eaff")
		mat.emission_energy_multiplier=3.2
	return mat

func _piece(group:Node3D,name:String,mesh:MeshInstance3D,pos:Vector3,material:Material)->void:
	mesh.name=name
	mesh.position=pos
	mesh.material_override=material
	group.add_child(mesh)

func _add_glow(group:Node3D,pos:Vector3,scale:float=1.0)->void:
	var ring:MeshInstance3D=MeshInstance3D.new()
	var torus:=TorusMesh.new()
	torus.inner_radius=0.55*scale
	torus.outer_radius=0.62*scale
	ring.mesh=torus
	ring.position=pos
	ring.rotation.x=PI*0.5
	ring.material_override=_material(Color("#68e9ff"),0.1,0.18,true)
	group.add_child(ring)

func _make_weapon(group:Node3D,item:String,base:Color,trim:Color,glowing:bool)->void:
	var shaft:MeshInstance3D=MeshInstance3D.new(); shaft.mesh=CylinderMesh.new(); shaft.mesh.top_radius=0.055; shaft.mesh.bottom_radius=0.065; shaft.mesh.height=1.35
	_piece(group,"WeaponShaft",shaft,Vector3(0.68,1.20,0.10),_material(base,0.65,0.25,glowing))
	var blade:MeshInstance3D=MeshInstance3D.new(); blade.mesh=BoxMesh.new(); blade.mesh.size=Vector3(0.14,0.72,0.12)
	_piece(group,"WeaponBlade",blade,Vector3(0.68,1.98,0.10),_material(trim,0.75,0.18,glowing))
	var guard:MeshInstance3D=MeshInstance3D.new(); guard.mesh=BoxMesh.new(); guard.mesh.size=Vector3(0.52,0.08,0.12)
	_piece(group,"WeaponGuard",guard,Vector3(0.68,1.57,0.10),_material(trim,0.7,0.2,glowing))
	if item.find("Staff")>=0 or item.find("Mace")>=0 or item.find("Hammer")>=0:
		blade.mesh=SphereMesh.new(); blade.mesh.radius=0.22; blade.mesh.height=0.38
		blade.position=Vector3(0.68,1.88,0.10)
	if item.find("Bow")>=0:
		var bow:MeshInstance3D=MeshInstance3D.new(); bow.mesh=TorusMesh.new(); bow.mesh.inner_radius=0.35; bow.mesh.outer_radius=0.39
		_piece(group,"BowFrame",bow,Vector3(0.68,1.75,0.10),_material(trim,0.3,0.35,glowing))
	if glowing: _add_glow(group,Vector3(0.0,1.55,0.0),1.15)

func _make_shield(group:Node3D,item:String,base:Color,trim:Color,glowing:bool)->void:
	var shield:MeshInstance3D=MeshInstance3D.new(); shield.mesh=SphereMesh.new(); shield.mesh.radius=0.43; shield.mesh.height=0.22
	_piece(group,"Shield",shield,Vector3(-0.62,1.25,0.18),_material(base,0.65,0.3,glowing))
	if glowing: _add_glow(group,Vector3(-0.62,1.25,0.18),0.75)

func _make_head_upper(group:Node3D,item:String,base:Color,trim:Color,glowing:bool)->void:
	var helm:MeshInstance3D=MeshInstance3D.new(); helm.mesh=SphereMesh.new(); helm.mesh.radius=0.48; helm.mesh.height=0.35
	_piece(group,"HeadUpper",helm,Vector3(0,2.34,0),_material(base,0.55,0.3,glowing))
	var crest:MeshInstance3D=MeshInstance3D.new(); crest.mesh=BoxMesh.new(); crest.mesh.size=Vector3(0.10,0.32,0.16)
	_piece(group,"HeadCrest",crest,Vector3(0,2.65,0),_material(trim,0.7,0.2,glowing))
	if glowing: _add_glow(group,Vector3(0,2.32,0),0.78)

func _make_head_middle(group:Node3D,item:String,base:Color,trim:Color,glowing:bool)->void:
	var visor:MeshInstance3D=MeshInstance3D.new(); visor.mesh=BoxMesh.new(); visor.mesh.size=Vector3(0.58,0.12,0.20)
	_piece(group,"HeadMiddle",visor,Vector3(0,2.27,0.34),_material(trim,0.5,0.22,glowing))

func _make_head_lower(group:Node3D,item:String,base:Color,trim:Color,glowing:bool)->void:
	var scarf:MeshInstance3D=MeshInstance3D.new(); scarf.mesh=BoxMesh.new(); scarf.mesh.size=Vector3(0.62,0.22,0.18)
	_piece(group,"HeadLower",scarf,Vector3(0,2.03,0.28),_material(base,0.1,0.7,glowing))

func _make_armor_piece(group:Node3D,item:String,base:Color,trim:Color,glowing:bool)->void:
	var chest:MeshInstance3D=MeshInstance3D.new(); chest.mesh=BoxMesh.new(); chest.mesh.size=Vector3(0.84,0.72,0.52)
	_piece(group,"EquippedArmor",chest,Vector3(0,1.37,0.04),_material(base,0.55,0.3,glowing))
	for side in [-1.0,1.0]:
		var shoulder:MeshInstance3D=MeshInstance3D.new(); shoulder.mesh=BoxMesh.new(); shoulder.mesh.size=Vector3(0.25,0.25,0.42)
		_piece(group,"ArmorShoulder",shoulder,Vector3(side*0.55,1.62,0),_material(trim,0.65,0.25,glowing))
	if glowing: _add_glow(group,Vector3(0,1.38,0),1.0)

func _make_garment(group:Node3D,item:String,base:Color,trim:Color,glowing:bool)->void:
	var cape:MeshInstance3D=MeshInstance3D.new(); cape.mesh=BoxMesh.new(); cape.mesh.size=Vector3(1.02,1.25,0.10)
	_piece(group,"EquippedGarment",cape,Vector3(0,1.42,-0.38),_material(base,0.12,0.62,glowing))
	if item.find("Wing")>=0:
		for side in [-1.0,1.0]:
			var wing:MeshInstance3D=MeshInstance3D.new(); wing.mesh=BoxMesh.new(); wing.mesh.size=Vector3(0.62,0.88,0.08)
			wing.rotation.z=side*0.28
			_piece(group,"Wing",wing,Vector3(side*0.58,1.58,-0.25),_material(trim,0.18,0.35,glowing))
	if glowing: _add_glow(group,Vector3(0,1.45,-0.3),1.18)

func _make_shoes(group:Node3D,item:String,base:Color,trim:Color,glowing:bool)->void:
	for side in [-1.0,1.0]:
		var boot:MeshInstance3D=MeshInstance3D.new(); boot.mesh=BoxMesh.new(); boot.mesh.size=Vector3(0.28,0.58,0.34)
		_piece(group,"EquippedBoot",boot,Vector3(side*0.21,0.43,0.03),_material(base,0.3,0.5,glowing))
	if glowing: _add_glow(group,Vector3(0,0.55,0),0.72)

func _make_accessory(group:Node3D,item:String,base:Color,trim:Color,glowing:bool,x:float)->void:
	var orb:MeshInstance3D=MeshInstance3D.new(); orb.mesh=SphereMesh.new(); orb.mesh.radius=0.10; orb.mesh.height=0.20
	_piece(group,"Accessory",orb,Vector3(x,1.05,0.42),_material(trim,0.35,0.22,glowing))

func _animate(hero:Node3D)->void:
	var breathing:float=sin(elapsed*2.1)*0.018
	var armor:Node3D=hero.get_node_or_null("DetailArmor") as Node3D
	if armor!=null:
		armor.rotation.z=breathing
	var cape:Node3D=hero.get_node_or_null("DetailCape") as Node3D
	if cape!=null:
		cape.rotation.x=sin(elapsed*1.8)*0.05
	var equipped:Node3D=hero.get_node_or_null("EquippedVisuals") as Node3D
	if equipped!=null:
		equipped.position.y=sin(elapsed*2.0)*0.008

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
