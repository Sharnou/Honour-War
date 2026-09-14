import bpy
import math
import os
from mathutils import Vector

# Honour War production-grade visual asset pass.
# Mandatory upstream: tools/visual_rag/honour_war_visual_rag.py
# Art path: Visual RAG -> Blender -> Substance 3D Painter handoff -> GLB/GLTF -> Godot 4.
# This generator creates high-detail, original fantasy MMORPG silhouettes and PBR-ready materials.

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../assets/3d/generated"))
CLASSES = {
    "Warrior": ((0.62, 0.16, 0.08, 1), "Sword"),
    "Mage": ((0.35, 0.22, 0.78, 1), "Staff"),
    "Archer": ((0.15, 0.58, 0.25, 1), "Bow"),
    "Thief": ((0.70, 0.12, 0.42, 1), "Dagger"),
    "Acolyte": ((0.86, 0.66, 0.16, 1), "Mace"),
    "Merchant": ((0.10, 0.48, 0.70, 1), "Hammer"),
}
TIERS = [("Foundation", 0), ("Specialization", 1), ("Advanced", 2), ("Mastery", 3), ("Transcendence", 4)]


def material(name, color, metallic=0.0, roughness=0.5, emission=None):
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = color
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    if emission:
        bsdf.inputs["Emission Color"].default_value = emission
        bsdf.inputs["Emission Strength"].default_value = 2.5
    return m


def clear():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for block in (bpy.data.meshes, bpy.data.curves, bpy.data.materials, bpy.data.armatures):
        for item in list(block):
            if item.users == 0:
                block.remove(item)


def finish(o, mat, bevel=0.04, smooth=True):
    o.data.materials.append(mat)
    if bevel and o.type == "MESH":
        mod = o.modifiers.new("ProductionBevel", "BEVEL")
        mod.width = bevel
        mod.segments = 3
    if smooth and o.type == "MESH":
        for p in o.data.polygons:
            p.use_smooth = True
    return o


def uv(name, loc, scale, mat):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=48, ring_count=32, location=loc)
    o = bpy.context.object
    o.name = name
    o.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return finish(o, mat, 0.0, True)


def cube(name, loc, scale, mat, bevel=0.06):
    bpy.ops.mesh.primitive_cube_add(location=loc)
    o = bpy.context.object
    o.name = name
    o.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return finish(o, mat, bevel, False)


def cyl(name, loc, radius, depth, mat, verts=48):
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=radius, depth=depth, location=loc)
    o = bpy.context.object
    o.name = name
    return finish(o, mat, 0.025, True)


def cone(name, loc, radius, depth, mat, verts=32):
    bpy.ops.mesh.primitive_cone_add(vertices=verts, radius1=radius, radius2=0.0, depth=depth, location=loc)
    o = bpy.context.object
    o.name = name
    return finish(o, mat, 0.02, True)


def torus(name, loc, major, minor, mat):
    bpy.ops.mesh.primitive_torus_add(major_radius=major, minor_radius=minor, major_segments=64, minor_segments=16, location=loc)
    o = bpy.context.object
    o.name = name
    return finish(o, mat, 0.0, True)


def beam(name, points, radius, mat):
    curve = bpy.data.curves.new(name, "CURVE")
    curve.dimensions = "3D"
    curve.bevel_depth = radius
    curve.bevel_resolution = 5
    spline = curve.splines.new("BEZIER")
    spline.bezier_points.add(len(points) - 1)
    for bp, co in zip(spline.bezier_points, points):
        bp.co = co
        bp.handle_left_type = "AUTO"
        bp.handle_right_type = "AUTO"
    o = bpy.data.objects.new(name, curve)
    bpy.context.collection.objects.link(o)
    curve.materials.append(mat)
    return o


def parent_all(root):
    for o in list(bpy.context.scene.objects):
        if o != root and o.parent is None:
            o.parent = root


