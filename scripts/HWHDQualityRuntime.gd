extends Node

## Godot 4.7 HD startup presentation guard.
## Applies the authored HD presentation once at startup, then leaves graphics
## presets, perspective camera control, and gameplay-owned settings under their existing systems.

const CAMERA_SIZE := 13.5
const TARGET_OFFSET := Vector3(0.0, 1.0, 0.0)

func _ready()->void:
    call_deferred("_apply_startup")

func _apply_startup()->void:
    var scene := get_tree().current_scene
    if scene == null:
        return

    var graphics := get_node_or_null("/root/GraphicsManager")
    if graphics != null and graphics.has_method("apply_preset"):
        graphics.call("apply_preset", 2)

    var camera_controller := scene.get_node_or_null("Camera3D") as Node
    var camera := camera_controller as Camera3D
    if camera != null:
        # Honour War gameplay uses a readable perspective MMO camera so the
        # full hero body, roads, trees and building depth remain visible.
        camera.projection = Camera3D.PROJECTION_PERSPECTIVE
        camera.fov = 58.0
        camera.near = 0.05
        camera.far = 700.0
    if camera_controller != null:
        if camera_controller.get("target_offset") != null:
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
    for child:Node in node.get_children():
        _collect_world_environments(child, output)
