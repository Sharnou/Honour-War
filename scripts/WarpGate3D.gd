class_name WarpGate3D
extends Area3D

@export var target_map:int=10
@export var target_x:int=180
@export var target_y:int=150
@export var label_text:String="Dungeon Warp"

var ring:MeshInstance3D
var core:MeshInstance3D
var pulse:float=0.0

func _ready()->void:
	add_to_group("warp_gate")
	input_ray_pickable=true
	_build_visual()
	var collision:=CollisionShape3D.new()
	var shape:=SphereShape3D.new()
	shape.radius=0.95
	collision.shape=shape
	collision.position.y=0.85
	add_child(collision)
	_refresh_visibility()

func _process(delta:float)->void:
	pulse+=delta
	if ring!=null:
		ring.scale=Vector3.ONE*(1.0+sin(pulse*3.0)*0.07)
	if core!=null:
		core.scale=Vector3.ONE*(0.92+sin(pulse*4.5)*0.06)
	_refresh_visibility()

func _refresh_visibility()->void:
	var game:Node=get_parent()
	var legacy:Node=game.get_node_or_null("LegacyGame") if game!=null else null
	if legacy==null:
		return
	var hero_value:Variant=legacy.get("hero")
	if not hero_value is Dictionary:
		return
	visible=not TeleportSystem.is_dungeon(int((hero_value as Dictionary).get("map_id",0)))

func activate()->void:
	var game:Node=get_parent()
	var legacy:Node=game.get_node_or_null("LegacyGame") if game!=null else null
	if legacy!=null and legacy.has_method("fast_travel"):
		legacy.call("fast_travel",target_map,target_x,target_y)

func _build_visual()->void:
	ring=MeshInstance3D.new()
	var torus:=TorusMesh.new()
	torus.inner_radius=0.72
	torus.outer_radius=0.84
	ring.mesh=torus
	ring.rotation_degrees.x=90.0
	ring.material_override=_material(Color("#65cfff"),0.35,0.22,true)
	add_child(ring)
	core=MeshInstance3D.new()
	var sphere:=SphereMesh.new()
	sphere.radius=0.30
	sphere.height=0.60
	core.mesh=sphere
	core.position.y=0.80
	core.material_override=_material(Color("#5ba9ff"),0.05,0.20,true)
	add_child(core)
	var label:=Label3D.new()
	label.text=label_text
	label.position=Vector3(0.0,1.75,0.0)
	label.font_size=30
	label.outline_size=8
	label.modulate=Color("#e4f7ff")
	label.no_depth_test=true
	add_child(label)

func _material(color:Color,metallic:float,roughness:float,emissive:bool)->StandardMaterial3D:
	var material:=StandardMaterial3D.new()
	material.albedo_color=color
	material.metallic=metallic
	material.roughness=roughness
	if emissive:
		material.emission_enabled=true
		material.emission=color
		material.emission_energy_multiplier=3.0
	return material
