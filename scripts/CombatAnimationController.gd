class_name CombatAnimationController
extends Node3D

signal hero_attack_started
signal hero_attack_impact
signal hero_attack_completed
signal pet_attack_started
signal pet_attack_impact
signal pet_attack_completed

var game:Node3D
var legacy:Node2D
var hero_timer:float=0.0
var pet_timer:float=0.0
var hero_active:bool=false
var pet_active:bool=false
var elapsed:float=0.0

const HERO_ATTACK_LENGTH:float=0.34
const HERO_IMPACT_TIME:float=0.20
const PET_ATTACK_LENGTH:float=0.30
const PET_IMPACT_TIME:float=0.18

func _ready()->void:
    game=get_parent() as Node3D
    if game!=null: legacy=game.get_node_or_null("LegacyGame") as Node2D

func _process(delta:float)->void:
    elapsed+=delta
    if hero_active:
        hero_timer+=delta
        var hero:Node3D=game.get("hero_visual") as Node3D if game else null
        if hero:
            var phase:=clamp(hero_timer/HERO_ATTACK_LENGTH,0.0,1.0)
            hero.scale=Vector3.ONE*(1.0+sin(phase*PI)*0.08)
        if hero_timer>=HERO_IMPACT_TIME and hero_timer-delta<HERO_IMPACT_TIME: hero_attack_impact.emit()
        if hero_timer>=HERO_ATTACK_LENGTH:
            hero_active=false
            if hero: hero.scale=Vector3.ONE
            hero_attack_completed.emit()
    if pet_active:
        pet_timer+=delta
        var pet:Node3D=game.get("pet_visual") as Node3D if game else null
        if pet:
            var phase_pet:=clamp(pet_timer/PET_ATTACK_LENGTH,0.0,1.0)
            pet.scale=Vector3.ONE*(1.0+sin(phase_pet*PI)*0.10)
        if pet_timer>=PET_IMPACT_TIME and pet_timer-delta<PET_IMPACT_TIME: pet_attack_impact.emit()
        if pet_timer>=PET_ATTACK_LENGTH:
            pet_active=false
            if pet: pet.scale=Vector3.ONE
            pet_attack_completed.emit()

func play_hero_attack()->void:
    if hero_active: return
    hero_timer=0.0
    hero_active=true
    hero_attack_started.emit()

func play_pet_attack()->void:
    if pet_active: return
    pet_timer=0.0
    pet_active=true
    pet_attack_started.emit()

func trigger_monster_hit(visual:Node3D)->void:
    if visual==null or not is_instance_valid(visual): return
    var burst:=MeshInstance3D.new()
    var mesh:=SphereMesh.new()
    mesh.radius=0.18
    mesh.height=0.36
    burst.mesh=mesh
    burst.position=Vector3(0.0,1.0,0.0)
    var material:=StandardMaterial3D.new()
    material.albedo_color=Color("#f5e4b2")
    material.emission_enabled=true
    material.emission=Color("#f5e4b2")
    material.emission_energy_multiplier=2.0
    material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
    burst.material_override=material
    visual.add_child(burst)
    var tween:=create_tween()
    tween.set_parallel(true)
    tween.tween_property(burst,"scale",Vector3.ONE*2.0,0.18)
    tween.tween_method(func(alpha:float)->void:
        if is_instance_valid(material): material.albedo_color=Color(0.96,0.89,0.70,alpha)
    ,1.0,0.0,0.16)
    tween.set_parallel(false)
    tween.tween_callback(burst.queue_free)
