class_name HDActorDetails
extends Node3D

var game:Node3D
var labels:Dictionary={}
var last_monster_ids:Dictionary={}

func _ready()->void:
	game=get_parent() as Node3D
	process_priority=900

func _process(_delta:float)->void:
	if game==null: return
	var hero:Node3D=game.get("hero_visual") as Node3D
	var pet:Node3D=game.get("pet_visual") as Node3D
	var legacy:Node=game.get_node_or_null("LegacyGame")
	if hero!=null and legacy!=null:
		var hero_data:Variant=legacy.get("hero")
		if hero_data is Dictionary:
			var h:Dictionary=hero_data
			_set_detail(hero,"hero",str(h.get("name","Hero")),"Lv.%d %s | HP %d/%d" % [int(h.get("level",1)),str(h.get("class","Warrior")),int(h.get("hp",0)),int(h.get("max_hp",1))],Vector3(0.0,3.25,0.0))
			var p:Variant=h.get("pet",{})
			if p is Dictionary and pet!=null:
				_set_detail(pet,"pet",str(p.get("name","Pet")),"Lv.%d %s | HP %d/%d | %s" % [int(p.get("level",1)),str(p.get("species","Pet")),int(p.get("hp",0)),int(p.get("max_hp",1)),str(p.get("role","Companion"))],Vector3(0.0,1.45,0.0))
	var visuals:Dictionary=game.get("monster_visuals") as Dictionary
	var monsters_value:Variant=legacy.get("monsters") if legacy!=null else null
	var active:Dictionary={}
	if monsters_value is Array:
		for item in monsters_value as Array:
			if not item is Dictionary: continue
			var m:Dictionary=item
			var id:String=str(m.get("visual_id",m.get("name","monster")))
			active[id]=true
			if visuals!=null and visuals.has(id):
				var visual:Node3D=visuals[id] as Node3D
				if visual!=null:
					var prefix:String="MVP " if bool(m.get("mvp",false)) else ""
					_set_detail(visual,"monster_"+id,prefix+str(m.get("name","Monster")),"Lv.%d | HP %d/%d" % [int(m.get("level",1)),int(m.get("hp",0)),int(m.get("max",1))],Vector3(0.0,2.65 if bool(m.get("mvp",false)) else 2.15,0.0))
	for key in labels.keys():
		if not active.has(str(key)) and str(key).begins_with("monster_"):
			var old:Node=labels[key] as Node
			if old!=null and is_instance_valid(old): old.queue_free()
			labels.erase(key)

func _set_detail(actor:Node3D,key:String,title:String,subtitle:String,offset:Vector3)->void:
	if actor==null: return
	var label:Label3D=labels.get(key) as Label3D
	if label==null or not is_instance_valid(label):
		label=Label3D.new()
		label.name="HDDetail_"+key
		label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test=true
		label.outline_size=6
		label.font_size=32 if key=="hero" else 24
		label.modulate=Color.WHITE
		actor.add_child(label)
		labels[key]=label
	label.position=offset
	label.text=title+"\n"+subtitle
