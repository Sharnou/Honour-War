class_name HDAssetRuntime
extends Node3D

# Production asset bridge for Honour War.
# Art contract: Blender -> Substance 3D Painter -> GLB/GLTF -> Godot 4.
# Procedural meshes remain only as a runtime fallback until production art is present.

@export var hero_asset_root:String = "res://assets/3d/characters"
@export var pet_asset_root:String = "res://assets/3d/pets"
@export var monster_asset_root:String = "res://assets/3d/monsters"
@export var mvp_asset_root:String = "res://assets/3d/monsters"
@export var poll_interval:float = 0.25

var game:Node
var poll_elapsed:float = 0.0
var active_assets:Dictionary = {}
var attempted_paths:Dictionary = {}
var hero_animation_time:float = 0.0
var previous_hero_position:Vector3 = Vector3.ZERO

func _ready() -> void:
    game = get_parent()
    set_process(true)

func _process(delta:float) -> void:
    poll_elapsed += delta
    hero_animation_time += delta
    if game == null or not is_instance_valid(game):
        game = get_parent()
    if game == null:
        return
    if poll_elapsed >= poll_interval:
        poll_elapsed = 0.0
        _sync_hero()
        _sync_pet()
        _sync_monsters()
    _animate_hero_presentation(delta)

func _sync_hero() -> void:
    var hero_visual:Node3D = game.get("hero_visual") as Node3D
    if hero_visual == null or not is_instance_valid(hero_visual):
        return
    var legacy:Node = game.get("legacy") as Node
    if legacy == null:
        return
    var hero_value:Variant = legacy.get("hero")
    if not hero_value is Dictionary:
        return
    var hero:Dictionary = hero_value
    var class_id:String = str(hero.get("class", "Warrior"))
    var base:String = hero_asset_root + "/hero_" + _stable_id(class_id)
    var production_asset:bool = _replace_first_available("hero", hero_visual, [base + ".glb", base + ".gltf"])
    var current_visual:Node3D = game.get("hero_visual") as Node3D
    if current_visual == null or not is_instance_valid(current_visual):
        return
    if production_asset:
        current_visual.set_meta("hw_production_asset", true)
    else:
        _ensure_fallback_character(current_visual, hero)
    _update_nameplate(current_visual, hero)

func _sync_pet() -> void:
    var pet_visual:Node3D = game.get("pet_visual") as Node3D
    if pet_visual == null or not is_instance_valid(pet_visual):
        return
    var legacy:Node = game.get("legacy") as Node
    if legacy == null:
        return
    var hero_value:Variant = legacy.get("hero")
    if not hero_value is Dictionary:
        return
    var hero:Dictionary = hero_value
    var pet_value:Variant = hero.get("pet", {})
    if not pet_value is Dictionary:
        return
    var species:String = str(pet_value.get("species", "Pet"))
    var base:String = pet_asset_root + "/pet_" + _stable_id(species)
    _replace_first_available("pet", pet_visual, [base + ".glb", base + ".gltf"])

func _sync_monsters() -> void:
    var visuals:Variant = game.get("monster_visuals")
    if not visuals is Dictionary:
        return
    var legacy:Node = game.get("legacy") as Node
    if legacy == null:
        return
    var monsters_value:Variant = legacy.get("monsters")
    if not monsters_value is Array:
        return
    var monsters:Array = monsters_value
    for monster in monsters:
        if not monster is Dictionary:
            continue
        var id:String = str(monster.get("id", ""))
        if id.is_empty() or not visuals.has(id):
            continue
        var visual:Node3D = visuals[id] as Node3D
        if visual == null or not is_instance_valid(visual):
            continue
        var kind:String = str(monster.get("kind", "Monster"))
        var asset_root:String = mvp_asset_root if kind == "MVP" else monster_asset_root
        var prefix:String = "mvp_" if kind == "MVP" else "monster_"
        var base:String = asset_root + "/" + prefix + _stable_id(str(monster.get("name", "monster")))
        _replace_first_available("monster:" + id, visual, [base + ".glb", base + ".gltf"], id)

