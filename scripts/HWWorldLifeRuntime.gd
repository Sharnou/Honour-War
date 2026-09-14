extends Node3D

## Honour War world-life and combat atmosphere pass.
## Adds non-interactive ambient details and a lightweight objective pulse without
## replacing the real gameplay state or authored GLB assets.

var scene_root:Node
var life_root:Node3D
var pulse:float = 0.0
var objective_timer:float = 0.0
var objective_index:int = 0
var objective_labels:Array[String] = [
    "Hunt the strongest nearby monster",
    "Keep your pet active in combat",
    "Collect a rare card or equipment drop",
    "Advance your class specialization",
    "Refine one equipped item"
]
var banner:Label
var ribbon:Panel

func _ready()->void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("_build")

func _process(delta:float)->void:
    pulse += delta
    objective_timer += delta
    if scene_root == null or not is_instance_valid(scene_root):
        scene_root = get_tree().current_scene
        if scene_root != null:
            _build()
    if life_root != null and is_instance_valid(life_root):
        _animate_life()
    if objective_timer >= 18.0:
        objective_timer = 0.0
        objective_index = (objective_index + 1) % objective_labels.size()
        _update_objective()

func _build()->void:
    scene_root = get_tree().current_scene
    if scene_root == null or scene_root.get_node_or_null("HWWorldLife") != null:
        _update_objective()
        return
    life_root = Node3D.new()
    life_root.name = "HWWorldLife"
    scene_root.add_child(life_root)
    _add_environment_cluster(Vector3(-12,0.0,-4), 0.9)
    _add_environment_cluster(Vector3(14,0.0,4), 1.15)
    _add_environment_cluster(Vector3(-18,0.0,15), 0.75)
    _add_environment_cluster(Vector3(19,0.0,16), 0.95)
    _add_objective_ui()
    _update_objective()

func _add_environment_cluster(center:Vector3, scale_factor:float)->void:
    var wood:=_mat(Color("#5a3d2c"),0.82,0.05)
    var stone:=_mat(Color("#8e887d"),0.95,0.02)
    var cloth:=_mat(Color("#b98e5f"),0.9,0.0)
    var accent:=_mat(Color("#d9bb71"),0.48,0.42)
    for i in range(4):
        var dx:float=float(i-2)*0.72*scale_factor
        var post:=_box(wood,Vector3(0.13,1.3,0.13),center+Vector3(dx,0.68,0.28*sin(float(i))))
        post.rotation.y=0.12*float(i-2)
        life_root.add_child(post)
    var beam:=_box(wood,Vector3(2.25*scale_factor,0.16,0.16),center+Vector3(0,1.38,0.0))
    beam.rotation.z=0.025
    life_root.add_child(beam)
    var roof:=_box(cloth,Vector3(1.45*scale_factor,0.06,0.82*scale_factor),center+Vector3(0,1.62,0.0))
    roof.rotation.z=0.04
    life_root.add_child(roof)
    for x in [-0.78,0.78]:
        var crate:=_box(stone,Vector3(0.38,0.35,0.38),center+Vector3(x*scale_factor,0.22,0.55))
        crate.rotation_degrees=Vector3(0.0,18.0*x,0.0)
        life_root.add_child(crate)
    var lamp:=_sphere(accent,0.11,center+Vector3(0,1.12,-0.20))
    life_root.add_child(lamp)
    var light:=OmniLight3D.new()
    light.position=center+Vector3(0,1.12,-0.20)
    light.omni_range=3.2*scale_factor
    light.light_energy=0.24
    light.shadow_enabled=false
    life_root.add_child(light)

func _add_objective_ui()->void:
    var layer:=CanvasLayer.new()
    layer.name="HWWorldLifeHUD"
    scene_root.add_child(layer)
    ribbon=Panel.new()
    ribbon.position=Vector2(28,82)
    ribbon.size=Vector2(430,58)
    layer.add_child(ribbon)
    banner=Label.new()
    banner.position=Vector2(16,9)
    banner.size=Vector2(398,40)
    banner.add_theme_font_size_override("font_size",18)
    banner.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    ribbon.add_child(banner)

func _update_objective()->void:
    if banner==null or not is_instance_valid(banner):
        return
    banner.text="HONOUR OBJECTIVE  •  " + objective_labels[objective_index]

func _animate_life()->void:
    var glow:float=0.20+sin(pulse*1.4)*0.05
    for child in life_root.get_children():
        if child is OmniLight3D:
            (child as OmniLight3D).light_energy=max(0.08,glow)

func _mat(color:Color,roughness:float,metallic:float)->StandardMaterial3D:
    var material:=StandardMaterial3D.new()
    material.albedo_color=color
    material.roughness=roughness
    material.metallic=metallic
    return material

func _box(material:Material,size:Vector3,pos:Vector3)->MeshInstance3D:
    var node:=MeshInstance3D.new()
    var mesh:=BoxMesh.new()
    mesh.size=size
    node.mesh=mesh
    node.position=pos
    node.material_override=material
    return node

func _sphere(material:Material,radius:float,pos:Vector3)->MeshInstance3D:
    var node:=MeshInstance3D.new()
    var mesh:=SphereMesh.new()
    mesh.radius=radius
    mesh.height=radius*2.0
    mesh.radial_segments=24
    mesh.rings=12
    node.mesh=mesh
    node.position=pos
    node.material_override=material
    return node
