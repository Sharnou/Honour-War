class_name Game3D
extends Node3D

const WORLD_BOUNDS:Rect2 = Rect2(0.0,0.0,742.0,300.0)
const WORLD_SCALE:float = 0.055

var legacy:Node
var camera:Camera3D
var hero_root:Node3D
var pet_root:Node3D
var monster_roots:Dictionary = {}
var scenery_root:Node3D
var effects_root:Node3D
var hud:CanvasLayer
var status_label:Label
var hp_bar:ProgressBar
var sp_bar:ProgressBar
var command:LineEdit
var time:float = 0.0
var previous_hero_pos:Vector2 = Vector2.ZERO
var previous_monster_hp:Dictionary = {}
var hero_motion:Vector3 = Vector3.ZERO
var quality:int = 1

const QUALITY_NAMES:Array[String] = ["LOW", "HIGH", "ULTRA"]
const QUALITY_PARTS:Array[int] = [18, 30, 42]

func _ready() -> void:
	legacy = get_node_or_null("LegacyGame")
	camera = get_node_or_null("Camera3D")
	if legacy == null or camera == null:
		push_error("Game3D requires LegacyGame and Camera3D nodes.")
		return
	_build_world()
	_build_actor_visuals()
	_build_hud()
	_update_from_legacy(0.0)

func _process(delta:float) -> void:
	time += delta
	if legacy == null:
		return
	_update_from_legacy(delta)
	queue_redraw()

func _build_world() -> void:
	scenery_root = Node3D.new()
	scenery_root.name = "Scenery"
	add_child(scenery_root)
	effects_root = Node3D.new()
	effects_root.name = "Effects"
	add_child(effects_root)
	var ground:MeshInstance3D = MeshInstance3D.new()
	var plane:PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(42.0,18.0)
	ground.mesh = plane
	ground.material_override = _material(Color("#17262a"),0.0,0.85)
	ground.position = Vector3(20.4,0.0,8.2)
	scenery_root.add_child(ground)
	_add_map_decor()
	var world_env:WorldEnvironment = WorldEnvironment.new()
	var env:Environment = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#09131c")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#b9c8d6")
	env.ambient_light_energy = 0.62
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_env.environment = env
	add_child(world_env)
	var sun:DirectionalLight3D = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48.0,-28.0,0.0)
	sun.light_energy = 1.35
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 55.0
	add_child(sun)
	var fill:OmniLight3D = OmniLight3D.new()
	fill.position = Vector3(20.0,7.0,8.0)
	fill.omni_range = 30.0
	fill.light_energy = 3.0
	fill.light_color = Color("#79b7d6")
	add_child(fill)

func _add_map_decor() -> void:
	var tree_mesh:Mesh = CylinderMesh.new()
	(tree_mesh as CylinderMesh).top_radius = 0.35
	(tree_mesh as CylinderMesh).bottom_radius = 0.55
	(tree_mesh as CylinderMesh).height = 3.4
	var tree_mat:StandardMaterial3D = _material(Color("#3c2d25"),0.0,1.0)
	var crown_mesh:Mesh = SphereMesh.new()
	(crown_mesh as SphereMesh).radius = 1.7
	(crown_mesh as SphereMesh).height = 3.4
	var crown_mat:StandardMaterial3D = _material(Color("#173f32"),0.0,0.95)
	for i in QUALITY_PARTS[quality]:
		var x:float = 1.0 + float((i * 37) % 390) * 0.10
		var z:float = -7.0 + float((i * 23) % 230) * 0.10
		if abs(x-20.0)<3.5 and abs(z-8.0)<2.5:
			continue
		var trunk:MeshInstance3D = MeshInstance3D.new()
		trunk.mesh = tree_mesh
		trunk.material_override = tree_mat
		trunk.position = Vector3(x,1.7,z)
		trunk.scale = Vector3.ONE * (0.75 + float(i % 4) * 0.10)
		scenery_root.add_child(trunk)
		var crown:MeshInstance3D = MeshInstance3D.new()
		crown.mesh = crown_mesh
		crown.material_override = crown_mat
		crown.position = Vector3(x,4.0,z)
		crown.scale = Vector3.ONE * (0.85 + float(i % 3) * 0.10)
		scenery_root.add_child(crown)
	var ring_mesh:TorusMesh = TorusMesh.new()
	ring_mesh.inner_radius = 2.3
	ring_mesh.outer_radius = 2.36
	var ring:MeshInstance3D = MeshInstance3D.new()
	ring.mesh = ring_mesh
	ring.material_override = _material(Color("#3b83a4"),0.0,0.55)
	ring.position = Vector3(20.0,0.04,8.2)
	ring.rotation_degrees.x = -90.0
	scenery_root.add_child(ring)

