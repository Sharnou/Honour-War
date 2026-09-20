extends SceneTree

const CAPTURE_PATH:String = "artifacts/honour-war-real-game.png"
const WARMUP_FRAMES:int = 180

func _initialize() -> void:
    call_deferred("_boot_capture")

func _boot_capture() -> void:
    var packed:PackedScene = load("res://Main3D.tscn") as PackedScene
    if packed == null:
        push_error("REAL_GAME_SCREENSHOT_FAIL: Main3D.tscn could not be loaded")
        quit(1)
        return
    var game:Node = packed.instantiate()
    get_root().add_child(game)
    for i in range(WARMUP_FRAMES):
        await process_frame
    var viewport:Viewport = get_root().get_viewport()
    var image:Image = viewport.get_texture().get_image()
    if image == null or image.is_empty():
        push_error("REAL_GAME_SCREENSHOT_FAIL: rendered game viewport is empty")
        quit(1)
        return
    var absolute_path:String = ProjectSettings.globalize_path(CAPTURE_PATH)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("artifacts"))
    var error:Error = image.save_png(absolute_path)
    if error != OK:
        push_error("REAL_GAME_SCREENSHOT_FAIL: PNG save error %s" % str(error))
        quit(1)
        return
    print("REAL_GAME_SCREENSHOT_PASS: captured rendered Main3D.tscn viewport at %dx%d -> %s" % [image.get_width(),image.get_height(),absolute_path])
    quit(0)
