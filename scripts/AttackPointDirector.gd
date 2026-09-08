class_name AttackPointDirector
extends Node3D

var game:Node3D
var legacy:Node2D
var vfx:Node
var seen:Dictionary={}
var active_fx:Array[Node3D]=[]
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
        var key:=str(effect.get("kind",""))+":"+str(i)+":"+str(effect.get("pos",Vector2.ZERO))
        if seen.has(key):
            continue
        seen[key]=elapsed
        var kind:=str(effect.get("kind",""))
        var pos:Vector2=effect.get("pos",Vector2.ZERO)
        if kind=="hero_attack":
            _hero_attack_point(pos)
        elif kind=="pet_attack":
            _pet_attack_point(pos)
        elif kind=="hit" or kind=="critical":
            _impact_point(pos,kind=="critical")
        elif kind=="death":
            _death_point(pos)
        elif kind=="heal":
            _heal_point(pos)
        elif kind=="skill" or kind=="ultimate":
            _skill_point(pos,kind=="ultimate")
        elif kind=="mvp":
            _mvp_point(pos)

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
    var direction:=origin.direction_to(target_pos)
    _spawn_attack_arc(origin,target_pos,direction,class_id,false)
    _spawn_point_marker(target_pos,Color("#ffd36b"),0.30,1.0)

func _pet_attack_point(target_pos:Vector2)->void:
    var hero_value:Variant=legacy.get("hero")
    if not hero_value is Dictionary:
        return
    var hero:Dictionary=hero_value
    var origin:=Vector2(float(hero.get("pos_x",0.0)),float(hero.get("pos_y",0.0)))+Vector2(34.0,24.0)
    _spawn_attack_arc(origin,target_pos,origin.direction_to(target_pos),"Pet",true)
    _spawn_point_marker(target_pos,Color("#8fe8ff"),0.34,0.9)

func _spawn_attack_arc(origin:Vector2,target:Vector2,direction:Vector2,class_id:String,pet:bool)->void:
    var start:=_world(origin,1.15 if not pet else 0.72)
    var end:=_world(target,0.86)
    var midpoint:Vector3=start.lerp(end,0.55)
    var arc:=MeshInstance3D.new()
    arc.name="AttackArc"
    var mesh:=TorusMesh.new()
    mesh.inner_radius=0.20 if not pet else 0.14
    mesh.outer_radius=0.25 if not pet else 0.19
    mesh.rings=12
    mesh.ring_segments=24
    arc.mesh=mesh
    arc.position=midpoint
    var yaw:=rad_to_deg(atan2(direction.x,direction.y))
    arc.rotation_degrees=Vector3(90.0,yaw,0.0)
    if pet:
        arc.rotation_degrees.z=18.0
    var color:=_class_color(class_id)
    arc.material_override=_emissive_material(color,1.8 if not pet else 1.2)
    game.add_child(arc)
    active_fx.append(arc)
    var tween:=create_tween()
    tween.set_parallel(true)
    tween.tween_property(arc,"scale",Vector3.ONE*1.7,0.13)
    tween.tween_property(arc,"transparency",0.9,0.13)
    tween.chain().tween_callback(arc.queue_free)
    var line:=MeshInstance3D.new()
    line.name="AttackLine"
    var cylinder:=CylinderMesh.new()
    cylinder.top_radius=0.018
    cylinder.bottom_radius=0.032
    cylinder.height=max(0.35,start.distance_to(end))
    line.mesh=cylinder
    line.position=start.lerp(end,0.5)
    line.look_at(end,Vector3.UP)
    line.rotate_object_local(Vector3.RIGHT,PI*0.5)
    line.material_override=_emissive_material(color,1.0)
    game.add_child(line)
    active_fx.append(line)
    var line_tween:=create_tween()
    line_tween.tween_property(line,"transparency",1.0,0.16)
    line_tween.tween_callback(line.queue_free)

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
    tween.set_parallel(true)
    tween.tween_property(marker,"scale",Vector3.ONE*(scale_value*1.8),duration)
    tween.tween_property(marker,"transparency",1.0,duration)
    tween.chain().tween_callback(marker.queue_free)

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
    tween.set_parallel(true)
    tween.tween_property(ring,"scale",Vector3.ONE*(2.8 if critical else 2.1),0.16)
    tween.tween_property(ring,"position:y",0.42 if critical else 0.32,0.16)
    tween.tween_property(ring,"transparency",1.0,0.18)
    tween.chain().tween_callback(ring.queue_free)

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
