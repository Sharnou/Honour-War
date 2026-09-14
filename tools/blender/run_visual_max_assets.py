import pathlib

# Blender 4.2 LTS uses bpy.ops.export_scene.gltf. The visual-max generator is kept
# isolated so its art logic can stay stable while the exporter API evolves.
source_path = pathlib.Path(__file__).with_name("honour_war_visual_max_assets.py")
source = source_path.read_text(encoding="utf-8")
source = source.replace("bpy.ops.wm.gltf_export", "bpy.ops.export_scene.gltf")
code = compile(source, str(source_path), "exec")
globals_dict = {"__name__": "__main__", "__file__": str(source_path)}
exec(code, globals_dict, globals_dict)
