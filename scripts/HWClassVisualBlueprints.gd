class_name HWClassVisualBlueprints
extends RefCounted

# High-detail first-class visual layer for Honour War.
# The six blueprints are original game assets inspired by classic high-fantasy anime
# proportions, not copies of any external sprite/texture files.

static func apply(hero:Node3D, class_id:String, elapsed:float)->void:
	if hero==null or hero.get_node_or_null("HWClassBlueprint")!=null:
		return
	var root:=Node3D.new()
	root.name="HWClassBlueprint"
	hero.add_child(root)
	var key:=class_id.to_lower()
	if key in ["warrior","swordsman","swordsman / warrior"]:
		_warrior(root)
	elif key=="merchant":
		_merchant(root)
	elif key=="acolyte":
		_acolyte(root)
	elif key=="thief":
		_thief(root)
	elif key=="archer":
		_archer(root)
	elif key=="mage":
		_mage(root)
	else:
		_warrior(root)
	_add_emotion_controller(root,key,elapsed)

static func _mat(color:Color,metal:float,rough:float,emission:Color=Color(0,0,0),energy:float=0.0)->StandardMaterial3D:
	var m:=StandardMaterial3D.new()
	m.albedo_color=color
	m.metallic=metal
	m.roughness=rough
	if energy>0.0:
		m.emission_enabled=true
		m.emission=emission
		m.emission_energy_multiplier=energy
	return m

static func _box(parent:Node3D,name:String,size:Vector3,pos:Vector3,mat:Material,rot:Vector3=Vector3.ZERO)->MeshInstance3D:
	var n:=MeshInstance3D.new()
	n.name=name
	var mesh:=BoxMesh.new()
	mesh.size=size
	n.mesh=mesh
	n.position=pos
	n.rotation=rot
	n.material_override=mat
	parent.add_child(n)
	return n

static func _sphere(parent:Node3D,name:String,radius:float,height:float,pos:Vector3,mat:Material)->MeshInstance3D:
	var n:=MeshInstance3D.new()
	n.name=name
	var mesh:=SphereMesh.new()
	mesh.radius=radius
	mesh.height=height
	n.mesh=mesh
	n.position=pos
	n.material_override=mat
	parent.add_child(n)
	return n

static func _cylinder(parent:Node3D,name:String,top:float,bottom:float,height:float,pos:Vector3,mat:Material,rot:Vector3=Vector3.ZERO)->MeshInstance3D:
	var n:=MeshInstance3D.new()
	n.name=name
	var mesh:=CylinderMesh.new()
	mesh.top_radius=top
	mesh.bottom_radius=bottom
	mesh.height=height
	n.mesh=mesh
	n.position=pos
	n.rotation=rot
	n.material_override=mat
	parent.add_child(n)
	return n

static func _torus(parent:Node3D,name:String,inner:float,outer:float,pos:Vector3,mat:Material,rot:Vector3=Vector3.ZERO)->MeshInstance3D:
	var n:=MeshInstance3D.new()
	n.name=name
	var mesh:=TorusMesh.new()
	mesh.inner_radius=inner
	mesh.outer_radius=outer
	n.mesh=mesh
	n.position=pos
	n.rotation=rot
	n.material_override=mat
	parent.add_child(n)
	return n

static func _hair(parent:Node3D,color:Color)->void:
	var hair:=_sphere(parent,"HairMass",0.49,0.70,Vector3(0,2.47,0),_mat(color,0.0,0.58))
	hair.scale=Vector3(1.0,1.05,0.92)
	for i in range(7):
		var a=float(i-3)*0.20
		var spike:=_sphere(parent,"HairLock",0.13,0.45,Vector3(a,2.66,0.02),_mat(color,0.0,0.58))
		spike.rotation.z=-a*0.75

static func _face(parent:Node3D,skin:Color,eye:Color)->void:
	_sphere(parent,"Face",0.43,0.66,Vector3(0,2.34,0.02),_mat(skin,0.0,0.62))
	for side in [-1.0,1.0]:
		_sphere(parent,"Eye",0.055,0.10,Vector3(side*0.145,2.39,0.395),_mat(eye,0.0,0.22,eye,1.5))
		_sphere(parent,"EyeHighlight",0.018,0.036,Vector3(side*0.13,2.41,0.445),_mat(Color.WHITE,0.0,0.15,Color.WHITE,2.0))
	_box(parent,"Mouth",Vector3(0.18,0.018,0.025),Vector3(0,2.22,0.40),_mat(Color("#6e2730"),0.0,0.7))