func _build_actor_visuals() -> void:
	hero_root = Node3D.new()
	hero_root.name = "Hero3D"
	add_child(hero_root)
	pet_root = Node3D.new()
	pet_root.name = "Pet3D"
	add_child(pet_root)
	_build_hero_model()
	_build_pet_model()

func _clear_node(node:Node3D) -> void:
	for child in node.get_children():
		child.queue_free()

func _build_hero_model() -> void:
	_clear_node(hero_root)
	if legacy == null:
		return
	var hero_value:Variant = legacy.get("hero")
	if not hero_value is Dictionary:
		return
	var hero:Dictionary = hero_value
	var class_id:String = str(hero.get("class","Warrior"))
	var accent:Color = _class_color(class_id)
	var body:MeshInstance3D = _capsule(Color("#202631"),0.42,1.45)
	body.position = Vector3(0.0,1.05,0.0)
	hero_root.add_child(body)
	var armor:MeshInstance3D = _capsule(accent,0.50,0.92)
	armor.position = Vector3(0.0,1.48,0.0)
	hero_root.add_child(armor)
	var head:MeshInstance3D = _sphere(Color("#d6a47d"),0.40)
	head.position = Vector3(0.0,2.35,0.0)
	hero_root.add_child(head)
	var hair:MeshInstance3D = _sphere(Color("#30262a"),0.43)
	hair.position = Vector3(0.0,2.55,0.0)
	hair.scale = Vector3(1.05,0.55,1.05)
	hero_root.add_child(hair)
	var weapon:MeshInstance3D = _weapon_mesh(class_id,accent)
	weapon.position = Vector3(0.72,1.45,0.0)
	weapon.rotation_degrees = Vector3(0.0,0.0,-18.0)
	hero_root.add_child(weapon)

func _build_pet_model() -> void:
	_clear_node(pet_root)
	if legacy == null:
		return
	var hero_value:Variant = legacy.get("hero")
	if not hero_value is Dictionary:
		return
	var hero:Dictionary = hero_value
	var pet_value:Variant = hero.get("pet",{})
	if not pet_value is Dictionary:
		return
	var pet:Dictionary = pet_value
	var species:String = str(pet.get("species","Dire Wolf"))
	if species == "Royal Falcon":
		var body:MeshInstance3D = _sphere(Color("#b18d53"),0.35)
		body.scale = Vector3(1.2,0.65,0.8)
		body.position = Vector3.ZERO
		pet_root.add_child(body)
		for side in [-1.0,1.0]:
			var wing:MeshInstance3D = _wing(Color("#d9bc80"))
			wing.position = Vector3(0.0,0.08,0.55*side)
			wing.rotation_degrees = Vector3(0.0,0.0,-16.0*side)
			pet_root.add_child(wing)
	elif species == "Astral Sprite":
		var orb:MeshInstance3D = _sphere(Color("#69cfff"),0.48)
		pet_root.add_child(orb)
		for i in 3:
			var mote:MeshInstance3D = _sphere(Color("#b9f2ff"),0.09)
			var a:float = float(i) * TAU/3.0
			mote.position = Vector3(cos(a)*0.75,0.15+sin(a*2.0)*0.18,sin(a)*0.75)
			pet_root.add_child(mote)
	elif species == "Blessed Poring":
		var poring:MeshInstance3D = _sphere(Color("#f28db7"),0.58)
		poring.scale = Vector3(1.15,0.9,1.05)
		pet_root.add_child(poring)
	else:
		var wolf:MeshInstance3D = _capsule(Color("#5b6070"),0.48,0.95)
		wolf.scale = Vector3(1.1,0.85,1.45)
		wolf.position = Vector3.ZERO
		pet_root.add_child(wolf)
		var muzzle:MeshInstance3D = _sphere(Color("#343743"),0.30)
		muzzle.position = Vector3(0.0,0.15,0.58)
		muzzle.scale = Vector3(1.0,0.75,1.2)
		pet_root.add_child(muzzle)

