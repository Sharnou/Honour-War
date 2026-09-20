extends Node

## Real gameplay capture.
## This node is part of Main3D.tscn so the exported game owns the capture lifecycle.
## It saves pixels read directly from the live Godot viewport; it never generates,
## paints, composites, or substitutes a reference image.

const ENV_ENABLE:String = "HW_CAPTURE_SCREENSHOT"
const ENV_PATH:String = "HW_CAPTURE_PATH"
const CAPTURE_ARG:String = "--hw-capture-screenshot"
const DEFAULT_PATH:String = "artifacts/honour-war-exported-exe.png"
const MAX_WAIT_SECONDS:float = 20.0
const MAX_FRAME_RETRIES:int = 120
const SAMPLE_STEP:int = 16

var _armed:bool = false

func _ready() -> void:
    if not _capture_requested():
        return
    _armed = true
    call_deferred("_capture_when_game_is_rendering")

func _capture_requested() -> bool:
    if OS.get_environment(ENV_ENABLE) == "1":
        return true
    return CAPTURE_ARG in OS.get_cmdline_args() or CAPTURE_ARG in OS.get_cmdline_user_args()

func _capture_when_game_is_rendering() -> void:
    var start_msec:int = Time.get_ticks_msec()
    var prepared:bool = false
    var retry_count:int = 0
    while _armed and float(Time.get_ticks_msec() - start_msec) * 0.001 < MAX_WAIT_SECONDS:
        var scene:Node3D = get_tree().current_scene as Node3D
        if scene != null and is_instance_valid(scene):
            var camera:Camera3D = scene.get_node_or_null("Camera3D") as Camera3D
            var hero_value:Variant = scene.get("hero_visual")
            var world_root:Node3D = scene.get_node_or_null("World3D") as Node3D
            var production:Node3D = scene.get_node_or_null("HWProductionVisualRebuild") as Node3D
            var production_world:Node3D = scene.get_node_or_null("HWProductionVisualWorld") as Node3D
            var production_ready:bool = production != null and bool(production.get("built")) and production_world != null and production_world.visible
            var hero_ready:bool = hero_value is Node3D and is_instance_valid(hero_value) and (hero_value as Node3D).get_node_or_null("HWProductionHeroVisual") != null
            var legacy_retired:bool = world_root != null and bool(world_root.get_meta("legacy_geometry_hidden_by_production_rebuild",false))
            if camera != null and camera.is_inside_tree() and camera.current and hero_ready and production_ready and legacy_retired:
                if not prepared:
                        _prepare_capture_view(scene, camera, hero_value as Node3D)
                        prepared = true
                    await get_tree().process_frame
                    await RenderingServer.frame_post_draw
                    await get_tree().process_frame
                    retry_count += 1
                    if _try_save_rendered_viewport(retry_count):
                        return
        await get_tree().process_frame
    push_error("REAL_EXE_SCREENSHOT_FAIL: game scene did not reach a stable non-blank rendered frame")
    get_tree().quit(1)

func _prepare_capture_view(scene:Node3D, camera:Camera3D, hero:Node3D) -> void:
    # The normal gameplay camera remains owned by MovementStabilityFix. For an
    # evidence capture we temporarily freeze camera-writer nodes so no director
    # can move the camera between validation and framebuffer readback.
    for node_path:String in ["MovementStabilityFix", "HDPresentationDirector", "HWCameraFrameV3"]:
        var node:Node = scene.get_node_or_null(node_path)
        if node != null:
            node.set_process(false)
            node.set_process_unhandled_input(false)
    camera.projection = Camera3D.PROJECTION_PERSPECTIVE
    camera.fov = 54.0
    camera.near = 0.05
    camera.far = 700.0
    camera.cull_mask = 0xFFFFFFFF
    camera.current = true
    hero.visible = true
    var target:Vector3 = hero.global_position + Vector3(0.0, 1.05, 0.0)
    # Wide three-quarter framing keeps the full hero body/legs and surrounding
    # medieval town readable while staying entirely inside the real game camera.
    camera.global_position = target + Vector3(9.2, 6.8, 10.6)
    camera.look_at(target, Vector3.UP)

