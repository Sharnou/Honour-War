extends Node

const ClassTreeSystemClass = preload("res://scripts/ClassTreeSystemClass.gd")
const SaveSystemClass = preload("res://scripts/SaveSystem.gd")
const GameDataClass = preload("res://scripts/GameData.gd")

# Runtime class advancement controller. Base archetype remains stable for formulas,
# while the visual/class rank advances automatically at Honour War milestones.
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
    var candidate:Variant=legacy.get("hero")
    if candidate is Dictionary:
        hero=candidate
    else:
        return
    ClassTreeSystemClass.ensure_state(hero)
    var level:int=int(hero.get("level",1))
    var class_id:String=str(hero.get("class","Warrior"))
    var available_tier:int=ClassTreeSystemClass.available_tier(hero)
    var tier:int=available_tier-1
    var rank:String=_class_rank_for_level(level,class_id)
    var old_rank:String=str(hero.get("class_rank",""))
    var old_tier:int=int(hero.get("class_tier",-1))
    var old_branch:String=str(hero.get("class_branch",""))
    var old_mastery:int=int(hero.get("class_mastery",0))
    var changed:bool=force or tier!=last_tier or old_rank!=rank or old_tier!=tier or old_mastery!=int(hero.get("class_mastery",0))
    if changed:
        last_tier=tier
        hero["class_tier"]=tier
        hero["class_rank"]=rank
        hero["class_rank_tier"]=available_tier
        hero["class_branch"]=old_branch
        hero["class_mastery"]=old_mastery
        SaveSystem.save_game(hero)
        _update_hud()
        _update_visuals()
    else:
        _update_hud()
    if str(hero.get("class_branch",""))=="" and level>=25:
        if panel!=null: panel.visible=true
    elif panel!=null:
        panel.visible=tier>=1

func _build_hud()->void:
    if panel!=null: return
    var layer:CanvasLayer=CanvasLayer.new()
    layer.name="ClassAdvancementHUD"
    get_tree().current_scene.add_child(layer)
    panel=Panel.new()
    panel.position=Vector2(1450,38)
    panel.size=Vector2(425,258)
    layer.add_child(panel)
    var box:VBoxContainer=VBoxContainer.new()
    box.position=Vector2(16,12)
    box.size=Vector2(393,234)
    panel.add_child(box)
    title_label=Label.new()
    title_label.text="CLASS ADVANCEMENT"
    title_label.add_theme_font_size_override("font_size",22)
    box.add_child(title_label)
    detail_label=Label.new()
    detail_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    detail_label.custom_minimum_size=Vector2(390,62)
    box.add_child(detail_label)
    var prompt:Label=Label.new()
    prompt.text="Choose your specialization"
    prompt.add_theme_font_size_override("font_size",16)
    box.add_child(prompt)
    branch_box=VBoxContainer.new()
    branch_box.custom_minimum_size=Vector2(390,126)
    box.add_child(branch_box)

func _update_hud()->void:
    if detail_label==null: return
    var class_id:String=str(hero.get("class","Warrior"))
    var level:int=int(hero.get("level",1))
    var tier:int=ClassTreeSystemClass.available_tier(hero)
    var rank:String=_class_rank_for_level(level,class_id)
    var branch:String=str(hero.get("class_branch",""))
    var mastery:int=int(hero.get("class_mastery",0))
    var profile:Dictionary=ClassTreeSystemClass.class_profile(class_id)
    var branch_text:String=branch if branch!="" else "Not selected"
    title_label.text="%s  •  Lv.%d" % [rank,level]
    detail_label.text="%s\nTier: %s\nSpecialization: %s\nMastery: %d%%" % [str(profile.get("title",class_id)),TIER_NAMES.get(tier,"Foundation"),branch_text,mastery]
    for child:Node in branch_box.get_children():
        child.queue_free()
    branch_buttons.clear()
    if level<25 or branch!="":
        var status:Label=Label.new()
        status.text="Next promotion: Lv.%d" % _next_threshold(level)
        branch_box.add_child(status)
        return
    var branches:Array=profile.get("branches",[])
    var descriptions:Dictionary=ClassTreeSystemClass.branch_descriptions(class_id)
    for branch_name:String in branches:
        var button:Button=Button.new()
        button.text="%s — %s" % [branch_name,str(descriptions.get(branch_name,""))]
        button.custom_minimum_size=Vector2(390,30)
        button.pressed.connect(_select_branch.bind(branch_name))
        branch_box.add_child(button)
        branch_buttons[branch_name]=button

