"""
Honour War HD Asset Builder

Production rule:
Blender -> Substance 3D Painter -> GLB/GLTF -> Godot 4

This script is a repeatable starting point for production asset generation.
It intentionally creates a clean game-ready source scene rather than making
Godot responsible for modeling. Artists can replace the generated geometry
with sculpted/high-poly meshes and keep the same object names, material slots,
armature and export contract.

Run inside Blender's Scripting workspace.
"""

import bpy
import math
import os
from mathutils import Vector

OUTPUT_ROOT = bpy.path.abspath("//../../assets/3d")
CHARACTER_ROOT = os.path.join(OUTPUT_ROOT, "characters")


def clear_generated():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    for datablocks in (bpy.data.meshes, bpy.data.curves, bpy.data.materials, bpy.data.armatures):
        for block in list(datablocks):
            if block.users == 0:
                datablocks.remove(block)


def material(name, base_color, metallic=0.0, roughness=0.5):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*base_color, 1.0)
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    return mat


def add_uv_sphere(name, location, scale, mat):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=48, ring_count=24, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    bpy.ops.object.shade_smooth()
    return obj


def add_cylinder(name, location, radius, depth, mat):
    bpy.ops.mesh.primitive_cylinder_add(vertices=48, radius=radius, depth=depth, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(mat)
    bpy.ops.object.shade_smooth()
    bevel = obj.modifiers.new("EdgeSoftening", 'BEVEL')
    bevel.width = 0.035
    bevel.segments = 3
    return obj


def add_armature():
    bpy.ops.object.armature_add(enter_editmode=True, location=(0, 0, 0))
    armature = bpy.context.object
    armature.name = "HW_HeroArmature"
    armature.data.name = "HW_HeroSkeleton"
    armature.data.display_type = 'BBONE'
    bones = armature.data.edit_bones
    root = bones[0]
    root.name = "root"
    root.head = (0, 0, 0)
    root.tail = (0, 0, 0.25)

    def bone(name, head, tail, parent=None):
        b = bones.new(name)
        b.head = head
        b.tail = tail
        if parent:
            b.parent = bones.get(parent)
        return b

    bone("pelvis", (0, 0, 0.25), (0, 0, 0.8), "root")
    bone("spine", (0, 0, 0.8), (0, 0, 1.45), "pelvis")
    bone("chest", (0, 0, 1.45), (0, 0, 1.85), "spine")
    bone("neck", (0, 0, 1.85), (0, 0, 2.1), "chest")
    bone("head", (0, 0, 2.1), (0, 0, 2.45), "neck")
    bone("upper_arm.L", (-0.25, 0, 1.7), (-0.75, 0, 1.35), "chest")
    bone("forearm.L", (-0.75, 0, 1.35), (-0.95, 0, 0.95), "upper_arm.L")
    bone("hand.L", (-0.95, 0, 0.95), (-1.0, 0, 0.75), "forearm.L")
    bone("upper_arm.R", (0.25, 0, 1.7), (0.75, 0, 1.35), "chest")
    bone("forearm.R", (0.75, 0, 1.35), (0.95, 0, 0.95), "upper_arm.R")
    bone("hand.R", (0.95, 0, 0.95), (1.0, 0, 0.75), "forearm.R")
    bone("thigh.L", (-0.18, 0, 0.25), (-0.35, 0, -0.55), "pelvis")
    bone("shin.L", (-0.35, 0, -0.55), (-0.35, 0, -1.25), "thigh.L")
    bone("foot.L", (-0.35, 0, -1.25), (-0.35, -0.28, -1.45), "shin.L")
    bone("thigh.R", (0.18, 0, 0.25), (0.35, 0, -0.55), "pelvis")
    bone("shin.R", (0.35, 0, -0.55), (0.35, 0, -1.25), "thigh.R")
    bone("foot.R", (0.35, 0, -1.25), (0.35, -0.28, -1.45), "shin.R")
    bpy.ops.object.mode_set(mode='POSE')
    bpy.ops.object.mode_set(mode='OBJECT')
    return armature


def create_hero(class_id="Warrior"):
    clear_generated()
    os.makedirs(CHARACTER_ROOT, exist_ok=True)

    skin = material("MAT_Skin_PBR", (0.55, 0.25, 0.16), roughness=0.48)
    cloth = material("MAT_Cloth_PBR", (0.08, 0.10, 0.14), roughness=0.72)
    metal = material("MAT_Armor_Metal_PBR", (0.12, 0.16, 0.20), metallic=0.85, roughness=0.28)
    accent = material("MAT_Class_Accent_PBR", (0.10, 0.30, 0.65), metallic=0.25, roughness=0.36)
    hair = material("MAT_Hair_PBR", (0.035, 0.025, 0.02), roughness=0.62)

    root = bpy.data.objects.new("HW_Hero", None)
    bpy.context.collection.objects.link(root)

    pelvis = add_uv_sphere("Body_Pelvis", (0, 0, 1.0), (0.43, 0.28, 0.30), cloth)
    torso = add_uv_sphere("Body_Torso", (0, 0, 1.45), (0.48, 0.30, 0.62), cloth)
    chest = add_uv_sphere("Armor_Chest", (0, -0.02, 1.55), (0.52, 0.33, 0.48), metal)
    head = add_uv_sphere("Head", (0, 0, 2.30), (0.36, 0.34, 0.39), skin)
    hair_obj = add_uv_sphere("Hair", (0, -0.02, 2.49), (0.39, 0.36, 0.25), hair)

    for side in (-1, 1):
        add_uv_sphere("Shoulder_%s" % ("L" if side < 0 else "R"), (side * 0.52, 0, 1.72), (0.22, 0.27, 0.24), accent)
        add_cylinder("UpperArm_%s" % ("L" if side < 0 else "R"), (side * 0.67, 0, 1.36), 0.14, 0.62, cloth)
        add_uv_sphere("Glove_%s" % ("L" if side < 0 else "R"), (side * 0.78, -0.02, 1.02), (0.15, 0.14, 0.16), metal)
        add_uv_sphere("Boot_%s" % ("L" if side < 0 else "R"), (side * 0.22, -0.05, 0.24), (0.20, 0.31, 0.34), metal)

    weapon = add_cylinder("Weapon_Handle", (0.82, 0, 1.28), 0.055, 1.55, metal)
    weapon.rotation_euler[1] = math.radians(18)
    blade = add_uv_sphere("Weapon_Blade", (0.96, 0, 2.02), (0.12, 0.055, 0.55), accent)
    blade.rotation_euler[1] = math.radians(18)

    armature = add_armature()
    for obj in list(bpy.context.scene.objects):
        if obj.type == 'MESH' and obj.parent is None:
            obj.parent = root
        if obj.type == 'MESH':
            modifier = obj.modifiers.new("HW_Armature", 'ARMATURE')
            modifier.object = armature
            obj.parent = root
    armature.parent = root

    root["asset_id"] = "hero_%s" % class_id.lower()
    root["pipeline"] = "Blender -> Substance 3D Painter -> GLB/GLTF -> Godot 4"
    root["material_contract"] = "BaseColor, Normal, Roughness, Metallic, AO, Emissive"

    output = os.path.join(CHARACTER_ROOT, "hero_%s_source.blend" % class_id.lower())
    bpy.ops.wm.save_as_mainfile(filepath=output)
    return root


if __name__ == "__main__":
    create_hero("Warrior")
    print("Honour War HD source generated. Sculpt/detail in Blender, texture in Substance 3D Painter, then export GLB/GLTF to assets/3d/characters.")
