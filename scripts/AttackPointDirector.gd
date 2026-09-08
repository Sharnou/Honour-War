class_name AttackPointDirector
extends Node3D

var game:Node3D
var legacy:Node2D
var vfx:Node
var seen:Dictionary={}
var elapsed:=0.0

const MAP_SCALE:=0.055
const MAP_OFFSET:=Vector2(365.0,120.0)

func _ready()->void:
    game=get_parent() as Node3D
    if game!=null:
        legacy=game.get_node_or_null("LegacyGame")
        if legacy!=null:
            vfx=legacy.get_node_or_null("CombatVFX")
    set_process(true)

func _process(delta:float)->void:
    elapsed+=delta
    if game==null or legacy==null or vfx==null:
        return
    _watch_effects()
    _cleanup_seen()

func _watch_effects()->void:
    var effects_value:Variant=vfx.get("effects")
    if not effects_value is Array:
        return
    var effects:Array=effects_value
    for i in range(effects.size()):
        var effect:Variant=effects[i]
        if not effect is Dictionary:
            continue
        var age:=float(effect.get("age",99.0))
        if age>0.055:
            continue
        var key:=str(effect.get("kind",""))+":"+str(effect.get("pos",Vector2.ZERO))+":"+str(effect.get("damage",0))+":"+str(i)
        if seen.has(key):
            continue
        seen[key]=elapsed
        var kind:=str(effect.get("kind",""))
        var pos:Vector2=effect.get("pos",Vector2.ZERO)
        if kind=="hero_attack": _hero_attack_point(pos)
        elif kind=="pet_attack": _pet_attack_point(pos)
        elif kind=="hit" or kind=="critical": _impact_point(pos,kind=="critical")
        elif kind=="death": _death_point(pos)
        elif kind=="heal": _heal_point(pos)
        elif kind=="skill" or kind=="ultimate": _skill_point(pos,kind=="ultimate")
        elif kind=="mvp": _mvp_point(pos)

func _cleanup_seen()->void:
    for key in seen.keys():
        if elapsed-float(seen[key])>2.0:
            seen.erase(key)

func _world(map_pos:Vector2,y:float=0.0)->Vector3:
    return Vector3((map_pos.x-MAP_OFFSET.x)*MAP_SCALE,y,(map_pos.y-MAP_OFFSET.y)*MAP_SCALE)

func _hero_attack_point(target_pos:Vector2)->void:
    var hero_value:Variant=legacy.get("hero")
    if not hero_value is Dictionary:
        return
    var hero:Dictionary=hero_value
    var origin:=Vector2(float(hero.get("pos_x",0.0)),float(hero.get("pos_y",0.0)))
    var class_id:=str(hero.get("class","Warrior"))
    _spawn_class_attack(origin,target_pos,class_id)
    _spawn_point_marker(target_pos,_class_color(class_id),0.28,1.0)

func _pet_attack_point(target_pos:Vector2)->void:
    var hero_value:Variant=legacy.get("hero")
    if not hero_value is Dictionary:
        return
    var hero:Dictionary=hero_value
    var pet_value:Variant=hero.get("pet",{})
    var role:="Pet"
    if pet_value is Dictionary:
        role=str((pet_value as Dictionary).get("role","Pet"))
    var origin:=Vector2(float(hero.get("pos_x",0.0)),float(hero.get("pos_y",0.0)))+Vector2(34.0,24.0)
    _spawn_pet_choreography(origin,target_pos,role)
    _spawn_point_marker(target_pos,Color("#8fe8ff"),0.34,0.9)

func _spawn_class_attack(origin:Vector2,target:Vector2,class_id:String)->void:
    var direction:=origin.direction_to(target)
    var start:=_world(origin,1.05)
    var end:=_world(target,0.82)
    match class_id:
        "Warrior":
            _spawn_sweep(start,end,direction,Color("#e8a34b"),2.2,1.65)
            _spawn_blade_arc(end,direction,Color("#ffd36b"),1.9,0.22)
        "Mage":
            _spawn_projectile(start,end,Color("#b88cff"),0.20,2.4)
            _spawn_orb(end,Color("#d7c8ff"),0.28,1.35)
        "Archer":
            _spawn_projectile(start,end,Color("#8fe08f"),0.10,2.0)
            _spawn_projectile(start,end+Vector3(0.0,0.10,0.0),Color("#d7ffd9"),0.08,1.25)
        "Thief":
            _spawn_sweep(start,end,direction,Color("#ff7eb6"),1.8,1.4)
            _spawn_sweep(start,end,direction.rotated(0.55),Color("#ff9ccc"),1.4,1.15)
        "Acolyte":
            _spawn_holy_beam(start,end,Color("#fff0a3"))
            _spawn_orb(end,Color("#fff7c7"),0.30,1.25)
        "Merchant":
            _spawn_sweep(start,end,direction,Color("#7ed7ff"),2.0,1.5)
            _spawn_impact_box(end,Color("#b7efff"),0.28)
        _:
            _spawn_sweep(start,end,direction,Color.WHITE,1.5,1.0)