static func _boot_pair(parent:Node3D,color:Color,mat:Material)->void:
	for side in [-1.0,1.0]:
		_box(parent,"Boot",Vector3(0.30,0.58,0.38),Vector3(side*0.21,0.42,0.04),mat)
		_box(parent,"BootSole",Vector3(0.33,0.08,0.42),Vector3(side*0.21,0.13,0.05),_mat(color.darkened(0.18),0.15,0.78))

static func _belt(parent:Node3D,color:Color,metal:Color)->void:
	_box(parent,"UtilityBelt",Vector3(0.92,0.13,0.52),Vector3(0,1.05,0),_mat(color,0.05,0.76))
	_box(parent,"BeltBuckle",Vector3(0.18,0.17,0.08),Vector3(0,1.05,0.29),_mat(metal,0.72,0.22))

static func _merchant(p:Node3D)->void:
	var leather:=Color("#a86b3b")
	var dark:=Color("#4a2d20")
	var cream:=Color("#eee1c4")
	var brass:=Color("#d7a84e")
	_face(p,Color("#d59b72"),Color("#e7b94e"))
	_hair(p,Color("#b75b32"))
	_sphere(p,"Beret",0.50,0.25,Vector3(0,2.70,0),_mat(dark,0.0,0.88))
	_box(p,"Tunic",Vector3(0.70,0.68,0.44),Vector3(0,1.43,0),_mat(cream,0.0,0.82))
	_box(p,"LeatherVest",Vector3(0.76,0.54,0.48),Vector3(0,1.48,0.05),_mat(leather,0.12,0.64))
	for side in [-1.0,1.0]:
		_box(p,"Suspender",Vector3(0.08,0.62,0.06),Vector3(side*0.24,1.50,0.29),_mat(dark,0.0,0.72),Vector3(0,0,side*0.12))
		_box(p,"Glove",Vector3(0.20,0.30,0.20),Vector3(side*0.48,1.28,0.02),_mat(dark,0.05,0.82))
	_boot_pair(p,dark,_mat(dark,0.18,0.72))
	_belt(p,Color("#6b2f28"),brass)
	# Coin pouch and brass scale.
	_sphere(p,"CoinPouch",0.16,0.28,Vector3(0.38,1.00,0.32),_mat(Color("#c58b48"),0.05,0.78))
	_torus(p,"Scale",0.12,0.145,Vector3(0.53,1.42,0.34),_mat(brass,0.75,0.22),Vector3(PI*0.5,0,0))
	# Detailed wooden cart.
	var cart:=Node3D.new(); cart.name="MerchantCart"; p.add_child(cart)
	_box(cart,"CartBed",Vector3(1.15,0.30,0.82),Vector3(0,-0.15,-0.62),_mat(Color("#754728"),0.08,0.76))
	for side in [-1.0,1.0]:
		_torus(cart,"CartWheel",0.30,0.38,Vector3(side*0.58,-0.12,-0.63),_mat(Color("#3e2519"),0.05,0.82),Vector3(PI*0.5,0,0))
	_box(cart,"CartRail",Vector3(1.18,0.08,0.08),Vector3(0,0.16,-0.98),_mat(brass,0.55,0.34))
	for i in range(4):
		_sphere(cart,"Potion",0.055,0.16,Vector3(-0.38+i*0.25,0.10,-0.62),_mat(Color("#48a8ff") if i%2==0 else Color("#ef4f4f"),0.05,0.18,Color("#72caff") if i%2==0 else Color("#ff5b5b"),1.8))

static func _acolyte(p:Node3D)->void:
	var white:=Color("#f1eee5")
	var gold:=Color("#e4c56e")
	var blue:=Color("#324d9a")
	_face(p,Color("#f0d8c9"),Color("#637fda"))
	_hair(p,Color("#e7e8ed"))
	_box(p,"HolyRobe",Vector3(0.90,1.20,0.48),Vector3(0,1.26,0),_mat(white,0.02,0.74))
	_box(p,"BlueStole",Vector3(0.20,1.05,0.52),Vector3(0,1.40,0.27),_mat(blue,0.02,0.55))
	_box(p,"GoldCross",Vector3(0.08,0.32,0.04),Vector3(0,1.58,0.56),_mat(gold,0.45,0.20,gold,1.4))
	_box(p,"GoldCrossBar",Vector3(0.22,0.07,0.04),Vector3(0,1.62,0.56),_mat(gold,0.45,0.20,gold,1.4))
	_torus(p,"Halo",0.34,0.39,Vector3(0,2.58,0),_mat(gold,0.35,0.22,gold,2.2),Vector3(PI*0.5,0,0))
	for side in [-1.0,1.0]:
		_box(p,"WideSleeve",Vector3(0.30,0.78,0.36),Vector3(side*0.55,1.43,0),_mat(white,0.02,0.74))
	_boot_pair(p,Color("#e6e0d4"),_mat(Color("#e6e0d4"),0.0,0.85))
	_belt(p,Color("#f7f1de"),gold)
	_cylinder(p,"HolyStaff",0.035,0.045,1.85,Vector3(0.64,1.34,0.05),_mat(Color("#8a5b38"),0.05,0.66))
	_sphere(p,"StaffGem",0.14,0.25,Vector3(0.64,2.27,0.05),_mat(Color("#8ad5ff"),0.10,0.15,Color("#a8e4ff"),2.8))
	_torus(p,"DivineAura",0.52,0.56,Vector3(0,1.10,0),_mat(gold,0.05,0.25,gold,1.8),Vector3(PI*0.5,0,0))

