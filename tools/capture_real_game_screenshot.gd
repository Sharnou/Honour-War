extends SceneTree

const CAPTURE_DIR:String="res://visual-captures"

func _initialize()->void:
    get_root().set_meta("hw_visual_capture",true)
    call_deferred("_launch")

func _launch()->void:
    var error:int=DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CAPTURE_DIR))
    if error!=OK and error!=ERR_ALREADY_EXISTS:
        push_error("Could not create visual capture directory")
        quit(1)
        return
    var result:Error=change_scene_to_file("res://Main3D.tscn")
    if result!=OK:
        push_error("Could not launch Main3D.tscn for real-game capture")
        quit(1)
        return
    await create_timer(7.0).timeout
    await RenderingServer.frame_post_draw
    var viewport:Viewport=get_root().get_viewport()
    if viewport==null:
        push_error("Real game screenshot viewport unavailable")
        quit(1)
        return
    var image:Image=viewport.get_texture().get_image()
    var output:String=ProjectSettings.globalize_path(CAPTURE_DIR+"/honour-war-real-game.png")
    var save_error:Error=image.save_png(output)
    if save_error!=OK:
        push_error("Real game screenshot save failed")
        quit(1)
        return
    print("REAL_GAME_SCREENSHOT="+output)
    quit(0)
