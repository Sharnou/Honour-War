"""
Honour War GLB exporter.

Use after the Blender source asset has been modeled, rigged and prepared.
The exported file is the hand-off to Substance 3D Painter / Godot depending
on the team's texture and export workflow.

Pipeline:
Blender source -> Substance 3D Painter PBR -> Blender/GLTF export -> Godot 4
"""

import bpy
import os

OUTPUT_ROOT = bpy.path.abspath("//../../assets/3d")


def export_active_asset(asset_id):
    os.makedirs(OUTPUT_ROOT, exist_ok=True)
    safe_id = asset_id.strip().lower().replace(" ", "_").replace("-", "_")
    category = "characters" if safe_id.startswith("hero_") else "pets" if safe_id.startswith("pet_") else "monsters"
    output_dir = os.path.join(OUTPUT_ROOT, category)
    os.makedirs(output_dir, exist_ok=True)
    output_path = os.path.join(output_dir, safe_id + ".glb")

    bpy.ops.object.select_all(action='DESELECT')
    roots = [obj for obj in bpy.context.scene.objects if obj.get("asset_id") == safe_id]
    if not roots:
        raise RuntimeError("No scene root with asset_id=%s" % safe_id)

    root = roots[0]
    root.select_set(True)
    bpy.context.view_layer.objects.active = root

    bpy.ops.export_scene.gltf(
        filepath=output_path,
        export_format='GLB',
        use_selection=True,
        export_apply=True,
        export_texcoords=True,
        export_normals=True,
        export_tangents=True,
        export_materials='EXPORT',
        export_animations=True,
        export_skins=True,
        export_morph=True,
        export_lights=False,
        export_cameras=False,
    )
    print("Honour War GLB exported: %s" % output_path)


if __name__ == "__main__":
    export_active_asset("hero_warrior")
