extends Node

## Places the Rent NPC on every loaded map. The NPC sells only the rental contract;
## SS remains unavailable from character creation.

const NPC_NAME:String = "Rent"
const PRICE_ZENY:int = 1000000
var current_scene_id:int = 0
var npc:Node3D

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("_ensure_rent_npc")

func _process(_delta:float) -> void:
    var scene:Node = get_tree().current_scene
    if scene == null:
        return
    var id:int = scene.get_instance_id()
    if id != current_scene_id:
        current_scene_id = id
        npc = null
        call_deferred("_ensure_rent_npc")
    elif npc == null or not is_instance_valid(npc):
        call_deferred("_ensure_rent_npc")

func _ensure_rent_npc() -> void:
    var scene:Node = get_tree().current_scene
    if scene == null:
        return
    var existing:Node = scene.get_node_or_null("RentNPC")
    if existing != null:
        npc = existing
        return
    npc = Node3D.new()
    npc.name = "RentNPC"
    npc.add_to_group("rent_npc")
    npc.set_meta("npc_name",NPC_NAME)
    npc.set_meta("level",0)
    npc.set_meta("class","SS (SUPER SHAMBION)")
    npc.set_meta("rental_price_zeny",PRICE_ZENY)
    npc.position = Vector3(0.0,0.0,0.0)
    scene.add_child.call_deferred(npc)
    call_deferred("_decorate_npc")

func _decorate_npc() -> void:
    if npc == null or not is_instance_valid(npc):
        return
    var body:MeshInstance3D = MeshInstance3D.new()
    var mesh:CapsuleMesh = CapsuleMesh.new()
    mesh.radius = 0.48
    mesh.height = 1.8
    body.mesh = mesh
    body.position.y = 0.9
    var mat:StandardMaterial3D = StandardMaterial3D.new()
    mat.albedo_color = Color("#27344d")
    mat.metallic = 0.1
    mat.roughness = 0.65
    body.material_override = mat
    npc.add_child(body)
    var label:Label3D = Label3D.new()
    label.text = "Rent\n1,000,000 Zeny"
    label.position = Vector3(0.0,2.4,0.0)
    label.pixel_size = 0.004
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    label.modulate = Color("#ffd66b")
    npc.add_child(label)
    var area:Area3D = Area3D.new()
    area.name = "RentInteraction"
    area.collision_layer = 1
    area.collision_mask = 0
    area.input_ray_pickable = true
    var shape:CollisionShape3D = CollisionShape3D.new()
    var capsule:CapsuleShape3D = CapsuleShape3D.new()
    capsule.radius = 0.9
    capsule.height = 2.6
    shape.shape = capsule
    shape.position.y = 1.3
    area.add_child(shape)
    npc.add_child(area)
    area.input_event.connect(_on_npc_input)

func _on_npc_input(_camera:Node,_event:InputEvent,_position:Vector3,_normal:Vector3,_shape_idx:int) -> void:
    if _event is InputEventMouseButton and _event.button_index == MOUSE_BUTTON_LEFT and _event.pressed:
        var runtime:Node = get_node_or_null("/root/HWSSRentRuntime")
        if runtime != null and runtime.has_method("open_rent_panel"):
            runtime.call("open_rent_panel")
