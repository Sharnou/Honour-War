extends Node

## Presentation layer for the true-3D Honour War art direction.
## This script is registered as an autoload, so it intentionally has no
## class_name declaration that could collide with the singleton name.
const HEAD_SCALE:float = 1.16
const HAIR_SCALE:float = 1.14
const EYE_RADIUS:float = 0.115
var processed:Dictionary = {}

func _ready()->void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("_scan")

func _process(_delta:float)->void:
    _scan()

func _scan()->void:
    var scene:Node = get_tree().current_scene
    if scene == null: return
    var hero:Node = scene.find_child("Hero",true,false)
    if hero is Node3D and not processed.has(hero.get_instance_id()): _style_hero(hero as Node3D)
    var pet:Node = scene.find_child("Pet",true,false)
    if pet is Node3D and not processed.has(pet.get_instance_id()): _style_pet(pet as Node3D)

func _style_hero(hero:Node3D)->void:
    var id:int = hero.get_instance_id()
    processed[id] = true
    var meshes:Array[MeshInstance3D] = []
    for child in hero.get_children():
        if child is MeshInstance3D: meshes.append(child as MeshInstance3D)
    if meshes.size() >= 4:
        meshes[0].scale *= Vector3(0.92,0.88,0.92)
        meshes[1].scale *= Vector3(0.94,0.90,0.94)
        meshes[2].scale *= Vector3.ONE*HEAD_SCALE
        meshes[3].scale *= Vector3(HAIR_SCALE,HAIR_SCALE*0.92,HAIR_SCALE)
        meshes[2].name = "HeadModule"
        meshes[3].name = "HairModule"
    var outfit:Node3D = Node3D.new()
    outfit.name = "OutfitModule"
    hero.add_child(outfit)
    var collar:MeshInstance3D = _mesh_box(Color("#f4d27a"),Vector3(0.54,0.16,0.50))
    collar.position = Vector3(0.0,1.76,0.0)
    outfit.add_child(collar)
    var eye_root:Node3D = Node3D.new()
    eye_root.name = "FaceModule"
    hero.add_child(eye_root)
    _add_eye(eye_root,Vector3(-0.19,2.31,0.38))
    _add_eye(eye_root,Vector3(0.19,2.31,0.38))
    var mouth:MeshInstance3D = _mesh_box(Color("#7b3945"),Vector3(0.07,0.025,0.025))
    mouth.position = Vector3(0.0,2.16,0.395)
    eye_root.add_child(mouth)

func _add_eye(root:Node3D,pos:Vector3)->void:
    var white:MeshInstance3D = _sphere(Color("#fffaf2"),EYE_RADIUS)
    white.position = pos
    root.add_child(white)
    var iris:MeshInstance3D = _sphere(Color("#5b76c8"),EYE_RADIUS*0.60)
    iris.position = pos+Vector3(0.0,0.0,0.085)
    root.add_child(iris)
    var pupil:MeshInstance3D = _sphere(Color("#18233c"),EYE_RADIUS*0.32)
    pupil.position = pos+Vector3(0.0,0.0,0.13)
    root.add_child(pupil)
    var highlight:MeshInstance3D = _sphere(Color("#ffffff"),EYE_RADIUS*0.18)
    highlight.position = pos+Vector3(-0.035,0.035,0.15)
    root.add_child(highlight)

func _style_pet(pet:Node3D)->void:
    processed[pet.get_instance_id()] = true
    pet.scale *= 1.08

func _sphere(color:Color,radius:float)->MeshInstance3D:
    var n:MeshInstance3D = MeshInstance3D.new()
    var m:SphereMesh = SphereMesh.new()
    m.radius = radius
    m.height = radius*2.0
    n.mesh = m
    n.material_override = _material(color,0.0,0.42)
    return n

func _mesh_box(color:Color,size:Vector3)->MeshInstance3D:
    var n:MeshInstance3D = MeshInstance3D.new()
    var m:BoxMesh = BoxMesh.new()
    m.size = size
    n.mesh = m
    n.material_override = _material(color,0.02,0.48)
    return n

func _material(color:Color,metallic:float,roughness:float)->StandardMaterial3D:
    var m:StandardMaterial3D = StandardMaterial3D.new()
    m.albedo_color = color
    m.metallic = metallic
    m.roughness = roughness
    return m