static func _thief(p:Node3D)->void:
	var black:=Color("#1c1c28")
	var purple:=Color("#4b2c5f")
	var steel:=Color("#414858")
	_face(p,Color("#d5c5c2"),Color("#55d48b"))
	_hair(p,Color("#171722"))
	_box(p,"Mask",Vector3(0.48,0.22,0.08),Vector3(0,2.17,0.40),_mat(black,0.0,0.80))
	_box(p,"ShadowChest",Vector3(0.72,0.62,0.40),Vector3(-0.06,1.46,0.02),_mat(purple,0.15,0.66))
	_box(p,"Harness",Vector3(0.10,0.80,0.07),Vector3(-0.23,1.50,0.27),_mat(black,0.0,0.75),Vector3(0,0,-0.25))
	for side in [-1.0,1.0]:
		_box(p,"ArmWrap",Vector3(0.16,0.65,0.18),Vector3(side*0.48,1.40,0.01),_mat(steel,0.0,0.82))
		_box(p,"DaggerSheath",Vector3(0.10,0.46,0.07),Vector3(side*0.30,1.02,-0.28),_mat(black,0.12,0.78),Vector3(0,0,side*0.28))
	_boot_pair(p,black,_mat(black,0.12,0.84))
	_belt(p,black,steel)
	for side in [-1.0,1.0]:
		_cylinder(p,"Dagger",0.025,0.04,0.58,Vector3(side*0.53,1.53,0.12),_mat(Color("#b8c2d0"),0.82,0.20),Vector3(0,0,side*0.18))
	_torus(p,"ShadowSmoke",0.52,0.58,Vector3(0,0.34,0),_mat(Color("#6b3a83"),0.05,0.35,Color("#5e2879"),1.2),Vector3(PI*0.5,0,0))

static func _archer(p:Node3D)->void:
	var green:=Color("#3f7a4d")
	var tan:=Color("#a66f3f")
	var amber:=Color("#c58c3d")
	_face(p,Color("#c9966f"),Color("#6bc35b"))
	_hair(p,Color("#2f805f"))
	_box(p,"Tunic",Vector3(0.70,0.68,0.42),Vector3(0,1.44,0),_mat(green,0.02,0.70))
	_box(p,"ChestGuard",Vector3(0.46,0.45,0.08),Vector3(-0.24,1.53,0.27),_mat(tan,0.08,0.58),Vector3(0,0,-0.10))
	for side in [-1.0,1.0]:
		_box(p,"Bracer",Vector3(0.18,0.56,0.18),Vector3(side*0.50,1.34,0.05),_mat(tan,0.10,0.65))
	_boot_pair(p,Color("#6b4328"),_mat(Color("#6b4328"),0.05,0.78))
	_belt(p,amber,Color("#d9b26c"))
	var bow:=Node3D.new(); bow.name="Greatbow"; p.add_child(bow)
	_torus(bow,"BowArc",0.43,0.49,Vector3(0.68,1.55,0.05),_mat(Color("#8a5b34"),0.15,0.46),Vector3(PI*0.5,0,0))
	_box(bow,"BowGrip",Vector3(0.08,0.20,0.08),Vector3(0.68,1.55,0.05),_mat(Color("#4d3423"),0.0,0.74))
	_box(bow,"BowString",Vector3(0.015,0.80,0.015),Vector3(0.68,1.55,0.05),_mat(Color("#e8dfc7"),0.0,0.70))
	_box(p,"Quiver",Vector3(0.20,0.72,0.20),Vector3(0.47,1.16,-0.26),_mat(tan,0.05,0.66),Vector3(0.18,0,0.12))
	for i in range(5):
		_box(p,"Arrow",Vector3(0.025,0.52,0.025),Vector3(0.42+i*0.025,1.58,-0.26),_mat(Color("#ddd5bf"),0.05,0.52))

