import pathlib

# Blender runner for the Honour War HD Visual MAX generator.
# The generator itself owns the FBX export contract; this wrapper does not
# rewrite or introduce any GLTF/GLB exporter calls.

source_path = pathlib.Path(__file__).with_name("honour_war_visual_max_assets.py")
source = source_path.read_text(encoding="utf-8")
code = compile(source, str(source_path), "exec")
globals_dict = {"__name__": "__main__", "__file__": str(source_path)}
exec(code, globals_dict, globals_dict)
