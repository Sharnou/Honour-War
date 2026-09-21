"""Honour War environment source/GLB builder.

Creates repeatable game-ready environment packages for every TeleportSystem map:
10 towns, 10 dungeons, and 10 fields. Geometry is organized for later sculpting and
Substance 3D Painter texturing, then exported as approved FBX/OBJ source for Unreal Engine 5.8.
"""

import bpy
import math
import os

OUTPUT_ROOT = bpy.path.abspath("//../../assets/3d/generated/environments")

MAPS = {
    0: ("Prontera", "town", 1200, 700), 1: ("Payon", "town", 1200, 700), 2: ("Geffen", "town", 1200, 700),
    3: ("Morroc", "town", 1200, 700), 4: ("Izlude", "town", 1200, 700), 5: ("Alberta", "town", 1200, 700),
    6: ("Comodo", "town", 1200, 700), 7: ("Aldebaran", "town", 1200, 700), 8: ("Lutie", "town", 1200, 700),
    9: ("Umbala", "town", 1200, 700),
    10: ("Prontera Sewer", "dungeon", 1400, 900), 11: ("Payon Cave", "dungeon", 1400, 900),
    12: ("Geffen Tower", "dungeon", 1400, 900), 13: ("Morroc Ruins", "dungeon", 1400, 900),
    14: ("Orc Dungeon", "dungeon", 1400, 900), 15: ("Ice Cave", "dungeon", 1400, 900),
    16: ("Clock Tower", "dungeon", 1400, 900), 17: ("Sunken Ship", "dungeon", 1400, 900),
    18: ("Hidden Forest", "dungeon", 1400, 900), 19: ("Ancient Catacombs", "dungeon", 1400, 900),
    20: ("Prontera Field", "field", 1600, 1000), 21: ("Payon Forest", "field", 1600, 1000),
    22: ("Geffen Plains", "field", 1600, 1000), 23: ("Morroc Desert", "field", 1600, 1000),
    24: ("Izlude Coast", "field", 1600, 1000), 25: ("Alberta Coast", "field", 1600, 1000),
    26: ("Comodo Jungle", "field", 1600, 1000), 27: ("Aldebaran Meadow", "field", 1600, 1000),
    28: ("Lutie Snowfield", "field", 1600, 1000), 29: ("Umbala Wilds", "field", 1600, 1000),
}


def mat(name, color, metallic=0.0, roughness=0.6):
    material = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    material.use_nodes = True
    bsdf = material.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    return material


def cube(name, location, scale, material):
    bpy.ops.mesh.primitive_cube_add(location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(material)
    bevel = obj.modifiers.new("SoftEdges", "BEVEL")
    bevel.width = min(scale) * 0.08
    bevel.segments = 3
    return obj


def cylinder(name, location, radius, depth, material):
    bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=radius, depth=depth, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(material)
    bevel = obj.modifiers.new("SoftEdges", "BEVEL")
    bevel.width = radius * 0.08
    bevel.segments = 2
    return obj


def cone(name, location, radius1, radius2, depth, material):
    bpy.ops.mesh.primitive_cone_add(vertices=32, radius1=radius1, radius2=radius2, depth=depth, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(material)
    return obj


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)


def add_tree(x, y, height, foliage, trunk):
    cylinder("Tree_Trunk", (x, y, height * 0.35), height * 0.10, height * 0.70, trunk)
    cone("Tree_Crown", (x, y, height * 0.85), height * 0.42, 0.08, height * 1.10, foliage)


def add_rock(x, y, size, stone):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=size, location=(x, y, size * 0.65))
    obj = bpy.context.object
    obj.name = "Rock"
    obj.scale = (1.2, 0.9, 0.75)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(stone)


