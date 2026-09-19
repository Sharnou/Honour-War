class_name Game3D
extends Node3D

const TeleportSystemClass=preload("res://scripts/TeleportSystem.gd")

const WORLD_SCALE:float = 0.055
const QUALITY_NAMES:Array[String] = ["LOW", "HIGH", "ULTRA"]
const QUALITY_COUNTS:Array[int] = [14, 24, 36]

var legacy:Node2D
var camera:Camera3D
var world_root:Node3D
var actor_root:Node3D
var hero_visual:Node3D
var pet_visual:Node3D
var monster_visuals:Dictionary = {}
var monster_hp_cache:Dictionary = {}
var live_replication:Node
var remote_visuals:Dictionary = {}
var hud:CanvasLayer
var status_label:Label
var hp_bar:ProgressBar
var sp_bar:ProgressBar
var command_edit:LineEdit
var quality_label:Label
var quality:int = 1
var elapsed:float = 0.0
var last_hero_position:Vector2 = Vector2.ZERO
var facing:Vector2 = Vector2.RIGHT
var last_class:String = ""
var last_pet_species:String = ""

func _ready() -> void:
	legacy = get_node_or_null("LegacyGame")
	camera = get_node_or_null("Camera3D")
	if legacy == null or camera == null:
		push_error("Honour War 3D shell requires LegacyGame and Camera3D.")
		return
	world_root = Node3D.new()
	world_root.name = "World3D"
	add_child(world_root)
	actor_root = Node3D.new()
	actor_root.name = "Actors3D"
	add_child(actor_root)
	live_replication = get_node_or_null("/root/HWLiveWorldReplication")
	_build_lighting()
	_build_world()
	_build_hud()
	_update_visuals(0.0)

func _process(delta:float) -> void:
	elapsed += delta
	if legacy == null:
		return
	_update_visuals(delta)

func _update_visuals(delta:float) -> void:
	var hero_value:Variant = legacy.get("hero")
	if not hero_value is Dictionary:
		return
	var hero:Dictionary = hero_value
	var hero_pos:Vector2 = Vector2(float(hero.get("pos_x",595.0)),float(hero.get("pos_y",340.0)))
	var hero_class:String = str(hero.get("class","Warrior"))
	if hero_visual == null or hero_class != last_class:
		last_class = hero_class
		if hero_visual != null:
			hero_visual.queue_free()
		hero_visual = _create_hero(hero_class)
		actor_root.add_child(hero_visual)
	var hero_name:String = str(hero.get("character_name",hero.get("name","Hero")))
	hero_visual.set_meta("character_name",hero_name)
	hero_visual.set_meta("class",hero_class)
	hero_visual.set_meta("hp",int(hero.get("hp",0)))
	hero_visual.set_meta("max_hp",int(hero.get("max_hp",1)))
	hero_visual.set_meta("sp",int(hero.get("sp",0)))
	hero_visual.set_meta("max_sp",int(hero.get("max_sp",1)))
	var pet_value:Variant = hero.get("pet",{})
	var pet_species:String = "Pet"
	if pet_value is Dictionary:
		pet_species = str(pet_value.get("species","Pet"))
	if pet_visual == null or pet_species != last_pet_species:
		last_pet_species = pet_species
		if pet_visual != null:
			pet_visual.queue_free()
		pet_visual = _create_pet(pet_species)
		actor_root.add_child(pet_visual)
	var production_hero:bool = bool(hero_visual.get_meta("hw_production_asset",false))
	var target:Vector3 = _map_to_world(hero_pos)
	if production_hero:
		# Preserve the GLB-authored root Y while the gameplay transform follows X/Z.
		target.y = hero_visual.position.y
	var previous:Vector3 = hero_visual.position
	var blend:float = 1.0-exp(-16.0*max(delta,0.016))
	hero_visual.position = hero_visual.position.lerp(target,blend)
	var visual_velocity:Vector3 = (hero_visual.position-previous)/max(delta,0.016)
	var move_len:float = visual_velocity.length()
	if move_len > 0.25:
		facing = Vector2(visual_velocity.x,-visual_velocity.z).normalized()
	var yaw:float = atan2(-facing.x,-facing.y)
	hero_visual.rotation.y = lerp_angle(hero_visual.rotation.y,yaw,1.0-exp(-14.0*max(delta,0.016)))
	var gait:float = sin(elapsed*(8.0+min(move_len,8.0)))
	var locomotion:float = clamp(move_len/8.0,0.0,1.0)
	if not production_hero:
		hero_visual.position.y = 0.15+abs(gait)*0.04*locomotion
		hero_visual.scale = Vector3.ONE*(1.0+abs(gait)*0.025*locomotion)
	if pet_visual != null:
		var pet_target:Vector3 = hero_visual.position-fascinate_offset(hero_class)
		pet_visual.position = pet_visual.position.lerp(pet_target,1.0-exp(-8.0*max(delta,0.016)))
		pet_visual.position.y = 0.45+sin(elapsed*4.5)*0.10
		pet_visual.rotation.y = lerp_angle(pet_visual.rotation.y,yaw,0.08)
	_update_monsters(delta)
	_update_remote_players(delta)
	# Camera ownership belongs exclusively to MovementStabilityFix.
	# Do not follow the hero here; that made A/D move the whole screen.
	_update_hud(hero)
	last_hero_position = hero_pos

