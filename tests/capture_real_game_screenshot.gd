extends SceneTree

const CAPTURE_PATH:String = "artifacts/honour-war-real-game.png"
const WARMUP_FRAMES:int = 45

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
    current_scene = game
    for i in range(WARMUP_FRAMES):
        await process_frame
    var viewport:Viewport = get_root().get_viewport()
    var image:Image = viewport.get_texture().get_image()
    if image == null or image.is_empty():
        push_error("REAL_GAME_SCREENSHOT_FAIL: rendered game viewport is empty")
        if is_instance_valid(game): game.queue_free()
        quit(1)
        return
    var quality:Dictionary = _frame_quality(image)
    print("REAL_GAME_SCREENSHOT_FRAME: size=%dx%d mean=%.2f spread=%d dark_ratio=%.4f clipped_ratio=%.4f" % [
        image.get_width(), image.get_height(), float(quality.get("mean",0.0)),
        int(quality.get("spread",0)), float(quality.get("dark_ratio",1.0)),
        float(quality.get("clipped_ratio",1.0))
    ])
    if not bool(quality.get("valid",false)):
        push_error("REAL_GAME_SCREENSHOT_FAIL: framebuffer is blank, dark, or clipped")
        if is_instance_valid(game): game.queue_free()
        await process_frame
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
    if is_instance_valid(game): game.queue_free()
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    quit(0)

func _frame_quality(image:Image) -> Dictionary:
    var width:int = image.get_width()
    var height:int = image.get_height()
    if width < 960 or height < 540:
        return {"valid":false,"mean":0.0,"spread":0,"dark_ratio":1.0,"clipped_ratio":0.0}
    var total:float = 0.0
    var minimum:int = 255
    var maximum:int = 0
    var dark:int = 0
    var clipped:int = 0
    var count:int = 0
    const STEP:int = 16
    for y in range(0,height,STEP):
        for x in range(0,width,STEP):
            var c:Color = image.get_pixel(x,y)
            var r:int = int(clampf(c.r,0.0,1.0)*255.0)
            var g:int = int(clampf(c.g,0.0,1.0)*255.0)
            var b:int = int(clampf(c.b,0.0,1.0)*255.0)
            var peak:int = maxi(r,maxi(g,b))
            var low:int = mini(r,mini(g,b))
            total += float(r+g+b)/3.0
            minimum = min(minimum,low)
            maximum = max(maximum,peak)
            if peak < 12: dark += 1
            if peak >= 245: clipped += 1
            count += 1
    var mean:float = total/max(count,1)
    var dark_ratio:float = float(dark)/max(count,1)
    var clipped_ratio:float = float(clipped)/max(count,1)
    return {"valid":mean>=18.0 and (maximum-minimum)>=45 and dark_ratio<=0.97 and clipped_ratio<=0.72,"mean":mean,"spread":maximum-minimum,"dark_ratio":dark_ratio,"clipped_ratio":clipped_ratio}