def build_map(map_id):
    name, map_type, width, height = MAPS[map_id]
    clear_scene()
    ground = mat("MAT_Ground", (0.14, 0.20, 0.10), roughness=0.95)
    road = mat("MAT_Road", (0.30, 0.24, 0.18), roughness=0.88)
    wall = mat("MAT_Wall", (0.34, 0.36, 0.39), roughness=0.72)
    roof = mat("MAT_Roof", (0.20, 0.08, 0.05), roughness=0.65)
    wood = mat("MAT_Wood", (0.22, 0.12, 0.07), roughness=0.82)
    stone = mat("MAT_Stone", (0.27, 0.29, 0.31), roughness=0.9)
    water = mat("MAT_Water", (0.06, 0.20, 0.34), metallic=0.08, roughness=0.18)
    snow = mat("MAT_Snow", (0.72, 0.78, 0.84), roughness=0.94)
    sand = mat("MAT_Sand", (0.62, 0.46, 0.25), roughness=0.98)
    foliage = mat("MAT_Foliage", (0.08, 0.29, 0.10), roughness=0.95)
    dark = mat("MAT_Dark", (0.035, 0.04, 0.05), roughness=1.0)

    root = bpy.data.objects.new("HW_Environment_%02d" % map_id, None)
    bpy.context.collection.objects.link(root)
    root["map_id"] = map_id
    root["map_name"] = name
    root["map_type"] = map_type
    root["pipeline"] = "Blender/Neural4D -> Substance 3D Painter -> FBX/OBJ -> Unreal Engine 5.8"

    if "Desert" in name or "Morroc" in name:
        ground_mat = sand
    elif "Snow" in name or "Ice" in name or "Lutie" in name:
        ground_mat = snow
    elif "Coast" in name or "Ship" in name:
        ground_mat = road
    elif "Sewer" in name or "Cave" in name or "Tower" in name or "Ruins" in name or "Dungeon" in name or "Catacombs" in name:
        ground_mat = dark
    else:
        ground_mat = ground

    half_w, half_h = width * 0.5, height * 0.5
    cube("Terrain_Base", (half_w, half_h, -0.08), (half_w, half_h, 0.08), ground_mat).parent = root

    if map_type == "town":
        cube("Main_Road_X", (half_w, half_h, 0.03), (half_w * 0.92, 22, 0.04), road).parent = root
        cube("Main_Road_Y", (half_w, half_h, 0.035), (22, half_h * 0.90, 0.045), road).parent = root
        for ix in range(4):
            for iy in range(3):
                x = 150 + ix * 300
                y = 120 + iy * 210
                body = cube("Town_House", (x, y, 55), (70, 55, 55), wall)
                body.parent = root
                top = cone("Town_Roof", (x, y, 120), 82, 8, 70, roof)
                top.parent = root
        fountain = cylinder("Town_Fountain", (half_w, half_h, 10), 35, 20, stone)
        fountain.parent = root
        pool = cylinder("Town_Fountain_Water", (half_w, half_h, 21), 29, 3, water)
        pool.parent = root
    elif map_type == "field":
        for i in range(28):
            x = 50 + ((i * 137) % int(max(100, width - 100)))
            y = 50 + ((i * 211) % int(max(100, height - 100)))
            if "Coast" in name:
                base = cube("Coast_Waterline", (x, height - 55, 0.01), (80, 55, 0.02), water)
                base.parent = root
            elif "Desert" in name:
                add_rock(x, y, 18 + (i % 4) * 5, stone)
            elif "Snowfield" in name:
                add_rock(x, y, 16 + (i % 3) * 4, snow)
            else:
                add_tree(x, y, 60 + (i % 4) * 10, foliage, wood)
        for i in range(6):
            rock = add_rock(100 + i * 220, 80 + (i % 2) * 780, 28, stone)
            if rock is None:
                pass
    else:
        for i in range(9):
            x = 120 + i * 150
            pillar = cylinder("Dungeon_Pillar", (x, 180 + (i % 2) * 360, 85), 24, 170, stone)
            pillar.parent = root
        for i in range(7):
            wall_piece = cube("Dungeon_Wall", (220 + i * 150, 70 + (i % 3) * 280, 75), (60, 25, 75), wall)
            wall_piece.parent = root
        for i in range(10):
            rock = add_rock(100 + (i * 131) % int(max(100, width - 200)), 100 + (i * 173) % int(max(100, height - 200)), 14 + (i % 4) * 4, stone)
            if rock is not None:
                rock.parent = root

    os.makedirs(OUTPUT_ROOT, exist_ok=True)
    safe = "map_%02d_%s" % (map_id, name.lower().replace(" ", "_"))
    blend_path = os.path.join(OUTPUT_ROOT, safe + ".blend")
    fbx_path = os.path.join(OUTPUT_ROOT, safe + ".fbx")
    bpy.ops.wm.save_as_mainfile(filepath=blend_path)
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.fbx(filepath=fbx_path, use_selection=True, apply_unit_scale=True)
    return fbx_path


if __name__ == "__main__":
    for map_id in MAPS:
        build_map(map_id)
    print("HONOUR WAR ENVIRONMENT FBX SOURCE BUILD COMPLETE: %d maps" % len(MAPS))
