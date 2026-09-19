class_name FifthTierClassTreeSystem
extends RefCounted

## Honour War Fifth Tier: Transcendence.
## This is an endgame specialization layer above the existing four class branches.
## It is intentionally self-contained so headless CI can load it without autoload order.

const FIFTH_TIER := 5
const REQUIRED_LEVEL := 200
const MAX_LEVEL := 250
const REQUIRED_CLASS_MASTERY := 100
const REQUIRED_HERO_AGE_DAYS := 30
const PARADOX_MAX := 100.0
const ENTROPY_MAX := 12
const NETWORK_RESONANCE_MAX := 100.0
const COMPOSITE_STAT_COST_RATIO := 0.35

const PARADIGMS := {
    "singularity_arch": {
        "name": "The Singularity Arch",
        "title": "The Absolute Bastion",
        "identity": "Spatial defense, interception and kinetic control.",
        "composite": "Spatial Mass",
        "source_attributes": ["STR", "VIT"],
        "primary_resource": "simulation_paradox",
        "skills": ["gravity_well", "unyielding_threshold", "coordinate_lock"],
        "ultimate": "coordinate_lock",
    },
    "doomsday_vector": {
        "name": "The Doomsday Vector",
        "title": "The Sovereign Striker",
        "identity": "Absolute offense, causality rupture and structural scars.",
        "composite": "Causality Precision",
        "source_attributes": ["DEX", "CRIT"],
        "primary_resource": "entropy_shards",
        "skills": ["absolute_vacuum", "causality_rupture", "structural_scar"],
        "ultimate": "structural_scar",
    },
    "chrono_architect": {
        "name": "The Chrono-Architect",
        "title": "The Reality Weaver",
        "identity": "Timeline control, rollback and primordial elemental synthesis.",
        "composite": "Aetherial Frequency",
        "source_attributes": ["INT", "SP"],
        "primary_resource": "simulation_paradox",
        "skills": ["temporal_anchor", "primordial_chaos", "stasis_dome"],
        "ultimate": "stasis_dome",
    },
    "matrix_sovereign": {
        "name": "The Matrix Sovereign",
        "title": "The System Overlord",
        "identity": "Party utility, economy, equipment and battlefield infrastructure.",
        "composite": "Network Resonance",
        "source_attributes": ["LUK", "INT"],
        "primary_resource": "network_resonance",
        "skills": ["card_suppression", "algorithmic_reprogramming", "fabricator_node"],
        "ultimate": "fabricator_node",
    },
}

const CLASS_AFFINITY := {
    "Warrior": "singularity_arch",
    "Mage": "chrono_architect",
    "Archer": "doomsday_vector",
    "Thief": "doomsday_vector",
    "Acolyte": "chrono_architect",
    "Merchant": "matrix_sovereign",
}

const RESOURCE_RULES := {
    "simulation_paradox": {"cap": PARADOX_MAX, "acquire": "combat cell occupation", "risk": "At 100, Paradox Collapse deals 25% max HP and resets Paradox to 35."},
    "entropy_shards": {"cap": ENTROPY_MAX, "acquire": "high-tier MVP/boss defeats", "risk": "Consumed permanently during the current combat instance; no automatic regeneration."},
    "network_resonance": {"cap": NETWORK_RESONANCE_MAX, "acquire": "linked party members across the world", "risk": "Decays rapidly when the sovereign is isolated from its linked party."},
}

static func ensure_state(hero: Dictionary) -> void:
    if not hero.has("fifth_tier"): hero["fifth_tier"] = {}
    var state: Dictionary = hero["fifth_tier"]
    if not state.has("unlocked"): state["unlocked"] = false
    if not state.has("paradigm"): state["paradigm"] = ""
    if not state.has("composite_attributes"): state["composite_attributes"] = {"Spatial Mass": 0.0, "Aetherial Frequency": 0.0, "Causality Precision": 0.0}
    if not state.has("simulation_paradox"): state["simulation_paradox"] = 0.0
    if not state.has("entropy_shards"): state["entropy_shards"] = 0
    if not state.has("network_resonance"): state["network_resonance"] = 0.0
    if not state.has("structural_integrity"): state["structural_integrity"] = 1.0
    if not state.has("temporal_anchor"): state["temporal_anchor"] = {}
    if not state.has("skills"): state["skills"] = {}
    if not state.has("awakening_count"): state["awakening_count"] = 0
    hero["fifth_tier"] = state

static func can_attempt_awakening(hero: Dictionary) -> bool:
    ensure_state(hero)
    if bool(hero["fifth_tier"].get("unlocked", false)): return false
    return int(hero.get("level", 1)) >= REQUIRED_LEVEL and int(hero.get("class_mastery", 0)) >= REQUIRED_CLASS_MASTERY and int(hero.get("hero_age_days", 0)) >= REQUIRED_HERO_AGE_DAYS