func _update_from_legacy(delta:float) -> void:
	var hero_value:Variant = legacy.get("hero")
	if not hero_value is Dictionary:
		return
	var hero:Dictionary = hero_value
	var current:Vector2 = Vector2(float(hero.get("pos_x",595.0)),float(hero.get("pos_y",340.0)))
	var visual_target:Vector3 = _world_from_map(current)
	var old_hero:Vector3 = hero_root.position
	hero_root.position = hero_root.position.lerp(visual_target,1.0-exp(-14.0*max(delta,0.016)))
	hero_motion = (hero_root.position-old_hero)/max(delta,0.016)
	var facing:Vector2 = Vector2(1.0,0.0)
	var last_value:Variant = hero.get("last_move_direction",Vector2.ZERO)
	if last_value is Vector2 and last_value.length()>0.05:
		facing = last_value.normalized()
	var target_yaw:float = atan2(-facing.x,-facing.y)
	hero_root.rotation.y = lerp_angle(hero_root.rotation.y,target_yaw,1.0-exp(-12.0*max(delta,0.016)))
	var move_speed:float = hero_motion.length()
	var phase:float = time*(8.0+min(move_speed,12.0))
	var stride:float = sin(phase)*min(0.12,move_speed*0.012)
	hero_root.scale.y = 1.0+abs(stride)*0.35
	hero_root.position.y = visual_target.y+abs(stride)*0.18
	pet_root.position = hero_root.position+Vector3(-0.9,0.15,0.65)
	pet_root.position.y += sin(time*4.2)*0.08
	_update_monsters()
	_update_hud(hero)

func _update_monsters() -> void:
	var monsters_value:Variant = legacy.get("monsters")
	if not monsters_value is Array:
		return
	var alive_ids:Dictionary = {}
	for item in monsters_value:
		if not item is Dictionary:
			continue
		var monster:Dictionary = item
		var id:String = str(monster.get("visual_id",monster.get("name","monster")))
		alive_ids[id] = true
		if not monster_roots.has(id):
			var root:Node3D = _make_monster(monster)
			monster_roots[id] = root
			add_child(root)
		var root2:Node3D = monster_roots[id]
		var pos_value:Variant = monster.get("pos",Vector2.ZERO)
		if pos_value is Vector2:
			var target:Vector3 = _world_from_map(pos_value)
			root2.position = root2.position.lerp(target,0.20)
		var hp:int = int(monster.get("hp",0))
		var old_hp:int = int(previous_monster_hp.get(id,hp))
		if hp<old_hp:
			root2.scale = Vector3(1.12,0.88,1.12)
		previous_monster_hp[id] = hp
		root2.scale = root2.scale.lerp(Vector3.ONE,0.16)
	for id in monster_roots.keys():
		if not alive_ids.has(id):
			monster_roots[id].queue_free()
			monster_roots.erase(id)
			previous_monster_hp.erase(id)

func _update_hud(hero:Dictionary) -> void:
	if hud == null:
		return
	status_label.text = "HONOUR WAR  •  %s  •  Lv.%d  •  %s  •  FPS %d" % [str(hero.get("name","Hero")),int(hero.get("level",1)),_map_name(int(hero.get("map_id",0))),Engine.get_frames_per_second()]
	hp_bar.max_value = int(hero.get("max_hp",1))
	hp_bar.value = int(hero.get("hp",0))
	sp_bar.max_value = int(hero.get("max_sp",1))
	sp_bar.value = int(hero.get("sp",0))
	var pet_value:Variant = hero.get("pet",{})
	var pet_name:String = str(pet_value.get("name","Pet")) if pet_value is Dictionary else "Pet"
	$status_hint(pet_name)

func $status_hint(pet_name:String) -> void:
	if not is_instance_valid(command):
		return
	command.placeholder_text = "@go 0 | @go Prontera | @go 0 230:230  | Pet: " + pet_name

func _build_hud() -> void:
	hud = CanvasLayer.new()
	hud.name = "HUD3D"
	add_child(hud)
	var top:Panel = Panel.new()
	top.position = Vector2(18,16)
	top.size = Vector2(620,92)
	hud.add_child(top)
	status_label = Label.new()
	status_label.position = Vector2(18,10)
	status_label.add_theme_font_size_override("font_size",20)
	top.add_child(status_label)
	hp_bar = ProgressBar.new()
	hp_bar.position = Vector2(18,42)
	hp_bar.size = Vector2(260,18)
	hp_bar.show_percentage = true
	top.add_child(hp_bar)
	sp_bar = ProgressBar.new()
	sp_bar.position = Vector2(290,42)
	sp_bar.size = Vector2(200,18)
	sp_bar.show_percentage = true
	top.add_child(sp_bar)
	var quality_label:Label = Label.new()
	quality_label.text = "F9 Graphics: " + QUALITY_NAMES[quality]
	quality_label.position = Vector2(500,42)
	top.add_child(quality_label)
	command = LineEdit.new()
	command.position = Vector2(18,620)
	command.size = Vector2(680,40)
	command.placeholder_text = "@go 0 | @go Prontera | @go 0 230:230"
	command.text_submitted.connect(_send_command)
	hud.add_child(command)
	var skills:Label = Label.new()
	skills.text = "1–8 Skills   •   SPACE Attack   •   K Skills   •   F9 Quality"
	skills.position = Vector2(720,628)
	hud.add_child(skills)

