extends Node

## Independent rental-only SS combat/heal controller.
## Uses the existing LegacyGame state and never creates a player character.
const HEAL_INTERVAL:float = 1.5
const ATTACK_INTERVAL:float = 1.2
const HEAL_THRESHOLD:float = 0.72
var heal_clock:float = 0.0
var attack_clock:float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta:float) -> void:
	heal_clock += delta
	attack_clock += delta
	var runtime:Node = get_node_or_null("/root/HWRentalService")
	var scene:Node = get_tree().current_scene
	if runtime == null or scene == null or not bool(runtime.call("is_rented")):
		return
	var legacy:Node = scene.get_node_or_null("LegacyGame")
	if legacy == null:
		return
	var hero_value:Variant = legacy.get("hero")
	if not hero_value is Dictionary:
		return
	var hero:Dictionary = hero_value
	var state_value:Variant = runtime.get("ss")
	if not state_value is Dictionary or state_value.is_empty():
		return
	var state:Dictionary = state_value
	state["age"] = maxi(18,int(hero.get("age",18)))
	var behavior:Dictionary = state.get("behavior",{"follow":true,"heal":true,"fight":true})
	if bool(behavior.get("heal",true)) and heal_clock >= HEAL_INTERVAL:
		heal_clock = 0.0
		_heal_owner(legacy,hero,state)
	if bool(behavior.get("fight",true)) and attack_clock >= ATTACK_INTERVAL:
		attack_clock = 0.0
		_fight(legacy,hero,state)
	runtime.set("ss",state)

func _heal_owner(legacy:Node,hero:Dictionary,state:Dictionary) -> void:
	var max_hp:int = max(1,int(hero.get("max_hp",1)))
	var hp:int = clamp(int(hero.get("hp",0)),0,max_hp)
	if float(hp)/float(max_hp) >= HEAL_THRESHOLD:
		return
	var stats:Dictionary = state.get("status_points",{})
	var amount:int = max(8,int(float(max_hp)*0.06)+int(stats.get("VIT",0))+int(stats.get("INT",0)))
	hero["hp"] = min(max_hp,hp+amount)
	legacy.set("hero",hero)

func _fight(legacy:Node,hero:Dictionary,state:Dictionary) -> void:
	var monsters_value:Variant = legacy.get("monsters")
	if not monsters_value is Array:
		return
	var hero_pos:Vector2 = Vector2(float(hero.get("pos_x",595.0)),float(hero.get("pos_y",340.0)))
	var target_index:int = -1
	var best_distance:float = 999999.0
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
		var distance:float = hero_pos.distance_to(pos_value)
		if distance <= 180.0 and distance < best_distance:
			best_distance = distance
			target_index = i
	if target_index < 0:
		return
	var target:Dictionary = monsters_value[target_index]
	var level:int = clamp(int(state.get("level",0)),0,250)
	var stats:Dictionary = state.get("status_points",{})
	var damage:int = max(25,70+level*8+int(stats.get("STR",0))*3+int(stats.get("DEX",0)))
	target["hp"] = max(0,int(target.get("hp",0))-damage)
	if target["hp"] <= 0:
		var xp:int = max(25,int(target.get("level",1))*12)
		state["xp"] = int(state.get("xp",0))+xp
		state["kills"] = int(state.get("kills",0))+1
		state["zeny_earned"] = int(state.get("zeny_earned",0))+max(5,int(target.get("level",1))*3)
		_level_up(state)
	monsters_value[target_index] = target
	legacy.set("monsters",monsters_value)

func _level_up(state:Dictionary) -> void:
	var level:int = clamp(int(state.get("level",0)),0,250)
	var xp:int = max(0,int(state.get("xp",0)))
	while level < 250:
		var needed:int = max(100,(level+1)*100)
		if xp < needed:
			break
		xp -= needed
		level += 1
	state["xp"] = xp
	state["level"] = level
