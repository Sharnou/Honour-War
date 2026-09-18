extends Node

var emotion:String="fierce_courageous"
var elapsed:float=0.0

func _ready()->void:
	set_process(true)
	if get_meta("emotion",null)!=null:
		emotion=str(get_meta("emotion"))
	if get_meta("time",null)!=null:
		elapsed=float(get_meta("time"))

func _process(delta:float)->void:
	elapsed+=delta
	var root:=get_parent() as Node3D
	if root==null:
		return
	# Clothing emotion is expressed through subtle cloth/gear motion, not a generic idle.
	# This keeps each archetype visually readable while avoiding large physics costs.
	var sway:=sin(elapsed*1.8)*0.025
	var pulse:=sin(elapsed*2.4)*0.012
	for child in root.get_children():
		if child is MeshInstance3D:
			var mesh:=child as MeshInstance3D
			if mesh.name in ["BlueCape","ShadowSmoke","MerchantCart","MagicCircle","DivineAura","WarriorAura"]:
				mesh.rotation.z=sway
			if mesh.name in ["WideSleeve","ArmWrap","Gauntlet","Bracer"]:
				mesh.rotation.x=pulse
	# Emotional body language: the clothing layer follows a distinct rhythm per class.
		if emotion=="confident_opportunistic":
			root.rotation.y=sin(elapsed*0.7)*0.018
		elif emotion=="serene_benevolent":
			root.rotation.z=sin(elapsed*0.9)*0.008
		elif emotion=="focused_calculating":
			root.rotation.y=sin(elapsed*1.4)*0.032
		elif emotion=="alert_natural":
			root.rotation.y=sin(elapsed*1.1)*0.022
		elif emotion=="aloof_concentrated":
			root.rotation.z=sin(elapsed*0.8)*0.012
		else:
			root.rotation.z=sin(elapsed*1.2)*0.016