func _send_command(text:String) -> void:
	if legacy!=null and legacy.has_method("execute_command"):
		legacy.call("execute_command",text)
		command.clear()

func _unhandled_input(event:InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_F9:
		quality=(quality+1)%QUALITY_NAMES.size()
		_add_map_quality()

func _add_map_quality() -> void:
	if scenery_root==null:
		return
	for child in scenery_root.get_children():
		if child.name.begins_with("QualityTree"):
			child.queue_free()
	var count:int = QUALITY_PARTS[quality]
	for i in count:
		var tree:MeshInstance3D = MeshInstance3D.new()
		tree.name = "QualityTree%d" % i
		var crown:SphereMesh = SphereMesh.new()
		crown.radius = 1.25
		crown.height = 2.6
		tree.mesh = crown
		tree.material_override = _material(Color("#1f5a41"),0.0,0.9)
		tree.position = Vector3(4.0+float((i*47)%330)*0.1,2.2,-6.5+float((i*29)%210)*0.1)
		scenery_root.add_child(tree)

func _make_monster(monster:Dictionary) -> Node3D:
	var root:Node3D = Node3D.new()
	var name:String = str(monster.get("name","Monster"))
	var accent:Color = Color("#8f9aaa")
	match name:
		"Orc": accent=Color("#648f3f")
		"Wolf": accent=Color("#657080")
		"Dragon": accent=Color("#b84b40")
		"Golem": accent=Color("#8b7560")
		"Mantis": accent=Color("#6a9a52")
		"Poring": accent=Color("#e17ba5")
	var body:MeshInstance3D = _capsule(accent,0.55,1.0)
	body.position.y=0.78
	root.add_child(body)
	var head:MeshInstance3D = _sphere(accent.lightened(0.08),0.46)
	head.position.y=1.72
	root.add_child(head)
	var eye1:MeshInstance3D = _sphere(Color("#f8d764"),0.07)
	eye1.position=Vector3(-0.16,1.77,0.38)
	root.add_child(eye1)
	var eye2:MeshInstance3D = _sphere(Color("#f8d764"),0.07)
	eye2.position=Vector3(0.16,1.77,0.38)
	root.add_child(eye2)
	return root

func _capsule(color:Color,radius:float,height:float) -> MeshInstance3D:
	var node:MeshInstance3D = MeshInstance3D.new()
	var mesh:CapsuleMesh = CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	node.mesh = mesh
	node.material_override = _material(color,0.05,0.78)
	return node

func _sphere(color:Color,radius:float) -> MeshInstance3D:
	var node:MeshInstance3D = MeshInstance3D.new()
	var mesh:SphereMesh = SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius*2.0
	node.mesh = mesh
	node.material_override = _material(color,0.02,0.72)
	return node

func _wing(color:Color) -> MeshInstance3D:
	var node:MeshInstance3D = MeshInstance3D.new()
	var mesh:BoxMesh = BoxMesh.new()
	mesh.size = Vector3(1.0,0.08,0.7)
	node.mesh = mesh
	node.material_override = _material(color,0.0,0.5)
	return node

func _weapon_mesh(class_id:String,accent:Color) -> MeshInstance3D:
	var node:MeshInstance3D = MeshInstance3D.new()
	if class_id=="Mage":
		var staff:CylinderMesh = CylinderMesh.new()
		staff.top_radius=0.06
		staff.bottom_radius=0.08
		staff.height=2.2
		node.mesh=staff
		node.material_override=_material(Color("#6d4932"),0.0,0.9)
	else:
		var blade:BoxMesh=BoxMesh.new()
		blade.size=Vector3(0.10,1.65,0.24)
		node.mesh=blade
		node.material_override=_material(Color("#d7dce5"),0.65,0.32)
	return node

func _material(color:Color,metallic:float,roughness:float)->StandardMaterial3D:
	var material:StandardMaterial3D=StandardMaterial3D.new()
	material.albedo_color=color
	material.metallic=metallic
	material.roughness=roughness
	return material

func _class_color(class_id:String)->Color:
	match class_id:
		"Warrior": return Color("#d39743")
		"Mage": return Color("#8c72e8")
		"Archer": return Color("#65b879")
		"Thief": return Color("#c05d8e")
		"Acolyte": return Color("#e8d46f")
		"Merchant": return Color("#5ba5c4")
	return Color("#d9e1ea")

func _world_from_map(pos:Vector2)->Vector3:
	var x:float=(pos.x-365.0)*WORLD_SCALE
	var z:float=(pos.y-120.0)*WORLD_SCALE
	return Vector3(x,0.0,z)

func _map_name(map_id:int)->String:
	if TeleportSystem.MAPS.has(map_id):
		return str(TeleportSystem.MAPS[map_id].get("name","Unknown"))
	return "Unknown"
