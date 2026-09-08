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
var hero_timeline:=0.0
var pet_timeline:=0.0
var hero_timeline_active:=false
var pet_timeline_active:=false
const HERO_ATTACK_LENGTH:=0.34
const HERO_IMPACT_TIME:=0.20
const PET_ATTACK_LENGTH:=0.30
const PET_IMPACT_TIME:=0.18

func _ready()->void:
    game=get_parent() as Node3D
    if game!=null:
        legacy=game.get_node_or_null("LegacyGame")
    call_deferred("_build_runtime_nodes")
    set_process(true)

func _build_runtime_nodes()->void:
    if not is_inside_tree(): return
    _build_animation_players()
    _build_animation_trees()

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
    if hero_machine!=null: hero_machine.start("idle")
    if pet_machine!=null: pet_machine.start("idle")

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
    var path:=NodePath("../Actors3D/Pet:scale" if is_pet else "../Actors3D/Hero:scale")
    var track:=animation.add_track(Animation.TYPE_VALUE)
    animation.track_set_path(track,path)
    animation.track_insert_key(track,0.0,Vector3.ONE)
    animation.track_insert_key(track,0.14,Vector3(1.015,0.985,1.015))
    animation.track_insert_key(track,0.275,Vector3.ONE)
    animation.track_insert_key(track,0.41,Vector3(1.015,0.985,1.015))
    animation.track_insert_key(track,0.55,Vector3.ONE)
    return animation

func _make_attack(is_pet:bool)->Animation:
    var animation:=Animation.new()
    animation.length=PET_ATTACK_LENGTH if is_pet else HERO_ATTACK_LENGTH
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
    _advance_attack_timelines(delta)
    hero_pulse=max(0.0,hero_pulse-delta*5.0)
    pet_pulse=max(0.0,pet_pulse-delta*5.5)
    hit_pulse=max(0.0,hit_pulse-delta*8.0)
    hero_attack_lock=max(0.0,hero_attack_lock-delta)
    pet_attack_lock=max(0.0,pet_attack_lock-delta)
    for id in monster_hit_timer.keys():
        monster_hit_timer[id]=max(0.0,float(monster_hit_timer[id])-delta)
        if float(monster_hit_timer[id])<=0.0: monster_hit_timer.erase(id)
    if game==null or legacy==null: return
    var hero_value:Variant=legacy.get("hero")
    if not hero_value is Dictionary: return
    var hero:Dictionary=hero_value
    var hero_node:Node3D=game.get("hero_visual") as Node3D
    var pet_node:Node3D=game.get("pet_visual") as Node3D
    if hero_node!=null:
        var hero_pos:=Vector2(float(hero.get("pos_x",595.0)),float(hero.get("pos_y",340.0)))
        var moved:=hero_pos.distance_to(last_hero_pos)
        var moving:=moved>2.0 and last_hero_pos!=Vector2.ZERO
        if hero_attack_lock<=0.0 and hero_pulse<=0.0 and hit_pulse<=0.0: _set_hero_state("walk" if moving else "idle")
        last_hero_pos=hero_pos
    if pet_node!=null and pet_attack_lock<=0.0 and pet_pulse<=0.0: _set_pet_state("idle")
    _update_monster_motion()
    _watch_combat_effects()
    _stabilize_camera()

func _advance_attack_timelines(delta:float)->void:
    if hero_timeline_active:
        var previous:=hero_timeline
        hero_timeline+=delta
        if previous<HERO_IMPACT_TIME and hero_timeline>=HERO_IMPACT_TIME: hero_attack_impact.emit()
        if hero_timeline>=HERO_ATTACK_LENGTH:
            hero_timeline_active=false
            hero_attack_completed.emit()
    if pet_timeline_active:
        var previous_pet:=pet_timeline
        pet_timeline+=delta
        if previous_pet<PET_IMPACT_TIME and pet_timeline>=PET_IMPACT_TIME: pet_attack_impact.emit()
        if pet_timeline>=PET_ATTACK_LENGTH:
            pet_timeline_active=false
            pet_attack_completed.emit()

func play_hero_attack()->void:
    if hero_machine==null or hero_timeline_active: return
    hero_attack_lock=HERO_ATTACK_LENGTH
    hero_timeline=0.0
    hero_timeline_active=true
    hero_pulse=0.8
    hero_machine.travel("attack")
    hero_attack_started.emit()

func play_pet_attack()->void:
    if pet_machine==null or pet_timeline_active: return
    pet_attack_lock=PET_ATTACK_LENGTH
    pet_timeline=0.0
    pet_timeline_active=true
    pet_pulse=0.9
    pet_machine.travel("attack")
    pet_attack_started.emit()