func _next_threshold(level:int)->int:
    for threshold:int in [25,50,150,200,250]:
        if level<threshold: return threshold
    return 250

func _select_branch(branch_name:String)->void:
    if str(hero.get("class_branch",""))!="": return
    if not ClassTreeSystemClass.select_branch(hero,branch_name): return
    SaveSystem.save_game(hero)
    _update_hud()
    _update_visuals()

func _class_rank_for_level(level:int,class_id:String)->String:
    # Use the authoritative hero-aware rank for the Lv150 Fourth Job and Lv200 Fifth Job.
    var display_hero:Dictionary = {"level":level,"class":class_id,"class_branch":str(hero.get("class_branch",""))}
    return GameData.class_rank_for_hero(display_hero)

func _update_visuals()->void:
    if scene_root==null: return
    var actors:Node=scene_root.get_node_or_null("Actors3D")
    if actors==null: return
    var hero_node:Node3D=actors.get_node_or_null("Hero") as Node3D
    if hero_node==null: return
    var class_id:String=str(hero.get("class","Warrior"))
    var tier:int=ClassTreeSystemClass.available_tier(hero)
    var branch:String=str(hero.get("class_branch",""))
    var signature:String="%s:%d:%s:%d" % [class_id,tier,branch,int(hero.get("class_mastery",0))]
    if signature==visual_signature and hero_node.get_node_or_null("HWClassRankVisual")!=null: return
    visual_signature=signature
    var old:Node=hero_node.get_node_or_null("HWClassRankVisual")
    if old!=null: old.queue_free()
    var visual_root:Node3D=Node3D.new()
    visual_root.name="HWClassRankVisual"
    hero_node.add_child(visual_root)
    var accent:Color=_accent(class_id)
    var dark:StandardMaterial3D=_mat(Color("#161B22"),0.48,0.35)
    var metal:StandardMaterial3D=_mat(accent.lightened(0.16),0.26,0.78)
    var glow:StandardMaterial3D=_mat(accent,0.22,0.25)
    if tier>=3:
        _add_box(visual_root,Vector3(0.22,0.18,0.56),Vector3(-0.57,1.84,0.0),metal)
        _add_box(visual_root,Vector3(0.22,0.18,0.56),Vector3(0.57,1.84,0.0),metal)
    if tier>=4:
        _add_box(visual_root,Vector3(0.12,0.70,0.10),Vector3(-0.72,1.56,0.05),dark)
        _add_box(visual_root,Vector3(0.12,0.70,0.10),Vector3(0.72,1.56,0.05),dark)
        _add_box(visual_root,Vector3(0.10,0.62,0.14),Vector3(0,1.60,0.34),metal)
    if tier>=5:
        _add_box(visual_root,Vector3(0.16,0.42,0.16),Vector3(0,2.70,0),glow)
        _add_box(visual_root,Vector3(0.70,0.08,0.08),Vector3(0,2.61,0.02),metal)

func _accent(class_id:String)->Color:
    match class_id:
        "Mage": return Color("#A77BFF")
        "Archer": return Color("#74D27D")
        "Thief": return Color("#F16BAF")
        "Acolyte": return Color("#FFE17A")
        "Merchant": return Color("#67D4F4")
        _: return Color("#F2A64B")

func _mat(color:Color,roughness:float,metallic:float)->StandardMaterial3D:
    var material:StandardMaterial3D=StandardMaterial3D.new()
    material.albedo_color=color
    material.roughness=roughness
    material.metallic=metallic
    return material

func _add_box(parent:Node3D,size:Vector3,pos:Vector3,material:Material)->void:
    var node:MeshInstance3D=MeshInstance3D.new()
    var mesh:BoxMesh=BoxMesh.new()
    mesh.size=size
    node.mesh=mesh
    node.position=pos
    node.material_override=material
    parent.add_child(node)
