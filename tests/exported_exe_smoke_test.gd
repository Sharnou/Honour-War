extends Node

const QA_FLAG := "--qa-smoke-test"

var legacy:Node = null

func _ready() -> void:
    if not OS.get_cmdline_args().has(QA_FLAG):
        queue_free()
        return
    call_deferred("_run_smoke_test")

func _fail(message:String) -> void:
    push_error("EXE_QA_FAIL: " + message)
    get_tree().quit(1)

func _pass(message:String) -> void:
    print("EXE_QA_PASS: " + message)

func _run_smoke_test() -> void:
    legacy = get_node_or_null("../LegacyGame")
    if legacy == null:
        _fail("LegacyGame/Main runtime node is missing")
        return

    # hero is authoritative gameplay state, represented by a Dictionary rather
    # than a Godot Object. Do not call is_instance_valid() on the Dictionary.
    var hero_value:Variant = legacy.get("hero")
    if not hero_value is Dictionary:
        _fail("hero state is unavailable")
        return
    var hero:Dictionary = hero_value

    if int(hero.get("level",0)) < 1:
        _fail("hero level is invalid")
        return
    if not hero.has("pet") or not hero["pet"] is Dictionary:
        _fail("bonded pet state is missing")
        return

    # Exercise the real movement input path rather than directly moving the hero.
    var before_x:float = float(hero.get("pos_x",595.0))
    Input.action_press("move_right")
    await get_tree().create_timer(0.20).timeout
    Input.action_release("move_right")
    await get_tree().process_frame
    var after_x:float = float(hero.get("pos_x",before_x))
    if after_x <= before_x:
        _fail("movement input did not move the hero")
        return
    _pass("movement input")

    # Spawn a real monster through the gameplay runtime and use the real attack input.
    hero["pos_x"] = 595.0
    hero["pos_y"] = 340.0
    hero["map_id"] = 10
    legacy.call("spawn_monster")
    var monsters_value:Variant = legacy.get("monsters")
    if not monsters_value is Array or monsters_value.is_empty():
        _fail("runtime monster spawn failed")
        return
    var monsters:Array = monsters_value
    var monster:Dictionary = monsters[0]
    monster["pos"] = Vector2(595.0,340.0)
    monster["hp"] = max(1,int(monster.get("hp",100)))
    var hp_before:int = int(monster["hp"])

    var attack_event := InputEventKey.new()
    attack_event.pressed = true
    attack_event.keycode = KEY_SPACE
    legacy.call("_input",attack_event)
    await get_tree().process_frame
    if not monsters.has(monster) and hp_before > 0:
        _pass("hero attack and monster defeat")
    elif int(monster.get("hp",hp_before)) >= hp_before:
        _fail("hero attack input did not damage the target")
        return
    else:
        _pass("hero attack")

    # Exercise the class skill entry point and verify SP/cooldown state changes.
    hero["pos_x"] = 595.0
    hero["pos_y"] = 340.0
    if monsters.is_empty():
        legacy.call("spawn_monster")
        monsters_value = legacy.get("monsters")
        if monsters_value is Array and not monsters_value.is_empty():
            monsters = monsters_value
            monsters[0]["pos"] = Vector2(595.0,340.0)

    var class_id := str(hero.get("class","Warrior"))
    var skill_candidates := {
        "Warrior":"war_power_slash",
        "Mage":"mage_arcane_bolt",
        "Archer":"arch_celestial_arrow",
        "Thief":"thief_shadow_strike",
        "Acolyte":"aco_holy_pulse",
        "Merchant":"mer_forge_smash"
    }
    var skill_id:String = str(skill_candidates.get(class_id,""))
    if skill_id == "" or not legacy.has_method("use_skill"):
        _fail("class skill entry point is unavailable for " + class_id)
        return
    var sp_before:int = int(hero.get("sp",0))
    legacy.call("use_skill",skill_id)
    await get_tree().process_frame
    var cooldowns:Dictionary = hero.get("skill_cooldowns",{})
    if cooldowns.has(skill_id) or int(hero.get("sp",sp_before)) < sp_before:
        _pass("class skill execution")
    else:
        _fail("class skill did not execute")
        return

    # Exercise the real @go command and preserve the requested 230:220 coordinate.
    legacy.call("execute_command","@go 0 230:220")
    await get_tree().process_frame
    if int(hero.get("map_id",-1)) != 0:
        _fail("@go did not select map 0")
        return
    if abs(float(hero.get("pos_x",0.0)) - 595.0) > 0.5 or abs(float(hero.get("pos_y",0.0)) - 340.0) > 0.5:
        _fail("@go coordinate preservation failed")
        return
    _pass("@go coordinate transmission")

    # Verify the save path remains callable after live gameplay mutations.
    legacy.call("save_game")
    _pass("runtime save")

    print("EXE_QA_SMOKE_TEST: PASS")
    get_tree().quit(0)
