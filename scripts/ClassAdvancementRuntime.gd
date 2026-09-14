extends Node

# Runtime class advancement controller. Base archetype (Warrior/Mage/etc.) remains
# stable for formulas, while the visual/class rank advances automatically at the
# Honour War milestones and the player chooses a specialization branch at Lv.25+.
const TIER_NAMES:Dictionary={0:"Foundation",1:"Specialization",2:"Advanced",3:"Mastery",4:"Transcendence"}
const CHECK_INTERVAL:float=0.5

var timer:float=0.0
var last_tier:int=-1
var hero:Dictionary={}
var legacy:Node
var scene_root:Node
var panel:Panel
var title_label:Label
var detail_label:Label
var branch_box:VBoxContainer
var branch_buttons:Dictionary={}
var visual_signature:String=""

func _ready()->void:
	call_deferred("_find_game")

func _find_game()->void:
	scene_root=get_tree().current_scene
	if scene_root==null: return
	legacy=scene_root.get_node_or_null("LegacyGame")
	if legacy==null:
		legacy=scene_root.get_node_or_null("LegacyGame/CombatRuntime")
	_build_hud()
	_sync(true)

func _process(delta:float)->void:
	timer+=delta
	if timer<CHECK_INTERVAL: return
	timer=0.0
	_sync(false)

func _sync(force:bool)->void:
	if scene_root!=get_tree().current_scene or legacy==null or not is_instance_valid(legacy):
		_find_game()
		return
	var candidate=legacy.get("hero")
	if candidate is Dictionary:
		hero=candidate
	else:
		return
	ClassTreeSystem.ensure_state(hero)
	var level:int=int(hero.get("level",1))
	var class_id:=str(hero.get("class","Warrior"))
	var tier:=ClassTreeSystem.available_tier(hero)
	var rank:=GameData.class_rank_for_level(level,class_id)
	var changed:=force or tier!=last_tier or str(hero.get("class_rank",""))!=rank
	if changed:
		last_tier=tier
		hero["class_tier"]=GameData.class_tier_for_level(level)
		hero["class_rank"]=rank
		hero["class_rank_tier"]=tier
		SaveSystem.save_game(hero)
		_update_hud()
		_update_visuals()
	else:
		_update_hud()
	if str(hero.get("class_branch",""))=="" and level>=25:
		if panel!=null: panel.visible=true
	else:
		if panel!=null: panel.visible=tier>=2

func _build_hud()->void:
	if panel!=null: return
	var layer:=CanvasLayer.new()
	layer.name="ClassAdvancementHUD"
	get_tree().current_scene.add_child(layer)
	panel=Panel.new()
	panel.position=Vector2(1450,38)
	panel.size=Vector2(425,230)
	layer.add_child(panel)
	var box:=VBoxContainer.new()
	box.position=Vector2(16,12)
	box.size=Vector2(393,206)
	panel.add_child(box)
	title_label=Label.new()
	title_label.text="CLASS ADVANCEMENT"
	title_label.add_theme_font_size_override("font_size",22)
	box.add_child(title_label)
	detail_label=Label.new()
	detail_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	detail_label.custom_minimum_size=Vector2(390,54)
	box.add_child(detail_label)
	var prompt:=Label.new()
	prompt.text="Choose your specialization"
	prompt.add_theme_font_size_override("font_size",16)
	box.add_child(prompt)
	branch_box=VBoxContainer.new()
	branch_box.custom_minimum_size=Vector2(390,96)
	box.add_child(branch_box)

func _update_hud()->void:
	if detail_label==null: return
	var class_id:=str(hero.get("class","Warrior"))
	var level:=int(hero.get("level",1))
	var tier:=GameData.class_tier_for_level(level)
	var rank:=GameData.class_rank_for_level(level,class_id)
	var branch:=str(hero.get("class_branch",""))
	title_label.text="%s  •  Lv.%d" % [rank,level]
	detail_label.text="%s\nTier: %s\nSpecialization: %s" % [class_id,str(TIER_NAMES.get(tier,"Foundation")),branch if branch!="" else "Not selected"]
	for child in branch_box.get_children(): child.queue_free()
	branch_buttons.clear()
	if level<25 or branch!="":
		var status:=Label.new()
		status.text="Next promotion: Lv.%d" % _next_threshold(level)
		branch_box.add_child(status)
		return
	var profile:=ClassTreeSystem.class_profile(class_id)
	var descriptions:=ClassTreeSystem.branch_descriptions(class_id)
	for branch_name in profile["branches"]:
		var button:=Button.new()
		button.text="%s — %s" % [branch_name,str(descriptions.get(branch_name,""))]
		button.custom_minimum_size=Vector2(390,30)
		button.pressed.connect(_select_branch.bind(str(branch_name)))
		branch_box.add_child(button)
		branch_buttons[branch_name]=button

func _next_threshold(level:int)->int:
	for threshold in [25,50,100,200,250]:
		if level<threshold: return threshold
	return 250

func _select_branch(branch_name:String)->void:
	if str(hero.get("class_branch",""))!="": return
	if not ClassTreeSystem.select_branch(hero,branch_name): return
	SaveSystem.save_game(hero)
	_update_hud()
	_update_visuals()

