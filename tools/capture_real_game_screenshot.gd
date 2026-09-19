extends SceneTree

const CAPTURE_DIR:String="res://visual-captures"
const CAPTURE_FILE:String=CAPTURE_DIR+"/honour-war-real-game.png"
const STARTUP_TIMEOUT:float=45.0
const MIN_RENDER_FRAMES:int=20

var elapsed:float=0.0
var captured:bool=false
var seal_done:bool=false
var render_frames:int=0

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

    # Instantiate the production scene while it is still outside the active
    # SceneTree. Forward+ can create RenderingDevice material dependencies during
    # scene attachment, before ordinary _ready/deferred repair code can run.
    # Sanitize authored MeshInstance3D surfaces first, then attach the exact same
    # Main3D scene. This keeps the capture on the real game path and avoids hiding
    # an importer/renderer problem with a renderer switch.
    var packed:PackedScene=load("res://Main3D.tscn") as PackedScene
    if packed==null:
        push_error("Could not load Main3D.tscn for real-game capture")
        quit(1)
        return
    var production_scene:Node=packed.instantiate()
    if production_scene==null:
        push_error("Could not instantiate Main3D.tscn for real-game capture")
        quit(1)
        return
    var repaired:int=_sanitize_mesh_materials(production_scene)
    print("PREATTACH_MATERIAL_PREFLIGHT repaired=",repaired)
    get_root().add_child(production_scene)
    current_scene=production_scene
    # A few production/autoload directors create additional geometry during
    # scene attachment. Run a second seal immediately after attachment and on
    # every frame before capture so newly-created draw meshes cannot reach
    # Forward+ with a null material.
    call_deferred("_postattach_material_seal")

func _sanitize_mesh_materials(root:Node)->int:
    var repaired:int=0
    # Native Godot runtime capture no longer needs a full GLB-era geometry sweep.
    # Scan concrete mesh owners once; this keeps capture deterministic and avoids
    # repeatedly walking large procedural scenes during the 90-second CI window.
    for node:Node in root.find_children("*","MeshInstance3D",true,false):
        var mesh_instance:MeshInstance3D=node as MeshInstance3D
        if mesh_instance!=null and mesh_instance.mesh!=null:
            repaired+=_sanitize_mesh(mesh_instance.mesh,mesh_instance)
    for node:Node in root.find_children("*","MultiMeshInstance3D",true,false):
        var multi:MultiMeshInstance3D=node as MultiMeshInstance3D
        if multi!=null and multi.multimesh!=null and multi.multimesh.mesh!=null:
            var source_material:Material=multi.multimesh.mesh.surface_get_material(0) if multi.multimesh.mesh.get_surface_count()>0 else null
            if source_material==null and multi.material_override==null:
                var fallback_multi:=StandardMaterial3D.new()
                fallback_multi.albedo_color=Color("#9aa1aa")
                fallback_multi.metallic=0.15
                fallback_multi.roughness=0.58
                multi.material_override=fallback_multi
                repaired+=1
    for node:Node in root.find_children("*","GPUParticles3D",true,false):
        var particles:GPUParticles3D=node as GPUParticles3D
        if particles==null:
            continue
        for pass_index:int in range(particles.get_draw_passes()):
            var draw_mesh:Mesh=particles.get_draw_pass_mesh(pass_index)
            if draw_mesh!=null:
                repaired+=_sanitize_mesh(draw_mesh,null)
    return repaired

func _sanitize_mesh(mesh:Mesh, owner:MeshInstance3D)->int:
    var repaired:int=0
    for surface:int in mesh.get_surface_count():
        var material:Material=mesh.surface_get_material(surface)
        if owner!=null:
            var override_material:Material=owner.get_surface_override_material(surface)
            if override_material!=null:
                material=override_material
        if material==null:
            var fallback:=StandardMaterial3D.new()
            fallback.albedo_color=Color("#9aa1aa")
            fallback.metallic=0.15
            fallback.roughness=0.58
            if owner!=null:
                owner.set_surface_override_material(surface,fallback)
            else:
                mesh.surface_set_material(surface,fallback)
            repaired+=1
            print("PREATTACH_MATERIAL_PREFLIGHT repaired_path=",owner.get_path() if owner!=null else "<mesh>"," surface=",surface)
    return repaired

func _postattach_material_seal()->void:
    var seal_scene:Node=get_current_scene()
    if seal_scene==null:
        return
    var repaired:int=_sanitize_mesh_materials(seal_scene)
    if repaired>0:
        print("POSTATTACH_MATERIAL_SEAL repaired=",repaired)

func _process(delta:float)->bool:
    if captured:
        return false

    elapsed+=delta
    render_frames+=1
    if not seal_done and elapsed >= 2.0:
        # One bounded post-startup seal; never rescan the full scene every frame.
        var frame_seal_scene:Node=get_current_scene()
        if frame_seal_scene!=null:
            var repaired:int=_sanitize_mesh_materials(frame_seal_scene)
            if repaired>0:
                print("FRAME_MATERIAL_SEAL repaired=",repaired)
        seal_done=true
    if elapsed>STARTUP_TIMEOUT:
        push_error("Real game screenshot timed out after %.1f seconds" % STARTUP_TIMEOUT)
        quit(2)
        return false

    # Do not wait on RenderingServer.frame_post_draw. In headless/dummy CI
    # rendering that signal can never arrive, which previously left QA stuck.
    var capture_scene:Node=get_current_scene()
    var camera:=capture_scene.get_node_or_null("Camera3D") as Camera3D if capture_scene!=null else null
    var world_root:Node=capture_scene.get_node_or_null("World3D") if capture_scene!=null else null
    var mesh_nodes:Array[Node]=capture_scene.find_children("*","MeshInstance3D",true,false) if capture_scene!=null else []
    var world_ready:=world_root!=null and world_root.get_child_count()>0
    if render_frames==20 or (render_frames%120)==0:
        print("CAPTURE_WAIT elapsed=",elapsed," camera=",camera!=null," current=",camera.current if camera!=null else false," world=",world_ready," world_children=",world_root.get_child_count() if world_root!=null else -1," meshes=",mesh_nodes.size())
    # Do not make the evidence capture depend on one recovery node path. The
    # screenshot must capture the real Main3D scene as soon as its camera and
    # renderable world are alive.
    if elapsed<8.0 or render_frames<MIN_RENDER_FRAMES or camera==null or not camera.current or not world_ready:
        return false

    var viewport:Viewport=get_root().get_viewport()
    if viewport==null:
        return false

    var actor_root:Node=capture_scene.get_node_or_null("Actors3D")
    var mesh_count:int=mesh_nodes.size()
    print("VISUAL_DIAGNOSTIC camera=",camera," current=",camera.current if camera!=null else false," pos=",camera.global_position if camera!=null else Vector3.ZERO)
    print("VISUAL_DIAGNOSTIC world3d=",world_root," children=",world_root.get_child_count() if world_root!=null else -1," actors=",actor_root.get_child_count() if actor_root!=null else -1," meshes=",mesh_count)
    if camera!=null and camera.environment!=null:
        print("VISUAL_DIAGNOSTIC camera_env_mode=",camera.environment.background_mode," bg=",camera.environment.background_color," ambient=",camera.environment.ambient_light_energy)
    var world:World3D=(capture_scene as Node3D).get_world_3d()
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
