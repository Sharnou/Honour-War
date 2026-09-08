class_name WarpGates3D
extends Node3D

const WARP_GATE_SCRIPT=preload("res://scripts/WarpGate3D.gd")
const GATES:Array[Dictionary]=[
	{"map_id":10,"name":"Prontera Sewer","color":Color("#56d6ff"),"pos":Vector3(6.5,0.05,10.5),"x":180,"y":450},
	{"map_id":11,"name":"Payon Cave","color":Color("#7cff82"),"pos":Vector3(19.5,0.05,10.5),"x":180,"y":450},
	{"map_id":12,"name":"Geffen Tower","color":Color("#9d7cff"),"pos":Vector3(6.5,0.05,14.8),"x":180,"y":450},
	{"map_id":13,"name":"Morroc Ruins","color":Color("#ff9b58"),"pos":Vector3(19.5,0.05,14.8),"x":180,"y":450},
	{"map_id":14,"name":"Orc Dungeon","color":Color("#c8ff66"),"pos":Vector3(10.2,0.05,18.0),"x":180,"y":450},
	{"map_id":15,"name":"Ice Cave","color":Color("#7feaff"),"pos":Vector3(15.8,0.05,18.0),"x":180,"y":450}
]

var legacy:Node
var root:Node3D
var elapsed:float=0.0
var gate_nodes:Array[Node3D]=[]

func _ready()->void:
	legacy=get_parent().get_node_or_null("LegacyGame")
	call_deferred("_build_runtime")

func _build_runtime()->void:
	if not is_inside_tree(): return
	root=Node3D.new()
	root.name="WarpGates"
	add_child(root)
	_build_gates()

func _process(delta:float)->void:
	elapsed+=delta
	if legacy==null: return
	var hero_value:Variant=legacy.get("hero")
	if not hero_value is Dictionary: return
	var map_id:int=int((hero_value as Dictionary).get("map_id",0))
	var visible:bool=not TeleportSystem.is_dungeon(map_id)
	if root!=null: root.visible=visible
	for i in gate_nodes.size():
		var gate:Node3D=gate_nodes[i]
		if gate==null: continue
		var pulse:float=1.0+sin(elapsed*2.4+float(i))*0.08
		gate.scale=Vector3.ONE*pulse
		gate.rotation.y=elapsed*(0.32+float(i)*0.03)

func _build_gates()->void:
	for data in GATES:
		var gate:Node3D=WARP_GATE_SCRIPT.new() as Node3D
		gate.name="Warp_"+str(data["map_id"])
		gate.position=data["pos"]
		gate.set("target_map",int(data["map_id"]))
		gate.set("target_x",int(data["x"]))
		gate.set("target_y",int(data["y"]))
		gate.set("label_text","WARP GATE\n"+str(data["name"]))
		root.add_child(gate)
		gate_nodes.append(gate)
