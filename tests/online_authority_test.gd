extends SceneTree

# Headless regression suite for Honour War's authoritative network boundary.
# Run with Godot 4.7.2: godot --headless --path . --script res://tests/online_authority_test.gd

const AuthorityScript = preload("res://scripts/HWOnlineAuthorityRuntime.gd")
var failures:int = 0

func _initialize() -> void:
    var runtime:Node = AuthorityScript.new()

    _check("move payload accepted", runtime._validate_payload("move", {"x":0.5,"y":-0.5}))
    _check("move payload rejects out-of-range", not runtime._validate_payload("move", {"x":2.0,"y":0.0}))
    _check("attack payload accepted", runtime._validate_payload("attack", {"target_id":1}))
    _check("attack payload rejects zero target", not runtime._validate_payload("attack", {"target_id":0}))
    _check("chat payload accepted", runtime._validate_payload("chat", {"message":"hello"}))
    _check("chat payload rejects blank message", not runtime._validate_payload("chat", {"message":"   "}))
    _check("unknown action rejected", not runtime._action_is_allowed("delete_everything"))
    _check("warp payload accepted", runtime._validate_payload("warp", {"map_id":0,"x":230.0,"y":220.0}))
    _check("warp payload rejects negative map", not runtime._validate_payload("warp", {"map_id":-1,"x":0.0,"y":0.0}))

    var oversized:Array = []
    for i in 65:
        oversized.append(i)
    _check("oversized array rejected", not runtime._validate_payload("rent_ss", {"items":oversized}))

    for i in 30:
        _check("rate budget item %d" % i, runtime._consume_action_budget(99))
    _check("rate limit rejects 31st action", not runtime._consume_action_budget(99))

    runtime.free()

    if failures == 0:
        print("PASS: Honour War online authority regression suite")
        quit(0)
    else:
        print("FAIL: Honour War online authority regression suite: ", failures, " failure(s)")
        quit(1)

func _check(label:String, condition:bool) -> void:
    if not condition:
        failures += 1
        print("FAIL: ", label)
