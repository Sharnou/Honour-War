extends SceneTree

# Fast account regression suite.
# Validates username/password registration policy, _M/_F gender naming, unique
# base-name login resolution, challenge authentication, and the absence of
# email-verification fields.

const AuthorityScript = preload("res://scripts/HWOnlineAuthorityRuntime.gd")
const AccountDatabaseClass = preload("res://scripts/HWAccountDatabase.gd")
const GameDataClass = preload("res://scripts/GameData.gd")

var failures:int = 0

func _initialize() -> void:
    var authority:Node = AuthorityScript.new()
    _check("fast password minimum is 6",authority.MIN_PASSWORD_LENGTH == 6)
    _check("123123 meets fast registration minimum","123123".length() >= authority.MIN_PASSWORD_LENGTH)
    _check("5-character password rejected","12345".length() < authority.MIN_PASSWORD_LENGTH)
    _check("male suffix detected",authority.gender_from_username("Sharnou_M") == "male")
    _check("female suffix detected",authority.gender_from_username("Sharnou_F") == "female")
    _check("unsuffixed gender remains unspecified",authority.gender_from_username("Sharnou") == "unspecified")

    var test_path:String = "user://honour_war_fast_auth_test_%d.json" % Time.get_ticks_usec()
    var database:RefCounted = AccountDatabaseClass.new(test_path)
    var hero:Dictionary = GameDataClass.new_hero()
    hero["account_username"] = "sharnou_m"
    hero["gender"] = "male"
    var salt:String = "0123456789abcdef0123456789abcdef"
    var verifier:String = AccountDatabaseClass.password_verifier("123123",salt)
    _check("create Sharnou_M account",database.create_account("Sharnou_M",salt,verifier,hero))
    _check("exact username stored",database.account_exists("sharnou_m"))
    _check("base Sharnou resolves to unique male account",authority.resolve_login_username(database,"Sharnou") == "sharnou_m")

    var nonce:String = "fast-auth-test-nonce"
    var response:String = AccountDatabaseClass.challenge_digest(verifier,nonce)
    _check("challenge accepts correct password",database.authenticate_challenge("Sharnou_M",response,nonce))
    var wrong_verifier:String = AccountDatabaseClass.password_verifier("wrongpw",salt)
    var wrong_response:String = AccountDatabaseClass.challenge_digest(wrong_verifier,nonce)
    _check("challenge rejects wrong password",not database.authenticate_challenge("Sharnou_M",wrong_response,nonce))

    var auth_record:Dictionary = database.get_auth_record("Sharnou_M")
    _check("account record has no email",not auth_record.has("email"))
    _check("account record has no email verification field",not auth_record.has("email_verified"))

    var female_hero:Dictionary = GameDataClass.new_hero()
    female_hero["account_username"] = "sharnou_f"
    female_hero["gender"] = "female"
    var female_salt:String = "fedcba9876543210fedcba9876543210"
    var female_verifier:String = AccountDatabaseClass.password_verifier("123123",female_salt)
    _check("create Sharnou_F account",database.create_account("Sharnou_F",female_salt,female_verifier,female_hero))
    _check("ambiguous base Sharnou is rejected",authority.resolve_login_username(database,"Sharnou").is_empty())
    _check("exact female login still resolves",authority.resolve_login_username(database,"Sharnou_F") == "sharnou_f")

    authority.free()
    DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path))

    if failures == 0:
        print("PASS: Honour War fast account registration/login regression suite")
        quit(0)
    else:
        print("FAIL: Honour War fast account registration/login regression suite: ",failures," failure(s)")
        quit(1)

func _check(label:String,condition:bool) -> void:
    if not condition:
        failures += 1
        print("FAIL: ",label)