def hero(class_id, tier_name, tier):
    accent_color, weapon = CLASSES[class_id]
    accent = material(class_id + "_Accent", accent_color, 0.35, 0.34)
    accent_dark = material(class_id + "_Dark", tuple(max(0.025, c * 0.42) for c in accent_color[:3]) + (1,), 0.50, 0.38)
    steel = material("HW_Steel", (0.34, 0.39, 0.46, 1), 0.88, 0.20)
    steel_dark = material("HW_SteelDark", (0.09, 0.12, 0.16, 1), 0.80, 0.24)
    gold = material("HW_Gold", (0.78, 0.57, 0.19, 1), 0.82, 0.18)
    skin = material("HW_Skin", (0.72, 0.43, 0.30, 1), 0.0, 0.46)
    hair = material("HW_Hair", (0.035, 0.025, 0.05, 1), 0.0, 0.30)
    cloth = material("HW_Cloth", (0.075, 0.09, 0.13, 1), 0.03, 0.72)
    cape = material("HW_Cape", (0.34, 0.035, 0.07, 1), 0.0, 0.62)
    glow = material("HW_Glow", accent_color, 0.15, 0.18, accent_color)

    root = bpy.data.objects.new("HW_" + class_id + "_" + tier_name, None)
    bpy.context.collection.objects.link(root)

    finish(uv("Torso", (0, 0, 1.45), (0.47, 0.30, 0.67), cloth), cloth, 0.0)
    cube("ChestPlate", (0, -0.03, 1.56), (0.47, 0.27, 0.48), accent, 0.10)
    cube("ChestInset", (0, -0.32, 1.57), (0.25, 0.025, 0.27), steel_dark, 0.025)
    cyl("WaistGuard", (0, 0, 1.05), 0.45, 0.14, gold)
    for x in (-0.23, 0.23):
        finish(uv("Leg", (x, 0, 0.55), (0.18, 0.18, 0.50), accent_dark), accent_dark, 0.0)
        finish(uv("Boot", (x, -0.09, 0.13), (0.23, 0.24, 0.25), steel_dark), steel_dark, 0.0)
        cube("BootTrim", (x, -0.26, 0.16), (0.17, 0.025, 0.04), gold, 0.01)
    for x in (-0.60, 0.60):
        finish(uv("Arm", (x, 0, 1.45), (0.14, 0.14, 0.47), cloth), cloth, 0.0)
        finish(uv("Gauntlet", (x, -0.03, 1.07), (0.18, 0.18, 0.25), steel), steel, 0.0)
        finish(uv("Hand", (x, -0.06, 0.83), (0.13, 0.13, 0.13), skin), skin, 0.0)
    cyl("Neck", (0, 0, 2.02), 0.14, 0.22, skin)
    finish(uv("Head", (0, 0, 2.37), (0.38, 0.34, 0.43), skin), skin, 0.0)
    finish(uv("Hair", (0, 0.03, 2.57), (0.43, 0.37, 0.27), hair), hair, 0.0)
    cube("HairFringe", (0, -0.30, 2.45), (0.38, 0.10, 0.10), hair, 0.03)
    eye_white = material("HW_EyeWhite", (0.92, 0.92, 0.88, 1), 0, 0.28)
    eye = material(class_id + "_Eye", accent_color, 0.15, 0.20, accent_color)
    for x in (-0.13, 0.13):
        finish(uv("Eye", (x, -0.34, 2.39), (0.055, 0.028, 0.065), eye_white), eye_white, 0.0)
        finish(uv("Iris", (x, -0.365, 2.39), (0.026, 0.012, 0.032), eye), eye, 0.0)
    cube("Mouth", (0, -0.35, 2.19), (0.075, 0.012, 0.018), steel_dark, 0.005)

    if tier >= 1:
        for x in (-0.58, 0.58):
            finish(uv("Shoulder", (x, 0, 1.80), (0.24, 0.28, 0.18), accent), accent, 0.0)
        cube("BeltBuckle", (0, -0.33, 1.05), (0.11, 0.025, 0.11), gold, 0.02)
    if tier >= 2:
        cube("BackArmor", (0, 0.34, 1.55), (0.39, 0.07, 0.46), steel, 0.04)
        for x in (-0.34, 0.34):
            cube("ArmorRib", (x, -0.01, 1.60), (0.035, 0.08, 0.36), gold, 0.01)
    if tier >= 3:
        torus("CrownRing", (0, 0, 2.83), 0.43, 0.035, gold)
        cone("CrownGem", (0, -0.02, 2.95), 0.12, 0.28, glow, 6)
    if tier >= 4:
        beam("TranscendentCrest", [(-0.42, 0, 2.68), (0, -0.02, 3.12), (0.42, 0, 2.68)], 0.035, glow)
        for a in range(0, 360, 45):
            r = math.radians(a)
            uv("Aura", (math.cos(r) * 0.72, math.sin(r) * 0.72, 1.45), (0.035, 0.035, 0.035), glow)

    # Class-specific silhouette.
    if weapon == "Sword":
        cube("SwordBlade", (0.86, -0.02, 1.58), (0.055, 0.05, 0.68), steel, 0.018)
        cube("SwordEdge", (0.93, -0.02, 1.58), (0.012, 0.055, 0.64), glow, 0.005)
        cube("SwordGuard", (0.86, -0.02, 0.88), (0.18, 0.05, 0.045), gold, 0.02)
    elif weapon == "Staff":
        cyl("Staff", (0.86, 0, 1.50), 0.045, 1.65, steel_dark)
        uv("StaffOrb", (0.86, 0, 2.36), (0.15, 0.15, 0.15), glow)
        torus("StaffHalo", (0.86, 0, 2.36), 0.22, 0.025, gold)
    elif weapon == "Bow":
        beam("Bow", [(0.72, 0, 2.05), (1.02, 0, 1.60), (0.72, 0, 1.18)], 0.045, accent)
        beam("BowString", [(0.72, 0, 2.05), (0.72, 0, 1.18)], 0.012, gold)
        for i in range(4):
            cyl("Arrow", (-0.48 + i * 0.04, 0.18, 1.50), 0.012, 0.72, gold, 12)
    elif weapon == "Dagger":
        cube("Dagger", (0.88, -0.02, 1.25), (0.05, 0.045, 0.42), steel, 0.015)
        cube("DaggerGuard", (0.88, -0.02, 0.82), (0.12, 0.045, 0.035), gold, 0.01)
    elif weapon == "Mace":
        cyl("MaceHandle", (0.87, 0, 1.28), 0.045, 0.92, steel_dark)
        uv("MaceHead", (0.87, 0, 1.76), (0.18, 0.18, 0.18), steel)
        torus("MaceCrown", (0.87, 0, 1.76), 0.20, 0.025, gold)
    else:
        cube("HammerHandle", (0.87, 0, 1.30), (0.055, 0.055, 0.44), steel_dark, 0.02)
        cube("HammerHead", (0.87, 0, 1.76), (0.27, 0.15, 0.16), steel, 0.04)
        cube("HammerGem", (0.87, -0.16, 1.76), (0.07, 0.02, 0.07), glow, 0.01)

    # Cape and shoulder crest create a stronger silhouette than the prototype.
    cube("Cape", (0, 0.38, 1.35), (0.50, 0.05, 0.90), cape, 0.08)
    torus("ShoulderCrest", (0, -0.01, 1.83), 0.56, 0.025, gold)
    parent_all(root)
    return root


