class_name CombatAnimationController
extends Node3D

var game:Node3D
var legacy:Node2D
var hero_player:AnimationPlayer
var pet_player:AnimationPlayer
var hero_tree:AnimationTree
var pet_tree:AnimationTree
var hero_machine:AnimationNodeStateMachinePlayback
var pet_machine:AnimationNodeStateMachinePlayback
var last_hero_pos:=Vector2.ZERO
var elapsed:=0.0
var hero_pulse:=0.0
var pet_pulse:=0.0
var hit_pulse:=0.0
var hero_attack_lock:=0.0
var pet_attack_lock:=0.0
var hero_state:String=""
var monster_hp_cache:Dictionary={}
var monster_hit_timer:Dictionary={}
var monster_base_y:Dictionary={}

func _ready()->void:
    game=get_parent() as Node3D
    if game!=null:
        legacy=game.get_node_or_null("LegacyGame")
    _build_animation_players()
    _build_animation_trees()
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

func _build_animation_trees()->void:
    hero_tree=_make_tree(hero_player)
    hero_tree.name="HeroAnimationTree"
    add_child(hero_tree)
    pet_tree=_make_tree(pet_player)
    pet_tree.name="PetAnimationTree"
    add_child(pet_tree)
    hero_machine=hero_tree.get("parameters/playback") as AnimationNodeStateMachinePlayback
    pet_machine=pet_tree.get("parameters/playback") as AnimationNodeStateMachinePlayback
    if hero_machine!=null:
        hero_machine.start("idle")
    if pet_machine!=null:
        pet_machine.start("idle")

func _make_tree(player:AnimationPlayer)->AnimationTree:
    var tree:=AnimationTree.new()
    tree.anim_player=NodePath("../"+player.name)
    var machine:=AnimationNodeStateMachine.new()
    machine.add_node("idle",_animation_node("idle"),Vector2(-360,0))
    machine.add_node("walk",_animation_node("walk"),Vector2(-80,0))
    machine.add_node("attack",_animation_node("attack"),Vector2(200,-100))
    machine.add_node("hit",_animation_node("hit"),Vector2(200,100))
    _add_transition(machine,"idle","walk",0.10)
    _add_transition(machine,"walk","idle",0.10)
    _add_transition(machine,"idle","attack",0.04)
    _add_transition(machine,"walk","attack",0.04)
    _add_transition(machine,"idle","hit",0.03)
    _add_transition(machine,"walk","hit",0.03)
    _add_transition(machine,"attack","idle",0.08)
    _add_transition(machine,"attack","walk",0.08)
    _add_transition(machine,"hit","idle",0.06)
    tree.tree_root=machine
    tree.active=true
    return tree

func _animation_node(animation_name:String)->AnimationNodeAnimation:
    var node:=AnimationNodeAnimation.new()
    node.animation=StringName(animation_name)
    return node

func _add_transition(machine:AnimationNodeStateMachine,from:String,to:String,fade:float)->void:
    var transition:=AnimationNodeStateMachineTransition.new()
    transition.xfade_time=fade
    transition.advance_mode=AnimationNodeStateMachineTransition.ADVANCE_MODE_ENABLED
    machine.add_transition(from,to,transition)

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
    for id in monster_hit_timer.keys():
        monster_hit_timer[id]=max(0.0,float(monster_hit_timer[id])-delta)
        if float(monster_hit_timer[id])<=0.0:
            monster_hit_timer.erase(id)
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
        _set_pet_state("idle")
    _update_monster_motion()
    _watch_combat_effects()

func _set_hero_state(state:String)->void:
    if hero_machine==null or hero_state==state:
        return
    hero_state=state
    hero_machine.travel(state)

func _set_pet_state(state:String)->void:
    if pet_machine==null:
        return
    if str(pet_machine.get_current_node())!=state:
        pet_machine.travel(state)

func _update_monster_motion()->void:
    var monsters_value:Variant=legacy.get("monsters")
    if not monsters_value is Array:
        return
    var active:Dictionary={}
    var visuals:Dictionary=game.get("monster_visuals") as Dictionary
    for item in monsters_value:
        if not item is Dictionary:
            continue
        var monster:Dictionary=item
        var id:String=str(monster.get("visual_id",monster.get("name","monster")))
        active[id]=true
        if not visuals.has(id):
            continue
        var visual:Node3D=visuals[id] as Node3D
        if visual==null:
            continue
        if not monster_base_y.has(id):
            monster_base_y[id]=visual.position.y
        var base_y:float=float(monster_base_y[id])
        var hp:int=int(monster.get("hp",0))
        var old_hp:int=int(monster_hp_cache.get(id,hp))
        if hp<old_hp:
            monster_hit_timer[id]=0.18
            _monster_hit_burst(visual)
        monster_hp_cache[id]=hp
        var hit:float=float(monster_hit_timer.get(id,0.0))
        var boss:bool=bool(monster.get("mvp",false))
        var bob_speed:float=2.6 if boss else 3.4
        var bob_amount:float=0.055 if boss else 0.035
        var target_y:float=base_y+sin(elapsed*bob_speed+float(id.hash()%17))*bob_amount
        visual.position.y=lerp(visual.position.y,target_y,0.10)
        var target_scale:Vector3=Vector3.ONE*(1.08 if boss else 1.0)
        if hit>0.0:
            target_scale*=Vector3(1.13,0.86,1.13)
        else:
            target_scale*=1.0+sin(elapsed*2.2+float(id.hash()%11))*0.012
        visual.scale=visual.scale.lerp(target_scale,0.16)
        visual.rotation.y+=delta_rotation(boss)
    for id in monster_hp_cache.keys():
        if not active.has(id):
            monster_hp_cache.erase(id)
            monster_hit_timer.erase(id)
            monster_base_y.erase(id)

func delta_rotation(boss:bool)->float:
    return (0.0035 if boss else 0.0020)*sin(elapsed*1.7)

func _monster_hit_burst(visual:Node3D)->void:
    if visual==null:
        return
    var burst:Node3D=Node3D.new()
    burst.name="HitPulse"
    visual.add_child(burst)
    var ring:MeshInstance3D=MeshInstance3D.new()
    var mesh:TorusMesh=TorusMesh.new()
    mesh.inner_radius=0.12
    mesh.outer_radius=0.18
    ring.mesh=mesh
    ring.rotation_degrees.x=90.0
    burst.add_child(ring)
    var tween:Tween=create_tween()
    tween.set_parallel(true)
    tween.tween_property(ring,"scale",Vector3(3.0,3.0,3.0),0.16)
    tween.chain().tween_callback(burst.queue_free)

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
    if hero_machine!=null:
        hero_machine.travel("attack")

func trigger_pet_attack()->void:
    pet_pulse=1.0
    pet_attack_lock=0.30
    if pet_machine!=null:
        pet_machine.travel("attack")

func trigger_hit()->void:
    hit_pulse=1.0
    if hero_machine!=null:
        hero_machine.travel("hit")
