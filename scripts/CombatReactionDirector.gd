class_name CombatReactionDirector
extends Node3D

const WORLD_SCALE:float=0.055
var game:Node3D
var legacy:Node2D
var monster_hp:Dictionary={}
var hero_hp:int=-1
var pet_hp:int=-1
var effects:Array[Dictionary]=[]
var elapsed:float=0.0

func _ready()->void:
	game=get_parent() as Node3D
	legacy=game.get_node_or_null("LegacyGame") if game!=null else null
	call_deferred("_prime")
	set_process(true)

func _prime()->void:
	if legacy==null: return
	var h:Variant=legacy.get("hero")
	if h is Dictionary:
		hero_hp=int(h.get("hp",0))
		var p:Variant=h.get("pet",{})
		if p is Dictionary: pet_hp=int(p.get("hp",0))

func _process(delta:float)->void:
	elapsed+=delta
	if game==null or legacy==null: return
	_update_combat_reactions()
	_update_effects(delta)

func _update_combat_reactions()->void:
	var hero_value:Variant=legacy.get("hero")
	if not hero_value is Dictionary: return
	var hero:Dictionary=hero_value
	var current_hero_hp:=int(hero.get("hp",0))
	if hero_hp>=0 and current_hero_hp<hero_hp:
		var amount:=hero_hp-current_hero_hp
		_spawn_impact(_map_to_world(Vector2(float(hero.get("pos_x",595.0)),float(hero.get("pos_y",340.0)))),amount,true,false)
	hero_hp=current_hero_hp
	var pet_value:Variant=hero.get("pet",{})
	if pet_value is Dictionary:
		var pet:Dictionary=pet_value
		var current_pet_hp:=int(pet.get("hp",0))
		if pet_hp>=0 and current_pet_hp<pet_hp:
			var amount:=pet_hp-current_pet_hp
			var hero_pos:=Vector2(float(hero.get("pos_x",595.0)),float(hero.get("pos_y",340.0)))
			_spawn_impact(_map_to_world(hero_pos)+Vector3(0.0,0.35,1.1),amount,false,true)
		pet_hp=current_pet_hp
	var monsters_value:Variant=legacy.get("monsters")
	if not monsters_value is Array: return
	var active:Dictionary={}
	var visuals:Dictionary=game.get("monster_visuals") as Dictionary
	for item in monsters_value:
		if not item is Dictionary: continue
		var monster:Dictionary=item
		var id:=str(monster.get("visual_id",monster.get("name","monster")))
		active[id]=true
		var hp:=int(monster.get("hp",0))
		if not monster_hp.has(id):
			monster_hp[id]=hp
			continue
		if hp<int(monster_hp[id]) and visuals.has(id):
			var map_pos:Vector2=monster.get("pos",Vector2.ZERO)
			var critical:bool=bool(monster.get("hit_critical",false))
			_spawn_impact(_map_to_world(map_pos)+Vector3(0.0,0.35,0.0),int(monster_hp[id])-hp,false,false,critical)
		monster_hp[id]=hp
	for id in monster_hp.keys():
		if not active.has(id): monster_hp.erase(id)

func _spawn_impact(position:Vector3,amount:int,hero_hit:bool,pet_hit:bool,critical:bool=false)->void:
	var root:=Node3D.new()
	root.name="AttackPointReaction"
	root.position=position
	add_child(root)
	var ring:=MeshInstance3D.new()
	var mesh:=TorusMesh.new()
	mesh.inner_radius=0.20
	mesh.outer_radius=0.34 if not critical else 0.46
	mesh.rings=12
	mesh.ring_segments=24
	ring.mesh=mesh
	var material:=StandardMaterial3D.new()
	material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color=Color("#ff5668") if hero_hit else (Color("#7ce8ff") if pet_hit else Color("#ffd66b"))
	material.emission_enabled=true
	material.emission=material.albedo_color
	material.emission_energy_multiplier=2.4 if critical else 1.5
	ring.material_override=material
	root.add_child(ring)
	var spark:=MeshInstance3D.new()
	var spark_mesh:=SphereMesh.new()
	spark_mesh.radius=0.08 if not critical else 0.13
	spark_mesh.height=0.16 if not critical else 0.26
	spark.mesh=spark_mesh
	spark.material_override=material
	root.add_child(spark)
	var life:=0.42 if not critical else 0.62
	effects.append({"root":root,"ring":ring,"spark":spark,"age":0.0,"life":life,"amount":amount})

func _update_effects(delta:float)->void:
	for i in range(effects.size()-1,-1,-1):
		var e:Dictionary=effects[i]
		e["age"]=float(e.get("age",0.0))+delta
		var t:float=clamp(float(e["age"])/float(e["life"]),0.0,1.0)
		var ring:=e["ring"] as Node3D
		var spark:=e["spark"] as Node3D
		if ring!=null:
			ring.scale=Vector3.ONE*(0.65+2.1*t)
			ring.rotation.y+=delta*7.0
		var mat:Material=(ring as MeshInstance3D).material_override if ring is MeshInstance3D else null
		if mat is StandardMaterial3D:
			(mat as StandardMaterial3D).albedo_color.a=1.0-t
		if spark!=null:
			spark.scale=Vector3.ONE*(1.5-1.0*t)
		if t>=1.0:
			var root:=e["root"] as Node3D
			if is_instance_valid(root): root.queue_free()
			effects.remove_at(i)

func _map_to_world(map_pos:Vector2)->Vector3:
	return Vector3((map_pos.x-365.0)*WORLD_SCALE,0.15,(map_pos.y-120.0)*WORLD_SCALE)