func fascinate_offset(hero_class:String)->Vector3:
	match hero_class:
		"Mage": return Vector3(1.0,0.0,0.8)
		"Archer": return Vector3(-1.0,0.0,0.8)
		"Thief": return Vector3(0.8,0.0,1.1)
		"Acolyte": return Vector3(-0.9,0.0,1.0)
		"Merchant": return Vector3(-1.1,0.0,0.5)
	return Vector3(-0.9,0.0,0.7)

func _build_lighting() -> void:
	var env_node:WorldEnvironment = WorldEnvironment.new()
	var env:Environment = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#466a7c")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#b6c9d6")
	env.ambient_light_energy = 0.34
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = -0.85
	env.tonemap_white = 1.15
	env_node.environment = env
	add_child(env_node)
	var world:World3D=get_world_3d()
	if world!=null:
		world.environment=env
		world.fallback_environment=env
	# Give the active camera an explicit environment override so multiple legacy
	# WorldEnvironment nodes cannot leave the actual game frame black.
	camera.environment = env
	var sun:DirectionalLight3D = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52.0,-32.0,0.0)
	sun.light_energy = 0.82
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 48.0
	add_child(sun)
	var rim:OmniLight3D = OmniLight3D.new()
	rim.position = Vector3(5.0,6.0,8.0)
	rim.omni_range = 24.0
	rim.light_energy = 0.32
	rim.light_color = Color("#7fc9ff")
	add_child(rim)

func _build_world() -> void:
	var map_center:=Vector3(12.925,0.0,12.65)
	var ground:MeshInstance3D = MeshInstance3D.new()
	var plane:PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(70.0,43.0)
	ground.mesh = plane
	ground.position = map_center-Vector3(0.0,0.05,0.0)
	ground.material_override = _material(Color("#172825"),0.0,0.88)
	world_root.add_child(ground)
	_build_road(map_center,Vector3(9.0,0.10,43.0),Color("#5b4b3e"))
	_build_road(map_center,Vector3(70.0,0.10,6.5),Color("#614f40"))
	_build_road(map_center+Vector3(0.0,0.03,-9.5),Vector3(56.0,0.08,4.2),Color("#725c48"))
	_build_road(map_center+Vector3(-17.0,0.04,6.5),Vector3(4.2,0.08,25.0),Color("#725c48"))
	_build_road(map_center+Vector3(17.0,0.04,6.5),Vector3(4.2,0.08,25.0),Color("#725c48"))
	_build_plaza(map_center+Vector3(0.0,0.08,5.0))
	_build_city_landmarks(map_center)
	_build_environment_objects()

func _build_road(center:Vector3,size:Vector3,color:Color)->void:
	var road:MeshInstance3D=MeshInstance3D.new()
	var mesh:BoxMesh=BoxMesh.new()
	mesh.size=size
	road.mesh=mesh
	road.position=center+Vector3(0.0,-0.01,0.0)
	road.material_override=_material(color,0.0,1.0)
	world_root.add_child(road)

func _build_plaza(center:Vector3)->void:
	var plaza:MeshInstance3D=MeshInstance3D.new()
	var mesh:CylinderMesh=CylinderMesh.new()
	mesh.top_radius=4.8
	mesh.bottom_radius=4.8
	mesh.height=0.16
	plaza.mesh=mesh
	plaza.position=center
	plaza.material_override=_material(Color("#75624d"),0.0,0.92)
	world_root.add_child(plaza)
	var fountain:MeshInstance3D=_ring(Color("#6ecfff"),2.2,0.12)
	fountain.rotation_degrees.x=90.0
	fountain.position=center+Vector3(0.0,0.18,0.0)
	world_root.add_child(fountain)

func _build_city_landmarks(center:Vector3)->void:
	var positions:Array[Vector3]=[center+Vector3(-12.0,2.0,-7.0),center+Vector3(12.0,2.0,-7.0),center+Vector3(-12.0,2.0,13.0),center+Vector3(12.0,2.0,13.0)]
	for i in positions.size():
		var building:MeshInstance3D=MeshInstance3D.new()
		var mesh:BoxMesh=BoxMesh.new()
		mesh.size=Vector3(6.0,4.0,5.0)
		building.mesh=mesh
		building.position=positions[i]
		building.material_override=_material(Color("#6b5547"),0.05,0.76)
		world_root.add_child(building)
		var roof:MeshInstance3D=MeshInstance3D.new()
		var roof_mesh:CylinderMesh=CylinderMesh.new()
		roof_mesh.top_radius=0.0
		roof_mesh.bottom_radius=3.9
		roof_mesh.height=2.3
		roof.mesh=roof_mesh
		roof.position=positions[i]+Vector3(0.0,3.0,0.0)
		roof.material_override=_material(Color("#3b3138"),0.0,0.9)
		world_root.add_child(roof)

