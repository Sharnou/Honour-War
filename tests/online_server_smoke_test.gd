extends SceneTree

## Headless smoke test for the dedicated Honour War server entrypoint.
## Validates that the authoritative ENet server can bind, expose its session
## contract, and shut down cleanly without requiring a graphical scene.

const AUTHORITY_SCRIPT = preload("res://scripts/HWOnlineAuthorityRuntime.gd")
const TEST_PORT:int = 24568

func _initialize() -> void:
    # A standalone SceneTree has no scene-root MultiplayerAPI by default.
    # Install the default API on the root and explicitly inject the same API
    # into the authority node because this test hosts the node outside the
    # normal Main3D scene hierarchy.
    var network_api:MultiplayerAPI = MultiplayerAPI.create_default_interface()
    set_multiplayer(network_api,root.get_path())

    var authority:Node = AUTHORITY_SCRIPT.new()
    root.add_child(authority)
    authority.set_multiplayer(network_api)

    var started:bool = authority.start_server(TEST_PORT)
    if not started:
        push_error("FAIL: authoritative server could not bind test port %d" % TEST_PORT)
        quit(1)
        return

    var snapshot:Dictionary = authority.get_session_snapshot()
    var failures:int = 0
    failures += _check("server authority active",bool(snapshot.get("authority",false)))
    failures += _check("protocol version present",int(snapshot.get("protocol",0)) == int(authority.PROTOCOL_VERSION))
    failures += _check("configured port is valid",TEST_PORT >= 1024 and TEST_PORT <= 65535)
    failures += _check("max players is positive",int(snapshot.get("max_players",0)) > 0)
    failures += _check("rate limit is positive",int(snapshot.get("rate_limit",0)) > 0)

    authority.stop_session()
    failures += _check("server stopped cleanly",not authority.is_authority())

    if failures == 0:
        print("PASS: Honour War dedicated server smoke test")
        quit(0)
    else:
        print("FAIL: Honour War dedicated server smoke test: %d failure(s)" % failures)
        quit(1)

func _check(label:String,condition:bool) -> int:
    if condition:
        print("PASS: ",label)
        return 0
    print("FAIL: ",label)
    return 1
