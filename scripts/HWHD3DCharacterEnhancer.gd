class_name HWHD3DCharacterEnhancer
extends Node3D

## Non-destructive HD presentation layer for the existing MMORPG prototype.
## It adds readable full-body proportions, face details, limbs, class equipment
## accents and soft contact shadows without replacing gameplay state or assets.

var game:Node
var enhanced_hero:Node3D
var last_class:String=""
var elapsed:float=0.0

func _ready()->void:
	process_priority=900
	game=get_parent()
	call_deferred("_refresh")

func _process(delta:float)->void:
	elapsed+=delta
	if game==null: return
	var current:Node3D=game.get("hero_visual") as Node3D
	if current!=enhanced_hero or (current!=null and str(current.get_meta("class",""))!=last_class):
		enhanced_hero=current
		last_class=str(current.get_meta("class","Warrior")) if current!=null else ""
		_refresh()
	if enhanced_hero!=null and is_instance_valid(enhanced_hero):
		_update_detail_motion(delta)

func _refresh()->void:
	if enhanced_hero==null or not is_instance_valid(enhanced_hero): return
	if bool(enhanced_hero.get_meta("hw_hd3d_enhanced",false)): return
	enhanced_hero.set_meta("hw_hd3d_enhanced",true)
	var class_id:=str(enhanced_hero.get_meta("class","Warrior"))
	_add_face(enhanced_hero,class_id)
	_add_arms(enhanced_hero,class_id)
	_add_legs(enhanced_hero,class_id)
	_add_belt(enhanced_hero,class_id)
	_add_class_details(enhanced_hero,class_id)
	_add_contact_ring(enhanced_hero)

func _mat(color:Color,roughness:float=0.72,metallic:float=0.0)->StandardMaterial3D:
	var m:=StandardMaterial3D.new()
	m.albedo_color=color
	m.roughness=roughness
	m.metallic=metallic
	m.specular_mode=BaseMaterial3D.SPECULAR_SCHLICK_GGX
	m.shading_mode=BaseMaterial3D.SHADING_MODE_PER_PIXEL
	return m

func _accent(class_id:String)->Color:
	match class_id:
		"Mage": return Color("#7d6cff")
		"Archer": return Color("#63c77b")
		"Thief": return Color("#b75cff")
		"Acolyte": return Color("#f4d46d")
		"Merchant": return Color("#d57a3f")
	return Color("#4f9cff")

func _add_face(root:Node3D,class_id:String)->void:
	var skin:=_mat(Color("#e3ad88"),0.82)
	var eye:=_mat(Color("#171b24"),0.30)
	var hair:=_mat(Color("#24222a"),0.72)
	for x in [-0.14,0.14]:
		var eye_mesh:=MeshInstance3D.new()
		var sphere:=SphereMesh.new(); sphere.radius=0.055; sphere.height=0.11
		eye_mesh.mesh=sphere; eye_mesh.material_override=eye
		eye_mesh.position=Vector3(x,2.30,-0.355)
		root.add_child(eye_mesh)
	var nose:=MeshInstance3D.new(); var nose_mesh:=SphereMesh.new(); nose_mesh.radius=0.045; nose_mesh.height=0.09
	nose.mesh=nose_mesh; nose.material_override=skin; nose.position=Vector3(0.0,2.22,-0.36); root.add_child(nose)
	var hair_band:=MeshInstance3D.new(); var band:=TorusMesh.new(); band.inner_radius=0.34; band.outer_radius=0.39; band.rings=32; band.ring_segments=10
	hair_band.mesh=band; hair_band.material_override=_mat(_accent(class_id),0.55,0.05); hair_band.position=Vector3(0,2.40,0); root.add_child(hair_band)
	var ear_l:=MeshInstance3D.new(); var ear_mesh:=SphereMesh.new(); ear_mesh.radius=0.07; ear_mesh.height=0.14
	ear_l.mesh=ear_mesh; ear_l.material_override=skin; ear_l.position=Vector3(-0.37,2.28,0); root.add_child(ear_l)
	var ear_r:=ear_l.duplicate() as MeshInstance3D; ear_r.position.x=0.37; root.add_child(ear_r)