func _build_environment_objects() -> void:
	var count:int = QUALITY_COUNTS[quality]
	var trunk_mesh:CylinderMesh = CylinderMesh.new()
	trunk_mesh.top_radius = 0.28
	trunk_mesh.bottom_radius = 0.50
	trunk_mesh.height = 3.2
	var crown_mesh:SphereMesh = SphereMesh.new()
	crown_mesh.radius = 1.45
	crown_mesh.height = 2.9
	var trunk_material:StandardMaterial3D = _material(Color("#49352b"),0.0,1.0)
	var crown_material:StandardMaterial3D = _material(Color("#24533a"),0.0,0.9)
	for i in count:
		var x:float = 3.0+float((i*41)%340)*0.10
		var z:float = -5.5+float((i*29)%210)*0.10
		if Vector2(x-12.925,z-12.65).length()<5.0:
			continue
		var trunk:MeshInstance3D = MeshInstance3D.new()
		trunk.mesh = trunk_mesh
		trunk.material_override = trunk_material
		trunk.position = Vector3(x,1.6,z)
		trunk.scale = Vector3.ONE*(0.85+float(i%3)*0.12)
		world_root.add_child(trunk)
		var crown:MeshInstance3D = MeshInstance3D.new()
		crown.mesh = crown_mesh
		crown.material_override = crown_material
		crown.position = Vector3(x,3.65,z)
		crown.scale = Vector3.ONE*(0.85+float((i+1)%3)*0.11)
		world_root.add_child(crown)

