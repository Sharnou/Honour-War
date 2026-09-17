extends SceneTree

## Regression coverage for Honour War's online persistence, party, and world layers.
const GAME_DATA = preload("res://scripts/GameData.gd")
const ACCOUNT = preload("res://scripts/HWAccountDatabase.gd")
const WORLD = preload("res://scripts/HWOnlineWorldState.gd")
const PARTY = preload("res://scripts/HWPartyService.gd")

var failures:int = 0

func _initialize() -> void:
    _check("account username validation accepts normal account", ACCOUNT.validate_username("player_01"))
    _check("account username validation rejects spaces", not ACCOUNT.validate_username("player one"))
    _check("password verifier is deterministic", ACCOUNT.password_verifier("password123","salt-0123456789") == ACCOUNT.password_verifier("password123","salt-0123456789"))
    _check("challenge digest is deterministic", ACCOUNT.challenge_digest("verifier","nonce") == ACCOUNT.challenge_digest("verifier","nonce"))

    var temp_path:String = "user://honour_war_online_test_accounts.json"
    if FileAccess.file_exists(temp_path):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
    var db:RefCounted = ACCOUNT.new(temp_path)
    var hero:Dictionary = GAME_DATA.new_hero()
    var salt:String = "salt-0123456789abcdef"
    var verifier:String = ACCOUNT.password_verifier("password123",salt)
    _check("test account can be created", db.create_account("test_player",salt,verifier,hero))
    _check("test account exists", db.account_exists("test_player"))
    var loaded:Dictionary = db.load_player("test_player",{})
    _check("player state persists in account", loaded.get("name","") == hero.get("name",""))
    var nonce:String = "nonce-123456"
    var response:String = ACCOUNT.challenge_digest(verifier,nonce)
    _check("valid account challenge authenticates", db.authenticate_challenge("test_player",response,nonce))
    _check("invalid challenge is rejected", not db.authenticate_challenge("test_player","bad",nonce))
    _check("player state can be updated", db.save_player("test_player",{"level":37,"zeny":98765}))
    _check("updated player state reloads", int(db.load_player("test_player",{}).get("level",0)) == 37)

    var world:Node = WORLD.new()
    var clamped:Vector2 = world._clamp_to_map(0,Vector2(-99999.0,-99999.0))
    _check("world bounds clamp X", clamped.x >= 365.0)
    _check("world bounds clamp Y", clamped.y >= 120.0)
    _check("world movement requires absolute payload", not world.validate_move_request(1,{"x":0.5,"y":0.5}))
    world.free()

    var party:Node = PARTY.new()
    _check("party cap is four", int(party.MAX_PARTY_SIZE) == 4)
    _check("party starts empty", party.parties.is_empty() and party.peer_party.is_empty())
    party.free()

    DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))

    if failures == 0:
        print("PASS: Honour War online persistence/party/world regression suite")
        quit(0)
    else:
        print("FAIL: Honour War online persistence/party/world regression suite: %d failure(s)" % failures)
        quit(1)

func _check(label:String, condition:bool) -> void:
    if condition:
        print("PASS: ",label)
    else:
        failures += 1
        print("FAIL: ",label)
