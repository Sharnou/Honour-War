import bpy
import math
import os

# Honour War SS (SUPER SHAMBION) production asset generator.
# Pipeline contract: Blender -> Substance 3D Painter handoff -> GLB/GLTF -> Godot 4.7.x.
# This intentionally does NOT create a player-selectable character class.

OUT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../assets/3d/generated/ss"))
OUT_FILE = os.path.join(OUT_DIR, "SS_SuperShambion.glb")


def mat(name, color, metallic=0.0, rough=0.45, emission=None):
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes.get("Principled BSDF")
    b.inputs["Base Color"].default_value = (*color, 1.0)
    b.inputs["Metallic"].default_value = metallic
    b.inputs["Roughness"].default_value = rough
    if emission:
        b.inputs["Emission Color"].default_value = (*emission, 1.0)
        b.inputs["Emission Strength"].default_value = 4.0
    return m


def finish(obj, material, bevel=0.04):
    obj.data.materials.append(material)
    if bevel and obj.type == "MESH":
        mod = obj.modifiers.new("SSProductionBevel", "BEVEL")
        mod.width = bevel
        mod.segments = 3
    if obj.type == "MESH":
        for poly in obj.data.polygons:
            poly.use_smooth = True
    return obj


def sphere(name, loc, scale, material):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=48, ring_count=32, location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return finish(obj, material, 0.0)


def cube(name, loc, scale, material, bevel=0.05):
    bpy.ops.mesh.primitive_cube_add(location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return finish(obj, material, bevel)


def cyl(name, loc, radius, depth, material):
    bpy.ops.mesh.primitive_cylinder_add(vertices=48, radius=radius, depth=depth, location=loc)
    obj = bpy.context.object
    obj.name = name
    return finish(obj, material, 0.025)


def torus(name, loc, major, minor, material):
    bpy.ops.mesh.primitive_torus_add(major_radius=major, minor_radius=minor, major_segments=64, minor_segments=20, location=loc)
    obj = bpy.context.object
    obj.name = name
    return finish(obj, material, 0.0)


def clear():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)


def build():
    clear()
    armor = mat("SS_Armor", (0.16, 0.035, 0.075), 0.72, 0.24)
    armor2 = mat("SS_Armor_Dark", (0.045, 0.012, 0.025), 0.78, 0.28)
    steel = mat("SS_Steel", (0.34, 0.39, 0.47), 0.90, 0.18)
    gold = mat("SS_Gold", (0.82, 0.58, 0.18), 0.86, 0.16)
    skin = mat("SS_Skin", (0.62, 0.31, 0.22), 0.0, 0.42)
    hair = mat("SS_Hair", (0.012, 0.008, 0.018), 0.0, 0.28)
    glow = mat("SS_Aura", (1.0, 0.45, 0.05), 0.15, 0.16, (1.0, 0.35, 0.03))

    root = bpy.data.objects.new("SS_SuperShambion", None)
    bpy.context.collection.objects.link(root)
    root["class"] = "SS (SUPER SHAMBION)"
    root["rental_only"] = True
    root["max_level"] = 250
    root["signature_skill"] = "Asura Strike"
    root["supports_follow"] = True
    root["supports_heal"] = True
    root["supports_fight"] = True

    finish(sphere("Torso", (0, 0, 1.50), (0.50, 0.32, 0.70), armor2), armor2, 0.0)
    cube("ChestArmor", (0, -0.31, 1.58), (0.43, 0.08, 0.46), armor, 0.08)
    cube("ChestCore", (0, -0.40, 1.58), (0.13, 0.025, 0.16), glow, 0.015)
    cyl("WaistArmor", (0, 0, 1.04), 0.47, 0.16, gold)

    for x in (-0.24, 0.24):
        sphere("Leg", (x, 0, 0.56), (0.19, 0.19, 0.51), armor)
        sphere("Boot", (x, -0.11, 0.15), (0.24, 0.25, 0.25), steel)
        cube("BootTrim", (x, -0.34, 0.17), (0.17, 0.025, 0.045), gold, 0.01)

    for x in (-0.62, 0.62):
        sphere("Arm", (x, 0, 1.48), (0.15, 0.15, 0.47), armor2)
        sphere("Gauntlet", (x, -0.03, 1.10), (0.19, 0.19, 0.25), steel)
        sphere("Hand", (x, -0.07, 0.84), (0.13, 0.13, 0.13), skin)
        sphere("Shoulder", (x, 0, 1.83), (0.25, 0.29, 0.19), armor)

    cyl("Neck", (0, 0, 2.04), 0.14, 0.22, skin)
    sphere("Head", (0, 0, 2.39), (0.39, 0.35, 0.44), skin)
    sphere("Hair", (0, 0.03, 2.60), (0.44, 0.38, 0.28), hair)
    cube("HairFringe", (0, -0.31, 2.47), (0.38, 0.10, 0.10), hair, 0.025)

    eye_white = mat("SS_EyeWhite", (0.95, 0.93, 0.84), 0.0, 0.25)
    for x in (-0.135, 0.135):
        sphere("Eye", (x, -0.345, 2.42), (0.058, 0.025, 0.067), eye_white)
        sphere("EyeGlow", (x, -0.371, 2.42), (0.026, 0.010, 0.032), glow)

    torus("Crown", (0, 0, 2.88), 0.44, 0.04, gold)
    sphere("CrownCore", (0, -0.02, 2.94), (0.11, 0.08, 0.14), glow)
    for i in range(8):
        a = math.radians(i * 45.0)
        sphere("AuraNode", (math.cos(a) * 0.78, math.sin(a) * 0.78, 1.48), (0.045, 0.045, 0.045), glow)

    # Distinctive Asura gauntlet and back crest.
    cube("AsuraGauntlet", (0.74, -0.10, 1.28), (0.18, 0.22, 0.30), steel, 0.06)
    for i in range(3):
        cube("AsuraFinger", (0.78 + i * 0.065, -0.29, 1.20), (0.025, 0.08, 0.16), gold, 0.01)
    cube("BackCrest", (0, 0.38, 1.65), (0.32, 0.08, 0.52), armor, 0.04)
    torus("CoreRing", (0, -0.42, 1.58), 0.16, 0.025, glow)

    for obj in bpy.context.scene.objects:
        if obj != root and obj.parent is None:
            obj.parent = root

    root.select_set(True)
    bpy.context.view_layer.objects.active = root
    os.makedirs(OUT_DIR, exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=OUT_FILE, export_format="GLB", export_apply=True)
    print("HONOUR WAR SS PRODUCTION ASSET:", OUT_FILE)


if __name__ == "__main__":
    build()
