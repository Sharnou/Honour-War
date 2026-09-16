extends Node3D

## Rental-only SS (SUPER SHAMBION) autonomous gameplay controller.
## One authoritative controller owns follow, healing, combat, progression and VFX.
## Combat mutates the same LegacyGame monster state used by the normal game loop.

const FOLLOW_DISTANCE:float = 1.7
const LEGACY_COMBAT_RANGE:float = 180.0
const HEAL_THRESHOLD:float = 0.72
const HEAL_INTERVAL:float = 2.25
const COMBAT_INTERVAL:float = 1.15
const MAX_LEVEL:int = 250
const ASURA_SKILL:String = "Asura Strike"
const PRODUCTION_ASSET:String = "res://assets/3d/generated/ss/SS_SuperShambion.glb"

var ss_visual:Node3D
var elapsed:float = 0.0
var combat_clock:float = 0.0
var heal_clock:float = 0.0
var last_action:String = "Follow"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_sync")

func _process(delta:float) -> void:
	elapsed += delta
	combat_clock += delta
	heal_clock += delta
	_sync()

func _sync() -> void:
	var runtime:Node = get_node_or_null("/root/HWRentalService")
	var scene:Node = get_tree().current_scene
	if runtime == null or scene == null:
		return
	var rented:bool = bool(runtime.call("is_rented"))
	if rented and ss_visual == null:
		_spawn_ss(scene)
	elif not rented and ss_visual != null:
		ss_visual.queue_free()
		ss_visual = null
	if not rented or ss_visual == null:
		return
	var legacy:Node = scene.get_node_or_null("LegacyGame")
	if legacy == null:
		return
	var hero_value:Variant = legacy.get("hero")
	if not hero_value is Dictionary:
		return
	var hero:Dictionary = hero_value
	var data:Dictionary = runtime.call("get_ss")
	if data.is_empty():
		return
	data["age"] = maxi(18,int(hero.get("age",18)))
	var behavior:Dictionary = data.get("behavior",{"follow":true,"heal":true,"fight":true}).duplicate(true)
	var hero_pos:Vector2 = Vector2(float(hero.get("pos_x",595.0)),float(hero.get("pos_y",340.0)))
	var target_pos:Vector3 = _map_to_world(hero_pos) + Vector3(FOLLOW_DISTANCE,0.0,0.8)
	if bool(behavior.get("follow",true)):
		ss_visual.position = ss_visual.position.lerp(target_pos,1.0-exp(-8.0*0.016))
		last_action = "Follow"
	ss_visual.set_meta("behavior",behavior)
	ss_visual.set_meta("skill",ASURA_SKILL)
	ss_visual.set_meta("class","SS (SUPER SHAMBION)")
	ss_visual.set_meta("level",int(data.get("level",0)))
	ss_visual.set_meta("age",int(data.get("age",18)))
	ss_visual.set_meta("hp",int(data.get("hp",data.get("max_hp",100))))
	ss_visual.set_meta("max_hp",int(data.get("max_hp",100)))
	ss_visual.set_meta("ai_action",last_action)
	if bool(behavior.get("heal",true)) and heal_clock >= HEAL_INTERVAL:
		heal_clock = 0.0
		_try_heal(legacy,hero,data)
	if bool(behavior.get("fight",true)) and combat_clock >= COMBAT_INTERVAL:
		combat_clock = 0.0
		_try_fight(legacy,data)

func _try_heal(legacy:Node,hero:Dictionary,data:Dictionary) -> void:
	var hero_max:int = max(1,int(hero.get("max_hp",100)))
	var hero_hp:int = clamp(int(hero.get("hp",hero_max)),0,hero_max)
	var ss_max:int = max(1,int(data.get("max_hp",100)))
	var ss_hp:int = clamp(int(data.get("hp",ss_max)),0,ss_max)
	var stats:Dictionary = data.get("status_points",{}).duplicate(true)
	var vit:int = maxi(0,int(stats.get("VIT",0)))
	var spirit:int = maxi(0,int(stats.get("INT",0)))
	var hero_healed:bool = false
	var self_healed:bool = false
	if float(hero_hp)/float(hero_max) < HEAL_THRESHOLD:
		var hero_amount:int = maxi(12,int(hero_max*0.10)+vit+spirit)
		hero["hp"] = min(hero_max,hero_hp+hero_amount)
		legacy.set("hero",hero)
		hero_healed = true
	if float(ss_hp)/float(ss_max) < HEAL_THRESHOLD:
		var self_amount:int = maxi(16,int(ss_max*0.14)+vit+spirit)
		data["hp"] = min(ss_max,ss_hp+self_amount)
		self_healed = true
	if hero_healed and self_healed:
		last_action = "Heal Hero + Self"
	elif hero_healed:
		last_action = "Heal Hero"
	elif self_healed:
		last_action = "Heal Self"
	if hero_healed or self_healed:
		_store_ss(data)
		if legacy.has_method("log_message"):
			var target_text:String = "Hero" if hero_healed else ""
			if self_healed:
				target_text += " + Self" if hero_healed else "Self"
			legacy.call("log_message","SS automatically healed %s." % target_text)

