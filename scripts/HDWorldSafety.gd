extends Node

## Startup safety layer for Honour War's 3D presentation.
## Guarantees that the main 3D scene has a usable camera, lighting and a
## visible fallback stage even when optional HD directors/assets are missing.

const TARGET := Vector3(12.925, 0.0, 12.65)
const CAMERA_DISTANCE := 18.5

var prepared := false

func _ready() -> void:
    call_deferred("_prepare")
    call_deferred("_prepare")

func _prepare() -> void:
    if prepared:
        return
    var scene := get_tree().current_scene
    if scene == null or not scene is Node3D:
        return
    prepared = true
    var root := scene as Node3D
    var camera := root.get_node_or_null("Camera3D") as Camera3D
    if camera == null:
        camera = Camera3D.new()
        camera.name = "Camera3D"
        root.add_child(camera)
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 16.0
    camera.near = 0.05
    camera.far = 500.0
    camera.global_position = TARGET + Vector3(0.0, 11.4, 14.2)
    camera.look_at(TARGET, Vector3.UP)
    camera.current = true
    _ensure_lighting(root)
    _ensure_stage(root)

func _ensure_lighting(root:Node3D) -> void:
    if root.get_node_or_null("HDWorldSafetyEnvironment") == null:
        var world := WorldEnvironment.new()
        world.name = "HDWorldSafetyEnvironment"
        var env := Environment.new()
        env.background_mode = Environment.BG_COLOR
        env.background_color = Color("#091522")
        env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
        env.ambient_light_color = Color("#d4dfeb")
        env.ambient_light_energy = 0.85
        env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
        world.environment = env
        root.add_child(world)
    if root.get_node_or_null("HDWorldSafetySun") == null:
        var sun := DirectionalLight3D.new()
        sun.name = "HDWorldSafetySun"
        sun.rotation_degrees = Vector3(-52.0, -32.0, 0.0)
        sun.light_energy = 1.8
        sun.shadow_enabled = true
        sun.directional_shadow_max_distance = 60.0
        root.add_child(sun)

func _ensure_stage(root:Node3D) -> void:
    var world := root.get_node_or_null("World3D") as Node3D
    if world == null:
        world = Node3D.new()
        world.name = "World3D"
        root.add_child(world)
    if world.get_node_or_null("HDGroundSafety") != null:
        return
    var ground := MeshInstance3D.new()
    ground.name = "HDGroundSafety"
    var mesh := BoxMesh.new()
    mesh.size = Vector3(70.0, 0.35, 43.0)
    ground.mesh = mesh
    ground.position = TARGET + Vector3(0.0, -0.20, 0.0)
    ground.material_override = _mat(Color("#294734"), 0.92)
    world.add_child(ground)

    var road := MeshInstance3D.new()
    road.name = "HDMainRoadSafety"
    var road_mesh := BoxMesh.new()
    road_mesh.size = Vector3(9.0, 0.12, 43.0)
    road.mesh = road_mesh
    road.position = TARGET + Vector3(0.0, 0.02, 0.0)
    road.material_override = _mat(Color("#665242"), 1.0)
    world.add_child(road)

    var plaza := MeshInstance3D.new()
    plaza.name = "HDPlazaSafety"
    var plaza_mesh := CylinderMesh.new()
    plaza_mesh.top_radius = 5.0
    plaza_mesh.bottom_radius = 5.0
    plaza_mesh.height = 0.18
    plaza.mesh = plaza_mesh
    plaza.position = TARGET + Vector3(0.0, 0.14, 5.0)
    plaza.material_override = _mat(Color("#806b53"), 0.9)
    world.add_child(plaza)

    _add_building(world, Vector3(6.0, 2.0, 5.0), Color("#a77858"), Color("#713c38"))
    _add_building(world, Vector3(20.0, 2.0, 5.0), Color("#7c6a58"), Color("#3d3d55"))
    _add_building(world, Vector3(6.0, 2.0, 20.0), Color("#96684e"), Color("#573a35"))
    _add_building(world, Vector3(20.0, 2.0, 20.0), Color("#65735e"), Color("#394c3e"))

func _add_building(parent:Node3D, pos:Vector3, wall:Color, roof:Color) -> void:
    var base := MeshInstance3D.new()
    var body := BoxMesh.new()
    body.size = Vector3(5.5, 4.0, 4.5)
    base.mesh = body
    base.position = pos
    base.material_override = _mat(wall, 0.78)
    parent.add_child(base)
    var top := MeshInstance3D.new()
    var roof_mesh := CylinderMesh.new()
    roof_mesh.top_radius = 0.0
    roof_mesh.bottom_radius = 3.7
    roof_mesh.height = 2.2
    top.mesh = roof_mesh
    top.position = pos + Vector3(0.0, 3.0, 0.0)
    top.material_override = _mat(roof, 0.9)
    parent.add_child(top)

func _mat(color:Color, roughness:float) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = roughness
    material.metallic = 0.0
    return material