func _create_hero(class_id:String)->Node3D:
	var root:Node3D = Node3D.new()
	root.name = "Hero"
	root.add_to_group("player")
	root.add_to_group("local_player")
	root.set_meta("hw_player",true)
	var hitbox:CollisionShape3D=CollisionShape3D.new()
	var sphere:SphereShape3D=SphereShape3D.new()
	sphere.radius=0.82
	hitbox.shape=sphere
	hitbox.position.y=1.20
	root.add_child(hitbox)

	# Native detailed runtime actor; no GLB dependency.
	var accent:Color = _class_color(class_id)
	var dark:Color = accent.darkened(0.58)
	var metal:Color = accent.lightened(0.28)
	var skin:Color = Color("#e0a27f")
	var hair_color:Color = Color("#24202a")
	var leather:Color = Color("#5a3929")

	var torso:MeshInstance3D = _capsule(Color("#1f2732"),0.39,1.20)
	torso.position.y = 1.04
	root.add_child(torso)
	var coat:MeshInstance3D = _capsule(accent,0.50,0.90)
	coat.position.y = 1.43
	root.add_child(coat)
	var chest:MeshInstance3D = _box(accent.lightened(0.08),Vector3(0.78,0.54,0.58))
	chest.position = Vector3(0,1.48,0.02)
	root.add_child(chest)
	var belt:MeshInstance3D = _box(leather,Vector3(0.86,0.13,0.60))
	belt.position = Vector3(0,1.08,0.02)
	root.add_child(belt)
	var buckle:MeshInstance3D = _box(metal,Vector3(0.16,0.16,0.08))
	buckle.position = Vector3(0,1.08,0.34)
	root.add_child(buckle)

	var leg_l:MeshInstance3D = _capsule(dark,0.18,0.72)
	leg_l.position = Vector3(-0.22,0.39,0)
	root.add_child(leg_l)
	var leg_r:MeshInstance3D = _capsule(dark,0.18,0.72)
	leg_r.position = Vector3(0.22,0.39,0)
	root.add_child(leg_r)
	var boot_l:MeshInstance3D = _box(leather,Vector3(0.32,0.25,0.52))
	boot_l.position = Vector3(-0.22,0.09,0.08)
	root.add_child(boot_l)
	var boot_r:MeshInstance3D = _box(leather,Vector3(0.32,0.25,0.52))
	boot_r.position = Vector3(0.22,0.09,0.08)
	root.add_child(boot_r)

	var arm_l:MeshInstance3D = _capsule(accent,0.16,0.72)
	arm_l.position = Vector3(-0.56,1.34,0)
	arm_l.rotation_degrees.z = -10.0
	root.add_child(arm_l)
	var arm_r:MeshInstance3D = _capsule(accent,0.16,0.72)
	arm_r.position = Vector3(0.56,1.34,0)
	arm_r.rotation_degrees.z = 10.0
	root.add_child(arm_r)
	var glove_l:MeshInstance3D = _sphere(leather,0.17)
	glove_l.position = Vector3(-0.61,1.00,0)
	root.add_child(glove_l)
	var glove_r:MeshInstance3D = _sphere(leather,0.17)
	glove_r.position = Vector3(0.61,1.00,0)
	root.add_child(glove_r)

	var shoulder_l:MeshInstance3D = _sphere(metal,0.25)
	shoulder_l.position = Vector3(-0.55,1.67,0)
	shoulder_l.scale = Vector3(1.20,0.70,1.10)
	root.add_child(shoulder_l)
	var shoulder_r:MeshInstance3D = _sphere(metal,0.25)
	shoulder_r.position = Vector3(0.55,1.67,0)
	shoulder_r.scale = Vector3(1.20,0.70,1.10)
	root.add_child(shoulder_r)
	var collar:MeshInstance3D = _ring(metal,0.27,0.055)
	collar.position.y=1.86
	root.add_child(collar)

	var neck:MeshInstance3D = _cylinder_skin(0.15,0.22,Vector3(0,1.91,0))
	root.add_child(neck)
	var head:MeshInstance3D = _sphere(skin,0.40)
	head.position.y = 2.28
	root.add_child(head)
	var hair:MeshInstance3D = _sphere(hair_color,0.46)
	hair.position = Vector3(0,2.48,-0.03)
	hair.scale = Vector3(1.08,0.68,1.04)
	root.add_child(hair)
	var fringe:MeshInstance3D = _sphere(hair_color,0.27)
	fringe.position = Vector3(0,2.37,0.31)
	fringe.scale = Vector3(1.45,0.52,0.46)
	root.add_child(fringe)
	var eye_l:MeshInstance3D = _sphere(Color("#273142"),0.055)
	eye_l.position = Vector3(-0.14,2.31,0.355)
	root.add_child(eye_l)
	var eye_r:MeshInstance3D = _sphere(Color("#273142"),0.055)
	eye_r.position = Vector3(0.14,2.31,0.355)
	root.add_child(eye_r)
	var eye_glow_l:MeshInstance3D = _sphere(Color("#ffffff"),0.018)
	eye_glow_l.position = Vector3(-0.125,2.325,0.395)
	root.add_child(eye_glow_l)
	var eye_glow_r:MeshInstance3D = _sphere(Color("#ffffff"),0.018)
	eye_glow_r.position = Vector3(0.155,2.325,0.395)
	root.add_child(eye_glow_r)

	match class_id:
		"Mage":
			var mantle:=_ring(accent,0.58,0.08)
			mantle.rotation_degrees.x=90.0
			mantle.position.y=1.55
			root.add_child(mantle)
			var gem:=_sphere(Color("#c8a8ff"),0.13)
			gem.position=Vector3(0,2.70,0.05)
			root.add_child(gem)
		"Archer":
			var quiver:=_box(leather,Vector3(0.24,0.62,0.18))
			quiver.position=Vector3(-0.43,1.32,-0.18)
			root.add_child(quiver)
		"Thief":
			var scarf:=_box(Color("#331d38"),Vector3(0.92,0.12,0.18))
			scarf.position=Vector3(0,1.84,0.25)
			root.add_child(scarf)
		"Acolyte":
			var holy:=_ring(Color("#fff0a3"),0.33,0.045)
			holy.position.y=2.72
			root.add_child(holy)
		"Merchant":
			var satchel:=_box(leather,Vector3(0.34,0.38,0.24))
			satchel.position=Vector3(-0.62,1.18,0.06)
			root.add_child(satchel)

	var weapon:MeshInstance3D = _weapon(class_id,accent)
	weapon.position = Vector3(0.66,1.42,0.04)
	root.add_child(weapon)
	var ring:=_ring(Color("#ffe18a"),0.76,0.045)
	ring.rotation_degrees.x=90.0
	ring.position.y=0.055
	root.add_child(ring)
	var light:OmniLight3D=OmniLight3D.new()
	light.light_color=accent
	light.light_energy=0.42
	light.omni_range=3.2
	light.position=Vector3(0,1.55,0)
	root.add_child(light)
	return root

func _cylinder_skin(radius:float,height:float,pos:Vector3)->MeshInstance3D:
	var node:MeshInstance3D=MeshInstance3D.new()
	var mesh:CylinderMesh=CylinderMesh.new()
	mesh.top_radius=radius
	mesh.bottom_radius=radius
	mesh.height=height
	node.mesh=mesh
	node.position=pos
	node.material_override=_material(Color("#e0a27f"),0.02,0.72)
	return node

