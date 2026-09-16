extends Node3D

## Visual/runtime bridge for the rental-only SS AI hero.
## SS is spawned only while HWSSRentRuntime reports an active rental.
## The SS actor follows the real hero and exposes behavior metadata for follow/heal/fight.

var ss_visual:Node3D
var last_rented:bool = false
var elapsed:float = 0.0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("_sync")

func _process(delta:float) -> void:
    elapsed += delta
    _sync()

func _sync() -> void:
    var runtime:Node = get_node_or_null("/root/HWSSRentRuntime")
    var scene:Node = get_tree().current_scene
    if runtime == null or scene == null:
        return
    var rented:bool = bool(runtime.call("is_rented"))
    if rented and ss_visual == null:
        _spawn_ss(scene)
    elif not rented and ss_visual != null:
        ss_visual.queue_free()
        ss_visual = null
    if not rented or ss_visual == null:
        last_rented = rented
        return
    var legacy:Node = scene.get_node_or_null("LegacyGame")
    if legacy == null:
        return
    var hero_value:Variant = legacy.get("hero")
    if not hero_value is Dictionary:
        return
    var hero:Dictionary = hero_value
    var hero_pos:Vector2 = Vector2(float(hero.get("pos_x",595.0)),float(hero.get("pos_y",340.0)))
    var target:Vector3 = _map_to_world(hero_pos) + Vector3(1.25,0.0,1.05)
    ss_visual.position = ss_visual.position.lerp(target,1.0-exp(-9.0*0.016))
    ss_visual.set_meta("behavior",runtime.call("get_ss").get("behavior",{}))
    ss_visual.set_meta("skill","Asura Strike")
    ss_visual.set_meta("class","SS (SUPER SHAMBION)")
    ss_visual.set_meta("level",0)
    ss_visual.set_meta("age",int(runtime.call("get_ss").get("age",18)))
    ss_visual.rotation.y = atan2(-(target.x-ss_visual.position.x),-(target.z-ss_visual.position.z))
    ss_visual.position.y = 0.18 + abs(sin(elapsed*5.0))*0.025
    last_rented = rented

func _spawn_ss(scene:Node) -> void:
    ss_visual = Node3D.new()
    ss_visual.name = "SSSuperShambion"
    ss_visual.add_to_group("ss_companion")
    ss_visual.set_meta("class","SS (SUPER SHAMBION)")
    ss_visual.set_meta("level",0)
    scene.add_child(ss_visual)
    var body:MeshInstance3D = MeshInstance3D.new()
    var capsule:CapsuleMesh = CapsuleMesh.new()
    capsule.radius = 0.62
    capsule.height = 2.15
    body.mesh = capsule
    body.position.y = 1.08
    var material:StandardMaterial3D = StandardMaterial3D.new()
    material.albedo_color = Color("#7b1e35")
    material.metallic = 0.25
    material.roughness = 0.45
    body.material_override = material
    ss_visual.add_child(body)
    var head:MeshInstance3D = MeshInstance3D.new()
    var sphere:SphereMesh = SphereMesh.new()
    sphere.radius = 0.48
    sphere.height = 0.96
    head.mesh = sphere
    head.position.y = 2.45
    head.material_override = material
    ss_visual.add_child(head)
    var label:Label3D = Label3D.new()
    label.text = "SS\nSUPER SHAMBION\nAsura Strike"
    label.position = Vector3(0.0,3.25,0.0)
    label.pixel_size = 0.0032
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    label.modulate = Color("#ffd66b")
    ss_visual.add_child(label)

func _map_to_world(pos:Vector2) -> Vector3:
    return Vector3(pos.x*0.055,0.0,pos.y*0.055)