def pet(class_id, species):
    accent_color, _ = CLASSES[class_id]
    accent = material(class_id + "_PetAccent", accent_color, 0.18, 0.42)
    dark = material("HW_PetDark", (0.08, 0.10, 0.14, 1), 0.15, 0.55)
    gold = material("HW_PetGold", (0.78, 0.56, 0.18, 1), 0.75, 0.20)
    glow = material("HW_PetGlow", accent_color, 0.10, 0.20, accent_color)
    root = bpy.data.objects.new("HW_Pet_" + species, None)
    bpy.context.collection.objects.link(root)
    if species == "Falcon":
        uv("Body", (0, 0, 0.70), (0.52, 0.35, 0.35), accent)
        uv("Head", (0, -0.04, 1.05), (0.28, 0.25, 0.27), dark)
        cone("Beak", (0, -0.32, 1.05), 0.12, 0.28, gold, 4)
        for x in (-0.48, 0.48):
            beam("Wing", [(0, 0, 0.82), (x * 0.75, 0, 0.72), (x, 0, 0.34)], 0.11, accent)
        for x in (-0.10, 0.10): uv("Eye", (x, -0.26, 1.10), (0.045, 0.03, 0.045), glow)
    elif species in ("Wolf", "Panther"):
        uv("Body", (0, 0, 0.70), (0.62, 0.40, 0.44), accent)
        uv("Head", (0, -0.42, 0.95), (0.36, 0.32, 0.32), dark)
        for x in (-0.25, 0.25):
            cone("Ear", (x, -0.44, 1.30), 0.16, 0.42, dark, 4)
            uv("Eye", (x * 0.65, -0.69, 1.02), (0.055, 0.025, 0.055), glow)
            for z in (-0.22, 0.22):
                cyl("Leg", (x, 0, 0.34), 0.12, 0.55, dark, 20)
    elif species == "PoringAngel":
        uv("Body", (0, 0, 0.70), (0.60, 0.50, 0.56), accent)
        torus("Halo", (0, 0, 1.40), 0.48, 0.04, gold)
        for x in (-0.18, 0.18): uv("Eye", (x, -0.49, 0.82), (0.06, 0.03, 0.06), dark)
    else:
        uv("Core", (0, 0, 0.76), (0.48, 0.48, 0.48), glow)
        torus("RingA", (0, 0, 0.76), 0.62, 0.035, gold)
        torus("RingB", (0, 0, 0.76), 0.78, 0.025, glow)
    parent_all(root)
    return root


