import bpy
import math
import os
from mathutils import Vector

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../assets/3d/generated/monsters"))
FAMILIES = [
    "Poring", "Goblin", "Wolf", "Skeleton", "Zombie", "Orc",
    "Mantis", "Golem", "Evil Druid", "Dragon", "Bloody Knight"
]


def make_mat(name, rgba, metallic=0.0, roughness=0.6):
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = rgba
        bsdf.inputs["Metallic"].default_value = metallic
        bsdf.inputs["Roughness"].default_value = roughness
    return m


def clear():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)


def smooth(o):
    if o.type == "MESH":
        for p in o.data.polygons:
            p.use_smooth = True


def bevel(o, amount=0.05):
    if o.type != "MESH":
        return
    mod = o.modifiers.new("SoftEdges", "BEVEL")
    mod.width = amount
    mod.segments = 3


def sphere(name, loc, scale, material):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=48, ring_count=32, location=loc)
    o = bpy.context.object
    o.name = name
    o.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    o.data.materials.append(material)
    smooth(o)
    return o


def cube(name, loc, scale, material):
    bpy.ops.mesh.primitive_cube_add(location=loc)
    o = bpy.context.object
    o.name = name
    o.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    o.data.materials.append(material)
    bevel(o, min(scale) * 0.35)
    return o


def cone(name, loc, radius1, radius2, depth, material, vertices=48):
    bpy.ops.mesh.primitive_cone_add(vertices=vertices, radius1=radius1, radius2=radius2, depth=depth, location=loc)
    o = bpy.context.object
    o.name = name
    o.data.materials.append(material)
    smooth(o)
    return o