func _spawn_pet_choreography(origin:Vector2,target:Vector2,role:String)->void:
    var start:=_world(origin,0.68)
    var end:=_world(target,0.76)
    var direction:=origin.direction_to(target)
    var color:=Color("#8fe8ff")
    if role=="Assassin": color=Color("#ff7eb6")
    elif role=="Healer": color=Color("#8dffb1")
    elif role=="Guardian" or role=="Tank": color=Color("#ffd36b")
    _spawn_sweep(start,end,direction,color,1.25,1.1)
    _spawn_orb(end,color,0.26,0.9)

func _spawn_sweep(start:Vector3,end:Vector3,direction:Vector2,color:Color,energy:float,scale_value:float)->void:
    var arc:=MeshInstance3D.new()
    arc.name="WeaponSweep"
    var mesh:=TorusMesh.new()
    mesh.inner_radius=0.17
    mesh.outer_radius=0.23
    mesh.rings=12
    mesh.ring_segments=32
    arc.mesh=mesh
    arc.position=start.lerp(end,0.72)
    arc.rotation_degrees=Vector3(90.0,rad_to_deg(atan2(direction.x,direction.y)),0.0)
    arc.material_override=_emissive_material(color,energy)
    game.add_child(arc)
    var tween:=create_tween()
    tween.set_parallel(true)
    tween.tween_property(arc,"scale",Vector3.ONE*scale_value,0.13)
    tween.chain().tween_callback(arc.queue_free).set_delay(0.17)
    _spawn_line(start,end,color,energy*0.55,0.15)

func _spawn_blade_arc(pos:Vector3,direction:Vector2,color:Color,energy:float,duration:float)->void:
    var arc:=MeshInstance3D.new()
    var mesh:=TorusMesh.new()
    mesh.inner_radius=0.24
    mesh.outer_radius=0.30
    mesh.rings=12
    mesh.ring_segments=32
    arc.mesh=mesh
    arc.position=pos+Vector3(0.0,0.16,0.0)
    arc.rotation_degrees=Vector3(90.0,rad_to_deg(atan2(direction.x,direction.y)),24.0)
    arc.material_override=_emissive_material(color,energy)
    game.add_child(arc)
    var tween:=create_tween()
    tween.tween_property(arc,"scale",Vector3(1.8,1.8,1.8),duration)
    tween.tween_callback(arc.queue_free)

func _spawn_projectile(start:Vector3,end:Vector3,color:Color,radius:float,energy:float)->void:
    var projectile:=MeshInstance3D.new()
    var mesh:=SphereMesh.new()
    mesh.radius=radius
    mesh.height=radius*2.0
    projectile.mesh=mesh
    projectile.position=start
    projectile.material_override=_emissive_material(color,energy)
    game.add_child(projectile)
    var tween:=create_tween()
    tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tween.tween_property(projectile,"position",end,0.18)
    tween.tween_callback(projectile.queue_free)

func _spawn_orb(pos:Vector3,color:Color,duration:float,scale_value:float)->void:
    var orb:=MeshInstance3D.new()
    var mesh:=SphereMesh.new()
    mesh.radius=0.13
    mesh.height=0.26
    orb.mesh=mesh
    orb.position=pos+Vector3(0.0,0.22,0.0)
    orb.material_override=_emissive_material(color,2.2)
    game.add_child(orb)
    var tween:=create_tween()
    tween.tween_property(orb,"scale",Vector3.ONE*scale_value,duration)
    tween.tween_callback(orb.queue_free)

func _spawn_holy_beam(start:Vector3,end:Vector3,color:Color)->void:
    _spawn_line(start,end,color,2.6,0.20)
    _spawn_orb(end,color,0.35,1.45)

