class_name DamageNumbers3D
extends Node3D

const MAX_ACTIVE:int=80
var active:Array[Label3D]=[]

func _ready()->void:
	set_process(true)

func show_damage(world_position:Vector3,amount:int,critical:bool=false,source:String="enemy")->void:
	var label:=Label3D.new()
	label.text=str(amount) if source!="heal" else "+"+str(amount)
	label.font_size=64 if critical else 52
	label.outline_size=12
	label.no_depth_test=true
	label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	label.pixel_size=0.0042 if critical else 0.0048
	label.modulate=Color("#ffcf55") if critical else Color("#fff2d2")
	if source=="hero":
		label.modulate=Color("#ff5b5b")
	elif source=="pet":
		label.modulate=Color("#8ee8ff")
	elif source=="heal":
		label.modulate=Color("#75ff9a")
	elif amount<=0:
		label.text="MISS"
		label.modulate=Color("#b7c4d1")
	label.position=world_position+Vector3((randf()-0.5)*0.45,1.35+(randf()*0.20),0.0)
	if critical and source!="hero":
		label.text="CRITICAL\n"+label.text
	label.scale=Vector3.ONE*(1.18 if critical else 0.88)
	add_child(label)
	active.append(label)
	if active.size()>MAX_ACTIVE:
		var old:Label3D=active.pop_front()
		if is_instance_valid(old):
			old.queue_free()
	var start:Vector3=label.position
	var end:Vector3=start+Vector3((randf()-0.5)*0.3,1.0,0.0)
	var duration:float=0.95 if critical else 0.75
	var tween:=create_tween()
	tween.set_parallel(true)
	tween.tween_property(label,"position",end,duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label,"scale",Vector3.ONE*(1.35 if critical else 1.0),0.12)
	tween.chain().tween_property(label,"modulate:a",0.0,0.28)
	tween.chain().tween_callback(_remove_label.bind(label))

func _remove_label(label:Label3D)->void:
	active.erase(label)
	if is_instance_valid(label):
		label.queue_free()