def export_root(root, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    for o in bpy.context.scene.objects:
        o.select_set(True)
    bpy.context.view_layer.objects.active = root
    bpy.ops.wm.gltf_export(filepath=path, export_format="GLB", export_materials="EXPORT", export_cameras=False, export_lights=False)


def build_all():
    os.makedirs(ROOT, exist_ok=True)
    # Heroes: exact runtime naming contract, 30 class/tier GLBs.
    for class_id in CLASSES:
        for tier_name, tier in TIERS:
            clear()
            root = hero(class_id, tier_name, tier)
            export_root(root, os.path.join(ROOT, "characters", class_id, tier_name + ".glb"))
    # Pets: class-specific contract plus shared species assets.
    for class_id, (_, _) in CLASSES.items():
        species = {"Warrior":"Wolf", "Mage":"ArcaneOrb", "Archer":"Falcon", "Thief":"Panther", "Acolyte":"PoringAngel", "Merchant":"Clockwork"}[class_id]
        clear()
        root = pet(class_id, species)
        export_root(root, os.path.join(ROOT, "pets", class_id + "_pet.glb"))
    for species in ["Falcon", "Wolf", "Panther", "PoringAngel", "ArcaneOrb", "Clockwork"]:
        clear()
        root = pet("Warrior", species)
        export_root(root, os.path.join(ROOT, "pets", species + ".glb"))
    clear()
    with open(os.path.join(ROOT, "VISUAL_MAX_BUILD.txt"), "w", encoding="utf-8") as f:
        f.write("Honour War Visual MAX assets generated by Blender.\n")
        f.write("30 class/tier hero GLBs + class pet GLBs + shared pet GLBs.\n")
        f.write("PBR-ready materials; final Substance 3D Painter texturing remains a production handoff stage.\n")


if __name__ == "__main__":
    build_all()
