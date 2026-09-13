class_name HDMonsterMotionDirector
extends Node3D

## Universal monster presentation layer for the procedural fallback.
## Production GLB/GLTF actors are not structurally modified by this director.
var game:Node
var states:Dictionary={}

func _ready()->void:
    game=get_parent()
    set_process(true)

func _process(delta:float)->void:
    if game==null: return
    var visuals:Variant=game.get("monster_visuals")
    var legacy:Node=game.get("legacy") as Node
    if not visuals is Dictionary or legacy==null: return
    var monsters_value:Variant=legacy.get("monsters")
    if not monsters_value is Array: return
    var monsters:Array=monsters_value
    var hero_value:Variant=legacy.get("hero")
    var hero_pos:=Vector2.ZERO
    if hero_value is Dictionary:
        hero_pos=Vector2(float(hero_value.get("pos_x",0.0)),float(hero_value.get("pos_y",0.0)))
    var live:Dictionary={}
    for monster in monsters:
        if not monster is Dictionary: continue
        var id:String=str(monster.get("id",monster.get("visual_id",monster.get("name","monster"))))
        if id.is_empty() or not visuals.has(id): continue
        var visual:Node3D=visuals[id] as Node3D
        if visual==null or not is_instance_valid(visual): continue
        live[id]=true
        if bool(visual.get_meta("hw_production_asset",false)): continue
        if not states.has(id):
            states[id]={"time":0.0,"next_attack":0.8,"next_cast":1.4,"hp":int(monster.get("hp",0)),"death":false}
            _remove_labels(visual)
            _add_detail_parts(visual,str(monster.get("name","Monster")))
        _animate(delta,visual,monster,hero_pos,states[id])
    for id in states.keys():
        if not live.has(id): states.erase(id)

func _animate(delta:float,visual:Node3D,monster:Dictionary,hero_pos:Vector2,state:Dictionary)->void:
    state["time"]=float(state["time"])+delta
    state["next_attack"]=float(state["next_attack"])-delta
    state["next_cast"]=float(state["next_cast"])-delta
    var hp:int=int(monster.get("hp",0))
    if hp<=0:
        if not bool(state.get("death",false)):
            state["death"]=true
            var tween:=visual.create_tween()
            tween.tween_property(visual,"rotation",Vector3(0,visual.rotation.y,1.0),0.25)
            tween.parallel().tween_property(visual,"scale",Vector3(0.12,0.12,0.12),0.40)
        return
    var world_pos:Vector2=monster.get("pos",Vector2.ZERO)
    var distance:float=world_pos.distance_to(hero_pos)
    var phase:float=float(state["time"])*5.0
    var moving:bool=distance>CombatRulesSafe.range(monster) and distance<300.0
    var bob:float=sin(phase)*0.035
    visual.position.y=0.15+bob
    if moving:
        visual.position.y+=abs(sin(phase))*0.045
        visual.rotation.z=sin(phase)*0.045
    else:
        visual.rotation.z=lerp(visual.rotation.z,0.0,0.10)
    var previous_hp:int=int(state.get("hp",hp))
    if hp<previous_hp:
        visual.scale=Vector3(1.13,0.90,1.10)
        var recover:=visual.create_tween()
        recover.tween_property(visual,"scale",Vector3.ONE,0.15)
    state["hp"]=hp
    if distance<150.0 and float(state["next_attack"])<=0.0:
        state["next_attack"]=1.1 if not bool(monster.get("mvp",false)) else 0.75
        _attack(visual,monster)
    var ranged:bool=bool(monster.get("ranged",false)) or str(monster.get("attack_type",""))=="Ranged"
    if ranged and distance<220.0 and float(state["next_cast"])<=0.0:
        state["next_cast"]=2.8 if not bool(monster.get("mvp",false)) else 1.9
        _cast(visual,monster)
    _animate_limbs(visual,phase)

func _attack(visual:Node3D,monster:Dictionary)->void:
    var weapon:Node3D=visual.get_node_or_null("HW_MonsterWeapon") as Node3D
    var original:Vector3=visual.scale
    var tween:=visual.create_tween()
    tween.tween_property(visual,"scale",Vector3(1.10,0.94,1.08),0.07)
    if weapon!=null:
        tween.parallel().tween_property(weapon,"rotation",weapon.rotation+Vector3(0,0,-0.65),0.10)
        tween.tween_property(weapon,"rotation",weapon.rotation,0.14)
    tween.tween_property(visual,"scale",original,0.12)