func _mesh_count(root:Node) -> int:
    if root == null or not is_instance_valid(root):
        return 0
    var count:int = 0
    for node:Node in root.find_children("*", "MeshInstance3D", true, false):
        if node is MeshInstance3D and (node as MeshInstance3D).visible and (node as MeshInstance3D).mesh != null:
            count += 1
    return count

func _try_save_rendered_viewport(retry_count:int) -> bool:
    var viewport:Viewport = get_viewport()
    if viewport == null:
        push_error("REAL_EXE_SCREENSHOT_FAIL: no game viewport")
        get_tree().quit(1)
        return false
    var image:Image = viewport.get_texture().get_image()
    if image == null or image.is_empty():
        return false
    var quality:Dictionary = _frame_quality(image)
    print("REAL_EXE_SCREENSHOT_FRAME: attempt=%d size=%dx%d mean=%.2f spread=%d dark_ratio=%.4f clipped_ratio=%.4f" % [
        retry_count,
        image.get_width(),
        image.get_height(),
        float(quality.get("mean", 0.0)),
        int(quality.get("spread", 0)),
        float(quality.get("dark_ratio", 1.0)),
        float(quality.get("clipped_ratio", 1.0))
    ])
    if not bool(quality.get("valid", false)):
        return retry_count >= MAX_FRAME_RETRIES and _fail_capture("all sampled frames were blank/dark/invalid")
    var requested_path:String = OS.get_environment(ENV_PATH)
    var path:String = requested_path if not requested_path.is_empty() else DEFAULT_PATH
    var absolute_path:String = path if path.is_absolute_path() else ProjectSettings.globalize_path(path)
    var parent:String = absolute_path.get_base_dir()
    if not DirAccess.dir_exists_absolute(parent):
        DirAccess.make_dir_recursive_absolute(parent)
    var error:Error = image.save_png(absolute_path)
    if error != OK:
        _fail_capture("PNG save error %s" % str(error))
        return false
    print("REAL_EXE_SCREENSHOT_PASS: exported gameplay viewport captured at %dx%d -> %s" % [image.get_width(), image.get_height(), absolute_path])
    get_tree().quit(0)
    return true

func _frame_quality(image:Image) -> Dictionary:
    var width:int = image.get_width()
    var height:int = image.get_height()
    if width < 960 or height < 540:
        return {"valid": false, "mean": 0.0, "spread": 0, "dark_ratio": 1.0, "clipped_ratio": 0.0}
    var count:int = 0
    var dark:int = 0
    var clipped:int = 0
    var total:float = 0.0
    var minimum:int = 255
    var maximum:int = 0
    for y in range(0, height, SAMPLE_STEP):
        for x in range(0, width, SAMPLE_STEP):
            var c:Color = image.get_pixel(x, y)
            var r:int = int(clampf(c.r, 0.0, 1.0) * 255.0)
            var g:int = int(clampf(c.g, 0.0, 1.0) * 255.0)
            var b:int = int(clampf(c.b, 0.0, 1.0) * 255.0)
            var peak:int = maxi(r, maxi(g, b))
            var low:int = mini(r, mini(g, b))
            total += float(r + g + b) / 3.0
            minimum = min(minimum, low)
            maximum = max(maximum, peak)
            if peak < 12:
                dark += 1
            if peak >= 245:
                clipped += 1
            count += 1
    var mean:float = total / max(count, 1)
    var dark_ratio:float = float(dark) / max(count, 1)
    var clipped_ratio:float = float(clipped) / max(count, 1)
    var spread:int = maximum - minimum
    var valid:bool = mean >= 18.0 and spread >= 45 and dark_ratio <= 0.97 and clipped_ratio <= 0.72
    return {
        "valid": valid,
        "mean": mean,
        "spread": spread,
        "dark_ratio": dark_ratio,
        "clipped_ratio": clipped_ratio
    }

func _fail_capture(reason:String) -> bool:
    push_error("REAL_EXE_SCREENSHOT_FAIL: " + reason)
    get_tree().quit(1)
    return false
