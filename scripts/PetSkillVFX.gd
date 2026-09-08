class_name PetSkillVFX
extends Node3D

var feedback:Node
var active:Array[Node3D]=[]

func _ready()->void:
    feedback=get_parent().get_node_or_null("HDCombatFeedback") if get_parent() else null

func play(species:String,skill_id:String,position:Vector3,radius:float=2.0)->void:
    match species:
        "Falcon": _falcon(skill_id,position,radius)
        "Wolf": _wolf(skill_id,position,radius)
        "Dragon": _dragon(skill_id,position,radius)
        "Wolf Cub": _wolf_cub(skill_id,position,radius)
        _: _impact(position,radius)

func _falcon(skill_id:String,position:Vector3,radius:float)->void:
    if skill_id.find("mark")>=0 or skill_id.find("eye")>=0: _target_ring(position,0.8,1.0)
    elif skill_id.find("storm")>=0 or skill_id.find("tempest")>=0 or skill_id.find("requiem")>=0: _vortex(position,radius,1.15)
    else: _slash(position,0.9,2.8)

func _wolf(skill_id:String,position:Vector3,radius:float)->void:
    if skill_id.find("howl")>=0: _shockwave(position,radius,1.0)
    elif skill_id.find("fury")>=0 or skill_id.find("alpha")>=0:
        _shockwave(position,radius*0.8,1.5)
        _slash(position,1.1,3.4)
    else: _slash(position,0.75,4.0)

func _dragon(skill_id:String,position:Vector3,radius:float)->void:
    if skill_id.find("meteor")>=0 or skill_id.find("apocalypse")>=0 or skill_id.find("eternity")>=0: _meteor(position,radius)
    elif skill_id.find("wing")>=0: _arc(position,radius,1.8)
    else: _burst(position,radius*0.7,1.3)

func _wolf_cub(skill_id:String,position:Vector3,radius:float)->void:
    if skill_id.find("guardian")>=0 or skill_id.find("bond")>=0 or skill_id.find("legend")>=0: _shield(position,radius)
    elif skill_id.find("howl")>=0: _shockwave(position,radius*0.75,0.8)
    else: _slash(position,0.55,2.0)

func _material(emission:Color,alpha:float=0.85)->StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
    m.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
    m.albedo_color=Color(emission.r,emission.g,emission.b,alpha)
    m.emission_enabled=true
    m.emission=emission
    m.emission_energy_multiplier=3.0
    return m

func _mesh_node(mesh:Mesh,position:Vector3,material:Material)->MeshInstance3D:
    var node:=MeshInstance3D.new()
    node.mesh=mesh
    node.global_position=position+Vector3(0,0.08,0)
    node.material_override=material
    add_child(node)
    active.append(node)
    while active.size()>40:
        var old:Node3D=active.pop_front()
        if old and is_instance_valid(old): old.queue_free()
    return node

func _target_ring(position:Vector3,inner:float,outer:float)->void:
    var mesh:=TorusMesh.new()
    mesh.inner_radius=inner
    mesh.outer_radius=outer
    mesh.rings=32
    mesh.ring_segments=8
    var node:=_mesh_node(mesh,position,_material(Color(0.35,0.85,1.0)))
    _animate(node,Vector3(1.4,1.0,1.4),0.42,2.2)

func _slash(position:Vector3,scale:float,speed:float)->void:
    var mesh:=TorusMesh.new()
    mesh.inner_radius=0.22
    mesh.outer_radius=0.48
    mesh.rings=24
    mesh.ring_segments=6
    var node:=_mesh_node(mesh,position,_material(Color(0.75,0.92,1.0)))
    node.rotation.x=1.15
    _animate(node,Vector3.ONE*scale,0.24,speed)

func _shockwave(position:Vector3,radius:float,speed:float)->void:
    var mesh:=TorusMesh.new()
    mesh.inner_radius=max(0.1,radius*0.65)
    mesh.outer_radius=max(0.16,radius*0.75)
    mesh.rings=32
    mesh.ring_segments=8
    var node:=_mesh_node(mesh,position,_material(Color(0.95,0.92,0.65)))
    _animate(node,Vector3(1.4,1.0,1.4),0.38,speed)

func _vortex(position:Vector3,radius:float,speed:float)->void:
    for i in range(3):
        var mesh:=TorusMesh.new()
        mesh.inner_radius=radius*0.22+float(i)*0.18
        mesh.outer_radius=radius*0.30+float(i)*0.18
        mesh.rings=24
        mesh.ring_segments=8
        var node:=_mesh_node(mesh,position+Vector3(0,0.12+float(i)*0.12,0),_material(Color(0.30,0.78,1.0),0.72))
        node.rotation.x=float(i)*0.5
        _animate(node,Vector3(1.8,1.0,1.8),0.55+float(i)*0.08,speed+float(i)*0.5)

func _meteor(position:Vector3,radius:float)->void:
    var sphere:=SphereMesh.new()
    sphere.radius=0.35
    sphere.height=0.7
    var node:=_mesh_node(sphere,position+Vector3(0,4.5,0),_material(Color(1.0,0.28,0.06)))
    var tween:=create_tween()
    tween.set_parallel(true)
    tween.tween_property(node,"global_position",position+Vector3(0,0.35,0),0.32)
    tween.tween_property(node,"scale",Vector3.ONE*1.5,0.32)
    tween.set_parallel(false)
    tween.tween_callback(func(): _burst(position,radius,1.7))
    tween.tween_callback(node.queue_free)

func _burst(position:Vector3,radius:float,strength:float)->void:
    var mesh:=SphereMesh.new()
    mesh.radius=0.4
    mesh.height=0.8
    var node:=_mesh_node(mesh,position,_material(Color(1.0,0.30,0.08),0.70))
    _animate(node,Vector3.ONE*max(1.0,radius)*strength,0.30,1.0)

func _arc(position:Vector3,radius:float,speed:float)->void:
    var mesh:=TorusMesh.new()
    mesh.inner_radius=radius*0.55
    mesh.outer_radius=radius*0.68
    mesh.rings=28
    mesh.ring_segments=8
    var node:=_mesh_node(mesh,position,_material(Color(1.0,0.42,0.08)))
    node.rotation.z=0.8
    _animate(node,Vector3(1.1,1.0,1.1),0.35,speed)

func _shield(position:Vector3,radius:float)->void:
    var mesh:=TorusMesh.new()
    mesh.inner_radius=radius*0.55
    mesh.outer_radius=radius*0.62
    mesh.rings=32
    mesh.ring_segments=8
    var node:=_mesh_node(mesh,position,_material(Color(0.35,1.0,0.65),0.72))
    node.rotation.x=PI*0.5
    _animate(node,Vector3.ONE*1.2,0.65,1.6)

func _impact(position:Vector3,radius:float)->void:
    var mesh:=SphereMesh.new()
    mesh.radius=0.28
    mesh.height=0.56
    var node:=_mesh_node(mesh,position,_material(Color(0.7,0.8,1.0),0.8))
    _animate(node,Vector3.ONE*max(1.0,radius)*0.9,0.28,1.8)

func _animate(node:Node3D,final_scale:Vector3,duration:float,rotation_speed:float)->void:
    var tween:=create_tween()
    tween.set_parallel(true)
    tween.tween_property(node,"scale",final_scale,duration)
    tween.tween_property(node,"rotation:y",TAU*rotation_speed,duration)
    tween.tween_property(node,"modulate:a",0.0,duration).set_delay(duration*0.25)
    tween.set_parallel(false)
    tween.tween_callback(node.queue_free)
