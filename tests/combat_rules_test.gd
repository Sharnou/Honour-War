extends SceneTree

# Headless regression suite for Honour War's single combat-distance authority.
# Run with Godot 4: godot --headless --path . --script res://tests/combat_rules_test.gd

var failures:int = 0

func _initialize() -> void:
    _check_close("Warrior engagement", CombatRules.class_engagement_m({"class":"Warrior"}), 2.4)
    _check_close("Mage engagement", CombatRules.class_engagement_m({"class":"Mage"}), 7.5)
    _check_close("Archer engagement", CombatRules.class_engagement_m({"class":"Archer"}), 12.0)
    _check_close("Ranger engagement", CombatRules.class_engagement_m({"class":"Ranger"}), 13.5)
    _check_close("Thief engagement", CombatRules.class_engagement_m({"class":"Thief"}), 2.2)
    _check_close("Acolyte engagement", CombatRules.class_engagement_m({"class":"Acolyte"}), 5.0)
    _check_close("Merchant engagement", CombatRules.class_engagement_m({"class":"Merchant"}), 2.4)

    _check_close("Falcon range", CombatRules.pet_attack_distance_m({"species":"Falcon"}), 9.0)
    _check_close("Wolf range", CombatRules.pet_attack_distance_m({"species":"Wolf"}), 2.6)
    _check_close("Dragon range", CombatRules.pet_attack_distance_m({"species":"Dragon"}), 10.0)
    _check_close("Wolf Cub range", CombatRules.pet_attack_distance_m({"species":"Wolf Cub"}), 2.4)
    _check_close("Guardian range", CombatRules.pet_attack_distance_m({"species":"Guardian"}), 2.8)
    _check_close("Sprite range", CombatRules.pet_attack_distance_m({"species":"Sprite"}), 6.0)
    _check_close("Shadowcat range", CombatRules.pet_attack_distance_m({"species":"Shadowcat"}), 3.0)

    _check_close("Normal monster range", CombatRules.map_to_meters(CombatRules.monster_attack_distance({})), 2.4)
    _check_close("Ranged monster range", CombatRules.map_to_meters(CombatRules.monster_attack_distance({"ranged":true})), 9.0)
    _check_close("MVP range", CombatRules.map_to_meters(CombatRules.monster_attack_distance({"mvp":true})), 3.5)

    var snapped:Vector2 = CombatRules.snap_map_point(Vector2(10.49, 20.51))
    _check_equal("1x1 grid snap", snapped, Vector2(10.0, 21.0))

    if failures == 0:
        print("PASS: Honour War combat range regression suite")
        quit(0)
    else:
        print("FAIL: Honour War combat range regression suite: ", failures, " failure(s)")
        quit(1)

func _check_close(label:String, actual:float, expected:float) -> void:
    if not is_equal_approx(actual, expected):
        failures += 1
        print("FAIL: ", label, " expected=", expected, " actual=", actual)

func _check_equal(label:String, actual:Vector2, expected:Vector2) -> void:
    if actual != expected:
        failures += 1
        print("FAIL: ", label, " expected=", expected, " actual=", actual)
