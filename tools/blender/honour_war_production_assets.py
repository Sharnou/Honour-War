import bpy
import math
import os
from mathutils import Vector

# Honour War production asset generator.
# Run with Blender 4.x in background mode to build production FBX assets.
# Pipeline: Visual RAG -> Blender/Neural4D -> Substance 3D Painter -> FBX/OBJ -> Unreal Engine 5.8.

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../assets/3d/generated"))

CLASSES = {
    "Warrior": {"accent": (0.68, 0.18, 0.08, 1), "weapon": "Sword", "pet": "Wolf"},
    "Mage": {"accent": (0.36, 0.20, 0.85, 1), "weapon": "Staff", "pet": "ArcaneOrb"},
    "Archer": {"accent": (0.18, 0.62, 0.25, 1), "weapon": "Bow", "pet": "Falcon"},
    "Thief": {"accent": (0.78, 0.16, 0.48, 1), "weapon": "Dagger", "pet": "Panther"},
    "Acolyte": {"accent": (0.90, 0.70, 0.18, 1), "weapon": "Mace", "pet": "PoringAngel"},
    "Merchant": {"accent": (0.12, 0.58, 0.78, 1), "weapon": "Hammer", "pet": "Clockwork"},
}

TIERS = ["Foundation", "Specialization", "Advanced", "Mastery", "Transcendence"]


def mat(name, color, metallic=0.0, roughness=0.55):
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
        for p in obj.data.polygons:
            p.use_smooth = True


def bevel(obj, amount=0.06, segments=3):
    if obj.type != "MESH":
        return
    mod = obj.modifiers.new("EdgeSoftening", "BEVEL")
    mod.width = amount
    mod.segments = segments


def uv(obj):
    if obj.type != "MESH":
        return
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=1.15192)
    bpy.ops.object.mode_set(mode="OBJECT")
    obj.select_set(False)


def sphere(name, loc, scale, material, segments=48, rings=32):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, location=loc)
    o = bpy.context.object
    o.name = name
    o.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    o.data.materials.append(material)
    smooth(o)
    return o


def capsule(name, loc, radius, depth, material):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=40, ring_count=28, location=loc)
    o = bpy.context.object
    o.name = name
    o.scale = (radius, radius, depth * 0.5)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    o.data.materials.append(material)
    smooth(o)
    return o


def cube(name, loc, scale, material, bevel_amount=0.05):
    bpy.ops.mesh.primitive_cube_add(location=loc)
    o = bpy.context.object
    o.name = name
    o.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    o.data.materials.append(material)
    bevel(o, bevel_amount, 3)
    return o


def cylinder(name, loc, radius, depth, material, vertices=48):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=loc)
    o = bpy.context.object
    o.name = name
    o.data.materials.append(material)
    bevel(o, 0.025, 2)
    smooth(o)
    return o


def curve_beam(name, points, bevel_depth, material):
    c = bpy.data.curves.new(name, "CURVE")
    c.dimensions = "3D"
    c.bevel_depth = bevel_depth
    c.bevel_resolution = 4
    spl = c.splines.new("BEZIER")
    spl.bezier_points.add(len(points) - 1)
    for bp, co in zip(spl.bezier_points, points):
        bp.co = co
        bp.handle_left_type = "AUTO"
        bp.handle_right_type = "AUTO"
    o = bpy.data.objects.new(name, c)
    bpy.context.collection.objects.link(o)
    o.data.materials.append(material)
    return o


def make_rig_root(name):
    arm = bpy.data.armatures.new(name + "_Rig")
    arm_obj = bpy.data.objects.new(name + "_Rig", arm)
    bpy.context.collection.objects.link(arm_obj)
    bpy.context.view_layer.objects.active = arm_obj
    arm_obj.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    b = arm.edit_bones.new("root")
    b.head = (0, 0, 0)
    b.tail = (0, 0, 1)
    spine = arm.edit_bones.new("spine")
    spine.head = (0, 0, 1)
    spine.tail = (0, 0, 2.0)
    spine.parent = b
    head = arm.edit_bones.new("head")
    head.head = (0, 0, 2.0)
    head.tail = (0, 0, 2.7)
    head.parent = spine
    bpy.ops.object.mode_set(mode="OBJECT")
    arm_obj.select_set(False)
    return arm_obj