func _spawn_impact_box(pos:Vector3,color:Color,duration:float)->void:
    var box:=MeshInstance3D.new()
    var mesh:=BoxMesh.new()
    mesh.size=Vector3(0.22,0.22,0.22)
    box.mesh=mesh
    box.position=pos+Vector3(0.0,0.16,0.0)
    box.rotation_degrees=Vector3(0.0,45.0,45.0)
    box.material_override=_emissive_material(color,1.8)
    game.add_child(box)
    var tween:=create_tween()
    tween.tween_property(box,"scale",Vector3.ONE*2.0,duration)
    tween.tween_callback(box.queue_free)

func _spawn_line(start:Vector3,end:Vector3,color:Color,energy:float,duration:float)->void:
    var line:=MeshInstance3D.new()
    var cylinder:=CylinderMesh.new()
    cylinder.top_radius=0.018
    cylinder.bottom_radius=0.035
    cylinder.height=max(0.35,start.distance_to(end))
    line.mesh=cylinder
    line.position=start.lerp(end,0.5)
    line.look_at(end,Vector3.UP)
    line.rotate_object_local(Vector3.RIGHT,PI*0.5)
    line.material_override=_emissive_material(color,energy)
    game.add_child(line)
    var tween:=create_tween()
    tween.tween_callback(line.queue_free).set_delay(duration)

func _spawn_point_marker(pos:Vector2,color:Color,duration:float,scale_value:float)->void:
    var marker:=MeshInstance3D.new()
    marker.name="AttackPoint"
    var mesh:=TorusMesh.new()
    mesh.inner_radius=0.10
    mesh.outer_radius=0.15
    mesh.rings=10
    mesh.ring_segments=24
    marker.mesh=mesh
    marker.position=_world(pos,0.10)
    marker.rotation_degrees.x=90.0
    marker.scale=Vector3.ONE*scale_value
    marker.material_override=_emissive_material(color,2.0)
    game.add_child(marker)
    var tween:=create_tween()
    tween.tween_property(marker,"scale",Vector3.ONE*(scale_value*1.8),duration)
    tween.tween_callback(marker.queue_free)

func _impact_point(pos:Vector2,critical:bool)->void:
    var ring:=MeshInstance3D.new()
    ring.name="ImpactReaction"
    var mesh:=TorusMesh.new()
    mesh.inner_radius=0.10 if not critical else 0.16
    mesh.outer_radius=0.15 if not critical else 0.23
    mesh.rings=12
    mesh.ring_segments=28
    ring.mesh=mesh
    ring.position=_world(pos,0.16)
    ring.rotation_degrees.x=90.0
    ring.material_override=_emissive_material(Color("#ffb347") if not critical else Color("#fff0a3"),2.4 if critical else 1.6)
    game.add_child(ring)
    var tween:=create_tween()
    tween.tween_property(ring,"scale",Vector3.ONE*(2.8 if critical else 2.1),0.16)
    tween.tween_property(ring,"position:y",0.42 if critical else 0.32,0.16)
    tween.tween_callback(ring.queue_free)

func _death_point(pos:Vector2)->void:
    _spawn_point_marker(pos,Color("#ffe08a"),0.55,1.0)

func _heal_point(pos:Vector2)->void:
    _spawn_point_marker(pos,Color("#8dffb1"),0.70,0.8)

func _skill_point(pos:Vector2,ultimate:bool)->void:
    _spawn_point_marker(pos,Color("#fff0a3"),0.50 if ultimate else 0.28,1.3 if ultimate else 1.0)

func _mvp_point(pos:Vector2)->void:
    _spawn_point_marker(pos,Color("#f2c15d"),0.70,1.4)

func _class_color(class_id:String)->Color:
    match class_id:
        "Warrior": return Color("#e8a34b")
        "Mage": return Color("#b88cff")
        "Archer": return Color("#8fe08f")
        "Thief": return Color("#ff7eb6")
        "Acolyte": return Color("#fff0a3")
        "Merchant": return Color("#7ed7ff")
        _: return Color("#ffffff")

func _emissive_material(color:Color,energy:float)->StandardMaterial3D:
    var mat:=StandardMaterial3D.new()
    mat.albedo_color=color
    mat.emission_enabled=true
    mat.emission=color
    mat.emission_energy_multiplier=energy
    mat.roughness=0.28
    return mat