func _create_pet(species:String)->Node3D:
	var root:Node3D = Node3D.new()
	root.name = "Pet"
	match species:
		"Royal Falcon":
			var body:MeshInstance3D = _sphere(Color("#a9824c"),0.34)
			body.scale = Vector3(1.3,0.7,0.9)
			root.add_child(body)
			var wing_l:MeshInstance3D = _box(Color("#dbc07d"),Vector3(0.15,0.08,0.95))
			wing_l.rotation_degrees.y = 22.0
			wing_l.position = Vector3(-0.35,0.08,0.0)
			root.add_child(wing_l)
			var wing_r:MeshInstance3D = _box(Color("#dbc07d"),Vector3(0.15,0.08,0.95))
			wing_r.rotation_degrees.y = -22.0
			wing_r.position = Vector3(0.35,0.08,0.0)
			root.add_child(wing_r)
		"Astral Sprite":
			var orb:MeshInstance3D = _sphere(Color("#6bd6ff"),0.44)
			root.add_child(orb)
			var halo:MeshInstance3D = _ring(Color("#b8f2ff"),0.58,0.035)
			halo.rotation_degrees.x = 90.0
			root.add_child(halo)
		"Blessed Poring":
			var poring:MeshInstance3D = _sphere(Color("#ef8fb8"),0.53)
			poring.scale = Vector3(1.12,0.88,1.05)
			root.add_child(poring)
		_:
			var wolf:MeshInstance3D = _sphere(Color("#76818a"),0.48)
			wolf.scale = Vector3(1.2,0.78,1.45)
			root.add_child(wolf)
			var snout:MeshInstance3D = _sphere(Color("#4d5961"),0.25)
			snout.position = Vector3(0.0,0.02,-0.48)
			root.add_child(snout)
	return root

func _update_monsters(delta:float)->void:
	var monsters_value:Variant = legacy.get("monsters")
	if not monsters_value is Array:
		return
	var active:Dictionary = {}
	for item in monsters_value:
		if not item is Dictionary:
			continue
		var monster:Dictionary = item
		var id:String = str(monster.get("visual_id",monster.get("name","monster")))
		active[id] = true
		if not monster_visuals.has(id):
			var visual:Node3D = _create_monster(str(monster.get("name","Monster")),bool(monster.get("mvp",false)))
			monster_visuals[id] = visual
			actor_root.add_child(visual)
		var visual2:Node3D = monster_visuals[id]
		visual2.set_meta("character_name",str(monster.get("name","Monster")))
		visual2.set_meta("hp",int(monster.get("hp",0)))
		visual2.set_meta("max_hp",int(monster.get("max_hp",max(1,int(monster.get("hp",0))))))
		var pos_value:Variant = monster.get("pos",Vector2.ZERO)
		if pos_value is Vector2:
			var target:Vector3 = _map_to_world(pos_value)
			visual2.position = visual2.position.lerp(target,1.0-exp(-10.0*max(delta,0.016)))
		var hp:int = int(monster.get("hp",0))
		var old_hp:int = int(monster_hp_cache.get(id,hp))
		if hp < old_hp:
			_trigger_hit_effect(visual2.global_position,bool(monster.get("mvp",false)))
			visual2.scale = Vector3(1.16,0.82,1.16)
		monster_hp_cache[id] = hp
		visual2.scale = visual2.scale.lerp(Vector3.ONE,1.0-exp(-20.0*max(delta,0.016)))
	for id in monster_visuals.keys():
		if not active.has(id):
			monster_visuals[id].queue_free()
			monster_visuals.erase(id)
			monster_hp_cache.erase(id)

func _trigger_hit_effect(position:Vector3,boss:bool)->void:
	var root:Node3D = Node3D.new()
	root.position = position+Vector3(0.0,0.9,0.0)
	world_root.add_child(root)
	var ring:MeshInstance3D = _ring(Color("#ffcc6e"),0.3 if not boss else 0.55,0.045)
	ring.rotation_degrees.x = 90.0
	root.add_child(ring)
	var light:OmniLight3D = OmniLight3D.new()
	light.light_color = Color("#ff8c55") if not boss else Color("#ffcc55")
	light.light_energy = 4.0 if not boss else 7.0
	light.omni_range = 4.0 if not boss else 7.0
	root.add_child(light)
	var tween:Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring,"scale",Vector3(4.0,4.0,4.0),0.20)
	tween.tween_property(light,"light_energy",0.0,0.20)
	tween.chain().tween_callback(root.queue_free)


