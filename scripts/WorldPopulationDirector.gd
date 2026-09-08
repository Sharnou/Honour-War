class_name WorldPopulationDirector
extends Node

var legacy:Node2D
var last_map:int=-1
var timer:float=0.0
var rng:=RandomNumberGenerator.new()
var spawn_serial:int=0
const MIN_MONSTERS:=6
const MAX_MONSTERS:=10

func _ready()->void:
	rng.randomize()
	legacy=get_parent().get_node_or_null("LegacyGame") as Node2D
	call_deferred("_sync_population")

func _process(delta:float)->void:
	if legacy==null: return
	timer+=delta
	var hero_value:Variant=legacy.get("hero")
	if not hero_value is Dictionary: return
	var map_id:int=int((hero_value as Dictionary).get("map_id",0))
	if map_id!=last_map:
		_sync_population()
	if timer>=3.0:
		timer=0.0
		_replenish()

func _sync_population()->void:
	if legacy==null: return
	var hero_value:Variant=legacy.get("hero")
	if not hero_value is Dictionary: return
	last_map=int((hero_value as Dictionary).get("map_id",0))
	var monsters_value:Variant=legacy.get("monsters")
	if not monsters_value is Array: return
	(monsters_value as Array).clear()
	for i in MIN_MONSTERS:
		_spawn_one(true)
	if legacy.has_method("log_message"):
		legacy.call("log_message","Map populated: %d visible combat creatures are active." % MIN_MONSTERS)

func _replenish()->void:
	var monsters_value:Variant=legacy.get("monsters")
	if not monsters_value is Array: return
	var monsters:Array=monsters_value as Array
	while monsters.size()<MIN_MONSTERS:
		_spawn_one(false)

func _spawn_one(near_hero:bool)->void:
	var hero_value:Variant=legacy.get("hero")
	if not hero_value is Dictionary: return
	var hero:Dictionary=hero_value
	var monsters:Array=legacy.get("monsters") as Array
	if monsters==null or monsters.size()>=MAX_MONSTERS: return
	var families:Array=GameData.monster_families()
	if families.is_empty(): return
	var family:String=str(families[rng.randi_range(0,families.size()-1)])
	var hero_level:int=int(hero.get("level",1))
	var zone:int=max(1,int(hero_level/10)+1)
	var level:int=WorldSystem.monster_level_for_zone(zone,rng.randi_range(0,families.size()-1))
	var stats:Dictionary=WorldSystem.monster_stats(level)
	var map_id:int=int(hero.get("map_id",0))
	var map_data:Dictionary=TeleportSystem.MAPS.get(map_id,{})
	var width:float=float(map_data.get("width",1200))
	var height:float=float(map_data.get("height",700))
	var hero_pos:=Vector2(float(hero.get("pos_x",595.0)),float(hero.get("pos_y",340.0)))
	var pos:=Vector2.ZERO
	if near_hero:
		var angle:float=rng.randf_range(0.0,TAU)
		var radius:float=rng.randf_range(85.0,175.0)
		pos=hero_pos+Vector2(cos(angle),sin(angle))*radius
	else:
		pos=Vector2(365.0+rng.randf_range(60.0,max(61.0,width-60.0)),120.0+rng.randf_range(60.0,max(61.0,height-60.0)))
	pos.x=clamp(pos.x,365.0+60.0,365.0+max(61.0,width-60.0))
	pos.y=clamp(pos.y,120.0+60.0,120.0+max(61.0,height-60.0))
	spawn_serial+=1
	monsters.append({"visual_id":family+"_"+str(spawn_serial),"name":family,"level":level,"pos":pos,"hp":stats["max_hp"],"max":stats["max_hp"],"attack":stats["attack"],"defense":stats["defense"],"exp":stats["exp"],"zmin":stats["zeny_min"],"zmax":stats["zeny_max"]})
