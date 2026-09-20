extends Node

## Real gameplay capture.
## This node is part of Main3D.tscn so the exported game owns the capture lifecycle.
## It saves the actual rendered game viewport; it does not generate or composite an image.

const ENV_ENABLE:String = "HW_CAPTURE_SCREENSHOT"
const ENV_PATH:String = "HW_CAPTURE_PATH"
const CAPTURE_ARG:String = "--hw-capture-screenshot"
const DEFAULT_PATH:String = "artifacts/honour-war-exported-exe.png"
const MAX_WAIT_SECONDS:float = 12.0

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
    while _armed and float(Time.get_ticks_msec() - start_msec) * 0.001 < MAX_WAIT_SECONDS:
        var scene:Node3D = get_tree().current_scene as Node3D
        if scene != null and scene.has_method("get"):
            var camera:Camera3D = scene.get_node_or_null("Camera3D") as Camera3D
            var hero_value:Variant = scene.get("hero_visual")
            var world_root:Node3D = scene.get_node_or_null("World3D") as Node3D
            if camera != null and camera.current and hero_value is Node3D and is_instance_valid(hero_value):
                if world_root != null and _mesh_count(world_root) > 8:
                    await get_tree().process_frame
                    await RenderingServer.frame_post_draw
                    await get_tree().process_frame
                    _save_rendered_viewport()
                    return
        await get_tree().process_frame
    push_error("REAL_EXE_SCREENSHOT_FAIL: game scene did not reach rendered gameplay state")
    get_tree().quit(1)

func _mesh_count(root:Node) -> int:
    if root == null or not is_instance_valid(root):
        return 0
    var count:int = 0
    for node:Node in root.find_children("*","MeshInstance3D",true,false):
        if node is MeshInstance3D and (node as MeshInstance3D).visible and (node as MeshInstance3D).mesh != null:
            count += 1
    return count

func _save_rendered_viewport() -> void:
    if not _armed:
        return
    var viewport:Viewport = get_viewport()
    if viewport == null:
        push_error("REAL_EXE_SCREENSHOT_FAIL: no game viewport")
        get_tree().quit(1)
        return
    var image:Image = viewport.get_texture().get_image()
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

    print("REAL_EXE_SCREENSHOT_PASS: exported gameplay viewport captured at %dx%d -> %s" % [image.get_width(),image.get_height(),absolute_path])
    get_tree().quit(0)
