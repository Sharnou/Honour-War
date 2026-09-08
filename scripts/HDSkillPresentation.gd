class_name HDSkillPresentation
extends Node

signal cast_started(skill_id:String, skill_name:String, duration:float)
signal cast_completed(skill_id:String, skill_name:String)
signal cooldown_started(skill_id:String, cooldown:float)
signal rejected(skill_id:String, reason:String)

@export var feedback_path:NodePath
@export var cast_time:float = 0.18

var feedback:Node
var active_skill:String = ""
var active_until:float = 0.0

func _ready() -> void:
    feedback = get_node_or_null(feedback_path)
    if feedback == null:
        feedback = get_parent().get_node_or_null("HDCombatFeedback")

func try_cast(hero:Dictionary, skill_id:String, target_position:Vector3, now:float = -1.0)->Dictionary:
    if now < 0.0:
        now = Time.get_ticks_msec() / 1000.0
    var result:Dictionary = SkillSystem.use(hero, skill_id, now)
    if not bool(result.get("ok",false)):
        rejected.emit(skill_id,str(result.get("reason","rejected")))
        return result
    var skill:Dictionary = result["skill"]
    active_skill = skill_id
    active_until = now + cast_time
    cast_started.emit(skill_id,str(skill["name"]),cast_time)
    if feedback:
        if feedback.has_method("show_telegraph") and _is_area_skill(skill_id):
            feedback.show_telegraph("circle",target_position,_skill_radius(skill_id),max(0.35,cast_time + 0.2))
        if feedback.has_method("play_skill_effect"):
            feedback.play_skill_effect(skill_id,target_position)
    cooldown_started.emit(skill_id,float(skill.get("cooldown",0.0)))
    cast_completed.emit(skill_id,str(skill["name"]))
    return result

func _is_area_skill(skill_id:String)->bool:
    return skill_id in [
        "war_whirlwind","war_earthbreaker","war_emperors_judgment","war_immortal_arsenal",
        "mage_comet","mage_frost_prison","mage_meteor_surge","mage_arcane_overload","mage_astral_apocalypse",
        "arch_trap","arch_hawk_storm","arch_celestial_barrage",
        "thief_smoke","thief_shadow_requiem","thief_eternal_assassin",
        "aco_sanctuary","aco_holy_nova","aco_seraphic_light","aco_judgment","aco_heaven_gate",
        "mer_cart_impact","mer_magma_forge","mer_titan_cart","mer_arsenal_overlord"
    ]

func _skill_radius(skill_id:String)->float:
    if skill_id in ["mage_astral_apocalypse","arch_celestial_barrage","war_immortal_arsenal","aco_heaven_gate","mer_arsenal_overlord","thief_eternal_assassin"]:
        return 4.5
    if skill_id in ["war_earthbreaker","mage_meteor_surge","arch_hawk_storm","aco_judgment","mer_titan_cart","thief_shadow_requiem"]:
        return 3.0
    return 2.0