func _update_visuals()->void:
	if scene_root==null: return
	var actors:=scene_root.get_node_or_null("Actors3D")
	if actors==null: return
	var hero_node:=actors.get_node_or_null("Hero") as Node3D
	if hero_node==null: return
	var class_id:=str(hero.get("class","Warrior"))
	var tier:=GameData.class_tier_for_level(int(hero.get("level",1)))
	var branch:=str(hero.get("class_branch",""))
	var signature:="%s:%d:%s" % [class_id,tier,branch]
	if signature==visual_signature and hero_node.get_node_or_null("HWClassRankVisual")!=null: return
	visual_signature=signature
	var old:=hero_node.get_node_or_null("HWClassRankVisual")
	if old!=null: old.queue_free()
	var root:=Node3D.new()
	root.name="HWClassRankVisual"
	hero_node.add_child(root)
	var accent:=_accent(class_id)
	var dark:=_mat(Color("#161B22"),0.48,0.35)
	var metal:=_mat(accent.lightened(0.16),0.26,0.78)
	var glow:=_mat(accent,0.22,0.25)
	# Tier silhouette upgrades: shoulders, crest, backplate and weapon ornaments.
	if tier>=1:
		_add_box(root,Vector3(0.22,0.18,0.56),Vector3(-0.57,1.84,0.0),metal)
		_add_box(root,Vector3(0.22,0.18,0.56),Vector3(0.57,1.84,0.0),metal)
	if tier>=2:
		_add_box(root,Vector3(0.12,0.70,0.10),Vector3(-0.72,1.56,0.05),dark)
		_add_box(root,Vector3(0.12,0.70,0.10),Vector3(0.72,1.56,0.05),dark)
		_add_box(root,Vector3(0.10,0.62,0.14),Vector3(0,1.60,0.34),metal)
	if tier>=3:
		_add_box(root,Vector3(0.16,0.42,0.16),Vector3(0,2.70,0),glow)
		_add_box(root,Vector3(0.70,0.08,0.08),Vector3(0,2.61,0.02),metal)
	if tier>=4:
		_add_box(root,Vector3(1.14,0.08,0.08),Vector3(0,2.03,0.05),glow)
		_add_box(root,Vector3(0.08,0.82,0.08),Vector3(0.0,1.55,0.48),metal)
	# Class identity weapon ornament. This supplements the existing body rather than replacing it.
	match class_id:
		"Warrior":
			_add_box(root,Vector3(0.10,1.30,0.10),Vector3(0.86,1.50,-0.10),metal)
			_add_box(root,Vector3(0.34,0.08,0.08),Vector3(0.86,2.05,-0.10),glow)
		"Mage":
			_add_cyl(root,0.07,1.45,Vector3(0.86,1.50,-0.04),metal)
			_add_sphere(root,0.14,Vector3(0.86,2.26,-0.04),glow)
		"Archer":
			_add_torus(root,0.42,0.035,Vector3(0.86,1.62,-0.08),metal)
			_add_box(root,Vector3(0.64,0.035,0.04),Vector3(0.86,1.62,-0.08),glow)
		"Thief":
			_add_box(root,Vector3(0.06,0.95,0.16),Vector3(0.86,1.42,-0.08),metal)
			_add_box(root,Vector3(0.24,0.06,0.07),Vector3(0.86,1.92,-0.08),glow)
		"Acolyte":
			_add_box(root,Vector3(0.12,1.25,0.12),Vector3(0.86,1.46,-0.08),metal)
			_add_torus(root,0.15,0.035,Vector3(0.86,2.08,-0.08),glow)
		"Merchant":
			_add_box(root,Vector3(0.24,0.85,0.24),Vector3(0.86,1.30,-0.08),metal)
			_add_box(root,Vector3(0.40,0.08,0.40),Vector3(0.86,1.76,-0.08),glow)

func _accent(class_id:String)->Color:
	match class_id:
		"Mage": return Color("#A77BFF")
		"Archer": return Color("#74D27D")
		"Thief": return Color("#F16BAF")
		"Acolyte": return Color("#FFE17A")
		"Merchant": return Color("#67D4F4")
		_: return Color("#F2A64B")

func _mat(color:Color,roughness:float,metallic:float)->StandardMaterial3D:
	var material:=StandardMaterial3D.new()
	material.albedo_color=color
	material.roughness=roughness
	material.metallic=metallic
	return material

func _add_box(parent:Node3D,size:Vector3,pos:Vector3,material:Material)->void:
	var node:=MeshInstance3D.new()
	var mesh:=BoxMesh.new()
	mesh.size=size
	node.mesh=mesh
	node.position=pos
	node.material_override=material
	parent.add_child(node)

func _add_cyl(parent:Node3D,radius:float,height:float,pos:Vector3,material:Material)->void:
	var node:=MeshInstance3D.new()
	var mesh:=CylinderMesh.new()
	mesh.top_radius=radius
	mesh.bottom_radius=radius
	mesh.height=height
	mesh.radial_segments=28
	node.mesh=mesh
	node.position=pos
	node.material_override=material
	parent.add_child(node)

func _add_sphere(parent:Node3D,radius:float,pos:Vector3,material:Material)->void:
	var node:=MeshInstance3D.new()
	var mesh:=SphereMesh.new()
	mesh.radius=radius
	mesh.height=radius*2.0
	mesh.radial_segments=24
	mesh.rings=12
	node.mesh=mesh
	node.position=pos
	node.material_override=material
	parent.add_child(node)

func _add_torus(parent:Node3D,outer:float,inner:float,pos:Vector3,material:Material)->void:
	var node:=MeshInstance3D.new()
	var mesh:=TorusMesh.new()
	mesh.inner_radius=inner
	mesh.outer_radius=outer
	mesh.rings=40
	mesh.ring_segments=12
	node.mesh=mesh
	node.position=pos
	node.rotation_degrees=Vector3(90,0,0)
	node.material_override=material
	parent.add_child(node)