def build_hero(class_id, tier):
    data = CLASSES[class_id]
    accent = mat(class_id + "_Accent", data["accent"], 0.25, 0.40)
    accent_dark = mat(class_id + "_AccentDark", tuple(max(0.03, c * 0.45) for c in data["accent"][:3]) + (1,), 0.35, 0.43)
    skin = mat("Hero_Skin", (0.68, 0.39, 0.26, 1), 0.0, 0.50)
    hair = mat("Hero_Hair", (0.025, 0.018, 0.035, 1), 0.0, 0.38)
    metal = mat("Hero_Metal", (0.32, 0.36, 0.42, 1), 0.82, 0.23)
    trim = mat("Hero_Trim", (0.80, 0.57, 0.20, 1), 0.78, 0.22)
    cloth = mat("Hero_Cloth", (0.12, 0.13, 0.18, 1), 0.05, 0.72)
    root = bpy.data.objects.new("HW_" + class_id + "_" + tier, None)
    bpy.context.collection.objects.link(root)

    torso = capsule("Torso", (0, 0, 1.45), 0.48, 1.4, cloth); torso.parent = root
    chest = cube("ChestArmor", (0, -0.01, 1.55), (0.48, 0.28, 0.55), accent, 0.10); chest.parent = root
    belt = cylinder("Belt", (0, -0.02, 1.03), 0.45, 0.13, trim); belt.rotation_euler[0] = math.radians(90); belt.parent = root

    for x in (-0.24, 0.24):
        leg = capsule("Leg", (x, 0, 0.56), 0.18, 1.10, accent_dark); leg.parent = root
        boot = capsule("Boot", (x, -0.06, 0.12), 0.22, 0.46, metal); boot.parent = root
    for x in (-0.62, 0.62):
        arm = capsule("Arm", (x, 0, 1.50), 0.14, 0.95, cloth); arm.parent = root
        gaunt = capsule("Gauntlet", (x, -0.02, 1.08), 0.17, 0.45, metal); gaunt.parent = root

    neck = cylinder("Neck", (0, 0, 2.03), 0.14, 0.22, skin); neck.parent = root
    head = sphere("Head", (0, 0, 2.38), (0.37, 0.34, 0.43), skin); head.parent = root
    hair_obj = sphere("Hair", (0, 0.02, 2.55), (0.40, 0.36, 0.25), hair); hair_obj.parent = root
    for x in (-0.13, 0.13):
        eye = sphere("Eye", (x, -0.33, 2.40), (0.045, 0.025, 0.055), mat(class_id + "_Eye", data["accent"], 0.1, 0.25)); eye.parent = root

    # Tier silhouette progression.
    if tier in ("Specialization", "Advanced", "Mastery", "Transcendence"):
        for x in (-0.62, 0.62):
            shoulder = sphere("Shoulder", (x, 0, 1.88), (0.22, 0.30, 0.16), accent); shoulder.parent = root
    if tier in ("Advanced", "Mastery", "Transcendence"):
        back = cube("Backplate", (0, 0.30, 1.55), (0.38, 0.06, 0.46), metal, 0.04); back.parent = root
        trim_obj = curve_beam("BackTrim", [(-0.3, 0.37, 1.55), (0, 0.37, 1.85), (0.3, 0.37, 1.55)], 0.025, trim); trim_obj.parent = root
    if tier in ("Mastery", "Transcendence"):
        crest = cylinder("Crest", (0, -0.02, 2.92), 0.11, 0.28, accent); crest.parent = root
        crest.rotation_euler[0] = math.radians(90)
    if tier == "Transcendence":
        halo = curve_beam("TranscendentAura", [(0, -0.28, 2.75), (0.5, -0.05, 2.55), (0, 0.25, 2.75), (-0.5, -0.05, 2.55), (0, -0.28, 2.75)], 0.035, trim); halo.parent = root

    # Weapon silhouette.
    weapon_mat = metal
    if data["weapon"] == "Sword":
        blade = cube("SwordBlade", (0.88, -0.02, 1.48), (0.055, 0.05, 0.62), weapon_mat, 0.02); blade.parent = root
        hilt = cube("SwordHilt", (0.88, -0.02, 0.87), (0.16, 0.06, 0.045), trim, 0.02); hilt.parent = root
    elif data["weapon"] == "Staff":
        staff = cylinder("Staff", (0.88, 0.02, 1.50), 0.045, 1.55, weapon_mat); staff.parent = root
        gem = sphere("StaffGem", (0.88, 0.02, 2.30), (0.10, 0.10, 0.10), accent); gem.parent = root
    elif data["weapon"] == "Bow":
        bow = curve_beam("Bow", [(0.72, 0, 2.05), (1.00, 0, 1.65), (0.72, 0, 1.20)], 0.045, accent); bow.parent = root
        string = curve_beam("BowString", [(0.72, 0, 2.05), (0.72, 0, 1.65), (0.72, 0, 1.20)], 0.012, trim); string.parent = root
    elif data["weapon"] == "Dagger":
        dagger = cube("Dagger", (0.85, -0.03, 1.20), (0.055, 0.045, 0.42), metal, 0.02); dagger.rotation_euler[1] = math.radians(-25); dagger.parent = root
    elif data["weapon"] == "Mace":
        shaft = cylinder("MaceShaft", (0.86, -0.02, 1.23), 0.045, 0.9, wood := mat("MaceWood", (0.24, 0.13, 0.08, 1), 0.0, 0.70)); shaft.parent = root
        head_obj = sphere("MaceHead", (0.86, -0.02, 1.72), (0.17, 0.17, 0.17), metal); head_obj.parent = root
    else:
        hammer = cube("Hammer", (0.87, -0.02, 1.28), (0.11, 0.14, 0.38), metal, 0.04); hammer.parent = root
        hammer_head = cube("HammerHead", (0.87, -0.02, 1.72), (0.28, 0.16, 0.16), trim, 0.04); hammer_head.parent = root

    rig = make_rig_root(root.name)
    rig.parent = root
    return root


