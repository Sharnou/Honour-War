class_name CombatAnimationController
extends Node3D

var game:Node3D
var legacy:Node2D
var last_hero_pos:=Vector2.ZERO
var elapsed:=0.0
var hero_pulse:=0.0
var pet_pulse:=0.0
var hit_pulse:=0.0

func _ready()->void:
    game=get_parent() as Node3D
    if game!=null:
        legacy=game.get_node_or_null("LegacyGame")
    set_process(true)

func _process(delta:float)->void:
    elapsed+=delta
    hero_pulse=max(0.0,hero_pulse-delta*5.0)
    pet_pulse=max(0.0,pet_pulse-delta*5.5)
    hit_pulse=max(0.0,hit_pulse-delta*8.0)
    if game==null or legacy==null:
        return
    var hero_value:Variant=legacy.get("hero")
    if not hero_value is Dictionary:
        return
    var hero:Dictionary=hero_value
    var hero_node:Node3D=game.get("hero_visual") as Node3D
    var pet_node:Node3D=game.get("pet_visual") as Node3D
    if hero_node!=null:
        var hero_pos:=Vector2(float(hero.get("pos_x",595.0)),float(hero.get("pos_y",340.0)))
        var moved:=hero_pos.distance_to(last_hero_pos)
        var locomotion:=clamp(moved/2.0,0.0,1.0)
        hero_node.scale=Vector3.ONE*(1.0+sin(elapsed*3.2)*0.012)
        if moved>2.0 and last_hero_pos!=Vector2.ZERO:
            hero_node.position.y+=abs(sin(elapsed*9.0))*0.025*locomotion
        if hero_pulse>0.0:
            hero_node.scale*=1.0+hero_pulse*0.14
        if hit_pulse>0.0:
            hero_node.position.x+=sin(elapsed*42.0)*hit_pulse*0.035
        last_hero_pos=hero_pos
    if pet_node!=null:
        pet_node.scale=Vector3.ONE*(1.0+sin(elapsed*4.6)*0.018)
        if pet_pulse>0.0:
            pet_node.scale*=1.0+pet_pulse*0.16
    _watch_combat_effects()

func _watch_combat_effects()->void:
    var vfx=legacy.get_node_or_null("CombatVFX")
    if vfx==null:
        return
    var effects_value:Variant=vfx.get("effects")
    if not effects_value is Array:
        return
    for effect in effects_value:
        if not effect is Dictionary:
            continue
        var kind:=str(effect.get("kind",""))
        var age:=float(effect.get("age",99.0))
        if age>0.08:
            continue
        if kind=="hero_attack":
            hero_pulse=1.0
        elif kind=="pet_attack":
            pet_pulse=1.0
        elif kind=="hit" or kind=="critical":
            hit_pulse=1.0

func trigger_hero_attack()->void:
    hero_pulse=1.0

func trigger_pet_attack()->void:
    pet_pulse=1.0
