extends Node

## Godot 4.7 HD presentation guard.
## Keeps the complete hero in frame, restores the authored environment after any
## legacy presentation pass, and enforces the HD preset without removing gameplay systems.

const CAMERA_SIZE := 13.5
const CAMERA_MIN := 6.5
const CAMERA_MAX := 20.0
const TARGET_OFFSET := Vector3(0.0, 1.0, 0.0)

var elapsed:float = 0.0
var initialized:bool = false

func _ready()->void:
    call_deferred("_apply")

func _process(delta:float)->void:
    elapsed += delta
    if elapsed < 0.5 and initialized:
        return
    elapsed = 0.0
    _apply()

func _apply()->void:
    var scene := get_tree().current_scene
    if scene == null:
        return
    var game := scene as Node
    if game == null:
        return

    var graphics := get_node_or_null("/root/GraphicsManager")
    if graphics != null and graphics.has_method("is_hd") and not graphics.is_hd():
        graphics.call("apply_preset", graphics.get("Preset").HD if graphics.get("Preset") != null else 2)

    var camera := scene.find_child("Camera3D", true, false) as Camera3D
    if camera != null:
        camera.projection = Camera3D.PROJECTION_ORTHOGONAL
        camera.size = clampf(camera.size, CAMERA_MIN, CAMERA_MAX)
        if camera.size < 11.5:
            camera.size = CAMERA_SIZE
        if camera is Node3D:
            var camera_controller := scene.get_node_or_null("Camera3D")
            if camera_controller != null and "orthographic_size" in camera_controller:
                camera_controller.set("orthographic_size", CAMERA_SIZE)
            if camera_controller != null and "min_zoom" in camera_controller:
                camera_controller.set("min_zoom", CAMERA_MIN)
            if camera_controller != null and "max_zoom" in camera_controller:
                camera_controller.set("max_zoom", CAMERA_MAX)
            if camera_controller != null and "target_offset" in camera_controller:
                camera_controller.set("target_offset", TARGET_OFFSET)

    var authored_world := scene.get_node_or_null("HDEnvironmentDirector")
    if authored_world != null:
        authored_world.visible = true
    var generated_world := scene.get_node_or_null("HDPresentationWorld")
    if generated_world != null:
        generated_world.visible = false
    var simple_world := scene.get_node_or_null("World3D")
    if simple_world != null:
        simple_world.visible = true

    _tune_environment(scene)
    initialized = true

func _tune_environment(scene:Node)->void:
    var environment_nodes:Array[Node] = []
    _collect_world_environments(scene, environment_nodes)
    if environment_nodes.is_empty():
        return
    var world := environment_nodes[0] as WorldEnvironment
    if world == null:
        return
    if world.environment == null:
        world.environment = Environment.new()
    var env := world.environment
    env.ambient_light_energy = max(env.ambient_light_energy, 0.85)
    env.tonemap_mode = Environment.TONE_MAPPER_ACES
    env.tonemap_exposure = clampf(env.tonemap_exposure, -0.85, -0.45)
    env.ssao_enabled = true
    env.ssao_radius = max(env.ssao_radius, 2.0)
    env.ssao_intensity = max(env.ssao_intensity, 1.05)
    env.glow_enabled = false

func _collect_world_environments(node:Node, output:Array[Node])->void:
    if node is WorldEnvironment:
        output.append(node)
    for child in node.get_children():
        _collect_world_environments(child, output)