func _replace_first_available(key:String,current:Node3D,paths:Array[String],monster_id:String="") -> bool:
    for path in paths:
        if ResourceLoader.exists(path):
            return _replace_if_available(key,current,path,monster_id)
        attempted_paths[path] = true
    return false

func _replace_if_available(key:String,current:Node3D,path:String,monster_id:String="") -> bool:
    if active_assets.has(key):
        var record:Variant = active_assets[key]
        if record is Dictionary:
            var existing:Node = record.get("node") as Node
            var existing_path:String = str(record.get("path", ""))
            if existing != null and is_instance_valid(existing) and existing_path == path:
                return true
            if existing != null and is_instance_valid(existing):
                existing.queue_free()
            active_assets.erase(key)
    var packed:PackedScene = load(path) as PackedScene
    if packed == null:
        attempted_paths[path] = true
        return false
    var parent:Node = current.get_parent()
    if parent == null or not current.is_inside_tree():
        return false
    var replacement:Node = packed.instantiate()
    if replacement == null or not replacement is Node3D:
        if replacement != null:
            replacement.queue_free()
        return false
    parent.add_child(replacement)
    var replacement_3d:Node3D = replacement as Node3D
    replacement_3d.global_transform = current.global_transform
    replacement_3d.name = current.name + "_HDAsset"
    active_assets[key] = {"node":replacement,"path":path}
    if key == "hero":
        game.set("hero_visual", replacement_3d)
    elif key == "pet":
        game.set("pet_visual", replacement_3d)
    elif not monster_id.is_empty():
        var visuals:Variant = game.get("monster_visuals")
        if visuals is Dictionary:
            visuals[monster_id] = replacement_3d
    current.queue_free()
    return true