func _update_remote_players(delta:float)->void:
	if live_replication == null or not is_instance_valid(live_replication) or actor_root == null:
		return
	var map_id:int = int(hero_data_for_replication().get("map_id",0))
	var values:Variant = live_replication.get_remote_players(map_id)
	if not values is Dictionary:
		return
	var active:Dictionary = {}
	for key:Variant in (values as Dictionary).keys():
		var peer_id:int = int(key)
		var state:Dictionary = (values as Dictionary)[key]
		if peer_id <= 0:
			continue
		var class_id:String = str(state.get("class","Warrior"))
		var level:int = clamp(int(state.get("level",1)),1,250)
		active[peer_id] = true
		if not remote_visuals.has(peer_id):
			var remote:Node3D = _create_remote_player(class_id,level,peer_id)
			remote_visuals[peer_id] = remote
			actor_root.add_child(remote)
		else:
			var existing:Node3D = remote_visuals[peer_id] as Node3D
			if existing == null or not is_instance_valid(existing) or str(existing.get_meta("hw_remote_class","")) != class_id or int(existing.get_meta("hw_remote_level",0)) != level:
				if existing != null and is_instance_valid(existing):
					existing.queue_free()
				var replacement:Node3D = _create_remote_player(class_id,level,peer_id)
				remote_visuals[peer_id] = replacement
				actor_root.add_child(replacement)
		var visual:Node3D = remote_visuals[peer_id] as Node3D
		if visual == null or not is_instance_valid(visual):
			continue
		visual.visible = true
		visual.set_meta("character_name",str(state.get("username","Player")))
		visual.set_meta("class",class_id)
		visual.set_meta("level",level)
		visual.set_meta("hp",int(state.get("hp",0)))
		visual.set_meta("max_hp",max(1,int(state.get("max_hp",1))))
		var target:Vector3 = _map_to_world(Vector2(float(state.get("pos_x",595.0)),float(state.get("pos_y",340.0))))
		var blend:float = 1.0-exp(-18.0*max(delta,0.016))
		visual.position = visual.position.lerp(target,blend)
		var moving_target:Vector3 = target-visual.position
		if moving_target.length_squared()>0.0001:
			visual.rotation.y = atan2(-moving_target.x,-moving_target.z)
	for key:Variant in remote_visuals.keys():
		if not active.has(int(key)):
			var stale:Node = remote_visuals[key] as Node
			if stale != null and is_instance_valid(stale):
				stale.queue_free()
			remote_visuals.erase(key)

func hero_data_for_replication()->Dictionary:
	if legacy == null:
		return {}
	var value:Variant = legacy.get("hero")
	return value if value is Dictionary else {}

func _create_remote_player(class_id:String,level:int,peer_id:int)->Node3D:
	var root:Node3D = _create_hero(class_id)
	root.name = "RemotePlayer_%d" % peer_id
	if root.is_in_group("local_player"):
		root.remove_from_group("local_player")
	root.add_to_group("network_player")
	root.add_to_group("remote_player")
	root.set_meta("hw_network_player",true)
	root.set_meta("hw_remote_player",true)
	root.set_meta("hw_remote_class",class_id)
	root.set_meta("hw_remote_level",level)
	root.set_meta("hw_remote_peer_id",peer_id)
	_try_attach_remote_production_asset(root,class_id,level)
	return root

func _try_attach_remote_production_asset(root:Node3D,class_id:String,level:int)->void:
	var tier:String = "Foundation"
	if level>=200:
		tier="Transcendence"
	elif level>=100:
		tier="Mastery"
	elif level>=50:
		tier="Advanced"
	elif level>=25:
		tier="Specialization"
	var path:String = "res://assets/3d/generated/characters/%s/%s.glb" % [class_id,tier]
	if not ResourceLoader.exists(path):
		return
	var packed:PackedScene = load(path) as PackedScene
	if packed == null:
		return
	var model:Node = packed.instantiate()
	if model == null or not model is Node3D:
		if model != null:
			model.queue_free()
		return
	model.name = "HW_RemoteGeneratedGLB"
	var model_3d := model as Node3D
	_repair_generated_materials(model_3d)
	root.add_child(model)
	for child:Node in root.get_children():
		if child == model:
			continue
		if child is MeshInstance3D:
			(child as MeshInstance3D).visible = false
	root.set_meta("hw_remote_production_asset",true)

func _repair_generated_materials(root:Node3D)->void:
	if root == null:
		return
	for node:Node in root.find_children("*","MeshInstance3D",true,false):
		var mesh_instance := node as MeshInstance3D
		if mesh_instance == null or mesh_instance.mesh == null:
			continue
		for surface:int in mesh_instance.mesh.get_surface_count():
			var material:Material = mesh_instance.get_surface_override_material(surface)
			if material == null:
				material = mesh_instance.mesh.surface_get_material(surface)
			if material == null:
				var fallback := StandardMaterial3D.new()
				fallback.albedo_color = Color("#9aa1aa")
				fallback.metallic = 0.15
				fallback.roughness = 0.58
				mesh_instance.set_surface_override_material(surface,fallback)

func _update_camera(_delta:float)->void:
	return

