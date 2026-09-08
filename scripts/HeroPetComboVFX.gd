class_name HeroPetComboVFX
extends Node3D

var game:Node3D
var combo:Node
var active_effects:Array[Node3D]=[]
var lock_ring:MeshInstance3D
var lock_target:Node3D
var elapsed:float=0.0
var pulse:float=0.0

func _ready()->void:
    game=get_parent() as Node3D
    combo=game.get_node_or_null("HeroPetComboSystem") if game else null
    if combo:
        combo.combo_changed.connect(_on_combo_changed)
        combo.combo_triggered.connect(_on_combo_triggered)
        combo.finisher_executed.connect(_on_finisher)
    _build_lock_ring()

func _process(delta:float)->void:
    elapsed+=delta
    pulse=max(0.0,pulse-delta)
    _resolve_target()
    if lock_ring!=null:
        lock_ring.rotation.y=elapsed*1.8
        lock_ring.scale=Vector3.ONE*(1.0+sin(elapsed*5.0)*0.04)
        lock_ring.visible=lock_target!=null
        if lock_target!=null:
            lock_ring.global_position=lock_target.global_position+Vector3(0.0,0.05,0.0)
    for effect in active_effects.duplicate():
        if not is_instance_valid(effect):
            active_effects.erase(effect)
            continue
        var ttl:float=float(effect.get_meta("ttl",0.0))-delta
        effect.set_meta("ttl",ttl)
        effect.scale*=1.0+delta*0.7
        effect.modulate.a=max(0.0,ttl*1.8)
        if ttl<=0.0:
            active_effects.erase(effect)
            effect.queue_free()

func _build_lock_ring()->void:
    lock_ring=MeshInstance3D.new()
    lock_ring.name="BondTargetLock"
    var torus:=TorusMesh.new()
    torus.inner_radius=0.48
    torus.outer_radius=0.55
    torus.rings=32
    torus.ring_segments=10
    lock_ring.mesh=torus
    var material:=StandardMaterial3D.new()
    material.albedo_color=Color(0.95,0.75,0.22,0.85)
    material.emission_enabled=true
    material.emission=Color(0.95,0.55,0.08)
    material.emission_energy_multiplier=2.4
    material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
    material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
    lock_ring.material_override=material
    add_child(lock_ring)

func _resolve_target()->void:
    if game==null: return
    var combat:Node=game.get_node_or_null("LegacyGame/CombatRuntime")
    if combat==null:
        lock_target=null
        return
    var value:Variant=combat.get("target")
    if not value is Dictionary:
        lock_target=null
        return
    var target:Dictionary=value
    var id:String=str(target.get("visual_id",target.get("name","")))
    var visuals:Variant=game.get("monster_visuals")
    if visuals is Dictionary and visuals.has(id):
        lock_target=visuals[id] as Node3D
    else:
        lock_target=null

func _on_combo_changed(count:int,_grade:String)->void:
    if count>=5:
        pulse=0.16
        _draw_bond_link(0.16,0.8+min(0.9,float(count)*0.025))

func _on_combo_triggered(name:String,count:int)->void:
    if name=="Bond Finisher":
        _spawn_finisher_burst(count)
    elif count>=5:
        _spawn_milestone_burst(count)

func _on_finisher(_damage:int,_target:Node)->void:
    _spawn_finisher_burst(10)

func _draw_bond_link(duration:float,width:float)->void:
    var hero:Node3D=game.get("hero_visual") as Node3D
    var pet:Node3D=game.get("pet_visual") as Node3D
    if hero==null or pet==null: return
    var midpoint:Vector3=(hero.global_position+pet.global_position)*0.5+Vector3(0.0,0.8,0.0)
    var beam:=_beam(hero.global_position+Vector3(0,0.7,0),pet.global_position+Vector3(0,0.7,0),width)
    beam.set_meta("ttl",duration)
    active_effects.append(beam)
    add_child(beam)
    if lock_target!=null:
        var beam2:=_beam(pet.global_position+Vector3(0,0.7,0),lock_target.global_position+Vector3(0,0.7,0),width*0.7)
        beam2.set_meta("ttl",duration)
        active_effects.append(beam2)
        add_child(beam2)
    var orb:=_orb(midpoint,0.16+width*0.06)
    orb.set_meta("ttl",duration)
    active_effects.append(orb)
    add_child(orb)

func _spawn_milestone_burst(count:int)->void:
    if lock_target==null: return
    var ring:=MeshInstance3D.new()
    var mesh:=TorusMesh.new()
    mesh.inner_radius=0.42+float(count)*0.012
    mesh.outer_radius=0.49+float(count)*0.012
    mesh.rings=36
    mesh.ring_segments=12
    ring.mesh=mesh
    ring.global_position=lock_target.global_position+Vector3(0,0.12,0)
    var mat:=_glow_material(Color(1.0,0.78,0.18),3.2)
    ring.material_override=mat
    ring.set_meta("ttl",0.55)
    active_effects.append(ring)
    add_child(ring)

func _spawn_finisher_burst(count:int)->void:
    var hero:Node3D=game.get("hero_visual") as Node3D
    var pet:Node3D=game.get("pet_visual") as Node3D
    if hero==null or pet==null: return
    var center:Vector3=(hero.global_position+pet.global_position)*0.5+Vector3(0,1.0,0)
    if lock_target!=null: center=(center+lock_target.global_position+Vector3(0,0.7,0))*0.5
    var ring:=MeshInstance3D.new()
    var mesh:=TorusMesh.new()
    mesh.inner_radius=0.2
    mesh.outer_radius=0.32
    mesh.rings=48
    mesh.ring_segments=16
    ring.mesh=mesh
    ring.global_position=center
    var mat:=_glow_material(Color(1.0,0.62,0.08),5.0)
    ring.material_override=mat
    ring.set_meta("ttl",0.9)
    active_effects.append(ring)
    add_child(ring)
    _draw_bond_link(0.8,1.7+min(1.0,float(count)*0.03))
    if lock_target!=null:
        for angle in range(0,360,45):
            var spoke:=_beam(center,lock_target.global_position+Vector3(cos(deg_to_rad(float(angle)))*0.35,0.5,sin(deg_to_rad(float(angle)))*0.35),0.35)
            spoke.set_meta("ttl",0.5)
            active_effects.append(spoke)
            add_child(spoke)

func _beam(from:Vector3,to:Vector3,width:float)->MeshInstance3D:
    var node:=MeshInstance3D.new()
    var mesh:=CylinderMesh.new()
    mesh.top_radius=width*0.055
    mesh.bottom_radius=width*0.08
    mesh.height=max(0.05,from.distance_to(to))
    mesh.radial_segments=10
    node.mesh=mesh
    node.global_position=(from+to)*0.5
    node.look_at(to,Vector3.UP)
    node.rotate_object_local(Vector3.RIGHT,PI*0.5)
    node.material_override=_glow_material(Color(1.0,0.78,0.25),3.8)
    return node

func _orb(position:Vector3,radius:float)->MeshInstance3D:
    var node:=MeshInstance3D.new()
    var mesh:=SphereMesh.new()
    mesh.radius=radius
    mesh.height=radius*2.0
    mesh.radial_segments=16
    mesh.rings=8
    node.mesh=mesh
    node.global_position=position
    node.material_override=_glow_material(Color(1.0,0.85,0.35),4.0)
    return node

func _glow_material(color:Color,energy:float)->StandardMaterial3D:
    var material:=StandardMaterial3D.new()
    material.albedo_color=color
    material.emission_enabled=true
    material.emission=color
    material.emission_energy_multiplier=energy
    material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
    return material