func _ensure_fallback_character(hero_visual:Node3D,hero:Dictionary)->void:
    if hero_visual.has_meta("hw_character_enhanced"):
        return
    hero_visual.set_meta("hw_character_enhanced",true)
    var class_id:String = str(hero.get("class","Warrior"))
    var accent:Color = _class_color(class_id)
    var dark:Color = Color("#242931")
    var leather:Color = Color("#4b3326")
    var metal:Color = Color("#b7c2ca")

    var left_leg:Node3D = Node3D.new()
    left_leg.name="HW_LeftLeg"
    left_leg.position=Vector3(-0.20,0.86,0.0)
    hero_visual.add_child(left_leg)
    var left_shin:MeshInstance3D=_make_capsule(metal,0.13,0.70)
    left_shin.position=Vector3(0,-0.36,0)
    left_leg.add_child(left_shin)
    var left_boot:MeshInstance3D=_make_box(dark,Vector3(0.30,0.18,0.50))
    left_boot.position=Vector3(0,-0.76,-0.08)
    left_leg.add_child(left_boot)

    var right_leg:Node3D = Node3D.new()
    right_leg.name="HW_RightLeg"
    right_leg.position=Vector3(0.20,0.86,0.0)
    hero_visual.add_child(right_leg)
    var right_shin:MeshInstance3D=_make_capsule(metal,0.13,0.70)
    right_shin.position=Vector3(0,-0.36,0)
    right_leg.add_child(right_shin)
    var right_boot:MeshInstance3D=_make_box(dark,Vector3(0.30,0.18,0.50))
    right_boot.position=Vector3(0,-0.76,-0.08)
    right_leg.add_child(right_boot)

    var left_arm:Node3D=Node3D.new()
    left_arm.name="HW_LeftArm"
    left_arm.position=Vector3(-0.50,1.66,0)
    hero_visual.add_child(left_arm)
    var left_sleeve:MeshInstance3D=_make_capsule(accent,0.12,0.72)
    left_sleeve.position=Vector3(0,-0.36,0)
    left_arm.add_child(left_sleeve)
    var left_hand:MeshInstance3D=_make_sphere(Color("#d6a27d"),0.15)
    left_hand.position=Vector3(0,-0.76,0)
    left_arm.add_child(left_hand)

    var right_arm:Node3D=Node3D.new()
    right_arm.name="HW_RightArm"
    right_arm.position=Vector3(0.50,1.66,0)
    hero_visual.add_child(right_arm)
    var right_sleeve:MeshInstance3D=_make_capsule(accent,0.12,0.72)
    right_sleeve.position=Vector3(0,-0.36,0)
    right_arm.add_child(right_sleeve)
    var right_hand:MeshInstance3D=_make_sphere(Color("#d6a27d"),0.15)
    right_hand.position=Vector3(0,-0.76,0)
    right_arm.add_child(right_hand)

    var belt:MeshInstance3D=_make_box(leather,Vector3(0.94,0.12,0.56))
    belt.name="HW_Belt"
    belt.position=Vector3(0,1.02,0.02)
    hero_visual.add_child(belt)

    var class_badge:MeshInstance3D=_make_ring(accent,0.18,0.035)
    class_badge.name="HW_ClassBadge"
    class_badge.rotation_degrees.x=90.0
    class_badge.position=Vector3(0,1.53,-0.36)
    hero_visual.add_child(class_badge)

    var cape:MeshInstance3D=_make_box(accent.darkened(0.28),Vector3(0.84,1.05,0.06))
    cape.name="HW_Cape"
    cape.position=Vector3(0,1.45,0.34)
    hero_visual.add_child(cape)

    if class_id=="Warrior":
        var helm:MeshInstance3D=_make_box(metal,Vector3(0.62,0.18,0.58))
        helm.name="HW_Helm"
        helm.position=Vector3(0,2.58,0)
        hero_visual.add_child(helm)
    elif class_id=="Mage":
        var hood:MeshInstance3D=_make_ring(accent,0.34,0.055)
        hood.name="HW_MageHood"
        hood.rotation_degrees.x=90.0
        hood.position=Vector3(0,2.55,0)
        hero_visual.add_child(hood)
    elif class_id=="Archer":
        var quiver:MeshInstance3D=_make_box(leather,Vector3(0.18,0.55,0.18))
        quiver.name="HW_Quiver"
        quiver.position=Vector3(-0.46,1.30,0.24)
        quiver.rotation_degrees.z=-12.0
        hero_visual.add_child(quiver)
    elif class_id=="Thief":
        var hood_band:MeshInstance3D=_make_box(Color("#191a20"),Vector3(0.66,0.10,0.42))
        hood_band.name="HW_ThiefBand"
        hood_band.position=Vector3(0,2.47,0)
        hero_visual.add_child(hood_band)
    elif class_id=="Acolyte":
        var halo:MeshInstance3D=_make_ring(Color("#f4dc75"),0.40,0.035)
        halo.name="HW_AcolyteHalo"
        halo.rotation_degrees.x=90.0
        halo.position=Vector3(0,2.74,0)
        hero_visual.add_child(halo)
    elif class_id=="Merchant":
        var pouch:MeshInstance3D=_make_box(Color("#845b36"),Vector3(0.34,0.30,0.25))
        pouch.name="HW_MerchantPouch"
        pouch.position=Vector3(0.56,1.15,0.15)
        hero_visual.add_child(pouch)

func _update_nameplate(hero_visual:Node3D,hero:Dictionary)->void:
    var nameplate:Label3D=hero_visual.get_node_or_null("HW_Nameplate") as Label3D
    if nameplate==null:
        nameplate=Label3D.new()
        nameplate.name="HW_Nameplate"
        nameplate.position=Vector3(0,3.28,0)
        nameplate.font_size=30
        nameplate.outline_size=8
        nameplate.no_depth_test=true
        nameplate.billboard=BaseMaterial3D.BILLBOARD_ENABLED
        nameplate.pixel_size=0.0034
        hero_visual.add_child(nameplate)
    var class_id:String=str(hero.get("class","Warrior"))
    var weapon:String=_equipment_name(hero,"weapon","Weapon")
    var armor:String=_equipment_name(hero,"armor","Armor")
    var refine:int=_equipment_refine(hero,"weapon")
    nameplate.text="%s  •  Lv.%d  %s\n%s +%d   •   %s" % [str(hero.get("name","Hero")),int(hero.get("level",1)),class_id,weapon,refine,armor]
    nameplate.modulate=_class_color(class_id)

