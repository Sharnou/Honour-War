class_name FifthTierClassTreeSystem
extends RefCounted

## Honour War Fifth Tier: Transcendence.
## Fifth-tier identity is derived from the hero's FIRST-TIER profession.
## Weapon, silhouette, materials, aura and VFX remain profession-authentic while
## the transcendent mechanics come from the mapped apex paradigm.

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

# Every Fifth Tier is permanently rooted in the hero's original profession.
# A profession may share an apex paradigm with another profession, but never
# shares its weapon identity, materials, silhouette or visual language.
const CLASS_AFFINITY := {
    "Warrior": {
        "paradigm": "singularity_arch",
        "name": "Warrior: Singularity Warlord",
        "title": "The Gravitational Vanguard",
        "weapon_family": "sword_and_shield",
        "primary_weapon": "Transcendent Greatsword",
        "secondary_weapon": "Singularity Shield",
        "weapon_material": "void-tempered steel",
        "armor_material": "blackened warplate",
        "accent_material": "crimson gravity crystal",
        "silhouette": "armored vanguard with broad shoulders, grounded shield profile and floating blade shards",
        "aura": "crimson gravitational rings with compressed steel fragments",
        "vfx": "gravity arcs, impact compression and red spatial distortion",
        "visual_rule": "retain Warrior armor mass, shield stance and sword-first combat silhouette",
    },
    "Mage": {
        "paradigm": "chrono_architect",
        "name": "Mage: Chrono Arcanist",
        "title": "The Eternal Spellwright",
        "weapon_family": "staff",
        "primary_weapon": "Chrono Arcane Staff",
        "secondary_weapon": "Aether Focus",
        "weapon_material": "astral crystal and elderwood",
        "armor_material": "layered arcane silk and crystal filaments",
        "accent_material": "prismatic timeglass",
        "silhouette": "robed caster with tall staff, floating spell rings and luminous headpiece",
        "aura": "violet-blue clockwork sigils and suspended crystal motes",
        "vfx": "time trails, glyph recursion and frozen spell frames",
        "visual_rule": "retain Mage robe, staff, caster posture and spell-circle language",
    },
    "Archer": {
        "paradigm": "doomsday_vector",
        "name": "Archer: Doomsday Ranger",
        "title": "The Causality Marksman",
        "weapon_family": "bow",
        "primary_weapon": "Doomsday Longbow",
        "secondary_weapon": "Causality Quiver",
        "weapon_material": "starwood and vacuum-fiber",
        "armor_material": "layered ranger leather and lightweight alloy",
        "accent_material": "golden aether crystal",
        "silhouette": "light-footed ranger with longbow, quiver and elevated aiming posture",
        "aura": "thin golden targeting lines and geometric arrow trajectories",
        "vfx": "vacuum arrows, causality trails and persistent ground scars",
        "visual_rule": "retain Archer bow, quiver, agile stance and ranged-combat silhouette",
    },
    "Thief": {
        "paradigm": "doomsday_vector",
        "name": "Thief: Causality Assassin",
        "title": "The Absolute Shadow",
        "weapon_family": "dual_daggers",
        "primary_weapon": "Causality Twin Daggers",
        "secondary_weapon": "Voidstep Blade",
        "weapon_material": "phase-forged voidsteel",
        "armor_material": "shadowweave leather and flexible void mesh",
        "accent_material": "black-violet null crystal",
        "silhouette": "low-profile rogue with paired blades, asymmetric cloak and forward-leaning stance",
        "aura": "black-violet fracture lines and short-range afterimages",
        "vfx": "blink cuts, vacuum crescents and causality rupture marks",
        "visual_rule": "retain Thief dual-blade, stealth posture and lightweight silhouette",
    },
    "Acolyte": {
        "paradigm": "chrono_architect",
        "name": "Acolyte: Chrono Seraph",
        "title": "The Eternal Benediction",
        "weapon_family": "mace_and_holy_focus",
        "primary_weapon": "Chrono Sanctified Mace",
        "secondary_weapon": "Seraphic Scripture",
        "weapon_material": "consecrated silver and timeglass",
        "armor_material": "white sanctified vestment with luminous plate",
        "accent_material": "radiant gold crystal",
        "silhouette": "support cleric with mace, holy focus and layered halo geometry",
        "aura": "golden concentric halos with white temporal particles",
        "vfx": "time-locked blessings, restorative frames and stasis geometry",
        "visual_rule": "retain Acolyte holy vestment, mace/focus language and support-caster posture",
    },
    "Merchant": {
        "paradigm": "matrix_sovereign",
        "name": "Merchant: Matrix Artificer",
        "title": "The Infinite Quartermaster",
        "weapon_family": "axe",
        "primary_weapon": "Matrix Forged Axe",
        "secondary_weapon": "Fabricator Ledger",
        "weapon_material": "runic brass and hardened industrial steel",
        "armor_material": "reinforced trader coat, plated harness and utility belts",
        "accent_material": "emerald data-crystal",
        "silhouette": "heavy utility merchant with broad axe, pack frame and mechanical modules",
        "aura": "green data grids, rotating inventory glyphs and fabrication sparks",
        "vfx": "repair beams, item-grid projections and autonomous fabricator drones",
        "visual_rule": "retain Merchant axe, equipment-heavy silhouette and industrial-trader identity",
    },
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
    if not state.has("profession_id"): state["profession_id"] = str(hero.get("class_id", hero.get("class", "")))
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

static func awaken(hero: Dictionary, paradigm_id: String = "") -> bool:
    ensure_state(hero)
    var profession_id := first_tier_profession(hero)
    var expected_paradigm := paradigm_for_class(profession_id)
    if paradigm_id.is_empty(): paradigm_id = expected_paradigm
    if paradigm_id != expected_paradigm: return false
    if paradigm_id not in PARADIGMS: return false
    if not available_paradigms(hero).has(paradigm_id): return false
    if not can_attempt_awakening(hero): return false
    hero["fifth_tier"]["unlocked"] = true
    hero["fifth_tier"]["paradigm"] = paradigm_id
    hero["fifth_tier"]["profession_id"] = profession_id
    hero["fifth_tier"]["awakening_count"] = int(hero["fifth_tier"].get("awakening_count", 0)) + 1
    hero["fifth_tier"]["simulation_paradox"] = 0.0
    hero["fifth_tier"]["entropy_shards"] = 0
    hero["fifth_tier"]["network_resonance"] = 0.0
    return true

static func first_tier_profession(hero: Dictionary) -> String:
    var state: Dictionary = hero.get("fifth_tier", {})
    var stored := str(state.get("profession_id", ""))
    if CLASS_AFFINITY.has(stored): return stored
    var direct := str(hero.get("first_tier_profession", hero.get("class_id", hero.get("class", ""))))
    if CLASS_AFFINITY.has(direct): return direct
    return "Warrior"

static func paradigm_for_class(class_id: String) -> String:
    var profile: Dictionary = CLASS_AFFINITY.get(class_id, {})
    return str(profile.get("paradigm", "singularity_arch"))

static func class_profile(class_id: String) -> Dictionary:
    return CLASS_AFFINITY.get(class_id, {})

static func natural_fifth_tier_profile(class_id: String) -> Dictionary:
    var profession := class_profile(class_id)
    if profession.is_empty(): return {}
    var paradigm_id := str(profession.get("paradigm", ""))
    var paradigm := paradigm_profile(paradigm_id)
    var result: Dictionary = profession.duplicate(true)
    result["first_tier_profession"] = class_id
    result["fifth_tier"] = 5
    result["paradigm_id"] = paradigm_id
    result["paradigm_name"] = paradigm.get("name", "")
    result["composite_attribute"] = paradigm.get("composite", "")
    return result

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
    var profession_id := first_tier_profession(hero)
    var profession := class_profile(profession_id)
    if not bool(state.get("unlocked", false)):
        return {"awakened": false, "first_tier_profession": profession_id, "natural_profile": profession}
    var paradigm_id := str(state.get("paradigm", paradigm_for_class(profession_id)))
    var paradigm := paradigm_profile(paradigm_id)
    return {
        "awakened": true,
        "tier": FIFTH_TIER,
        "first_tier_profession": profession_id,
        "name": profession.get("name", "Transcendent"),
        "title": profession.get("title", paradigm.get("title", "Transcendent")),
        "paradigm": paradigm_id,
        "paradigm_name": paradigm.get("name", ""),
        "weapon_family": profession.get("weapon_family", ""),
        "primary_weapon": profession.get("primary_weapon", ""),
        "secondary_weapon": profession.get("secondary_weapon", ""),
        "weapon_material": profession.get("weapon_material", ""),
        "armor_material": profession.get("armor_material", ""),
        "accent_material": profession.get("accent_material", ""),
        "silhouette": profession.get("silhouette", ""),
        "aura": profession.get("aura", ""),
        "vfx": profession.get("vfx", ""),
        "visual_rule": profession.get("visual_rule", ""),
        "composite_attribute": paradigm.get("composite", ""),
        "floating_height": 0.22,
        "geometry_aura": true,
        "timeline_distortion": paradigm_id == "chrono_architect",
        "vacuum_field": paradigm_id == "doomsday_vector",
        "gravity_field": paradigm_id == "singularity_arch",
        "fabricator_holograms": paradigm_id == "matrix_sovereign",
    }

static func rules_reference() -> Dictionary:
    return {
        "tier": FIFTH_TIER,
        "name": "Transcendence",
        "required_level": REQUIRED_LEVEL,
        "max_level": MAX_LEVEL,
        "paradigms": PARADIGMS,
        "resources": RESOURCE_RULES,
        "class_affinity": CLASS_AFFINITY,
        "weapon_locked_to_first_tier": true,
        "visual_identity_locked_to_first_tier": true,
        "material_identity_locked_to_first_tier": true,
    }