func _stabilize_camera()->void:
    if game==null or legacy==null: return
    var camera:Camera3D=game.get("camera") as Camera3D
    if camera==null or not camera.is_inside_tree(): return
    var hero_value:Variant=legacy.get("hero")
    if not hero_value is Dictionary: return
    var hero:Dictionary=hero_value
    var map_pos:=Vector2(float(hero.get("pos_x",595.0)),float(hero.get("pos_y",340.0)))
    var target:=Vector3((map_pos.x-365.0)*0.055,0.0,(map_pos.y-120.0)*0.055)
    var desired:=target+Vector3(0.0,10.5,13.5)
    camera.position=camera.position.lerp(desired,1.0-exp(-9.0/60.0))
    camera.look_at(target+Vector3(0.0,0.8,0.0),Vector3.UP)

func _set_hero_state(state:String)->void:
    if hero_machine==null or hero_state==state: return
    hero_state=state
    hero_machine.travel(state)

func _set_pet_state(state:String)->void:
    if pet_machine==null: return
    if str(pet_machine.get_current_node())!=state: pet_machine.travel(state)

func _update_monster_motion()->void:
    var monsters_value:Variant=legacy.get("monsters")
    if not monsters_value is Array: return
    var active:Dictionary={}
    var visuals:Dictionary=game.get("monster_visuals") as Dictionary
    for item in monsters_value:
        if not item is Dictionary: continue
        var monster:Dictionary=item
        var id:String=str(monster.get("visual_id",monster.get("name","monster")))
        active[id]=true
        if not visuals.has(id): continue
        var visual:Node3D=visuals[id] as Node3D
        if visual==null: continue
        _add_monster_details(visual,str(monster.get("name","Monster")),bool(monster.get("mvp",false)))
        if not monster_base_y.has(id): monster_base_y[id]=visual.position.y
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
        if hit>0.0: target_scale*=Vector3(1.13,0.86,1.13)
        else: target_scale*=1.0+sin(elapsed*2.2+float(id.hash()%11))*0.012
        visual.scale=visual.scale.lerp(target_scale,0.16)
        visual.rotation.y+=delta_rotation(boss)
    for id in monster_hp_cache.keys():
        if not active.has(id):
            monster_hp_cache.erase(id)
            monster_hit_timer.erase(id)
            monster_base_y.erase(id)

func delta_rotation(boss:bool)->float:
    return (0.0035 if boss else 0.0020)*sin(elapsed*1.7)

func _add_monster_details(visual:Node3D,name:String,boss:bool)->void:
    if visual==null or visual.get_node_or_null("DetailParts")!=null: return
    var root:=Node3D.new()
    root.name="DetailParts"
    visual.add_child(root)
    var n:=name.to_lower()
    var accent:=Color("#f2c15d") if boss else Color("#b8c5d0")
    if "orc" in n:
        root.add_child(_detail_box(Vector3(0.62,0.34,0.72),Vector3(0.0,1.05,0.0),Color("#4a3828")))
        root.add_child(_detail_horn(Vector3(-0.32,1.72,0.05),accent))
        root.add_child(_detail_horn(Vector3(0.32,1.72,0.05),accent))
    elif "wolf" in n:
        root.add_child(_detail_ear(Vector3(-0.25,1.82,0.0),accent))
        root.add_child(_detail_ear(Vector3(0.25,1.82,0.0),accent))
        root.add_child(_detail_tail(Vector3(0.0,0.72,-0.62),Color("#3d4652")))
    elif "dragon" in n:
        root.add_child(_detail_wing(Vector3(-0.62,1.15,0.0),Color("#7e2f39")))
        root.add_child(_detail_wing(Vector3(0.62,1.15,0.0),Color("#7e2f39")))
        root.add_child(_detail_horn(Vector3(-0.22,1.95,0.0),accent))
        root.add_child(_detail_horn(Vector3(0.22,1.95,0.0),accent))
    elif "golem" in n:
        root.add_child(_detail_box(Vector3(1.0,0.30,0.82),Vector3(0.0,1.15,0.0),Color("#5c5147")))
        root.add_child(_detail_box(Vector3(0.82,0.18,0.62),Vector3(0.0,1.62,0.0),Color("#a18c70")))
    elif "mantis" in n:
        root.add_child(_detail_blade(Vector3(-0.58,1.0,0.12),Color("#9bc76a")))
        root.add_child(_detail_blade(Vector3(0.58,1.0,0.12),Color("#9bc76a")))
    elif "skeleton" in n or "zombie" in n or "evil druid" in n:
        root.add_child(_detail_box(Vector3(0.78,0.18,0.55),Vector3(0.0,1.1,0.0),Color("#302c31")))
        root.add_child(_detail_horn(Vector3(-0.24,1.92,0.0),accent))
        root.add_child(_detail_horn(Vector3(0.24,1.92,0.0),accent))
    elif "poring" in n:
        root.add_child(_detail_horn(Vector3(0.0,1.95,0.0),accent))
    if boss:
        var crown:=_detail_ring(accent,1.02,0.055)
        root.add_child(crown)

