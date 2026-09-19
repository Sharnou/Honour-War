extends SceneTree

const FifthTier = preload("res://scripts/FifthTierClassTreeSystem.gd")

func _initialize() -> void:
    var hero: Dictionary = {"class": "Mage", "level": 200, "class_mastery": 100, "hero_age_days": 30}
    FifthTier.ensure_state(hero)
    assert(FifthTier.can_attempt_awakening(hero), "Fifth Tier prerequisites should be available at level 200/mastery 100/age 30")
    assert(FifthTier.paradigm_for_class("Mage") == "chrono_architect", "Mage affinity must be Chrono-Architect")
    assert(FifthTier.paradigm_for_class("Merchant") == "matrix_sovereign", "Merchant affinity must be Matrix Sovereign")
    assert(FifthTier.begin_severance_trial(hero), "Severance trial should begin")
    assert(FifthTier.complete_severance_trial(hero, true), "Mirror defeat should complete Severance")
    assert(FifthTier.fuse_attributes(hero, 1000.0), "Attribute fusion should succeed")
    assert(FifthTier.awaken(hero, "chrono_architect"), "Chrono-Architect awakening should succeed")
    assert(hero["fifth_tier"]["unlocked"], "Fifth Tier must be unlocked")
    assert(FifthTier.add_simulation_paradox(hero, 20.0)["value"] == 20.0, "Paradox must accumulate")
    var skill_result: Dictionary = FifthTier.use_skill(hero, "stasis_dome")
    assert(skill_result.get("ok", false), "Stasis Dome should consume Paradox and activate")
    FifthTier.ensure_state(hero)
    var visual: Dictionary = FifthTier.visual_profile(hero)
    assert(visual.get("awakened", false), "Awakened visual profile must be active")
    assert(visual.get("timeline_distortion", false), "Chrono-Architect visual distortion must be active")
    print("PASS: Fifth Tier transcendence class tree contract")
    quit()
