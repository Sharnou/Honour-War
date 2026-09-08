class_name Game3D
extends Node3D

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
	var target:Vector3 = _map_to_world(hero_pos)
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
	hero_visual.position.y = 0.15+abs(gait)*0.04*locomotion
	hero_visual.scale = Vector3.ONE*(1.0+abs(gait)*0.025*locomotion)
	if pet_visual != null:
		var pet_target:Vector3 = hero_visual.position-fascinate_offset(hero_class)
		pet_visual.position = pet_visual.position.lerp(pet_target,1.0-exp(-8.0*max(delta,0.016)))
		pet_visual.position.y = 0.45+sin(elapsed*4.5)*0.10
		pet_visual.rotation.y = lerp_angle(pet_visual.rotation.y,yaw,0.08)
	_update_monsters(delta)
	_update_camera(delta)
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
	env.background_color = Color("#07111b")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#b6c9d6")
	env.ambient_light_energy = 0.72
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env_node.environment = env
	add_child(env_node)
	var sun:DirectionalLight3D = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52.0,-32.0,0.0)
	sun.light_energy = 1.55
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 48.0
	add_child(sun)
	var rim:OmniLight3D = OmniLight3D.new()
	rim.position = Vector3(5.0,6.0,8.0)
	rim.omni_range = 24.0
	rim.light_energy = 2.8
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
		if abs(x-20.4)<4.2 and abs(z-8.2)<3.0:
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
	var accent:Color = _class_color(class_id)
	var body:MeshInstance3D = _capsule(Color("#252a32"),0.38,1.35)
	body.position.y = 1.0
	root.add_child(body)
	var coat:MeshInstance3D = _capsule(accent,0.49,0.88)
	coat.position.y = 1.45
	root.add_child(coat)
	var head:MeshInstance3D = _sphere(Color("#d6a27d"),0.38)
	head.position.y = 2.28
	root.add_child(head)
	var hair:MeshInstance3D = _sphere(Color("#2a2328"),0.43)
	hair.position = Vector3(0.0,2.47,-0.03)
	hair.scale = Vector3(1.03,0.60,1.03)
	root.add_child(hair)
	var shoulder_l:MeshInstance3D = _box(accent,Vector3(0.27,0.22,0.42))
	shoulder_l.position = Vector3(-0.51,1.63,0.0)
	root.add_child(shoulder_l)
	var shoulder_r:MeshInstance3D = _box(accent,Vector3(0.27,0.22,0.42))
	shoulder_r.position = Vector3(0.51,1.63,0.0)
	root.add_child(shoulder_r)
	var weapon:MeshInstance3D = _weapon(class_id,accent)
	weapon.position = Vector3(0.66,1.43,0.0)
	root.add_child(weapon)
	var light:OmniLight3D = OmniLight3D.new()
	light.light_color = accent
	light.light_energy = 0.85
	light.omni_range = 2.8
	light.position = Vector3(0.0,1.6,0.0)
	root.add_child(light)
	return root

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
			var wolf:MeshInstance3D = _capsule(Color("#5d6472"),0.46,0.95)
			wolf.scale = Vector3(1.15,0.8,1.35)
			root.add_child(wolf)
			var muzzle:MeshInstance3D = _sphere(Color("#323742"),0.27)
			muzzle.position = Vector3(0.0,0.17,0.55)
			muzzle.scale = Vector3(1.0,0.72,1.2)
			root.add_child(muzzle)
	return root

func _create_monster(name:String,mvp:bool)->Node3D:
	var root:Node3D = Node3D.new()
	root.name = "Monster_"+name
	var base_color:Color = _monster_color(name)
	var scale_factor:float = 1.28 if mvp else 1.0
	var body:MeshInstance3D = _capsule(base_color,0.48*scale_factor,1.0*scale_factor)
	body.position.y = 0.76*scale_factor
	root.add_child(body)
	var head:MeshInstance3D = _sphere(base_color.lightened(0.08),0.43*scale_factor)
	head.position.y = 1.55*scale_factor
	root.add_child(head)
	var eye_material:StandardMaterial3D = _material(Color("#ffcb55"),0.0,0.25)
	var eye_l:MeshInstance3D = _sphere(Color("#ffcb55"),0.065*scale_factor)
	eye_l.position = Vector3(-0.15,1.58*scale_factor,0.38*scale_factor)
	eye_l.material_override = eye_material
	root.add_child(eye_l)
	var eye_r:MeshInstance3D = _sphere(Color("#ffcb55"),0.065*scale_factor)
	eye_r.position = Vector3(0.15,1.58*scale_factor,0.38*scale_factor)
	eye_r.material_override = eye_material
	root.add_child(eye_r)
	if mvp:
		var aura:MeshInstance3D = _ring(Color("#ffd66e"),0.90*scale_factor,0.045)
		aura.rotation_degrees.x = 90.0
		aura.position.y = 0.08
		root.add_child(aura)
		var boss_light:OmniLight3D = OmniLight3D.new()
		boss_light.light_color = Color("#ffbc53")
		boss_light.light_energy = 1.3
		boss_light.omni_range = 3.5
		boss_light.position.y = 1.1*scale_factor
		root.add_child(boss_light)
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

func _update_camera(delta:float)->void:
	if camera == null or hero_visual == null:
		return
	var desired:Vector3 = hero_visual.position+Vector3(0.0,10.5,13.5)
	camera.position = camera.position.lerp(desired,1.0-exp(-7.0*max(delta,0.016)))
	camera.look_at(hero_visual.position+Vector3(0.0,0.8,0.0),Vector3.UP)

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
	status_label.text="HONOUR WAR  •  %s  •  Lv.%d  •  %s  •  FPS %d" % [str(hero.get("name","Hero")),int(hero.get("level",1)),TeleportSystem.map_name(int(hero.get("map_id",0))),Engine.get_frames_per_second()]
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
		staff.top_radius=0.055
		staff.bottom_radius=0.075
		staff.height=2.1
		node.mesh=staff
		node.material_override=_material(Color("#765238"),0.0,0.85)
	else:
		var blade:BoxMesh=BoxMesh.new()
		blade.size=Vector3(0.10,1.65,0.22)
		node.mesh=blade
		node.material_override=_material(Color("#dce5ef"),0.65,0.28)
	return node

func _material(color:Color,metallic:float,roughness:float)->StandardMaterial3D:
	var material:StandardMaterial3D=StandardMaterial3D.new()
	material.albedo_color=color
	material.metallic=metallic
	material.roughness=roughness
	return material

func _class_color(class_id:String)->Color:
	match class_id:
		"Warrior": return Color("#d59a43")
		"Mage": return Color("#8c70e7")
		"Archer": return Color("#68ba7a")
		"Thief": return Color("#c45a8e")
		"Acolyte": return Color("#e4d16b")
		"Merchant": return Color("#57a8c8")
	return Color("#d6dfe8")

func _monster_color(name:String)->Color:
	match name:
		"Orc": return Color("#638d3e")
		"Wolf": return Color("#667180")
		"Dragon": return Color("#ad4c42")
		"Golem": return Color("#8f7660")
		"Mantis": return Color("#6c9f54")
		"Poring": return Color("#e47fa8")
		"Skeleton": return Color("#bdb6a6")
		"Zombie": return Color("#637a63")
		"Evil Druid": return Color("#8066a0")
	return Color("#83909d")

func _map_to_world(pos:Vector2)->Vector3:
	return Vector3((pos.x-365.0)*WORLD_SCALE,0.0,(pos.y-120.0)*WORLD_SCALE)

func _draw()->void:
	pass
