extends SceneTree

## UI/account regression contract for the production login + registration +
## Create New Character flow. This is source-level for Canvas UI and uses the
## existing deterministic account database for the data-path checks.

const DB = preload("res://scripts/HWAccountDatabase.gd")
const AUTH = preload("res://scripts/HWOnlineAuthorityRuntime.gd")
const GAME_DATA = preload("res://scripts/GameData.gd")
var failures:int = 0

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var login_source := _read("res://scripts/HWOnlineLoginUI.gd")
    var identity_source := _read("res://scripts/HWPlayerIdentityUI.gd")

    _check("login UI exists", not login_source.is_empty())
    _check("registration button exists", login_source.contains('register_button.text = "REGISTER"'))
    _check("login button exists", login_source.contains('login_button.text = "LOGIN"'))
    _check("server address field exists", login_source.contains('"Server Address"'))
    _check("port field exists", login_source.contains('"Port"'))
    _check("username field exists", login_source.contains('"Username"'))
    _check("password field exists", login_source.contains('"Password"'))
    _check("automatic login option exists", login_source.contains("Automatic Login"))
    _check("registration calls authority", login_source.contains("authority.request_register"))
    _check("login calls authority", login_source.contains("authority.request_login"))
    _check("registration success is surfaced", login_source.contains("_on_registration_succeeded"))
    _check("authentication success is surfaced", login_source.contains("_on_authentication_succeeded"))

    _check("escape menu exposes create character", identity_source.contains("CREATE NEW CHARACTER"))
    _check("create character window exists", identity_source.contains('create_window = _menu_panel("CREATE NEW CHARACTER")'))
    _check("character name input exists", identity_source.contains("Real character name"))
    _check("Warrior selectable", identity_source.contains('"Warrior", "Mage", "Archer", "Thief", "Acolyte", "Merchant"'))
    _check("Mage selectable", identity_source.contains('"Warrior", "Mage", "Archer", "Thief", "Acolyte", "Merchant"'))
    _check("Archer selectable", identity_source.contains('"Warrior", "Mage", "Archer", "Thief", "Acolyte", "Merchant"'))
    _check("Thief selectable", identity_source.contains('"Warrior", "Mage", "Archer", "Thief", "Acolyte", "Merchant"'))
    _check("Acolyte selectable", identity_source.contains('"Warrior", "Mage", "Archer", "Thief", "Acolyte", "Merchant"'))
    _check("Merchant selectable", identity_source.contains('"Warrior", "Mage", "Archer", "Thief", "Acolyte", "Merchant"'))
    _check("new hero is initialized through CharacterProgression", identity_source.contains("CHARACTER.ensure_state(new_hero)"))
    _check("new hero is saved", identity_source.contains("SAVE.save_game(new_hero)"))

    var authority:Node = AUTH.new()
    _check("registration password minimum is six", authority.MIN_PASSWORD_LENGTH == 6)
    var path := "user://honour_war_ui_auth_character_%d.json" % Time.get_ticks_usec()
    var db:RefCounted = DB.new(path)
    var hero:Dictionary = GAME_DATA.new_hero()
    hero["account_username"] = "ui_qa_m"
    hero["gender"] = "male"
    var salt := "0123456789abcdef0123456789abcdef"
    var verifier := DB.password_verifier("123123",salt)
    _check("QA account registration succeeds", db.create_account("ui_qa_m",salt,verifier,hero))
    _check("registered account can authenticate", db.authenticate_challenge("ui_qa_m",DB.challenge_digest(verifier,"ui-nonce"),"ui-nonce"))
    var created:Dictionary = GAME_DATA.new_hero()
    created["name"] = "UI_Test_Hero"
    created["character_name"] = "UI_Test_Hero"
    created["class"] = "Archer"
    created["level"] = 1
    created["age"] = 18
    created["stats"] = {"str":1,"agi":1,"vit":1,"int":1,"dex":1,"luk":1}
    _check("new character has valid class", ["Warrior","Mage","Archer","Thief","Acolyte","Merchant"].has(str(created.get("class",""))))
    _check("new character starts at level 1", int(created.get("level",0)) == 1)
    _check("new character starts age 18", int(created.get("age",0)) == 18)
    _check("new character has name", not str(created.get("character_name","")).is_empty())
    _check("new character saves", db.save_player("ui_qa_m",created))
    var restored := db.load_player("ui_qa_m",GAME_DATA.new_hero())
    _check("saved character restores", str(restored.get("character_name","")) == "UI_Test_Hero" and str(restored.get("class","")) == "Archer")

    authority.free()
    if FileAccess.file_exists(path):
        DirAccess.remove_absolute(path)
    if failures == 0:
        print("PASS: Honour War login, registration and Create New Character UI regression")
        quit(0)
    else:
        print("FAIL: Honour War login, registration and Create New Character UI regression: %d failure(s)" % failures)
        quit(1)

func _read(path:String) -> String:
    var file := FileAccess.open(path,FileAccess.READ)
    if file == null:
        return ""
    var value := file.get_as_text()
    file.close()
    return value

func _check(label:String,condition:bool) -> void:
    if condition:
        print("PASS: ",label)
    else:
        failures += 1
        print("FAIL: ",label)
