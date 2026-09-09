class_name HDActorDetails
extends Node3D

var game:Node3D
var labels:Dictionary={}

func _ready()->void:
	game=get_parent() as Node3D
	process_priority=900

func _process(_delta:float)->void:
	if game==null: return
	var hero:Node3D=game.get("hero_visual") as Node3D
	var pet:Node3D=game.get("pet_visual") as Node3D
	var legacy:Node=game.get_node_or_null("LegacyGame")
	if hero==null or legacy==null: return
	var hero_data:Variant=legacy.get("hero")
	if not hero_data is Dictionary: return
	var h:Dictionary=hero_data
	var equipment:Dictionary=h.get("equipment",{}) if h.get("equipment",{}) is Dictionary else {}
	var hero_title:String=str(h.get("name","Hero"))+"  •  Lv."+str(h.get("level",1))+" "+str(h.get("class","Warrior"))
	var hero_info:String="HP %d/%d  •  Weapon: %s  •  Armor: %s" % [int(h.get("hp",0)),int(h.get("max_hp",1)),str(equipment.get("weapon","None")),str(equipment.get("armor","None"))]
	_set_detail(hero,"hero",hero_title,hero_info,Vector3(0.0,3.25,0.0),32)
	var p:Variant=h.get("pet",{})
	if p is Dictionary and pet!=null:
		var pet_data:Dictionary=p
		var pet_skills:Variant=pet_data.get("skills",[])
		var skill_text:String=str(pet_data.get("skills",[])) if not pet_skills is Array else ", ".join(pet_skills as Array)
		var pet_title:String=str(pet_data.get("name","Pet"))+"  •  Lv."+str(pet_data.get("level",1))+" "+str(pet_data.get("species","Pet"))
		var pet_info:String="%s  •  HP %d/%d  •  Skills: %s  •  Refine +%d" % [str(pet_data.get("role","Companion")),int(pet_data.get("hp",0)),int(pet_data.get("max_hp",1)),skill_text,int(pet_data.get("refine",0))]
		_set_detail(pet,"pet",pet_title,pet_info,Vector3(0.0,1.55,0.0),24)
	var visuals:Dictionary=game.get("monster_visuals") as Dictionary
	var monsters_value:Variant=legacy.get("monsters")
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
					var info:String="Lv.%d  •  HP %d/%d" % [int(m.get("level",1)),int(m.get("hp",0)),int(m.get("max",1))]
					_set_detail(visual,"monster_"+id,prefix+str(m.get("name","Monster")),info,Vector3(0.0,2.65 if bool(m.get("mvp",false)) else 2.15,0.0),24)
	var remove_keys:Array[String]=[]
	for key in labels.keys():
		var key_text:String=str(key)
		if key_text.begins_with("monster_"):
			var monster_id:String=key_text.substr(8)
			if not active.has(monster_id): remove_keys.append(key_text)
	for key_text in remove_keys:
		var old:Node=labels.get(key_text) as Node
		if old!=null and is_instance_valid(old): old.queue_free()
		labels.erase(key_text)

func _set_detail(actor:Node3D,key:String,title:String,subtitle:String,offset:Vector3,font_size:int)->void:
	if actor==null: return
	var label:Label3D=labels.get(key) as Label3D
	if label==null or not is_instance_valid(label):
		label=Label3D.new()
		label.name="HDDetail_"+key
		label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test=true
		label.outline_size=6
		label.font_size=font_size
		label.modulate=Color.WHITE
		actor.add_child(label)
		labels[key]=label
	label.position=offset
	label.text=title+"\n"+subtitle
