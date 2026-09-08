class_name HDCombatVFX
extends Node3D

@export var feedback_path:NodePath
@export var max_effects:int = 48
@export var damage_lifetime:float = 0.9
@export var telegraph_lifetime:float = 0.85

var feedback:Node
var active_effects:Array[Node3D] = []
var target_marker:MeshInstance3D
var target_node:Node3D

func _ready() -> void:
	feedback=get_node_or_null(feedback_path)
	if feedback==null: feedback=get_parent().get_node_or_null("HDCombatFeedback")
	if feedback==null: return
	if feedback.has_signal("damage_number_requested"): feedback.damage_number_requested.connect(_on_damage)
	if feedback.has_signal("telegraph_requested"): feedback.telegraph_requested.connect(_on_telegraph)
	if feedback.has_signal("skill_effect_requested"): feedback.skill_effect_requested.connect(_on_skill)

func _on_damage(amount:int,world_position:Vector3,critical:bool)->void:
	var label:=Label3D.new()
	label.text=("CRIT " if critical else "")+str(amount)
	label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size=64 if critical else 48
	label.outline_size=8
	label.modulate=Color(1.0,0.88,0.42,1.0) if critical else Color(1.0,1.0,1.0,1.0)
	label.position=world_position+Vector3(0.0,1.2,0.0)
	add_child(label)
	_track(label)
	var tween:=create_tween()
	tween.set_parallel(true)
	tween.tween_property(label,"position:y",label.position.y+(1.0 if critical else 0.7),damage_lifetime)
	tween.tween_property(label,"scale",Vector3.ONE*(1.35 if critical else 1.0),0.12)
	tween.tween_method(func(alpha:float): _set_label_alpha(label,alpha),1.0,0.0,damage_lifetime).set_delay(0.18)
	tween.set_parallel(false)
	tween.tween_callback(label.queue_free)
	tween.tween_callback(func(): _untrack(label))

func _set_label_alpha(label:Label3D,alpha:float)->void:
	if label!=null and is_instance_valid(label): label.modulate=Color(label.modulate.r,label.modulate.g,label.modulate.b,alpha)

func _on_telegraph(_shape:String,world_position:Vector3,radius:float,duration:float)->void:
	var ring:=MeshInstance3D.new()
	var mesh:=CylinderMesh.new()
	mesh.top_radius=radius
	mesh.bottom_radius=radius
	mesh.height=0.035
	mesh.radial_segments=48
	ring.mesh=mesh
	ring.position=world_position+Vector3(0.0,0.025,0.0)
	var material:=StandardMaterial3D.new()
	material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color=Color(1.0,0.22,0.18,0.26)
	material.emission_enabled=true
	material.emission=Color(1.0,0.08,0.04)
	material.emission_energy_multiplier=1.8
	ring.material_override=material
	add_child(ring)
	_track(ring)
	var tween:=create_tween()
	tween.set_loops(max(1,int(ceil(duration/0.16))))
	tween.tween_property(ring,"scale",Vector3(1.08,1.0,1.08),0.08)
	tween.tween_property(ring,"scale",Vector3.ONE,0.08)
	tween.finished.connect(func():
		if is_instance_valid(ring): ring.queue_free()
		_untrack(ring))

func _on_skill(_effect_id:String,world_position:Vector3)->void:
	var impact:=MeshInstance3D.new()
	var mesh:=TorusMesh.new()
	mesh.inner_radius=0.18
	mesh.outer_radius=0.48
	mesh.rings=32
	mesh.ring_segments=10
	impact.mesh=mesh
	impact.position=world_position+Vector3(0.0,0.12,0.0)
	var material:=StandardMaterial3D.new()
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color=Color(0.35,0.78,1.0,0.85)
	material.emission_enabled=true
	material.emission=Color(0.20,0.65,1.0)
	material.emission_energy_multiplier=3.0
	impact.material_override=material
	add_child(impact)
	_track(impact)
	var tween:=create_tween()
	tween.set_parallel(true)
	tween.tween_property(impact,"scale",Vector3(2.6,1.0,2.6),0.28)
	tween.tween_property(impact,"rotation:y",TAU,0.28)
	tween.tween_method(func(alpha:float): _set_material_alpha(impact,alpha),1.0,0.0,0.28)
	tween.set_parallel(false)
	tween.tween_callback(impact.queue_free)
	tween.tween_callback(func(): _untrack(impact))

func _set_material_alpha(node:MeshInstance3D,alpha:float)->void:
	if node==null or not is_instance_valid(node): return
	var material:=node.material_override as StandardMaterial3D
	if material==null: return
	var base:=material.albedo_color
	material.albedo_color=Color(base.r,base.g,base.b,alpha)
	material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA

func set_target_marker(value:Node3D)->void:
	target_node=value
	if target_marker and is_instance_valid(target_marker): target_marker.queue_free()
	target_marker=null
	if target_node==null: return
	target_marker=MeshInstance3D.new()
	var mesh:=TorusMesh.new()
	mesh.inner_radius=0.72
	mesh.outer_radius=0.82
	mesh.rings=32
	mesh.ring_segments=8
	target_marker.mesh=mesh
	var material:=StandardMaterial3D.new()
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color=Color(1.0,0.78,0.18,0.82)
	material.emission_enabled=true
	material.emission=Color(1.0,0.52,0.04)
	material.emission_energy_multiplier=1.5
	target_marker.material_override=material
	add_child(target_marker)

func _process(delta:float)->void:
	if target_marker and target_node and is_instance_valid(target_node):
		target_marker.global_position=target_node.global_position+Vector3(0.0,0.05,0.0)
		target_marker.rotation.y+=delta*2.5
	elif target_marker:
		target_marker.queue_free()
		target_marker=null

func _track(node:Node3D)->void:
	active_effects.append(node)
	while active_effects.size()>max_effects:
		var oldest:Node3D=active_effects.pop_front()
		if oldest and is_instance_valid(oldest): oldest.queue_free()

func _untrack(node:Node3D)->void:
	var index:=active_effects.find(node)
	if index>=0: active_effects.remove_at(index)