static func awakening_requirements(hero: Dictionary) -> Dictionary:
    ensure_state(hero)
    return {
        "level": {"required": REQUIRED_LEVEL, "current": int(hero.get("level", 1)), "met": int(hero.get("level", 1)) >= REQUIRED_LEVEL},
        "class_mastery": {"required": REQUIRED_CLASS_MASTERY, "current": int(hero.get("class_mastery", 0)), "met": int(hero.get("class_mastery", 0)) >= REQUIRED_CLASS_MASTERY},
        "hero_age_days": {"required": REQUIRED_HERO_AGE_DAYS, "current": int(hero.get("hero_age_days", 0)), "met": int(hero.get("hero_age_days", 0)) >= REQUIRED_HERO_AGE_DAYS},
        "severance_trial": {"required": true, "current": bool(hero["fifth_tier"].get("severance_trial_complete", false)), "met": bool(hero["fifth_tier"].get("severance_trial_complete", false))},
        "attribute_fusion": {"required": true, "current": bool(hero["fifth_tier"].get("attribute_fusion_complete", false)), "met": bool(hero["fifth_tier"].get("attribute_fusion_complete", false))},
    }

static func begin_severance_trial(hero: Dictionary) -> bool:
    ensure_state(hero)
    if int(hero.get("level", 1)) < REQUIRED_LEVEL: return false
    hero["fifth_tier"]["severance_trial_active"] = true
    return true

static func complete_severance_trial(hero: Dictionary, mirror_defeated: bool) -> bool:
    ensure_state(hero)
    if not bool(hero["fifth_tier"].get("severance_trial_active", false)) or not mirror_defeated: return false
    hero["fifth_tier"]["severance_trial_active"] = false
    hero["fifth_tier"]["severance_trial_complete"] = true
    return true

static func fuse_attributes(hero: Dictionary, base_stat_total: float) -> bool:
    ensure_state(hero)
    if not bool(hero["fifth_tier"].get("severance_trial_complete", false)) or bool(hero["fifth_tier"].get("attribute_fusion_complete", false)): return false
    if base_stat_total <= 0.0: return false
    var sacrificed: float = base_stat_total * COMPOSITE_STAT_COST_RATIO
    hero["fifth_tier"]["sacrificed_stat_points"] = sacrificed
    hero["fifth_tier"]["attribute_fusion_complete"] = true
    hero["fifth_tier"]["composite_attributes"]["Spatial Mass"] = sacrificed * 0.34
    hero["fifth_tier"]["composite_attributes"]["Aetherial Frequency"] = sacrificed * 0.33
    hero["fifth_tier"]["composite_attributes"]["Causality Precision"] = sacrificed * 0.33
    return true

static func available_paradigms(hero: Dictionary) -> Array[String]:
    ensure_state(hero)
    if not bool(hero["fifth_tier"].get("attribute_fusion_complete", false)): return []
    return PARADIGMS.keys()

static func awaken(hero: Dictionary, paradigm_id: String) -> bool:
    ensure_state(hero)
    if paradigm_id not in PARADIGMS: return false
    if paradigm_id not in available_paradigms(hero): return false
    if not can_attempt_awakening(hero): return false
    hero["fifth_tier"]["unlocked"] = true
    hero["fifth_tier"]["paradigm"] = paradigm_id
    hero["fifth_tier"]["awakening_count"] = int(hero["fifth_tier"].get("awakening_count", 0)) + 1
    hero["fifth_tier"]["simulation_paradox"] = 0.0
    hero["fifth_tier"]["entropy_shards"] = 0
    hero["fifth_tier"]["network_resonance"] = 0.0
    return true

static func paradigm_for_class(class_id: String) -> String:
    return str(CLASS_AFFINITY.get(class_id, "matrix_sovereign"))

static func paradigm_profile(paradigm_id: String) -> Dictionary:
    return PARADIGMS.get(paradigm_id, {})

static func add_simulation_paradox(hero: Dictionary, amount: float) -> Dictionary:
    ensure_state(hero)
    var state: Dictionary = hero["fifth_tier"]
    state["simulation_paradox"] = clamp(float(state.get("simulation_paradox", 0.0)) + max(0.0, amount), 0.0, PARADOX_MAX)
    var collapsed := false
    if float(state["simulation_paradox"]) >= PARADOX_MAX:
        collapsed = true
        state["simulation_paradox"] = 35.0
        state["paradox_collapse_count"] = int(state.get("paradox_collapse_count", 0)) + 1
    return {"value": state["simulation_paradox"], "collapsed": collapsed}