func _add_arms(root:Node3D,class_id:String)->void:
	var accent:=_accent(class_id)
	var arm_material:=_mat(Color("#c88f70"),0.84)
	for side in [-1.0,1.0]:
		var arm:=MeshInstance3D.new(); var mesh:=CapsuleMesh.new(); mesh.radius=0.14; mesh.height=0.78; mesh.radial_segments=16; mesh.rings=6
		arm.mesh=mesh; arm.material_override=arm_material; arm.position=Vector3(side*0.56,1.22,0.0); arm.rotation_degrees.z=side*7.0; root.add_child(arm)
		var cuff:=MeshInstance3D.new(); var cuff_mesh:=CylinderMesh.new(); cuff_mesh.top_radius=0.17; cuff_mesh.bottom_radius=0.17; cuff_mesh.height=0.14; cuff_mesh.radial_segments=16
		cuff.mesh=cuff_mesh; cuff.material_override=_mat(accent,0.58,0.08); cuff.position=Vector3(side*0.56,0.86,0.0); root.add_child(cuff)

func _add_legs(root:Node3D,class_id:String)->void:
	var cloth:=_mat(Color("#202733"),0.88)
	var boot:=_mat(Color("#343942"),0.62,0.12)
	for side in [-1.0,1.0]:
		var leg:=MeshInstance3D.new(); var mesh:=CapsuleMesh.new(); mesh.radius=0.17; mesh.height=0.82; mesh.radial_segments=16; mesh.rings=6
		leg.mesh=mesh; leg.material_override=cloth; leg.position=Vector3(side*0.22,0.46,0.0); root.add_child(leg)
		var shoe:=MeshInstance3D.new(); var shoe_mesh:=SphereMesh.new(); shoe_mesh.radius=0.25; shoe_mesh.height=0.24
		shoe.mesh=shoe_mesh; shoe.material_override=boot; shoe.position=Vector3(side*0.22,0.10,-0.08); shoe.scale=Vector3(1.0,0.60,1.35); root.add_child(shoe)

func _add_belt(root:Node3D,class_id:String)->void:
	var belt:=MeshInstance3D.new(); var mesh:=TorusMesh.new(); mesh.inner_radius=0.40; mesh.outer_radius=0.47; mesh.rings=32; mesh.ring_segments=10
	belt.mesh=mesh; belt.material_override=_mat(_accent(class_id),0.48,0.15); belt.position=Vector3(0,1.05,0); belt.rotation_degrees.x=90.0; root.add_child(belt)

func _add_class_details(root:Node3D,class_id:String)->void:
	var accent:=_accent(class_id)
	if class_id=="Archer":
		var quiver:=MeshInstance3D.new(); var q:=CylinderMesh.new(); q.top_radius=0.16; q.bottom_radius=0.20; q.height=0.80; q.radial_segments=16
		quiver.mesh=q; quiver.material_override=_mat(Color("#70482f"),0.72); quiver.position=Vector3(-0.42,1.25,0.30); quiver.rotation_degrees.z=-14.0; root.add_child(quiver)
	elif class_id=="Mage":
		var orb:=MeshInstance3D.new(); var s:=SphereMesh.new(); s.radius=0.13; s.height=0.26
		orb.mesh=s; orb.material_override=_mat(accent,0.35,0.1); orb.position=Vector3(0.0,1.72,0.28); root.add_child(orb)
	elif class_id=="Acolyte":
		var halo:=MeshInstance3D.new(); var h:=TorusMesh.new(); h.inner_radius=0.34; h.outer_radius=0.39; h.rings=32; h.ring_segments=10
		halo.mesh=h; halo.material_override=_mat(accent,0.30,0.05); halo.position=Vector3(0,2.88,0); halo.rotation_degrees.x=90.0; root.add_child(halo)
	else:
		var gem:=MeshInstance3D.new(); var g:=SphereMesh.new(); g.radius=0.10; g.height=0.20
		gem.mesh=g; gem.material_override=_mat(accent,0.38,0.08); gem.position=Vector3(0,1.65,-0.34); root.add_child(gem)

func _add_contact_ring(root:Node3D)->void:
	var ring:=MeshInstance3D.new(); var mesh:=TorusMesh.new(); mesh.inner_radius=0.48; mesh.outer_radius=0.52; mesh.rings=32; mesh.ring_segments=8
	ring.mesh=mesh; ring.rotation_degrees.x=90.0; ring.position=Vector3(0,0.035,0)
	var mat:=_mat(Color("#ffffff"),0.78); mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA; mat.albedo_color.a=0.28
	ring.material_override=mat; root.add_child(ring)

func _update_detail_motion(delta:float)->void:
	var aura:Node3D=enhanced_hero.get_node_or_null("MageOrb") as Node3D
	if aura!=null: aura.rotation.y+=delta*1.6
	var halo:Node3D=enhanced_hero.get_node_or_null("AcolyteHalo") as Node3D
	if halo!=null: halo.rotation.z+=delta*0.8