func _detail_box(size:Vector3,pos:Vector3,color:Color)->MeshInstance3D:
    var node:=MeshInstance3D.new()
    var mesh:=BoxMesh.new()
    mesh.size=size
    node.mesh=mesh
    node.position=pos
    node.material_override=_mat(color)
    return node

func _detail_horn(pos:Vector3,color:Color)->MeshInstance3D:
    var node:=MeshInstance3D.new()
    var mesh:=PrismMesh.new()
    mesh.size=Vector3(0.12,0.42,0.12)
    node.mesh=mesh
    node.position=pos
    node.rotation_degrees=Vector3(-18.0,0.0,0.0)
    node.material_override=_mat(color)
    return node

func _detail_ear(pos:Vector3,color:Color)->MeshInstance3D:
    var node:=MeshInstance3D.new()
    var mesh:=PrismMesh.new()
    mesh.size=Vector3(0.18,0.30,0.08)
    node.mesh=mesh
    node.position=pos
    node.rotation_degrees=Vector3(0.0,0.0,45.0 if pos.x<0 else -45.0)
    node.material_override=_mat(color)
    return node

func _detail_tail(pos:Vector3,color:Color)->MeshInstance3D:
    var node:=MeshInstance3D.new()
    var mesh:=CylinderMesh.new()
    mesh.top_radius=0.08
    mesh.bottom_radius=0.16
    mesh.height=0.8
    node.mesh=mesh
    node.position=pos
    node.rotation_degrees=Vector3(65.0,0.0,0.0)
    node.material_override=_mat(color)
    return node

func _detail_wing(pos:Vector3,color:Color)->MeshInstance3D:
    var node:=MeshInstance3D.new()
    var mesh:=PrismMesh.new()
    mesh.size=Vector3(0.8,0.12,1.0)
    node.mesh=mesh
    node.position=pos
    node.rotation_degrees=Vector3(0.0,0.0,25.0 if pos.x<0 else -25.0)
    node.material_override=_mat(color)
    return node

func _detail_blade(pos:Vector3,color:Color)->MeshInstance3D:
    var node:=MeshInstance3D.new()
    var mesh:=BoxMesh.new()
    mesh.size=Vector3(0.10,0.65,0.18)
    node.mesh=mesh
    node.position=pos
    node.rotation_degrees=Vector3(0.0,0.0,35.0 if pos.x<0 else -35.0)
    node.material_override=_mat(color)
    return node

func _detail_ring(color:Color,radius:float,width:float)->MeshInstance3D:
    var node:=MeshInstance3D.new()
    var mesh:=TorusMesh.new()
    mesh.inner_radius=radius-width
    mesh.outer_radius=radius
    mesh.rings=24
    mesh.ring_segments=8
    node.mesh=mesh
    node.position=Vector3(0.0,2.1,0.0)
    node.material_override=_mat(color)
    return node

func _mat(color:Color)->StandardMaterial3D:
    var material:=StandardMaterial3D.new()
    material.albedo_color=color
    material.roughness=0.72
    return material

func _watch_combat_effects()->void:
    var monsters_value:Variant=legacy.get("monsters")
    if not monsters_value is Array: return
    for item in monsters_value:
        if not item is Dictionary: continue
        var monster:Dictionary=item
        var id:String=str(monster.get("visual_id",monster.get("name","monster")))
        var hp:int=int(monster.get("hp",0))
        if hp<=0 and monster_hp_cache.has(id):
            monster_hp_cache.erase(id)

func _monster_hit_burst(visual:Node3D)->void:
    var burst:=MeshInstance3D.new()
    var mesh:=SphereMesh.new()
    mesh.radius=0.18
    mesh.height=0.36
    burst.mesh=mesh
    burst.position=Vector3(0.0,1.0,0.0)
    burst.material_override=_mat(Color("#f5e4b2"))
    visual.add_child(burst)
    var tween:=create_tween()
    tween.tween_property(burst,"scale",Vector3.ONE*2.0,0.14)
    tween.tween_property(burst,"modulate:a",0.0,0.12)
    tween.tween_callback(burst.queue_free)
