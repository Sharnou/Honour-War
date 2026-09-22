"""Honour War production asset bootstrap for Blender 4.x.

Purpose:
- Create clean, named, export-ready collection structure for the ten development roles.
- Generate non-destructive blockout guides that are intended to be replaced/refined
  into authored high-detail meshes, not shipped as final game art.
- Prepare FBX/OBJ export conventions for Blender/Neural4D -> Substance 3D Painter -> Unreal Engine 5.8.

Run inside Blender's Scripting workspace. This script does not claim to create
finished character/monster art; it establishes a repeatable production scaffold.
"""

import bpy
import math
from mathutils import Vector

ROOT = "HONOUR_WAR_PRODUCTION"
CATEGORIES = [
    "characters", "armor", "weapons", "pets", "monsters",
    "maps", "props", "effects", "ui"
]
CLASSES = ["Warrior", "Mage", "Archer", "Thief", "Acolyte", "Merchant"]
TIERS = ["Foundation", "Specialization", "Advanced", "Mastery", "Transcendence"]


def get_or_create_collection(name, parent=None):
    collection = bpy.data.collections.get(name)
    if collection is None:
        collection = bpy.data.collections.new(name)
    owner = parent or bpy.context.scene.collection
    if collection.name not in owner.children:
        owner.children.link(collection)
    return collection


def clear_scaffold_objects(collection):
    for obj in list(collection.objects):
        bpy.data.objects.remove(obj, do_unlink=True)


def make_material(name, base_color, metallic=0.0, roughness=0.55):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*base_color, 1.0)
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    return mat


def add_mesh_guide(name, location, scale, material, collection):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=48, ring_count=24, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    obj.data.materials.append(material)
    for col in list(obj.users_collection):
        col.objects.unlink(obj)
    collection.objects.link(obj)
    return obj


def create_character_scaffold(collection, class_name):
    class_root = get_or_create_collection(f"CHAR_{class_name}", collection)
    clear_scaffold_objects(class_root)
    mat = make_material(f"HW_{class_name}_Base", (0.32, 0.40, 0.55), 0.15, 0.48)
    skin = make_material("HW_SkinGuide", (0.55, 0.28, 0.18), 0.0, 0.60)
    add_mesh_guide(f"{class_name}_Body_Guide", (0, 0, 1.05), (0.42, 0.26, 0.72), mat, class_root)
    add_mesh_guide(f"{class_name}_Head_Guide", (0, 0, 2.0), (0.30, 0.25, 0.32), skin, class_root)
    for x in (-0.18, 0.18):
        add_mesh_guide(f"{class_name}_Foot_Guide", (x, -0.02, 0.12), (0.13, 0.23, 0.09), mat, class_root)
    for tier in TIERS:
        tier_collection = get_or_create_collection(f"{class_name}_{tier}", class_root)
        marker = add_mesh_guide(f"{class_name}_{tier}_SilhouetteMarker", (0, 0.02, 2.42), (0.34, 0.12, 0.08), mat, tier_collection)
        marker.hide_render = True


def create_export_metadata():
    scene = bpy.context.scene
    scene["HW_pipeline"] = "Blender/Neural4D -> Substance 3D Painter -> FBX/OBJ -> Unreal Engine 5.8"
    scene["HW_asset_status"] = "SCAFFOLD_ONLY"
    scene["HW_target_renderer"] = "Unreal Engine 5.8"
    scene["HW_texture_policy"] = "PBR: BaseColor / Normal / Roughness / Metallic / AO"
    scene["HW_units"] = "meters"
    scene["HW_export_rule"] = "Only export approved authored assets; scaffold guides are not final art."


def build():
    root = get_or_create_collection(ROOT)
    for category in CATEGORIES:
        get_or_create_collection(category.upper(), root)

    create_export_metadata()
    character_collection = root.children.get("CHARACTERS")
    for class_name in CLASSES:
        create_character_scaffold(character_collection, class_name)

    scene = bpy.context.scene
    scene["HW_class_count"] = len(CLASSES)
    scene["HW_tier_count"] = len(TIERS)
    print("Honour War production scaffold ready. Refine authored assets next; do not ship guides.")


if __name__ == "__main__":
    build()
