extends SceneTree

const FifthTier = preload("res://scripts/FifthTierClassTreeSystem.gd")

func _initialize() -> void:
    var expected := {
        "Warrior": ["singularity_arch", "sword_and_shield", "Transcendent Greatsword"],
        "Mage": ["chrono_architect", "staff", "Chrono Arcane Staff"],
        "Archer": ["doomsday_vector", "bow", "Doomsday Longbow"],
        "Thief": ["doomsday_vector", "dual_daggers", "Causality Twin Daggers"],
        "Acolyte": ["chrono_architect", "mace_and_holy_focus", "Chrono Sanctified Mace"],
        "Merchant": ["matrix_sovereign", "axe", "Matrix Forged Axe"],
    }
    for profession in expected.keys():
        var profile: Dictionary = FifthTier.natural_fifth_tier_profile(profession)
        assert(not profile.is_empty(), "missing Fifth Tier profile for %s" % profession)
        assert(profile["first_tier_profession"] == profession, "Fifth Tier must retain first-tier profession")
        assert(profile["paradigm_id"] == expected[profession][0], "wrong natural paradigm for %s" % profession)
        assert(profile["weapon_family"] == expected[profession][1], "wrong weapon family for %s" % profession)
        assert(profile["primary_weapon"] == expected[profession][2], "wrong primary weapon for %s" % profession)
        assert(not str(profile["weapon_material"]).is_empty(), "missing weapon material for %s" % profession)
        assert(not str(profile["armor_material"]).is_empty(), "missing armor material for %s" % profession)
        assert(not str(profile["silhouette"]).is_empty(), "missing silhouette for %s" % profession)
        assert(not str(profile["vfx"]).is_empty(), "missing VFX for %s" % profession)

    var hero := {
        "class_id": "Archer",
        "level": 200,
        "class_mastery": 100,
        "hero_age_days": 30,
    }
    FifthTier.ensure_state(hero)
    assert(FifthTier.paradigm_for_class("Archer") == "doomsday_vector", "Archer must naturally map to Doomsday Vector")
    assert(FifthTier.begin_severance_trial(hero), "Archer should start Fifth Tier trial")
    assert(FifthTier.complete_severance_trial(hero, true), "Archer trial should complete")
    assert(FifthTier.fuse_attributes(hero, 1000.0), "Archer attribute fusion should complete")
    assert(FifthTier.awaken(hero), "Archer should awaken into its natural Fifth Tier")
    var visual: Dictionary = FifthTier.visual_profile(hero)
    assert(visual["first_tier_profession"] == "Archer", "awakened identity must remain Archer")
    assert(visual["weapon_family"] == "bow", "awakened Archer must use a bow")
    assert(visual["primary_weapon"] == "Doomsday Longbow", "awakened Archer must use its natural Fifth Tier bow")
    assert(visual["paradigm"] == "doomsday_vector", "awakened Archer paradigm mismatch")
    print("PASS: all six Fifth Tier professions are weapon-, material-, silhouette- and VFX-rooted")
    quit(0)
