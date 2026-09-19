extends SceneTree

const CompleteTree = preload("res://scripts/CompleteClassSkillTreeSystem.gd")
const FifthTier = preload("res://scripts/FifthTierClassTreeSystem.gd")

func _initialize() -> void:
    var expected := {
        "Warrior": ["war_power_slash","war_whirlwind","war_earthbreaker","war_emperors_judgment"],
        "Mage": ["mage_arcane_spark","mage_comet","mage_void_lance","mage_arcane_overload"],
        "Archer": ["arch_celestial_arrow","arch_double_shot","arch_hawk_storm","arch_skybreaker"],
        "Thief": ["thief_shadow_strike","thief_blade_flurry","thief_execution","thief_shadow_requiem"],
        "Acolyte": ["aco_holy_pulse","aco_sanctuary","aco_seraphic_light","aco_judgment"],
        "Merchant": ["mer_forge_smash","mer_cart_impact","mer_magma_forge","mer_titan_cart"]
    }
    for class_id in CompleteTree.CLASSES:
        var tree:Dictionary = CompleteTree.skill_tree(class_id)
        assert(tree.size() > 0, "missing tree for %s" % class_id)
        for tier in range(1,5):
            assert(tree["tiers"][tier].size() >= 1, "%s tier %d empty" % [class_id,tier])
            assert(str(tree["tiers"][tier][0]["id"]) == expected[class_id][tier-1], "%s tier %d root mismatch" % [class_id,tier])
        var fifth:Array = tree["tiers"][5]
        assert(fifth.size() >= 3, "%s Fifth Tier must have 3 profession skills" % class_id)
        var fifth_profile:Dictionary = FifthTier.natural_fifth_tier_profile(class_id)
        for skill in fifth:
            assert(str(skill.get("weapon","")) == str(fifth_profile["primary_weapon"]) or str(skill.get("weapon","")) == str(fifth_profile["secondary_weapon"]), "%s Fifth Tier weapon identity mismatch" % class_id)
        assert(int(tree["max_tier"]) == 5, "%s does not expose Tier 5" % class_id)
    var failures:Array[String] = CompleteTree.validate()
    assert(failures.is_empty(), "Complete skill tree validation failed: %s" % str(failures))
    print("COMPLETE_CLASS_SKILL_TREE_QA: PASS — all six characters have connected Tier 1→2→3→4→5 skill trees")
    quit(0)
