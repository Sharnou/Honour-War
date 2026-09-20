extends SceneTree

const CombatRuntime = preload("res://scripts/CombatRuntime.gd")

class DummyGame:
	var hero:Dictionary = {}
	var monsters:Array = []

func _initialize() -> void:
	var failures:Array[String] = []
	var game = DummyGame.new()
	game.hero = {"pos_x":600.0,"pos_y":340.0,"level":50}
	var runtime = CombatRuntime.new()
	runtime.game = game

	var chasing:Dictionary = {
		"id":"qa_chase",
		"name":"QA Wolf",
		"level":50,
		"hp":100,
		"max":100,
		"pos":Vector2(540.0,340.0),
		"attack":10,
		"defense":2
	}
	game.monsters = [chasing]
	runtime.move_monsters(0.10,game.hero)
	_assert(chasing.get("movement_state","")=="chase", "chase state was not authoritative", failures)
	_assert(float(chasing.get("authoritative_movement_speed",0.0))>0.0, "authoritative monster velocity was not exposed", failures)
	_assert(Vector2(float(chasing.get("authoritative_velocity_x",0.0)),float(chasing.get("authoritative_velocity_y",0.0))).length()>0.0, "authoritative velocity vector is zero during chase", failures)
	_assert(Vector2(float(chasing.get("authoritative_facing_x",0.0)),float(chasing.get("authoritative_facing_y",0.0))).length()>0.0, "authoritative facing was not exposed", failures)

	var rooted:Dictionary = {
		"id":"qa_root",
		"name":"QA Rooted",
		"level":50,
		"hp":100,
		"max":100,
		"pos":Vector2(560.0,340.0),
		"attack":10,
		"defense":2,
		"root_until":runtime.now_seconds()+5.0
	}
	game.monsters = [rooted]
	runtime.move_monsters(0.10,game.hero)
	_assert(rooted.get("movement_state","")=="idle", "rooted monster remained in moving state", failures)
	_assert(float(rooted.get("authoritative_movement_speed",1.0))==0.0, "rooted monster retained stale authoritative speed", failures)

	var leashing:Dictionary = {
		"id":"qa_leash",
		"name":"QA Leash",
		"level":50,
		"hp":100,
		"max":100,
		"pos":Vector2(1000.0,340.0),
		"spawn_pos":Vector2(500.0,340.0),
		"attack":10,
		"defense":2
	}
	game.monsters = [leashing]
	runtime.move_monsters(0.10,game.hero)
	_assert(leashing.get("movement_state","")=="return", "leashing monster did not enter return state", failures)
	_assert(float(leashing.get("authoritative_movement_speed",0.0))>0.0, "leashing monster has no authoritative return velocity", failures)

	if failures.is_empty():
		print("MONSTER_MOTION_AUTHORITY_QA: PASS — chase, root/stop and leash return expose authoritative velocity/state/facing")
		quit(0)
	print("MONSTER_MOTION_AUTHORITY_QA: FAIL")
	for failure in failures:
		print("FAIL: ",failure)
	quit(1)

func _assert(condition:bool,message:String,failures:Array[String])->void:
	if not condition:
		failures.append(message)