func _cast(visual:Node3D,_monster:Dictionary)->void:
    var aura:MeshInstance3D=visual.get_node_or_null("HW_CastAura") as MeshInstance3D
    if aura==null: return
    aura.visible=true
    aura.scale=Vector3(0.35,0.35,0.35)
    var tween:=visual.create_tween()
    tween.tween_property(aura,"scale",Vector3(1.55,1.55,1.55),0.38)
    tween.tween_property(aura,"scale",Vector3(0.35,0.35,0.35),0.20)
    tween.tween_callback(func(): aura.visible=false)

func _animate_limbs(visual:Node3D,phase:float)->void:
    var left:Node3D=visual.get_node_or_null("HW_LeftLimb") as Node3D
    var right:Node3D=visual.get_node_or_null("HW_RightLimb") as Node3D
    var wings:Node3D=visual.get_node_or_null("HW_Wings") as Node3D
    if left: left.rotation.z=sin(phase)*0.28
    if right: right.rotation.z=-sin(phase)*0.28
    if wings: wings.rotation.y=sin(phase*1.7)*0.13

func _add_detail_parts(root:Node3D,family:String)->void:
    var accent:=_accent(family.to_lower())
    var mat:=_mat(accent.darkened(0.20),0.10,0.60)
    var dark:=_mat(Color("#252a32"),0.55,0.36)
    var left:=Node3D.new()
    left.name="HW_LeftLimb"
    left.position=Vector3(-0.30,0.78,0)
    root.add_child(left)
    var lm:=_capsule(mat,0.09,0.55)
    lm.position=Vector3(0,-0.28,0)
    left.add_child(lm)
    var right:=Node3D.new()
    right.name="HW_RightLimb"
    right.position=Vector3(0.30,0.78,0)
    root.add_child(right)
    var rm:=_capsule(mat,0.09,0.55)
    rm.position=Vector3(0,-0.28,0)
    right.add_child(rm)
    var name_lower:=family.to_lower()
    if name_lower.contains("dragon"):
        var wings:=Node3D.new()
        wings.name="HW_Wings"
        root.add_child(wings)
        var wl:=_box(mat,Vector3(0.12,0.20,1.15))
        wl.position=Vector3(-0.52,1.10,0)
        wl.rotation_degrees.y=-30.0
        wings.add_child(wl)
        var wr:=_box(mat,Vector3(0.12,0.20,1.15))
        wr.position=Vector3(0.52,1.10,0)
        wr.rotation_degrees.y=30.0
        wings.add_child(wr)
    var weapon:=_box(dark,Vector3(0.11,1.0,0.18))
    weapon.name="HW_MonsterWeapon"
    weapon.position=Vector3(0.58,0.78,0)
    root.add_child(weapon)
    var aura:=_ring(_mat(accent,0.35,0.22),0.38,0.035)
    aura.name="HW_CastAura"
    aura.visible=false
    aura.rotation_degrees.x=90.0
    aura.position.y=0.08
    root.add_child(aura)

func _remove_labels(root:Node)->void:
    for child in root.get_children():
        if child is Label3D:
            (child as Label3D).visible=false
        _remove_labels(child)

func _accent(name:String)->Color:
    if name.contains("poring"): return Color("#f18bb4")
    if name.contains("goblin"): return Color("#79a46a")
    if name.contains("wolf"): return Color("#758594")
    if name.contains("skeleton"): return Color("#d6d1bd")
    if name.contains("zombie"): return Color("#657e70")
    if name.contains("orc"): return Color("#5f8753")
    if name.contains("mantis"): return Color("#79a84e")
    if name.contains("golem"): return Color("#8c9299")
    if name.contains("druid"): return Color("#6a7397")
    if name.contains("dragon"): return Color("#a44f63")
    if name.contains("knight"): return Color("#8d3b45")
    return Color("#8da0ae")

func _mat(color:Color,metallic:float,roughness:float)->StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.albedo_color=color
    m.metallic=metallic
    m.roughness=roughness
    return m

func _capsule(mat:Material,radius:float,height:float)->MeshInstance3D:
    var n:=MeshInstance3D.new()
    var m:=CapsuleMesh.new()
    m.radius=radius
    m.height=height
    n.mesh=m
    n.material_override=mat
    return n

func _box(mat:Material,size:Vector3)->MeshInstance3D:
    var n:=MeshInstance3D.new()
    var m:=BoxMesh.new()
    m.size=size
    n.mesh=m
    n.material_override=mat
    return n

func _ring(mat:Material,radius:float,width:float)->MeshInstance3D:
    var n:=MeshInstance3D.new()
    var m:=TorusMesh.new()
    m.inner_radius=radius
    m.outer_radius=radius+width
    n.mesh=m
    n.material_override=mat
    return n

class CombatRulesSafe:
    static func range(_monster:Dictionary)->float:
        return 32.0