func _try_fight(legacy:Node,data:Dictionary) -> void:
	var monsters_value:Variant = legacy.get("monsters")
	if not monsters_value is Array:
		return
	var hero_value:Variant = legacy.get("hero")
	if not hero_value is Dictionary:
		return
	var hero:Dictionary = hero_value
	var ss_pos:Vector2 = Vector2(float(hero.get("pos_x",595.0)),float(hero.get("pos_y",340.0)))
	var best_index:int = -1
	var best_distance:float = INF
	for i in monsters_value.size():
		var value:Variant = monsters_value[i]
		if not value is Dictionary:
			continue
		var monster:Dictionary = value
		if int(monster.get("hp",0)) <= 0:
			continue
		var pos_value:Variant = monster.get("pos",Vector2.ZERO)
		if not pos_value is Vector2:
			continue
		var distance:float = ss_pos.distance_to(pos_value)
		if distance <= LEGACY_COMBAT_RANGE and distance < best_distance:
			best_distance = distance
			best_index = i
	if best_index < 0:
		return
	var target:Dictionary = monsters_value[best_index]
	var level:int = clampi(int(data.get("level",0)),0,MAX_LEVEL)
	var stats:Dictionary = data.get("status_points",{}).duplicate(true)
	var strength:int = maxi(0,int(stats.get("STR",0)))
	var dex:int = maxi(0,int(stats.get("DEX",0)))
	var refine:int = maxi(0,int(data.get("refine",0)))
	var damage:int = maxi(25,80+level*6+strength*4+dex*2+refine*5)
	var defense:int = maxi(0,int(target.get("defense",0)))
	damage = maxi(1,damage-defense)
	target["hp"] = maxi(0,int(target.get("hp",0))-damage)
	monsters_value[best_index] = target
	legacy.set("monsters",monsters_value)
	last_action = ASURA_SKILL
	if legacy.has_method("log_message"):
		legacy.call("log_message","SS uses %s for %d damage against Lv.%d %s." % [ASURA_SKILL,damage,int(target.get("level",1)),str(target.get("name","Monster"))])
	_play_skill_vfx(_map_to_world_variant(target.get("pos",ss_pos)),ASURA_SKILL)
	if int(target.get("hp",0)) <= 0:
		var xp:int = maxi(1,int(target.get("exp",100)))
		_grant_ss_progress(data,xp)
		if legacy.has_method("defeat_monster"):
			legacy.call("defeat_monster",target)

func _grant_ss_progress(data:Dictionary,xp_gain:int) -> void:
	var level:int = clampi(int(data.get("level",0)),0,MAX_LEVEL)
	var xp:int = maxi(0,int(data.get("xp",0)))+maxi(1,xp_gain)
	var kills:int = int(data.get("kills",0))+1
	while level < MAX_LEVEL:
		var needed:int = maxi(100,(level+1)*100)
		if xp < needed:
			break
		xp -= needed
		level += 1
	data["level"] = level
	data["xp"] = xp
	data["kills"] = kills
	_store_ss(data)

func _store_ss(data:Dictionary) -> void:
	var runtime:Node = get_node_or_null("/root/HWRentalService")
	if runtime != null and bool(runtime.call("is_rented")):
		runtime.set("ss",data.duplicate(true))

func _play_skill_vfx(position:Vector3,skill_name:String) -> void:
	var vfx:Node = get_node_or_null("/root/HWSkillVFXRuntime")
	if vfx != null and vfx.has_method("play_skill"):
		vfx.call("play_skill",skill_name,ss_visual.global_position,position)

func _spawn_ss(scene:Node) -> void:
	ss_visual = Node3D.new()
	ss_visual.name = "SSSuperShambion"
	ss_visual.add_to_group("ss_companion")
	ss_visual.set_meta("class","SS (SUPER SHAMBION)")
	scene.add_child(ss_visual)
	var production_scene:PackedScene = load(PRODUCTION_ASSET) as PackedScene
	if production_scene != null:
		var authored:Node = production_scene.instantiate()
		ss_visual.add_child(authored)
		authored.position = Vector3.ZERO
		return
	_spawn_development_fallback()

func _spawn_development_fallback() -> void:
	var body:MeshInstance3D = MeshInstance3D.new()
	var capsule:CapsuleMesh = CapsuleMesh.new()
	capsule.radius = 0.62
	capsule.height = 2.15
	body.mesh = capsule
	body.position.y = 1.08
	var material:StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color("#7b1e35")
	material.metallic = 0.25
	material.roughness = 0.45
	body.material_override = material
	ss_visual.add_child(body)
	var head:MeshInstance3D = MeshInstance3D.new()
	var sphere:SphereMesh = SphereMesh.new()
	sphere.radius = 0.48
	sphere.height = 0.96
	head.mesh = sphere
	head.position.y = 2.45
	head.material_override = material
	ss_visual.add_child(head)
	var label:Label3D = Label3D.new()
	label.text = "SS\nSUPER SHAMBION\nAsura Strike"
	label.position = Vector3(0.0,3.25,0.0)
	label.pixel_size = 0.0032
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color("#ffd66b")
	ss_visual.add_child(label)

func _map_to_world(pos:Vector2) -> Vector3:
	return Vector3(pos.x*0.055,0.0,pos.y*0.055)

func _map_to_world_variant(pos_value:Variant) -> Vector3:
	if pos_value is Vector2:
		return _map_to_world(pos_value)
	return ss_visual.global_position if ss_visual != null else Vector3.ZERO
