class_name WarpGates3D
extends Node3D

const GATES:Array[Dictionary]=[
	{"map_id":10,"name":"Prontera Sewer","color":Color("#56d6ff"),"pos":Vector3(-5.5,0.05,3.8)},
	{"map_id":11,"name":"Payon Cave","color":Color("#7cff82"),"pos":Vector3(5.5,0.05,3.8)},
	{"map_id":12,"name":"Geffen Tower","color":Color("#9d7cff"),"pos":Vector3(-5.5,0.05,-3.8)},
	{"map_id":13,"name":"Morroc Ruins","color":Color("#ff9b58"),"pos":Vector3(5.5,0.05,-3.8)}
]

var legacy:Node
var root:Node3D
var elapsed:float=0.0
var gate_nodes:Array[Node3D]=[]

func _ready()->void:
	legacy=get_parent().get_node_or_null("LegacyGame")
	root=Node3D.new()
	root.name="WarpGates"
	add_child(root)
	_build_gates()

func _process(delta:float)->void:
	elapsed+=delta
	if legacy==null:
		return
	var map_id:int=int(legacy.get("hero").get("map_id",0))
	var visible:bool=not TeleportSystem.is_dungeon(map_id)
	root.visible=visible
	for i in gate_nodes.size():
		var gate:Node3D=gate_nodes[i]
		var pulse:float=1.0+sin(elapsed*2.4+float(i))*0.08
		gate.scale=Vector3.ONE*pulse
		gate.rotation.y=elapsed*(0.32+float(i)*0.03)

func _material(c:Color)->StandardMaterial3D:
	var m:StandardMaterial3D=StandardMaterial3D.new()
	m.albedo_color=Color(c.r,c.g,c.b,0.42)
	m.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	m.emission_enabled=true
	m.emission=c
	m.emission_energy_multiplier=3.5
	return m

func _build_gates()->void:
	for data in GATES:
		var gate:Node3D=Node3D.new()
		gate.name="Warp_"+str(data["map_id"])
		gate.position=data["pos"]
		gate.set_meta("map_id",int(data["map_id"]))
		gate_nodes.append(gate)
		root.add_child(gate)
		var ring:MeshInstance3D=MeshInstance3D.new()
		var torus:TorusMesh=TorusMesh.new()
		torus.inner_radius=0.78
		torus.outer_radius=0.98
		torus.rings=32
		torus.ring_segments=12
		ring.mesh=torus
		ring.material_override=_material(data["color"])
		ring.rotation_degrees.x=90.0
		gate.add_child(ring)
		var inner:MeshInstance3D=MeshInstance3D.new()
		var sphere:SphereMesh=SphereMesh.new()
		sphere.radius=0.78
		sphere.height=0.18
		inner.mesh=sphere
		inner.material_override=_material(data["color"])
		gate.add_child(inner)
		var light:OmniLight3D=OmniLight3D.new()
		light.light_color=data["color"]
		light.light_energy=2.0
		light.omni_range=4.5
		light.position.y=0.8
		gate.add_child(light)
		var label:Label3D=Label3D.new()
		label.text="WARP GATE\n"+str(data["name"])
		label.position=Vector3(0,1.65,0)
		label.modulate=Color(1,1,1,0.92)
		label.font_size=32
		label.outline_size=8
		gate.add_child(label)
