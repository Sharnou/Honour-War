import bpy
import math
import os

# Honour War character production generator.
# Approved pipeline: Blender/Neural4D -> FBX/OBJ -> Unreal Engine 5.8.
# This generator creates playable hero and companion assets only.

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../assets/3d/generated"))
CLASSES = {
    "Warrior": ((0.68, 0.18, 0.08, 1), "Sword", "Wolf"),
    "Mage": ((0.36, 0.20, 0.85, 1), "Staff", "ArcaneOrb"),
    "Archer": ((0.18, 0.62, 0.25, 1), "Bow", "Falcon"),
    "Thief": ((0.78, 0.16, 0.48, 1), "Dagger", "Panther"),
    "Acolyte": ((0.90, 0.70, 0.18, 1), "Mace", "PoringAngel"),
    "Merchant": ((0.12, 0.58, 0.78, 1), "Hammer", "Clockwork"),
    "Ranger": ((0.20, 0.44, 0.30, 1), "Bow", "Falcon"),
}
TIERS = ("Foundation", "Specialization", "Advanced", "Mastery", "Transcendence")


def material(name, color, metallic=0.0, roughness=0.55):
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.diffuse_color = color
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = color
        bsdf.inputs["Metallic"].default_value = metallic
        bsdf.inputs["Roughness"].default_value = roughness
    return m


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for block in (bpy.data.meshes, bpy.data.curves, bpy.data.materials, bpy.data.cameras, bpy.data.lights):
        for item in list(block):
            if item.users == 0:
                block.remove(item)


def smooth(obj):
    if obj.type == "MESH":
        for poly in obj.data.polygons:
            poly.use_smooth = True


def bevel(obj, amount=0.05):
    if obj.type != "MESH":
        return
    mod = obj.modifiers.new("EdgeSoftening", "BEVEL")
    mod.width = amount
    mod.segments = 3


def sphere(name, loc, scale, mat):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=32, ring_count=20, location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    smooth(obj)
    return obj


def capsule(name, loc, radius, depth, mat):
    return sphere(name, loc, (radius, radius, depth * 0.5), mat)


def cube(name, loc, scale, mat):
    bpy.ops.mesh.primitive_cube_add(location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    bevel(obj)
    return obj


def cylinder(name, loc, radius, depth, mat):
    bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=radius, depth=depth, location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(mat)
    bevel(obj, 0.025)
    smooth(obj)
    return obj


def build_hero(class_name, tier):
    accent_color, weapon, _ = CLASSES[class_name]
    accent = material(class_name + "_Accent", accent_color, 0.25, 0.40)
    dark = material(class_name + "_Dark", tuple(max(0.03, c * 0.45) for c in accent_color[:3]) + (1,), 0.30, 0.45)
    skin = material("Hero_Skin", (0.68, 0.39, 0.26, 1), 0.0, 0.50)
    metal = material("Hero_Metal", (0.32, 0.36, 0.42, 1), 0.82, 0.23)
    cloth = material("Hero_Cloth", (0.12, 0.13, 0.18, 1), 0.05, 0.72)
    root = bpy.data.objects.new("HW_" + class_name + "_" + tier, None)
    bpy.context.collection.objects.link(root)

    parts = [
        capsule("Torso", (0, 0, 1.45), 0.48, 1.4, cloth),
        cube("ChestArmor", (0, -0.01, 1.55), (0.48, 0.28, 0.55), accent),
        cylinder("Belt", (0, 0, 1.03), 0.45, 0.13, metal),
        capsule("Head", (0, 0, 2.38), 0.36, 0.86, skin),
        sphere("Hair", (0, 0.02, 2.58), (0.39, 0.35, 0.23), dark),
    ]
    for x in (-0.24, 0.24):
        parts.extend([capsule("Leg", (x, 0, 0.56), 0.18, 1.10, dark), capsule("Boot", (x, -0.06, 0.12), 0.22, 0.46, metal)])
    for x in (-0.62, 0.62):
        parts.extend([capsule("Arm", (x, 0, 1.50), 0.14, 0.95, cloth), capsule("Gauntlet", (x, -0.02, 1.08), 0.17, 0.45, metal)])
    for obj in parts:
        obj.parent = root

    if tier != "Foundation":
        for x in (-0.62, 0.62):
            shoulder = sphere("Shoulder", (x, 0, 1.88), (0.22, 0.30, 0.16), accent)
            shoulder.parent = root
    if tier in ("Advanced", "Mastery", "Transcendence"):
        back = cube("Backplate", (0, 0.30, 1.55), (0.38, 0.06, 0.46), metal)
        back.parent = root
    if tier in ("Mastery", "Transcendence"):
        crest = cylinder("Crest", (0, -0.02, 2.92), 0.11, 0.28, accent)
        crest.rotation_euler[0] = math.radians(90)
        crest.parent = root

    if weapon == "Sword":
        blade = cube("SwordBlade", (0.88, -0.02, 1.48), (0.055, 0.05, 0.62), metal)
        blade.parent = root
    elif weapon == "Staff":
        staff = cylinder("Staff", (0.88, 0.02, 1.50), 0.045, 1.55, metal)
        staff.parent = root
    elif weapon == "Bow":
        bow = cube("Bow", (0.88, 0, 1.62), (0.045, 0.06, 0.55), accent)
        bow.rotation_euler[1] = math.radians(18)
        bow.parent = root
    elif weapon == "Dagger":
        dagger = cube("Dagger", (0.85, -0.03, 1.20), (0.055, 0.045, 0.42), metal)
        dagger.rotation_euler[1] = math.radians(-25)
        dagger.parent = root
    elif weapon == "Mace":
        shaft = cylinder("MaceShaft", (0.86, -0.02, 1.23), 0.045, 0.9, metal)
        head = sphere("MaceHead", (0.86, -0.02, 1.72), (0.17, 0.17, 0.17), metal)
        shaft.parent = root
        head.parent = root
    else:
        hammer = cube("Hammer", (0.87, -0.02, 1.28), (0.11, 0.14, 0.38), metal)
        hammer.parent = root

    return root


def build_companion(class_name, species):
    accent_color = CLASSES[class_name][0]
    accent = material(class_name + "_Companion", accent_color, 0.15, 0.48)
    root = bpy.data.objects.new("HW_Companion_" + species, None)
    bpy.context.collection.objects.link(root)
    body = sphere("CompanionBody", (0, 0, 0.65), (0.55, 0.42, 0.46), accent)
    head = sphere("CompanionHead", (0, -0.30, 0.92), (0.34, 0.30, 0.30), accent)
    body.parent = root
    head.parent = root
    return root


def export_asset(root, filename):
    os.makedirs(ROOT, exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    root.select_set(True)
    for child in root.children_recursive:
        child.select_set(True)
    bpy.context.view_layer.objects.active = root
    base = os.path.join(ROOT, filename)
    bpy.ops.export_scene.fbx(filepath=base + ".fbx", use_selection=True, add_leaf_bones=False)
    bpy.ops.wm.obj_export(filepath=base + ".obj", export_selected_objects=True)


def main():
    clear_scene()
    for class_name, (_, _, companion) in CLASSES.items():
        for tier in TIERS:
            root = build_hero(class_name, tier)
            export_asset(root, "HW_" + class_name + "_" + tier)
            bpy.data.objects.remove(root, do_unlink=True)
        root = build_companion(class_name, companion)
        export_asset(root, "HW_Companion_" + companion)
        bpy.data.objects.remove(root, do_unlink=True)
    print("HONOUR_WAR_CHARACTER_ASSET_PASS: FBX/OBJ character assets generated.")


if __name__ == "__main__":
    main()
