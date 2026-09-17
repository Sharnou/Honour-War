extends SceneTree

## Headless regression suite for authoritative player movement, warp validation,
## and persistent server state.

const AUTHORITY = preload("res://scripts/HWOnlineAuthorityRuntime.gd")
const DATABASE = preload("res://scripts/HWAccountDatabase.gd")
const WORLD = preload("res://scripts/HWOnlineWorldState.gd")
const GAME_DATA = preload("res://scripts/GameData.gd")
const TEST_PATH:String = "user://honour_war_world_state_regression.json"

var failures:int = 0

func _initialize() -> void:
    call_deferred("_run_world_test")

func _run_world_test() -> void:
    if FileAccess.file_exists(TEST_PATH):
        DirAccess.remove_absolute(TEST_PATH)

    var network_api:MultiplayerAPI = MultiplayerAPI.create_default_interface()
    set_multiplayer(network_api,NodePath("/root"))

    var authority:Node = root.get_node_or_null("HWOnlineAuthorityRuntime")
    if authority == null:
        authority = AUTHORITY.new()
        authority.name = "HWOnlineAuthorityRuntime"
        root.add_child(authority)
    _check("authority receives world-test multiplayer API",authority.multiplayer == network_api)
    authority.stop_session()
    authority.account_database = DATABASE.new(TEST_PATH)

    var started:bool = authority.start_server(24570)
    _check("authority server starts",started)
    if not started:
        quit(1)
        return

    var username:String = "world_state_qa"
    var salt:String = "world-state-salt-0001"
    var verifier:String = DATABASE.password_verifier("HonourWar-2026!",salt)
    var hero:Dictionary = GAME_DATA.new_hero()
    hero["pos_x"] = 595.0
    hero["pos_y"] = 340.0
    hero["map_id"] = 0
    _check("test account can be created",authority.account_database.create_account(username,salt,verifier,hero))
    authority._authenticated_peers[42] = username
    authority._peer_players[42] = hero.duplicate(true)

    var world:Node = root.get_node_or_null("HWOnlineWorldState")
    var created_world:bool = false
    if world == null:
        world = WORLD.new()
        world.name = "HWOnlineWorldState"
        root.add_child(world)
        created_world = true
    world.authority = authority
    world.last_positions[42] = Vector2(595.0,340.0)
    world.last_position_times[42] = Time.get_ticks_msec()/1000.0
    world.save_timers[42] = 0.0

    var valid_move:Dictionary = {"absolute":true,"x":605.0,"y":340.0}
    _check("normal movement validates",world.validate_move_request(42,valid_move))
    world._apply_server_action({"sender":42,"action":"move","payload":valid_move})
    var moved:Dictionary = authority.player_for_peer(42)
    _check("authoritative position is updated",absf(float(moved.get("pos_x",0.0))-605.0)<0.01)

    world.last_position_times[42] = Time.get_ticks_msec()/1000.0-0.016
    var too_far:Dictionary = {"absolute":true,"x":950.0,"y":950.0}
    _check("teleport-speed movement is rejected",not world.validate_move_request(42,too_far))

    var valid_warp:Dictionary = {"map_id":10,"x":180,"y":450}
    _check("valid dungeon warp validates",world.validate_warp_request(42,valid_warp))
    world._apply_server_action({"sender":42,"action":"warp","payload":valid_warp})
    var warped:Dictionary = authority.player_for_peer(42)
    _check("authoritative map changes on warp",int(warped.get("map_id",-1))==10)
    _check("authoritative warp X is preserved",absf(float(warped.get("pos_x",0.0))-545.0)<0.01)
    _check("authoritative warp Y is preserved",absf(float(warped.get("pos_y",0.0))-570.0)<0.01)

    _check("invalid map warp rejected",not world.validate_warp_request(42,{"map_id":999,"x":0,"y":0}))

    _check("server can persist current player",authority.save_player_for_peer(42,authority.player_for_peer(42)))
    var restored:Dictionary = authority.account_database.load_player(username,GAME_DATA.new_hero())
    _check("persisted world state restores",int(restored.get("map_id",-1))==10 and absf(float(restored.get("pos_x",0.0))-545.0)<0.01)

    if created_world:
        world.free()
    authority.stop_session()
    if FileAccess.file_exists(TEST_PATH):
        DirAccess.remove_absolute(TEST_PATH)

    if failures == 0:
        print("PASS: Honour War authoritative world state regression suite")
        quit(0)
        return
    print("FAIL: Honour War authoritative world state regression suite: %d failure(s)" % failures)
    quit(1)

func _check(label:String,condition:bool) -> void:
    if condition:
        print("PASS: ",label)
    else:
        failures += 1
        print("FAIL: ",label)
