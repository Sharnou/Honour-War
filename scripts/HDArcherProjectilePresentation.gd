class_name HDArcherProjectilePresentation
extends Node3D

var game:Node3D
var events:Node
var projectiles:Array[Node3D]=[]

func _ready()->void:
    game=get_parent() as Node3D
    events=game.get_node_or_null("CombatEventBus") if game else null
    if events and events.has_signal("hero_attack_landed"):
        events.hero_attack_landed.connect(_on_hero_attack)

func _process(delta:float)->void:
    for projectile in projectiles.duplicate():
        if not is_instance_valid(projectile):
            projectiles.erase(projectile)
            continue
        var ttl:float=float(projectile.get_meta("ttl",0.0))-delta
        projectile.set_meta("ttl",ttl)
        var from:Vector3=projectile.get_meta("from",projectile.global_position)
        var to:Vector3=projectile.get_meta("to",projectile.global_position)
        var duration:float=max(0.05,float(projectile.get_meta("duration",0.18)))
        var progress:float=clamp(1.0-ttl/duration,0.0,1.0)
        projectile.global_position=from.lerp(to,progress)
        var direction:=to-from
        if direction.length_squared()>0.0001:
            projectile.look_at(projectile.global_position+direction.normalized(),Vector3.UP)
        if ttl<=0.0:
            projectiles.erase(projectile)
            projectile.queue_free()

func _on_hero_attack(target:Dictionary,_damage:int,_critical:bool)->void:
    if game==null:
        return
    var legacy:=game.get_node_or_null("LegacyGame")
    if legacy==null:
        return
    var hero_value:Variant=legacy.get("hero")
    if not hero_value is Dictionary:
        return
    var hero:Dictionary=hero_value
    if str(hero.get("class","Warrior")).to_lower()!="archer":
        return
    var target_pos_value:Variant=target.get("pos",Vector2.ZERO)
    if not target_pos_value is Vector2:
        return
    var hero_pos:=Vector2(float(hero.get("pos_x",595.0)),float(hero.get("pos_y",340.0)))
    var from:Vector3=game.call("_map_to_world",hero_pos)+Vector3(0.0,1.55,0.0)
    var to:Vector3=game.call("_map_to_world",target_pos_value)+Vector3(0.0,1.15,0.0)
    var arrow:=MeshInstance3D.new()
    var mesh:=CylinderMesh.new()
    mesh.top_radius=0.025
    mesh.bottom_radius=0.025
    mesh.height=0.85
    mesh.radial_segments=6
    arrow.mesh=mesh
    var material:=StandardMaterial3D.new()
    material.albedo_color=Color("#e8c36a")
    material.emission_enabled=true
    material.emission=Color("#ffd978")
    material.emission_energy_multiplier=1.6
    arrow.material_override=material
    add_child(arrow)
    arrow.global_position=from
    arrow.set_meta("from",from)
    arrow.set_meta("to",to)
    arrow.set_meta("ttl",0.18)
    arrow.set_meta("duration",0.18)
    projectiles.append(arrow)