func _build_hud()->void:
	hud=CanvasLayer.new()
	hud.name="HUD3D"
	add_child(hud)
	var top:Panel=Panel.new()
	top.position=Vector2(18,16)
	top.size=Vector2(650,86)
	hud.add_child(top)
	status_label=Label.new()
	status_label.position=Vector2(16,8)
	status_label.add_theme_font_size_override("font_size",18)
	top.add_child(status_label)
	hp_bar=ProgressBar.new()
	hp_bar.position=Vector2(16,38)
	hp_bar.size=Vector2(250,18)
	top.add_child(hp_bar)
	sp_bar=ProgressBar.new()
	sp_bar.position=Vector2(278,38)
	sp_bar.size=Vector2(190,18)
	top.add_child(sp_bar)
	quality_label=Label.new()
	quality_label.text="Graphics: "+QUALITY_NAMES[quality]+" [F9]"
	quality_label.position=Vector2(482,38)
	top.add_child(quality_label)
	command_edit=LineEdit.new()
	command_edit.position=Vector2(18,638)
	command_edit.size=Vector2(720,38)
	command_edit.placeholder_text="@go 0 | @go Prontera | @go 0 230:230 | @autoloot"
	command_edit.text_submitted.connect(_send_command)
	hud.add_child(command_edit)
	var controls:Label=Label.new()
	controls.text="WASD Move   •   SPACE Attack   •   K Skills   •   1–8 Skills   •   F9 Graphics"
	controls.position=Vector2(760,646)
	hud.add_child(controls)

func _update_hud(hero:Dictionary)->void:
	if status_label==null:
		return
	status_label.text="HONOUR WAR  •  %s  •  Lv.%d  •  %s  •  ONLINE:%s  •  REMOTE:%d  •  FPS %d" % [str(hero.get("name","Hero")),int(hero.get("level",1)),TeleportSystemClass.map_name(int(hero.get("map_id",0))),("CONNECTED" if live_replication != null and multiplayer.has_multiplayer_peer() else "OFFLINE"),(live_replication.get_remote_players(int(hero.get("map_id",0))).size() if live_replication != null and is_instance_valid(live_replication) else 0),Engine.get_frames_per_second()]
	hp_bar.max_value=max(1,int(hero.get("max_hp",1)))
	hp_bar.value=int(hero.get("hp",0))
	sp_bar.max_value=max(1,int(hero.get("max_sp",1)))
	sp_bar.value=int(hero.get("sp",0))

func _send_command(text:String)->void:
	if legacy!=null and legacy.has_method("execute_command"):
		legacy.call("execute_command",text)
		command_edit.clear()

func _unhandled_input(event:InputEvent)->void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_F9:
			quality=(quality+1)%QUALITY_NAMES.size()
			quality_label.text="Graphics: "+QUALITY_NAMES[quality]+" [F9]"
			_add_quality_scenery()

func _add_quality_scenery()->void:
	var old:Node=world_root.get_node_or_null("QualityDecor")
	if old!=null:
		old.queue_free()
	var decor:Node3D=Node3D.new()
	decor.name="QualityDecor"
	world_root.add_child(decor)
	var count:int=QUALITY_COUNTS[quality]/2
	var rock_mesh:SphereMesh=SphereMesh.new()
	rock_mesh.radius=0.38
	rock_mesh.height=0.56
	var rock_material:StandardMaterial3D=_material(Color("#49535a"),0.05,0.95)
	for i in count:
		var rock:MeshInstance3D=MeshInstance3D.new()
		rock.mesh=rock_mesh
		rock.material_override=rock_material
		rock.position=Vector3(2.0+float((i*53)%360)*0.1,0.28,-5.0+float((i*17)%220)*0.1)
		decor.add_child(rock)

func _capsule(color:Color,radius:float,height:float)->MeshInstance3D:
	var node:MeshInstance3D=MeshInstance3D.new()
	var mesh:CapsuleMesh=CapsuleMesh.new()
	mesh.radius=radius
	mesh.height=height
	node.mesh=mesh
	node.material_override=_material(color,0.02,0.78)
	return node

func _sphere(color:Color,radius:float)->MeshInstance3D:
	var node:MeshInstance3D=MeshInstance3D.new()
	var mesh:SphereMesh=SphereMesh.new()
	mesh.radius=radius
	mesh.height=radius*2.0
	node.mesh=mesh
	node.material_override=_material(color,0.02,0.76)
	return node

func _box(color:Color,size:Vector3)->MeshInstance3D:
	var node:MeshInstance3D=MeshInstance3D.new()
	var mesh:BoxMesh=BoxMesh.new()
	mesh.size=size
	node.mesh=mesh
	node.material_override=_material(color,0.10,0.64)
	return node

func _ring(color:Color,radius:float,width:float)->MeshInstance3D:
	var node:MeshInstance3D=MeshInstance3D.new()
	var mesh:TorusMesh=TorusMesh.new()
	mesh.inner_radius=radius
	mesh.outer_radius=radius+width
	node.mesh=mesh
	node.material_override=_material(color,0.25,0.25)
	return node

