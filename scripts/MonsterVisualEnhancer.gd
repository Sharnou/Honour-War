class_name MonsterVisualEnhancer
extends Node3D

## Production-facing procedural presentation fallback for named monsters.
## Final high-detail Bloody Knight assets still follow Blender -> Painter -> GLB/GLTF -> Godot 4.
var game:Node3D
var built:Dictionary={}

func _ready()->void:
	game=get_parent() as Node3D

func _process(_delta:float)->void:
	if game==null: return
	var visuals:Variant=game.get("monster_visuals")
	if not visuals is Dictionary: return
	for id in visuals.keys():
		var node:Node3D=visuals[id] as Node3D
		if node==null or not is_instance_valid(node): continue
		if built.has(id): continue
		if str(node.name).to_lower().contains("bloody knight"):
			_build_bloody_knight(node)
			built[id]=true
	for id in built.keys():
		if not visuals.has(id): built.erase(id)

func _build_bloody_knight(root:Node3D)->void:
	var armor:=MeshInstance3D.new()
	armor.name="BloodIronArmor"
	var armor_mesh:=BoxMesh.new()
	armor_mesh.size=Vector3(1.15,1.15,0.62)
	armor.mesh=armor_mesh
	armor.position=Vector3(0.0,0.95,0.0)
	armor.material_override=_mat(Color("#20151a"),0.18,0.30)
	root.add_child(armor)
	var helm:=MeshInstance3D.new()
	helm.name="ExecutionerHelm"
	var helm_mesh:=SphereMesh.new()
	helm_mesh.radius=0.48
	helm_mesh.height=0.82
	helm.mesh=helm_mesh
	helm.position=Vector3(0.0,1.82,0.0)
	helm.scale=Vector3(1.0,0.92,0.86)
	helm.material_override=_mat(Color("#141015"),0.24,0.24)
	root.add_child(helm)
	var blade:=MeshInstance3D.new()
	blade.name="BloodGreatblade"
	var blade_mesh:=BoxMesh.new()
	blade_mesh.size=Vector3(0.16,1.65,0.32)
	blade.mesh=blade_mesh
	blade.position=Vector3(0.72,1.10,0.0)
	blade.rotation_degrees.z=-18.0
	blade.material_override=_mat(Color("#5b171d"),0.30,0.22)
	root.add_child(blade)
	for side in [-1.0,1.0]:
		var spike:=MeshInstance3D.new()
		var spike_mesh:=CylinderMesh.new()
		spike_mesh.top_radius=0.0
		spike_mesh.bottom_radius=0.12
		spike_mesh.height=0.52
		spike.mesh=spike_mesh
		spike.position=Vector3(side*0.62,1.72,0.0)
		spike.rotation_degrees.z=side*25.0
		spike.material_override=_mat(Color("#6f2026"),0.12,0.35)
		root.add_child(spike)
	var aura:=OmniLight3D.new()
	aura.name="BloodAura"
	aura.position=Vector3(0.0,1.0,0.0)
	aura.omni_range=4.5
	aura.light_energy=2.2
	aura.light_color=Color("#7d1520")
	root.add_child(aura)
	var label:=Label3D.new()
	label.name="ScaryTitle"
	label.text="BLOODY KNIGHT  •  EXECUTIONER"
	label.position=Vector3(0.0,2.55,0.0)
	label.font_size=34
	label.outline_size=10
	label.modulate=Color("#ffb0a8")
	root.add_child(label)

func _mat(albedo:Color,metallic:float,roughness:float)->StandardMaterial3D:
	var material:=StandardMaterial3D.new()
	material.albedo_color=albedo
	material.metallic=metallic
	material.roughness=roughness
	return material
