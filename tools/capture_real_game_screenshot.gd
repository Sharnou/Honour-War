extends SceneTree

const CAPTURE_DIR:String="res://visual-captures"
const CAPTURE_FILE:String=CAPTURE_DIR+"/honour-war-real-game.png"
const STARTUP_TIMEOUT:float=300.0
const MIN_RENDER_FRAMES:int=60
const MIN_SCENE_LUMA:float=0.035
const MIN_SCENE_VARIANCE:float=0.002
const TARGET_SIZE:Vector2i=Vector2i(1920,1080)

var elapsed:float=0.0
var captured:bool=false
var render_frames:int=0
var capture_output:String=CAPTURE_FILE

func _initialize()->void:
	get_root().set_meta("hw_visual_capture",true)
	if DisplayServer.get_name()!="headless":
		DisplayServer.window_set_size(TARGET_SIZE)
	var root_window:Window=get_root() as Window
	if root_window!=null:
		root_window.size=TARGET_SIZE
	call_deferred("_launch")

func _launch()->void:
	var error:int=DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CAPTURE_DIR))
	if error!=OK and error!=ERR_ALREADY_EXISTS:
		push_error("Could not create visual capture directory");quit(1);return
	var packed:PackedScene=load("res://Main3D.tscn") as PackedScene
	if packed==null:push_error("Could not load Main3D.tscn for real-game capture");quit(1);return
	var production_scene:Node=packed.instantiate()
	if production_scene==null:push_error("Could not instantiate Main3D.tscn for real-game capture");quit(1);return
	var repaired:int=_sanitize_render_materials(production_scene)
	print("PREATTACH_MATERIAL_PREFLIGHT repaired=",repaired)
	get_root().add_child(production_scene)
	current_scene=production_scene
	call_deferred("_postattach_material_seal")

func _fallback_material()->StandardMaterial3D:
	var fallback:=StandardMaterial3D.new()
	fallback.albedo_color=Color("#9aa1aa")
	fallback.metallic=0.15
	fallback.roughness=0.58
	return fallback

func _sanitize_render_materials(root:Node)->int:
	var repaired:int=0
	if root==null or not is_instance_valid(root):return repaired
	for node:Node in root.find_children("*","GeometryInstance3D",true,false):
		var geometry:=node as GeometryInstance3D
		if geometry==null or not is_instance_valid(geometry):continue
		if geometry.material_override==null:
			geometry.material_override=_fallback_material()
			repaired+=1
	for node:Node in root.find_children("*","MeshInstance3D",true,false):
		var mesh_instance:=node as MeshInstance3D
		if mesh_instance!=null and mesh_instance.mesh!=null:
			repaired+=_sanitize_mesh(mesh_instance.mesh,mesh_instance)
	return repaired

func _sanitize_mesh(mesh:Mesh,owner:MeshInstance3D)->int:
	var repaired:int=0
	for surface:int in mesh.get_surface_count():
		var material:Material=mesh.surface_get_material(surface)
		if owner!=null and owner.get_surface_override_material(surface)!=null:
			material=owner.get_surface_override_material(surface)
		if material==null and owner!=null:
			owner.set_surface_override_material(surface,_fallback_material())
			repaired+=1
	return repaired

func _postattach_material_seal()->void:
	var seal_scene:Node=get_current_scene()
	if seal_scene==null:return
	var repaired:int=_sanitize_render_materials(seal_scene)
	if repaired>0:print("POSTATTACH_MATERIAL_SEAL repaired=",repaired)

func _has_real_world_pixels(image:Image)->bool:
	var small:Image=image.duplicate()
	small.resize(32,18,Image.INTERPOLATE_BILINEAR)
	var sum:float=0.0
	var sum_sq:float=0.0
	var count:int=0
	for y:int in range(3,15):
		for x:int in range(2,30):
			var p:Color=small.get_pixel(x,y)
			var l:float=(p.r+p.g+p.b)/3.0
			sum+=l
			sum_sq+=l*l
			count+=1
	if count==0:return false
	var mean:float=sum/float(count)
	var variance:float=max(0.0,(sum_sq/float(count))-(mean*mean))
	return mean>=MIN_SCENE_LUMA and variance>=MIN_SCENE_VARIANCE

func _process(delta:float)->bool:
	if captured:return false
	elapsed+=delta
	render_frames+=1
	if elapsed>STARTUP_TIMEOUT:
		push_error("Real game screenshot timed out after %.1f seconds"%STARTUP_TIMEOUT);quit(2);return true
	var capture_scene:Node=get_current_scene()
	if capture_scene==null:return false
	var camera:=capture_scene.get_node_or_null("Camera3D") as Camera3D
	var old_world:Node=capture_scene.find_child("World3D",true,false)
	var detail_root:Node=capture_scene.find_child("HWWorldDetailOverhaul",true,false)
	var world_ready:bool=(old_world!=null and old_world.get_child_count()>0) or (detail_root!=null and detail_root.get_child_count()>0)
	if render_frames==20 or render_frames%120==0:
		print("CAPTURE_WAIT elapsed=",elapsed," camera=",camera!=null," current=",camera.current if camera!=null else false," world_ready=",world_ready," detail_children=",detail_root.get_child_count() if detail_root!=null else -1)
	if elapsed<6.0 or render_frames<MIN_RENDER_FRAMES or camera==null or not camera.current or not world_ready:return false
	var viewport:Viewport=get_root().get_viewport()
	if viewport==null:return false
	var image:Image=viewport.get_texture().get_image()
	if image==null or image.is_empty():return false
	if not _has_real_world_pixels(image):
		if render_frames%60==0:print("CAPTURE_WAIT scene pixels not ready")
		return false
	var source_size:=Vector2i(image.get_width(),image.get_height())
	if source_size!=TARGET_SIZE:
		print("CAPTURE_NORMALIZE source=",source_size," target=",TARGET_SIZE)
		image.resize(TARGET_SIZE.x,TARGET_SIZE.y,Image.INTERPOLATE_LANCZOS)
	var save_error:Error=image.save_png(capture_output)
	if save_error!=OK:
		push_error("Real game screenshot save failed: %s"%save_error);quit(1);return true
	captured=true
	print("REAL_GAME_SCREENSHOT="+capture_output)
	print("REAL_GAME_SCREENSHOT_SOURCE_VIEWPORT=",source_size)
	quit(0)
	return true
