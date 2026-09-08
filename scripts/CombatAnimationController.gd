class_name CombatAnimationController
extends Node3D

var game:Node3D
var legacy:Node2D
var hero_player:AnimationPlayer
var pet_player:AnimationPlayer
var last_hero_pos:=Vector2.ZERO
var elapsed:=0.0
var hero_pulse:=0.0
var pet_pulse:=0.0
var hit_pulse:=0.0
var hero_attack_lock:=0.0
var pet_attack_lock:=0.0
var hero_state: String = ""

func _ready()->void:
    game=get_parent() as Node3D
    if game!=null:
        legacy=game.get_node_or_null("LegacyGame")
    _build_animation_players()
    set_process(true)

func _build_animation_players()->void:
    hero_player=AnimationPlayer.new()
    hero_player.name="HeroAnimationPlayer"
    add_child(hero_player)
    hero_player.add_animation_library("",_build_library(false))
    pet_player=AnimationPlayer.new()
    pet_player.name="PetAnimationPlayer"
    add_child(pet_player)
    pet_player.add_animation_library("",_build_library(true))

func _build_library(is_pet:bool)->AnimationLibrary:
    var library:=AnimationLibrary.new()
    library.add_animation("idle",_make_idle(is_pet))
    library.add_animation("walk",_make_walk(is_pet))
    library.add_animation("attack",_make_attack(is_pet))
    library.add_animation("hit",_make_hit(is_pet))
    return library

func _make_idle(is_pet:bool)->Animation:
    var animation:=Animation.new()
    animation.length=1.2
    animation.loop_mode=Animation.LOOP_LINEAR
    var track:=animation.add_track(Animation.TYPE_VALUE)
    animation.track_set_path(track,NodePath("../Actors3D/Pet:scale" if is_pet else "../Actors3D/Hero:scale"))
    animation.track_insert_key(track,0.0,Vector3.ONE)
    animation.track_insert_key(track,0.6,Vector3(1.0,1.015 if is_pet else 1.012,1.0))
    animation.track_insert_key(track,1.2,Vector3.ONE)
    return animation

func _make_walk(is_pet:bool)->Animation:
    var animation:=Animation.new()
    animation.length=0.55
    animation.loop_mode=Animation.LOOP_LINEAR
    var path:=NodePath("../Actors3D/Pet:position:y" if is_pet else "../Actors3D/Hero:position:y")
    var track:=animation.add_track(Animation.TYPE_VALUE)
    animation.track_set_path(track,path)
    var base:float=0.45 if is_pet else 0.15
    animation.track_insert_key(track,0.0,base)
    animation.track_insert_key(track,0.14,base+0.055)
    animation.track_insert_key(track,0.275,base)
    animation.track_insert_key(track,0.41,base+0.055)
    animation.track_insert_key(track,0.55,base)
    return animation

func _make_attack(is_pet:bool)->Animation:
    var animation:=Animation.new()
    animation.length=0.30 if is_pet else 0.34
    var rotation_track:=animation.add_track(Animation.TYPE_VALUE)
    animation.track_set_path(rotation_track,NodePath("../Actors3D/Pet:rotation:y" if is_pet else "../Actors3D/Hero:rotation:y"))
    animation.track_insert_key(rotation_track,0.0,0.0)
    animation.track_insert_key(rotation_track,0.12,-0.28 if not is_pet else -0.18)
    animation.track_insert_key(rotation_track,0.22,0.34 if not is_pet else 0.24)
    animation.track_insert_key(rotation_track,animation.length,0.0)
    var scale_track:=animation.add_track(Animation.TYPE_VALUE)
    animation.track_set_path(scale_track,NodePath("../Actors3D/Pet:scale" if is_pet else "../Actors3D/Hero:scale"))
    animation.track_insert_key(scale_track,0.0,Vector3.ONE)
    animation.track_insert_key(scale_track,0.12,Vector3(1.08,0.94,1.08))
    animation.track_insert_key(scale_track,0.22,Vector3(1.10,1.06,1.10))
    animation.track_insert_key(scale_track,animation.length,Vector3.ONE)
    return animation

func _make_hit(is_pet:bool)->Animation:
    var animation:=Animation.new()
    animation.length=0.24
    var track:=animation.add_track(Animation.TYPE_VALUE)
    animation.track_set_path(track,NodePath("../Actors3D/Pet:position:x" if is_pet else "../Actors3D/Hero:position:x"))
    animation.track_insert_key(track,0.0,0.0)
    animation.track_insert_key(track,0.06,-0.06)
    animation.track_insert_key(track,0.12,0.06)
    animation.track_insert_key(track,0.18,-0.035)
    animation.track_insert_key(track,0.24,0.0)
    return animation

func _process(delta:float)->void:
    elapsed+=delta
    hero_pulse=max(0.0,hero_pulse-delta*5.0)
    pet_pulse=max(0.0,pet_pulse-delta*5.5)
    hit_pulse=max(0.0,hit_pulse-delta*8.0)
    hero_attack_lock=max(0.0,hero_attack_lock-delta)
    pet_attack_lock=max(0.0,pet_attack_lock-delta)
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
        var moving:=moved>2.0 and last_hero_pos!=Vector2.ZERO
        if hero_attack_lock<=0.0 and hero_pulse<=0.0 and hit_pulse<=0.0:
            _set_hero_state("walk" if moving else "idle")
        last_hero_pos=hero_pos
    if pet_node!=null and pet_attack_lock<=0.0 and pet_pulse<=0.0:
        if pet_player.current_animation!="idle":
            pet_player.play("idle",0.10)
    _watch_combat_effects()

func _set_hero_state(state:String)->void:
    if hero_player==null or hero_state==state:
        return
    hero_state=state
    hero_player.play(state,0.10)

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
            trigger_hero_attack()
        elif kind=="pet_attack":
            trigger_pet_attack()
        elif kind=="hit" or kind=="critical":
            trigger_hit()

func trigger_hero_attack()->void:
    hero_pulse=1.0
    hero_attack_lock=0.34
    if hero_player!=null:
        hero_player.play("attack",0.05)

func trigger_pet_attack()->void:
    pet_pulse=1.0
    pet_attack_lock=0.30
    if pet_player!=null:
        pet_player.play("attack",0.05)

func trigger_hit()->void:
    hit_pulse=1.0
    if hero_player!=null:
        hero_player.play("hit",0.04)
