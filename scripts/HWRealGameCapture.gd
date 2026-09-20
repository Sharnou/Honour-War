extends Node

const ENV_ENABLE:String = "HW_CAPTURE_SCREENSHOT"
const ENV_PATH:String = "HW_CAPTURE_PATH"
const DEFAULT_PATH:String = "artifacts/honour-war-exported-exe.png"
const WARMUP_SECONDS:float = 4.0

var _armed:bool = false

func _ready() -> void:
    if OS.get_environment(ENV_ENABLE) != "1":
        return
    _armed = true
    call_deferred("_prepare_capture_view")
    call_deferred("_capture_after_warmup")

func _prepare_capture_view() -> void:
    var scene:Node3D = get_tree().current_scene as Node3D
    if scene == null:
        return
    var camera:Camera3D = scene.get_node_or_null("Camera3D") as Camera3D
    if camera != null:
        camera.current = true
        camera.near = 0.05
        camera.far = 700.0
        camera.fov = 48.0
    var world_environment:WorldEnvironment = scene.get_node_or_null("HWCaptureEnvironment") as WorldEnvironment
    if world_environment == null:
        world_environment = WorldEnvironment.new()
        world_environment.name = "HWCaptureEnvironment"
        scene.add_child(world_environment)
    var environment:Environment = world_environment.environment
    if environment == null:
        environment = Environment.new()
        world_environment.environment = environment
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color("#78a7bd")
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color("#dcecf4")
    environment.ambient_light_energy = 1.35
    environment.tonemap_mode = Environment.TONE_MAPPER_ACES
    environment.tonemap_exposure = 0.35
    if camera != null:
        camera.environment = environment
    var world:World3D = scene.get_world_3d()
    if world != null:
        world.environment = environment
        world.fallback_environment = environment
    var key:DirectionalLight3D = scene.get_node_or_null("HWCaptureKeyLight") as DirectionalLight3D
    if key == null:
        key = DirectionalLight3D.new()
        key.name = "HWCaptureKeyLight"
        key.light_energy = 1.8
        key.light_color = Color("#fff1d2")
        key.shadow_enabled = true
        key.rotation_degrees = Vector3(-52.0,-28.0,0.0)
        scene.add_child(key)
    var fill:DirectionalLight3D = scene.get_node_or_null("HWCaptureFillLight") as DirectionalLight3D
    if fill == null:
        fill = DirectionalLight3D.new()
        fill.name = "HWCaptureFillLight"
        fill.light_energy = 0.55
        fill.light_color = Color("#c7ddff")
        fill.shadow_enabled = false
        fill.rotation_degrees = Vector3(-35.0,145.0,0.0)
        scene.add_child(fill)

func _capture_after_warmup() -> void:
    var timer:SceneTreeTimer = get_tree().create_timer(WARMUP_SECONDS, true, false, true)
    await timer.timeout
    if not _armed:
        return
    var viewport:Viewport = get_viewport()
    if viewport == null:
        push_error("REAL_EXE_SCREENSHOT_FAIL: no game viewport")
        get_tree().quit(1)
        return
    var texture:ViewportTexture = viewport.get_texture()
    if texture == null:
        push_error("REAL_EXE_SCREENSHOT_FAIL: no rendered viewport texture")
        get_tree().quit(1)
        return
    var image:Image = texture.get_image()
    if image == null or image.is_empty():
        push_error("REAL_EXE_SCREENSHOT_FAIL: rendered game image is empty")
        get_tree().quit(1)
        return
    var requested_path:String = OS.get_environment(ENV_PATH)
    var path:String = requested_path if not requested_path.is_empty() else DEFAULT_PATH
    var absolute_path:String = path if path.is_absolute_path() else ProjectSettings.globalize_path(path)
    var parent:String = absolute_path.get_base_dir()
    if not DirAccess.dir_exists_absolute(parent):
        DirAccess.make_dir_recursive_absolute(parent)
    var error:Error = image.save_png(absolute_path)
    if error != OK:
        push_error("REAL_EXE_SCREENSHOT_FAIL: PNG save error %s" % str(error))
        get_tree().quit(1)
        return
    print("REAL_EXE_SCREENSHOT_PASS: exported game viewport captured at %dx%d -> %s" % [image.get_width(),image.get_height(),absolute_path])
    get_tree().quit(0)
