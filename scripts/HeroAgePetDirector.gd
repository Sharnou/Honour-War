class_name HeroAgePetDirector
extends Node3D

const PetSkillSystem = preload("res://scripts/PetSkillSystem.gd")
const OnlineAge = preload("res://scripts/OnlineAgeSystem.gd")
const Save = preload("res://scripts/SaveSystem.gd")

var game:Node3D
var legacy:Node2D
var age_label:Label
var last_age:int=-1
var last_pet_level:int=-1
var last_pet_hp:int=-1
var age_detail:Node3D
var elapsed:float=0.0
var autosave_timer:float=0.0
var visual_age_applied:int=-1

func _ready()->void:
    game=get_parent() as Node3D
    legacy=game.get_node_or_null("LegacyGame") if game!=null else null
    call_deferred("_build_ui")
    set_process(true)

func _process(delta:float)->void:
    elapsed+=delta
    autosave_timer+=delta
    if legacy==null or game==null: return
    var hero_value:Variant=legacy.get("hero")
    if not hero_value is Dictionary: return
    var hero:Dictionary=hero_value
    _update_age(hero,delta)
    _update_pet(hero)
    _update_label(hero)
    _apply_aged_character_presentation(hero)
    if autosave_timer>=30.0:
        autosave_timer=0.0
        Save.save_game(hero)

func _update_age(hero:Dictionary,delta:float)->void:
    # Existing characters are migrated into the new dignified older-adult range.
    if not hero.has("age_origin"):
        hero["age_origin"]=OnlineAge.DEFAULT_STARTING_AGE
    var before:int=int(hero.get("age",OnlineAge.starting_age(hero)))
    hero["online_days"]=max(0.0,float(hero.get("online_days",0.0)))+delta/86400.0
    OnlineAge.normalize(hero)
    var age:int=int(hero.get("age",OnlineAge.DEFAULT_STARTING_AGE))
    if age!=last_age:
        last_age=age
        _refresh_age_detail(age)
        if age>before and legacy.has_method("log_message"):
            legacy.call("log_message","Age increased to %d. %s grows stronger with experience." % [age,OnlineAge.title(age)])

func _update_pet(hero:Dictionary)->void:
    var pet_value:Variant=hero.get("pet",{})
    if not pet_value is Dictionary: return
    var pet:Dictionary=pet_value
    PetSkillSystem.ensure_state(pet)
    var pet_node:Node3D=game.get("pet_visual") as Node3D
    if pet_node==null or not is_instance_valid(pet_node): return
    var level:int=int(pet.get("level",1))
    var hp:int=int(pet.get("hp",0))
    var max_hp:int=max(1,int(pet.get("max_hp",60)))
    var ratio:float=clamp(float(hp)/float(max_hp),0.0,1.0)
    if hp<last_pet_hp and last_pet_hp>=0: pet_node.rotation.z=sin(elapsed*30.0)*0.10
    else: pet_node.rotation.z=lerp(pet_node.rotation.z,0.0,0.15)
    if level!=last_pet_level:
        last_pet_level=level
        var growth:float=1.0+min(0.18,float(level-1)*0.0018)
        pet_node.scale=Vector3.ONE*growth
    elif ratio<0.35: pet_node.scale=pet_node.scale.lerp(Vector3.ONE*0.97,0.08)
    last_pet_hp=hp

