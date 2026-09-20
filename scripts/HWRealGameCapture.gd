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
    call_deferred("_capture_after_warmup")

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