static func add_entropy_shards(hero: Dictionary, amount: int) -> int:
    ensure_state(hero)
    hero["fifth_tier"]["entropy_shards"] = clampi(int(hero["fifth_tier"].get("entropy_shards", 0)) + max(0, amount), 0, ENTROPY_MAX)
    return int(hero["fifth_tier"]["entropy_shards"])

static func set_network_resonance(hero: Dictionary, value: float) -> float:
    ensure_state(hero)
    hero["fifth_tier"]["network_resonance"] = clamp(value, 0.0, NETWORK_RESONANCE_MAX)
    return float(hero["fifth_tier"]["network_resonance"])

static func consume_resource(hero: Dictionary, resource: String, amount: float) -> bool:
    ensure_state(hero)
    if amount <= 0.0: return true
    var state: Dictionary = hero["fifth_tier"]
    if resource == "simulation_paradox":
        if float(state["simulation_paradox"]) < amount: return false
        state["simulation_paradox"] -= amount
        return true
    if resource == "entropy_shards":
        if int(state["entropy_shards"]) < int(amount): return false
        state["entropy_shards"] -= int(amount)
        return true
    if resource == "network_resonance":
        if float(state["network_resonance"]) < amount: return false
        state["network_resonance"] -= amount
        return true
    return false

static func use_skill(hero: Dictionary, skill_id: String) -> Dictionary:
    ensure_state(hero)
    var state: Dictionary = hero["fifth_tier"]
    if not bool(state.get("unlocked", false)): return {"ok": false, "reason": "fifth_tier_locked"}
    var paradigm: Dictionary = paradigm_profile(str(state.get("paradigm", "")))
    if skill_id not in paradigm.get("skills", []): return {"ok": false, "reason": "skill_not_available"}
    var cost := _skill_cost(skill_id)
    var resource := _skill_resource(skill_id)
    if not consume_resource(hero, resource, cost): return {"ok": false, "reason": "insufficient_resource", "resource": resource, "cost": cost}
    state["skills"][skill_id] = int(state["skills"].get(skill_id, 0)) + 1
    return {"ok": true, "skill": skill_id, "resource": resource, "cost": cost, "rank": state["skills"][skill_id]}

static func _skill_resource(skill_id: String) -> String:
    if skill_id in ["absolute_vacuum", "causality_rupture", "structural_scar"]: return "entropy_shards"
    if skill_id in ["card_suppression", "algorithmic_reprogramming", "fabricator_node"]: return "network_resonance"
    return "simulation_paradox"

static func _skill_cost(skill_id: String) -> float:
    match skill_id:
        "gravity_well": return 12.0
        "unyielding_threshold": return 18.0
        "coordinate_lock": return 35.0
        "absolute_vacuum": return 2.0
        "causality_rupture": return 3.0
        "structural_scar": return 6.0
        "temporal_anchor": return 20.0
        "primordial_chaos": return 10.0
        "stasis_dome": return 35.0
        "card_suppression": return 15.0
        "algorithmic_reprogramming": return 25.0
        "fabricator_node": return 40.0
    return 999.0

static func tick(hero: Dictionary, delta: float, linked_party_count: int) -> Dictionary:
    ensure_state(hero)
    var state: Dictionary = hero["fifth_tier"]
    if not bool(state.get("unlocked", false)): return {"active": false}
    if str(state.get("paradigm", "")) == "matrix_sovereign":
        if linked_party_count <= 0:
            state["network_resonance"] = max(0.0, float(state["network_resonance"]) - 20.0 * max(0.0, delta))
        else:
            state["network_resonance"] = min(NETWORK_RESONANCE_MAX, float(state["network_resonance"]) + float(linked_party_count) * 3.0 * max(0.0, delta))
    return {"active": true, "paradigm": state["paradigm"], "network_resonance": state["network_resonance"]}

static func visual_profile(hero: Dictionary) -> Dictionary:
    ensure_state(hero)
    var state: Dictionary = hero["fifth_tier"]
    if not bool(state.get("unlocked", false)): return {"awakened": false}
    var paradigm_id := str(state.get("paradigm", ""))
    var profile := paradigm_profile(paradigm_id)
    return {
        "awakened": true,
        "paradigm": paradigm_id,
        "title": profile.get("title", "Transcendent"),
        "floating_height": 0.22,
        "geometry_aura": true,
        "timeline_distortion": paradigm_id == "chrono_architect",
        "vacuum_field": paradigm_id == "doomsday_vector",
        "gravity_field": paradigm_id == "singularity_arch",
        "fabricator_holograms": paradigm_id == "matrix_sovereign",
    }

static func rules_reference() -> Dictionary:
    return {"tier": FIFTH_TIER, "name": "Transcendence", "required_level": REQUIRED_LEVEL, "max_level": MAX_LEVEL, "paradigms": PARADIGMS, "resources": RESOURCE_RULES, "class_affinity": CLASS_AFFINITY}