def build(name):
    family = name
    base_colors = {
        "Poring": (0.14, 0.48, 0.95, 1), "Goblin": (0.20, 0.48, 0.18, 1),
        "Wolf": (0.22, 0.24, 0.28, 1), "Skeleton": (0.74, 0.68, 0.54, 1),
        "Zombie": (0.28, 0.42, 0.30, 1), "Orc": (0.34, 0.52, 0.16, 1),
        "Mantis": (0.20, 0.58, 0.28, 1), "Golem": (0.38, 0.39, 0.42, 1),
        "Evil Druid": (0.16, 0.26, 0.18, 1), "Dragon": (0.62, 0.13, 0.10, 1),
        "Bloody Knight": (0.20, 0.06, 0.08, 1),
    }
    skin = make_mat(family + "_Body", base_colors[family], 0.08, 0.62)
    dark = make_mat(family + "_Dark", tuple(max(0.02, c * 0.42) for c in base_colors[family][:3]) + (1,), 0.05, 0.74)
    eye = make_mat(family + "_Eye", (0.95, 0.16, 0.08, 1), 0.15, 0.24)
    metal = make_mat(family + "_Metal", (0.30, 0.34, 0.39, 1), 0.82, 0.28)
    root = bpy.data.objects.new("HW_Monster_" + family.replace(" ", "_"), None)
    bpy.context.collection.objects.link(root)

    if family == "Poring":
        body = sphere("Body", (0, 0, 0.45), (0.72, 0.72, 0.55), skin); body.parent = root
        crown = cone("Crown", (0, 0, 1.04), 0.18, 0.02, 0.55, dark); crown.parent = root
    elif family in ("Wolf", "Orc", "Zombie", "Goblin"):
        body = sphere("Body", (0, 0, 0.82), (0.56, 0.38, 0.68), skin); body.parent = root
        head = sphere("Head", (0, -0.22, 1.55), (0.38, 0.32, 0.36), skin); head.parent = root
        for x in (-0.42, 0.42):
            leg = sphere("Leg", (x, 0, 0.40), (0.17, 0.18, 0.45), dark); leg.parent = root
        for x in (-0.13, 0.13):
            e = sphere("Eye", (x, -0.50, 1.58), (0.055, 0.035, 0.06), eye); e.parent = root
        if family == "Wolf":
            for x in (-0.28, 0.28):
                ear = cone("Ear", (x, -0.18, 1.85), 0.15, 0.02, 0.36, dark); ear.parent = root
    elif family == "Mantis":
        thorax = sphere("Thorax", (0, 0, 0.90), (0.42, 0.32, 0.55), skin); thorax.parent = root
        head = sphere("Head", (0, -0.18, 1.48), (0.30, 0.24, 0.28), dark); head.parent = root
        for x in (-0.62, 0.62):
            arm = cube("ScytheArm", (x * 0.62, -0.02, 1.08), (0.12, 0.08, 0.55), skin); arm.parent = root
            arm.rotation_euler[1] = math.radians(42 if x > 0 else -42)
    elif family == "Golem":
        body = cube("Body", (0, 0, 0.95), (0.56, 0.44, 0.78), skin); body.parent = root
        head = cube("Head", (0, 0, 1.90), (0.40, 0.36, 0.34), dark); head.parent = root
        for x in (-0.72, 0.72):
            arm = cube("Arm", (x, 0, 1.02), (0.20, 0.24, 0.72), skin); arm.parent = root
        for x in (-0.28, 0.28):
            eye_obj = sphere("Eye", (x, -0.38, 1.96), (0.06, 0.04, 0.06), eye); eye_obj.parent = root
    elif family == "Skeleton":
        bones = make_mat("SkeletonBone", (0.78, 0.73, 0.62, 1), 0.0, 0.80)
        head = sphere("Skull", (0, 0, 1.82), (0.38, 0.34, 0.40), bones); head.parent = root
        spine = cube("Spine", (0, 0, 1.10), (0.12, 0.12, 0.58), bones); spine.parent = root
        for x in (-0.45, 0.45):
            arm = cube("Arm", (x, 0, 1.18), (0.08, 0.08, 0.52), bones); arm.parent = root
            arm.rotation_euler[1] = math.radians(45 if x > 0 else -45)
        for x in (-0.20, 0.20):
            leg = cube("Leg", (x, 0, 0.45), (0.08, 0.08, 0.55), bones); leg.parent = root
    elif family == "Evil Druid":
        robe = cone("Robe", (0, 0, 0.95), 0.62, 0.44, 1.6, dark); robe.parent = root
        hood = cone("Hood", (0, 0, 1.95), 0.45, 0.15, 0.80, skin); hood.parent = root
        staff = cube("Staff", (0.64, 0, 1.25), (0.06, 0.06, 0.82), metal); staff.parent = root
    elif family == "Dragon":
        body = sphere("Body", (0, 0, 1.00), (0.72, 0.46, 0.68), skin); body.parent = root
        neck = sphere("Neck", (0, -0.10, 1.62), (0.32, 0.30, 0.62), skin); neck.parent = root
        head = sphere("Head", (0, -0.34, 2.12), (0.46, 0.38, 0.40), dark); head.parent = root
        for x in (-0.58, 0.58):
            wing = cone("Wing", (x, 0.08, 1.42), 0.42, 0.05, 1.10, skin); wing.parent = root
            wing.rotation_euler[1] = math.radians(65 if x > 0 else -65)
        for x in (-0.18, 0.18):
            horn = cone("Horn", (x, -0.32, 2.57), 0.12, 0.02, 0.42, metal); horn.parent = root
    else:
        body = cube("ArmorBody", (0, 0, 1.05), (0.52, 0.38, 0.72), dark); body.parent = root
        helm = sphere("Helm", (0, 0, 1.95), (0.42, 0.38, 0.42), metal); helm.parent = root
        for x in (-0.62, 0.62):
            shoulder = sphere("Shoulder", (x, 0, 1.65), (0.22, 0.30, 0.18), skin); shoulder.parent = root
        sword = cube("Sword", (0.78, -0.02, 1.35), (0.06, 0.06, 0.72), metal); sword.parent = root

    return root


def export(root, path):
    bpy.ops.object.select_all(action="DESELECT")
    stack = [root]
    while stack:
        o = stack.pop()
        o.select_set(True)
        stack.extend(list(o.children))
    bpy.context.view_layer.objects.active = root
    os.makedirs(os.path.dirname(path), exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=True, export_materials="EXPORT", export_apply=True)
    bpy.ops.object.select_all(action="DESELECT")


def main():
    for family in FAMILIES:
        clear()
        root = build(family)
        export(root, os.path.join(ROOT, "monster_" + family.replace(" ", "_") + ".glb"))
    print("Generated monster GLBs in", ROOT)


if __name__ == "__main__":
    main()
