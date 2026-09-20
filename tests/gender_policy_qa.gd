extends SceneTree

## Deterministic QA for Honour War immutable account gender rules.
## Run with Godot 4.7.2 headless from the project root.

var failures:int = 0

func _initialize() -> void:
    _check(HWGenderPolicy.gender_from_username("Player_M") == HWGenderPolicy.MALE,"_M registration locks Male")
    _check(HWGenderPolicy.gender_from_username("Player_F") == HWGenderPolicy.FEMALE,"_F registration locks Female")
    _check(HWGenderPolicy.gender_from_username("Player") == HWGenderPolicy.UNKNOWN,"registration without gender suffix is rejected")
    _check(HWGenderPolicy.can_use_character_gender("M","M"),"Male account can use Male character")
    _check(not HWGenderPolicy.can_use_character_gender("M","F"),"Male account cannot use Female character")
    _check(HWGenderPolicy.can_use_character_gender("F","F"),"Female account can use Female character")
    _check(not HWGenderPolicy.can_use_character_gender("F","M"),"Female account cannot use Male character")

    var male:Dictionary = HWGenderPolicy.lock_player_gender({"name":"Aldric","gender":"F"},"M")
    _check(str(male.get("gender","")) == "M","player gender is overwritten by locked account gender")
    _check(bool(male.get("gender_locked",false)),"player gender is marked locked")
    _check(HWGenderPolicy.validate_player_gender({"gender":"M"},"M"),"matching player gender validates")
    _check(not HWGenderPolicy.validate_player_gender({"gender":"F"},"M"),"cross-gender player gender fails validation")

    print("GENDER_POLICY_QA: FAILURES=",failures)
    quit(1 if failures > 0 else 0)

func _check(condition:bool,label:String) -> void:
    if condition:
        print("PASS: ",label)
    else:
        push_error("FAIL: "+label)
        failures += 1
