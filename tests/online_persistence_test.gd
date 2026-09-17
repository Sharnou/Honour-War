extends SceneTree

## Persistence/authentication regression suite for Honour War.
## This test uses an isolated user:// database and deletes it after verification.

const DB = preload("res://scripts/HWAccountDatabase.gd")
const AUTHORITY = preload("res://scripts/HWOnlineAuthorityRuntime.gd")
const GAME_DATA = preload("res://scripts/GameData.gd")

const TEST_PATH:String = "user://honour_war_auth_regression.json"
var failures:int = 0

func _initialize() -> void:
    if FileAccess.file_exists(TEST_PATH):
        DirAccess.remove_absolute(TEST_PATH)

    var db:RefCounted = DB.new(TEST_PATH)
    var username:String = "qa_player_01"
    var password:String = "HonourWar-2026!"
    var salt:String = ("qa-salt-" + str(Time.get_ticks_usec())).sha256_text()
    var verifier:String = DB.password_verifier(password,salt)
    var hero:Dictionary = GAME_DATA.new_hero()
    hero["level"] = 27
    hero["zeny"] = 9876

    _check("username validation accepts production-safe name", DB.validate_username(username))
    _check("username validation rejects short name", not DB.validate_username("ab"))
    _check("password verifier is 64 hex chars", verifier.length() == 64)
    _check("account creation succeeds", db.create_account(username,salt,verifier,hero))
    _check("duplicate account rejected", not db.create_account(username,salt,verifier,hero))
    _check("account exists after creation", db.account_exists(username))

    var record:Dictionary = db.get_auth_record(username)
    _check("auth record stores salt", str(record.get("salt","")) == salt)
    _check("auth record does not store plaintext password", not record.has("password"))

    var nonce:String = "regression-nonce-01"
    var response:String = DB.challenge_digest(verifier,nonce)
    _check("correct challenge authenticates", db.authenticate_challenge(username,response,nonce))
    _check("wrong challenge response rejected", not db.authenticate_challenge(username,DB.challenge_digest("bad",nonce),nonce))

    var loaded:Dictionary = db.load_player(username,GAME_DATA.new_hero())
    _check("player state loads", int(loaded.get("level",0)) == 27 and int(loaded.get("zeny",0)) == 9876)
    loaded["level"] = 31
    _check("player state save succeeds", db.save_player(username,loaded))
    var restored:Dictionary = db.load_player(username,GAME_DATA.new_hero())
    _check("player state round-trip persists", int(restored.get("level",0)) == 31 and int(restored.get("zeny",0)) == 9876)

    var runtime:Node = AUTHORITY.new()
    runtime.account_database = db
    _check("runtime starts unauthenticated", not runtime.is_peer_authenticated(42))
    runtime._authenticated_peers[42] = username
    runtime._peer_players[42] = restored.duplicate(true)
    _check("runtime recognizes authenticated peer", runtime.is_peer_authenticated(42))
    _check("runtime resolves authenticated username", runtime.username_for_peer(42) == username)
    _check("runtime exposes persisted player", int(runtime.player_for_peer(42).get("level",0)) == 31)
    runtime.free()

    db = null
    if FileAccess.file_exists(TEST_PATH):
        DirAccess.remove_absolute(TEST_PATH)

    if failures == 0:
        print("PASS: Honour War online persistence regression suite")
        quit(0)
    print("FAIL: Honour War online persistence regression suite: %d failure(s)" % failures)
    quit(1)

func _check(label:String,condition:bool) -> void:
    if condition:
        print("PASS: ",label)
    else:
        failures += 1
        print("FAIL: ",label)