func _animate_hero_presentation(delta:float)->void:
    if game==null: return
    var hero_visual:Node3D=game.get("hero_visual") as Node3D
    if hero_visual==null or not is_instance_valid(hero_visual): return
    if bool(hero_visual.get_meta("hw_production_asset",false)):
        return
    var current:Vector3=hero_visual.position
    var dt:float=max(delta,0.016)
    var velocity:Vector3=(current-previous_hero_position)/dt
    if previous_hero_position==Vector3.ZERO:
        previous_hero_position=current
        return
    var speed:float=velocity.length()
    var walking:bool=speed>0.08
    var phase:float=hero_animation_time*(7.0+min(speed*2.0,8.0))
    var swing:float=sin(phase)*0.48 if walking else 0.0
    var left_leg:Node3D=hero_visual.get_node_or_null("HW_LeftLeg") as Node3D
    var right_leg:Node3D=hero_visual.get_node_or_null("HW_RightLeg") as Node3D
    var left_arm:Node3D=hero_visual.get_node_or_null("HW_LeftArm") as Node3D
    var right_arm:Node3D=hero_visual.get_node_or_null("HW_RightArm") as Node3D
    if left_leg: left_leg.rotation.x=swing
    if right_leg: right_leg.rotation.x=-swing
    if left_arm: left_arm.rotation.x=-swing*0.72
    if right_arm: right_arm.rotation.x=swing*0.72
    var bob:float=(abs(sin(phase))*0.035) if walking else 0.0
    hero_visual.position.y=0.15+bob
    previous_hero_position=current

func _equipment_name(hero:Dictionary,slot:String,fallback:String)->String:
    var equipment_value:Variant=hero.get("equipment",{})
    if not equipment_value is Dictionary:
        return fallback
    var value:Variant=equipment_value.get(slot,fallback)
    if value is Dictionary:
        return str(value.get("id",value.get("name",fallback)))
    return str(value)

func _equipment_refine(hero:Dictionary,slot:String)->int:
    var equipment_value:Variant=hero.get("equipment",{})
    if equipment_value is Dictionary:
        var value:Variant=equipment_value.get(slot,null)
        if value is Dictionary:
            return int(value.get("refine",0))
    var refine_value:Variant=hero.get("equipment_refine",{})
    if refine_value is Dictionary:
        return int(refine_value.get(slot,0))
    return int(hero.get("refine",0))

func _class_color(class_id:String)->Color:
    match class_id:
        "Mage": return Color("#b88cff")
        "Archer": return Color("#8fe08f")
        "Thief": return Color("#ff7eb6")
        "Acolyte": return Color("#fff0a3")
        "Merchant": return Color("#7ed7ff")
    return Color("#e8a34b")

func _make_capsule(color:Color,radius:float,height:float)->MeshInstance3D:
    var node:=MeshInstance3D.new()
    var mesh:=CapsuleMesh.new()
    mesh.radius=radius
    mesh.height=height
    node.mesh=mesh
    node.material_override=_material(color,0.08,0.52)
    return node

func _make_sphere(color:Color,radius:float)->MeshInstance3D:
    var node:=MeshInstance3D.new()
    var mesh:=SphereMesh.new()
    mesh.radius=radius
    mesh.height=radius*2.0
    node.mesh=mesh
    node.material_override=_material(color,0.05,0.55)
    return node

func _make_box(color:Color,size:Vector3)->MeshInstance3D:
    var node:=MeshInstance3D.new()
    var mesh:=BoxMesh.new()
    mesh.size=size
    node.mesh=mesh
    node.material_override=_material(color,0.10,0.58)
    return node

func _make_ring(color:Color,radius:float,width:float)->MeshInstance3D:
    var node:=MeshInstance3D.new()
    var mesh:=TorusMesh.new()
    mesh.inner_radius=radius
    mesh.outer_radius=radius+width
    node.mesh=mesh
    node.material_override=_material(color,0.18,0.35)
    return node

func _material(color:Color,metallic:float,roughness:float)->StandardMaterial3D:
    var material:=StandardMaterial3D.new()
    material.albedo_color=color
    material.metallic=metallic
    material.roughness=roughness
    return material

func _stable_id(value:String) -> String:
    var id:String = value.strip_edges().to_lower()
    id = id.replace(" ", "_")
    id = id.replace("-", "_")
    id = id.replace("'", "")
    return id