func _apply_aged_character_presentation(hero:Dictionary)->void:
    var hero_node:Node3D=game.get("hero_visual") as Node3D
    if hero_node==null or not is_instance_valid(hero_node): return
    var age:int=int(hero.get("age",OnlineAge.DEFAULT_STARTING_AGE))
    if age==visual_age_applied and hero_node.has_node("AgeMaturityDetails"): return
    visual_age_applied=age
    var details:Node3D=hero_node.get_node_or_null("AgeMaturityDetails") as Node3D
    if details==null:
        details=Node3D.new()
        details.name="AgeMaturityDetails"
        hero_node.add_child(details)
    # Dignified mature silhouette: subtle forward lean and slightly lower shoulders.
    hero_node.rotation.z=deg_to_rad(-3.0)
    var body:MeshInstance3D=hero_node.get_node_or_null("Body") as MeshInstance3D
    if body!=null: body.rotation.z=deg_to_rad(-2.0)
    var coat:MeshInstance3D=hero_node.get_node_or_null("Coat") as MeshInstance3D
    if coat!=null: coat.rotation.z=deg_to_rad(-2.5)
    var head:MeshInstance3D=hero_node.get_node_or_null("Head") as MeshInstance3D
    if head!=null:
        head.rotation.z=deg_to_rad(1.5)
        var head_material:Material=head.material_override
        if head_material is StandardMaterial3D:
            var skin:StandardMaterial3D=(head_material as StandardMaterial3D).duplicate()
            skin.albedo_color=Color("#c99578")
            skin.roughness=0.82
            head.material_override=skin
    var hair:MeshInstance3D=hero_node.get_node_or_null("Hair") as MeshInstance3D
    if hair!=null:
        var hair_material:Material=hair.material_override
        if hair_material is StandardMaterial3D:
            var silver:StandardMaterial3D=(hair_material as StandardMaterial3D).duplicate()
            silver.albedo_color=Color("#9b9b9d")
            silver.roughness=0.88
            hair.material_override=silver
    # A restrained cane/staff silhouette communicates age at gameplay distance.
    if not details.has_node("WalkingStaff"):
        var staff:=MeshInstance3D.new()
        staff.name="WalkingStaff"
        var shaft:=CylinderMesh.new()
        shaft.top_radius=0.045
        shaft.bottom_radius=0.075
        shaft.height=1.55
        staff.mesh=shaft
        staff.position=Vector3(0.58,0.72,0.0)
        staff.rotation_degrees.z=-8.0
        var staff_material:=StandardMaterial3D.new()
        staff_material.albedo_color=Color("#6b4c34")
        staff_material.roughness=0.9
        staff.material_override=staff_material
        details.add_child(staff)
        var handle:=MeshInstance3D.new()
        handle.name="StaffHandle"
        var handle_mesh:=TorusMesh.new()
        handle_mesh.inner_radius=0.11
        handle_mesh.outer_radius=0.16
        handle_mesh.rings=18
        handle_mesh.ring_segments=8
        handle.mesh=handle_mesh
        handle.position=Vector3(0.58,1.49,0.0)
        handle.rotation_degrees.x=90.0
        handle.material_override=staff_material
        details.add_child(handle)
    # Silver hair, subtle warm veteran light and no exaggerated glow.
    var elder_aura:OmniLight3D=details.get_node_or_null("ElderAura") as OmniLight3D
    if elder_aura==null:
        elder_aura=OmniLight3D.new()
        elder_aura.name="ElderAura"
        details.add_child(elder_aura)
    elder_aura.position=Vector3(0.0,1.5,0.0)
    elder_aura.omni_range=2.8
    elder_aura.light_energy=0.08
    elder_aura.light_color=Color("#e8d6a0")

func _refresh_age_detail(age:int)->void:
    # The age value belongs in character/status UI, never in the floating nameplate.
    var hero:Node3D=game.get("hero_visual") as Node3D
    if hero==null or not is_instance_valid(hero): return
    var details:Node3D=hero.get_node_or_null("AgeMaturityDetails") as Node3D
    if details==null:
        details=Node3D.new()
        details.name="AgeMaturityDetails"
        hero.add_child(details)
    _apply_aged_character_presentation({"age":age})

func _build_ui()->void:
    if game==null: return
    var layer:=CanvasLayer.new()
    layer.name="HeroLifePanel"
    game.add_child(layer)
    var panel:=PanelContainer.new()
    panel.position=Vector2(18,18)
    panel.size=Vector2(355,96)
    layer.add_child(panel)
    age_label=Label.new()
    age_label.add_theme_font_size_override("font_size",15)
    panel.add_child(age_label)

func _update_label(hero:Dictionary)->void:
    if age_label==null: return
    OnlineAge.normalize(hero)
    var age:int=int(hero.get("age",OnlineAge.DEFAULT_STARTING_AGE))
    var days:float=float(hero.get("online_days",0.0))
    var growth:Dictionary=OnlineAge.strength_bonus(hero)
    var pet_value:Variant=hero.get("pet",{})
    var pet_text:String="No bonded pet"
    if pet_value is Dictionary:
        var pet:Dictionary=pet_value
        pet_text="%s Lv.%d" % [str(pet.get("name","Pet")),int(pet.get("level",1))]
    age_label.text="HERO AGE  %d  •  %s\nOnline %.2f days  •  ATK +%d  HP +%d\nPET  %s" % [age,OnlineAge.title(age),days,int(growth["atk"]),int(growth["hp"]),pet_text]