def build_pet(class_id, species):
    accent = mat(class_id + "_Pet", CLASSES[class_id]["accent"], 0.18, 0.48)
    dark = mat(class_id + "_PetDark", (0.08, 0.09, 0.12, 1), 0.15, 0.55)
    root = bpy.data.objects.new("HW_Pet_" + species, None)
    bpy.context.collection.objects.link(root)
    body = sphere("PetBody", (0, 0, 0.65), (0.55, 0.42, 0.46), accent); body.parent = root
    if species == "Falcon":
        for x in (-0.48, 0.48):
            wing = curve_beam("Wing", [(0, 0, 0.85), (x * 0.8, 0.02, 0.65), (x, 0, 0.35)], 0.11, accent); wing.parent = root
        head = sphere("FalconHead", (0, -0.05, 1.10), (0.26, 0.24, 0.26), dark); head.parent = root
    elif species == "Wolf" or species == "Panther":
        head = sphere("PetHead", (0, -0.30, 0.92), (0.34, 0.30, 0.30), dark); head.parent = root
        for x in (-0.23, 0.23):
            leg = capsule("PetLeg", (x, 0, 0.28), 0.12, 0.50, dark); leg.parent = root
    else:
        orb = sphere("PetCore", (0, -0.02, 0.72), (0.24, 0.24, 0.24), accent); orb.parent = root
    return root


def export_fbx(root, path):
    bpy.ops.object.select_all(action="DESELECT")
    stack = [root]
    while stack:
        node = stack.pop()
        node.select_set(True)
        stack.extend(list(node.children))
    bpy.context.view_layer.objects.active = root
    os.makedirs(os.path.dirname(path), exist_ok=True)
    bpy.ops.export_scene.fbx(
        filepath=path,
        use_selection=True,
        apply_unit_scale=True,
        apply_scale_options="FBX_SCALE_ALL",
    )
    bpy.ops.object.select_all(action="DESELECT")


def main():
    clear_scene()
    out_root = ROOT
    os.makedirs(out_root, exist_ok=True)

    for class_id in CLASSES:
        for tier in TIERS:
            clear_scene()
            hero = build_hero(class_id, tier)
            export_fbx(hero, os.path.join(out_root, "characters", class_id, tier + ".fbx"))
        clear_scene()
        pet = build_pet(class_id, CLASSES[class_id]["pet"])
        export_fbx(pet, os.path.join(out_root, "pets", class_id + "_pet.fbx"))

    clear_scene()
    # Reusable town prop kit: lamp, tree, market stall, stone pillar, gate.
    stone = mat("TownStone", (0.28, 0.30, 0.32, 1), 0.08, 0.82)
    wood = mat("TownWood", (0.25, 0.11, 0.055, 1), 0.0, 0.75)
    leaf = mat("TownLeaf", (0.08, 0.30, 0.12, 1), 0.0, 0.92)
    lamp = bpy.data.objects.new("Town_Prop_Kit", None)
    bpy.context.collection.objects.link(lamp)
    pole = cylinder("LampPole", (0, 0, 1.25), 0.06, 2.5, stone); pole.parent = lamp
    globe = sphere("LampGlobe", (0, 0, 2.55), (0.15, 0.15, 0.18), mat("LampGlow", (0.95, 0.68, 0.18, 1), 0.05, 0.22)); globe.parent = lamp
    trunk = cylinder("TreeTrunk", (1.5, 0, 1.0), 0.20, 2.0, wood); trunk.parent = lamp
    crown = sphere("TreeCrown", (1.5, 0, 2.45), (1.05, 1.0, 1.25), leaf); crown.parent = lamp
    counter = cube("MarketCounter", (-1.8, 0, 0.75), (1.0, 0.45, 0.08), wood); counter.parent = lamp
    pillar = cylinder("StonePillar", (3.2, 0, 1.1), 0.30, 2.2, stone); pillar.parent = lamp
    export_fbx(lamp, os.path.join(out_root, "props", "town_prop_kit.fbx"))

    print("Honour War production assets generated under:", out_root)


if __name__ == "__main__":
    main()