func _weapon(class_id:String,accent:Color)->MeshInstance3D:
	var node:MeshInstance3D=MeshInstance3D.new()
	if class_id=="Mage":
		var staff:CylinderMesh=CylinderMesh.new()
		staff.top_radius=0.05
		staff.bottom_radius=0.07
		staff.height=1.8
		node.mesh=staff
		node.material_override=_material(Color("#8c6b4f"),0.0,0.85)
		return node
	if class_id=="Archer":
		var bow:TorusMesh=TorusMesh.new()
		bow.inner_radius=0.28
		bow.outer_radius=0.33
		node.mesh=bow
		node.rotation_degrees=Vector3(0.0,90.0,0.0)
		node.material_override=_material(accent,0.0,0.55)
		return node
	var blade:BoxMesh=BoxMesh.new()
	blade.size=Vector3(0.10,1.25,0.22)
	node.mesh=blade
	node.rotation_degrees.z=12.0
	node.material_override=_material(accent,0.15,0.35)
	return node

func _class_color(class_id:String)->Color:
	match class_id:
		"Mage": return Color("#b88cff")
		"Archer": return Color("#8fe08f")
		"Thief": return Color("#ff7eb6")
		"Acolyte": return Color("#fff0a3")
		"Merchant": return Color("#7ed7ff")
	return Color("#e8a34b")

func _create_monster(monster_name:String,mvp:bool)->Node3D:
	var root:Node3D=Node3D.new()
	root.name=monster_name
	root.add_to_group("enemy")
	root.set_meta("hw_enemy",true)
	var hitbox:CollisionShape3D=CollisionShape3D.new()
	var sphere:SphereShape3D=SphereShape3D.new()
	sphere.radius=0.72 if not mvp else 1.05
	hitbox.shape=sphere
	hitbox.position.y=0.9 if not mvp else 1.2
	root.add_child(hitbox)
	var base_color:Color=Color("#8d9aa3")
	var lower:String=monster_name.to_lower()
	if lower.contains("poring"): base_color=Color("#f18bb4")
	elif lower.contains("goblin"): base_color=Color("#79a46a")
	elif lower.contains("wolf"): base_color=Color("#6f7d8a")
	elif lower.contains("skeleton"): base_color=Color("#d4d0bd")
	elif lower.contains("zombie"): base_color=Color("#65816d")
	elif lower.contains("orc"): base_color=Color("#557b4d")
	elif lower.contains("mantis"): base_color=Color("#72a84e")
	elif lower.contains("golem"): base_color=Color("#858c95")
	elif lower.contains("druid"): base_color=Color("#5e6d8d")
	elif lower.contains("dragon"): base_color=Color("#a74f62")
	var scale_factor:float=1.0 if not mvp else 1.55
	var body:MeshInstance3D=_capsule(base_color,0.48*scale_factor,1.25*scale_factor)
	body.position.y=0.78*scale_factor
	root.add_child(body)
	var head:MeshInstance3D=_sphere(base_color.lightened(0.08),0.43*scale_factor)
	head.position.y=1.55*scale_factor
	root.add_child(head)
	var eye_material:StandardMaterial3D=_material(Color("#ffcb55"),0.0,0.25)
	var eye_l:MeshInstance3D=_sphere(Color("#ffcb55"),0.065*scale_factor)
	eye_l.position=Vector3(-0.15,1.58*scale_factor,0.38*scale_factor)
	eye_l.material_override=eye_material
	root.add_child(eye_l)
	var eye_r:MeshInstance3D=_sphere(Color("#ffcb55"),0.065*scale_factor)
	eye_r.position=Vector3(0.15,1.58*scale_factor,0.38*scale_factor)
	eye_r.material_override=eye_material
	root.add_child(eye_r)
	if mvp:
		var aura:MeshInstance3D=_ring(Color("#ffd66e"),0.90*scale_factor,0.045)
		aura.rotation_degrees.x=90.0
		aura.position.y=0.08
		root.add_child(aura)
		var boss_light:OmniLight3D=OmniLight3D.new()
		boss_light.light_color=Color("#ffbc53")
		boss_light.light_energy=1.3
		boss_light.omni_range=3.5
		boss_light.position.y=1.1*scale_factor
		root.add_child(boss_light)
	return root

func _material(color:Color,metallic:float,roughness:float)->StandardMaterial3D:
	var material:StandardMaterial3D=StandardMaterial3D.new()
	material.albedo_color=color
	material.metallic=metallic
	material.roughness=roughness
	return material

func _map_to_world(map_position:Vector2)->Vector3:
	return Vector3((map_position.x-365.0)*WORLD_SCALE,0.0,(map_position.y-120.0)*WORLD_SCALE)