static func _mage(p:Node3D)->void:
	var violet:=Color("#4c367f")
	var blue:=Color("#1e2d68")
	var gold:=Color("#d6ad4f")
	_face(p,Color("#ead8d5"),Color("#c36cff"))
	_hair(p,Color("#7456b5"))
	_sphere(p,"WizardHat",0.62,0.24,Vector3(0,2.78,0),_mat(violet,0.0,0.78))
	_cylinder(p,"HatCone",0.05,0.36,0.80,Vector3(0,3.08,0),_mat(violet,0.0,0.78),Vector3(0,0,-0.12))
	_torus(p,"HatBand",0.48,0.53,Vector3(0,2.84,0),_mat(gold,0.42,0.24),Vector3(PI*0.5,0,0))
	_box(p,"ArcaneRobe",Vector3(0.88,1.16,0.50),Vector3(0,1.29,0),_mat(blue,0.04,0.66))
	_box(p,"ShoulderMantle",Vector3(1.02,0.22,0.54),Vector3(0,1.77,0),_mat(violet,0.03,0.60))
	_box(p,"MagentaSash",Vector3(0.88,0.12,0.08),Vector3(0,1.12,0.29),_mat(Color("#a64f9d"),0.02,0.48))
	_boot_pair(p,Color("#2a2145"),_mat(Color("#2a2145"),0.08,0.72))
	_belt(p,Color("#3b2b62"),gold)
	_cylinder(p,"MageStaff",0.035,0.05,1.95,Vector3(0.67,1.38,0.03),_mat(Color("#6d4b36"),0.08,0.62))
	_sphere(p,"ArcaneOrb",0.18,0.32,Vector3(0.67,2.40,0.03),_mat(Color("#b06cff"),0.15,0.12,Color("#b06cff"),4.0))
	_torus(p,"MagicCircle",0.55,0.59,Vector3(0,1.56,0.48),_mat(gold,0.15,0.18,gold,2.2),Vector3(PI*0.5,0,0))

static func _warrior(p:Node3D)->void:
	var steel:=Color("#aeb8c6")
	var dark:=Color("#263650")
	var blue:=Color("#355fa4")
	var gold:=Color("#d4ad58")
	_face(p,Color("#c99578"),Color("#8f9cae"))
	_hair(p,Color("#9f342e"))
	_box(p,"PlateChest",Vector3(0.84,0.70,0.54),Vector3(0,1.45,0),_mat(steel,0.82,0.25))
	_box(p,"RoyalCrest",Vector3(0.22,0.22,0.05),Vector3(0,1.50,0.31),_mat(blue,0.45,0.22,gold,0.6))
	for side in [-1.0,1.0]:
		_sphere(p,"Pauldrons",0.25,0.36,Vector3(side*0.55,1.72,0),_mat(steel,0.80,0.25))
		_box(p,"Gauntlet",Vector3(0.22,0.50,0.24),Vector3(side*0.52,1.32,0),_mat(steel,0.80,0.25))
		_box(p,"Tasset",Vector3(0.26,0.48,0.34),Vector3(side*0.27,0.92,0),_mat(steel,0.78,0.28))
	_boot_pair(p,dark,_mat(steel,0.82,0.28))
	_belt(p,Color("#23304a"),gold)
	_box(p,"BlueCape",Vector3(0.96,1.12,0.10),Vector3(0,1.36,-0.34),_mat(blue,0.04,0.62))
	_cylinder(p,"GreatswordGrip",0.055,0.07,1.10,Vector3(0.70,1.35,0.02),_mat(Color("#26344b"),0.35,0.50))
	_box(p,"GreatswordBlade",Vector3(0.18,1.10,0.06),Vector3(0.70,2.15,0.02),_mat(steel,0.86,0.16))
	_box(p,"SwordGuard",Vector3(0.48,0.08,0.08),Vector3(0.70,1.68,0.02),_mat(gold,0.70,0.20))
	_torus(p,"WarriorAura",0.56,0.61,Vector3(0,0.42,0),_mat(blue,0.12,0.22,Color("#6f9cff"),1.3),Vector3(PI*0.5,0,0))

static func _add_emotion_controller(root:Node3D,key:String,start:float)->void:
	var controller:=Node.new()
	controller.name="ClothingEmotionController"
	root.add_child(controller)
	controller.set_meta("emotion",_emotion_for(key))
	controller.set_meta("time",start)
	controller.set_process(true)
	controller.set_script(_emotion_script())

static func _emotion_for(key:String)->String:
	match key:
		"merchant": return "confident_opportunistic"
		"acolyte": return "serene_benevolent"
		"thief": return "focused_calculating"
		"archer": return "alert_natural"
		"mage": return "aloof_concentrated"
		_: return "fierce_courageous"

static func _emotion_script()->Script:
	return preload("res://scripts/HWClothingEmotion.gd")
