extends SceneTree

const CAPTURE_DIR:String="res://visual-captures"
const CAPTURE_FILE:String=CAPTURE_DIR+"/honour-war-real-game.png"
const STARTUP_TIMEOUT:float=20.0

var elapsed:float=0.0
var captured:bool=false

func _initialize()->void:
    get_root().set_meta("hw_visual_capture",true)
    if DisplayServer.get_name() != "headless":
        DisplayServer.window_set_size(Vector2i(1280,720))
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

func _process(delta:float)->bool:
    if captured:
        return false

    elapsed+=delta
    if elapsed>STARTUP_TIMEOUT:
        push_error("Real game screenshot timed out after %.1f seconds" % STARTUP_TIMEOUT)
        quit(2)
        return false

    # Do not wait on RenderingServer.frame_post_draw. In headless/dummy CI
    # rendering that signal can never arrive, which previously left QA stuck.
    if elapsed<8.0:
        return false

    var viewport:Viewport=get_root().get_viewport()
    if viewport==null:
        return false

    var scene_root:Node=get_current_scene()
    var camera:Camera3D=scene_root.get_node_or_null("Camera3D") as Camera3D
    var world_root:Node=scene_root.get_node_or_null("World3D")
    var actor_root:Node=scene_root.get_node_or_null("Actors3D")
    var mesh_count:int=0
    var mesh_nodes:Array[Node]=scene_root.find_children("*","MeshInstance3D",true,false)
    mesh_count=mesh_nodes.size()
    print("VISUAL_DIAGNOSTIC camera=",camera," current=",camera.current if camera!=null else false," pos=",camera.global_position if camera!=null else Vector3.ZERO)
    print("VISUAL_DIAGNOSTIC world3d=",world_root," children=",world_root.get_child_count() if world_root!=null else -1," actors=",actor_root.get_child_count() if actor_root!=null else -1," meshes=",mesh_count)
    if camera!=null and camera.environment!=null:
        print("VISUAL_DIAGNOSTIC camera_env_mode=",camera.environment.background_mode," bg=",camera.environment.background_color," ambient=",camera.environment.ambient_light_energy)
    var world:World3D=(scene_root as Node3D).get_world_3d()
    if world!=null and world.environment!=null:
        print("VISUAL_DIAGNOSTIC world_env_mode=",world.environment.background_mode," bg=",world.environment.background_color)
    var texture:ViewportTexture=viewport.get_texture()
    if texture==null:
        return false

    var image:Image=texture.get_image()
    if image==null or image.is_empty():
        return false

    if image.get_width() < 1280 or image.get_height() < 720:
        image.resize(1280,720,Image.INTERPOLATE_LANCZOS)
    var output:String=ProjectSettings.globalize_path(CAPTURE_FILE)
    var save_error:Error=image.save_png(output)
    if save_error!=OK:
        push_error("Real game screenshot save failed: %s" % save_error)
        quit(1)
        return false

    captured=true
    print("REAL_GAME_SCREENSHOT="+output)
    quit(0)
    return false
