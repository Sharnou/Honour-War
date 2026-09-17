#!/usr/bin/env python3
"""Embed and verify deterministic PBR texture maps in generated Honour War GLBs.

This is a Blender texture-authoring pass, not a claim that Substance 3D Painter
was executed. It preserves the existing geometry while replacing flat material
colors with compact, embedded base-color and roughness maps.

Every exported GLB is immediately reopened as a binary glTF document and
verified to contain embedded image bufferViews plus valid base-color and
metallic-roughness texture references that resolve to those embedded images.
A successful process therefore cannot silently produce the old
"no embedded texture images found" or dangling-texture failures.
"""

from __future__ import annotations

import hashlib
import json
import math
import os
import struct
from pathlib import Path

import bpy

ROOT = Path(os.path.abspath(os.path.join(os.path.dirname(__file__), "../../assets/3d/generated")))
TEXTURE_SIZE = 256
MAGIC = b"glTF"
JSON_CHUNK = 0x4E4F534A


def clamp(value: float) -> float:
    return max(0.0, min(1.0, value))


def seed_for(text: str) -> int:
    return int(hashlib.sha256(text.encode("utf-8")).hexdigest()[:8], 16)


def make_pixels(name: str, color, roughness: float):
    seed = seed_for(name)
    phase_a = (seed % 997) / 997.0 * math.tau
    phase_b = ((seed // 997) % 991) / 991.0 * math.tau
    r, g, b = color[:3]
    base = bpy.data.images.new(name=name, width=TEXTURE_SIZE, height=TEXTURE_SIZE, alpha=False)
    rough = bpy.data.images.new(name=name + "_Roughness", width=TEXTURE_SIZE, height=TEXTURE_SIZE, alpha=False)

    base_pixels = [0.0] * (TEXTURE_SIZE * TEXTURE_SIZE * 4)
    rough_pixels = [0.0] * (TEXTURE_SIZE * TEXTURE_SIZE * 4)
    i = 0
    for y in range(TEXTURE_SIZE):
        v = y / float(TEXTURE_SIZE - 1)
        for x in range(TEXTURE_SIZE):
            u = x / float(TEXTURE_SIZE - 1)
            n1 = math.sin((u * 14.0 + phase_a) + math.sin(v * 9.0 + phase_b) * 0.8)
            n2 = math.sin((u * 43.0 + v * 31.0) + phase_b * 1.7)
            n3 = math.sin((u * 121.0 - v * 87.0) + phase_a * 2.3)
            variation = 1.0 + n1 * 0.045 + n2 * 0.018 + n3 * 0.008
            rr = clamp(r * variation)
            gg = clamp(g * variation)
            bb = clamp(b * variation)
            micro = clamp(roughness + n1 * 0.035 + n2 * 0.018)
            base_pixels[i:i + 4] = (rr, gg, bb, 1.0)
            rough_pixels[i:i + 4] = (micro, micro, micro, 1.0)
            i += 4
    base.pixels.foreach_set(base_pixels)
    rough.pixels.foreach_set(rough_pixels)
    return base, rough


def ensure_uv(obj):
    if obj.type != "MESH" or not obj.data:
        return
    if len(obj.data.uv_layers) > 0:
        return
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    try:
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.mesh.select_all(action="SELECT")
        bpy.ops.uv.smart_project(angle_limit=math.radians(66.0), island_margin=0.025)
        bpy.ops.object.mode_set(mode="OBJECT")
    except Exception:
        try:
            bpy.ops.object.mode_set(mode="OBJECT")
        except Exception:
            pass
    finally:
        obj.select_set(False)


def original_color(bsdf):
    value = bsdf.inputs.get("Base Color")
    if value is None:
        return (0.6, 0.6, 0.6, 1.0)
    return tuple(value.default_value)


def _has_image_link(bsdf, socket_name: str) -> bool:
    socket = bsdf.inputs.get(socket_name)
    if socket is None or not socket.is_linked:
        return False
    for link in socket.links:
        node = link.from_node
        if node.type == "TEX_IMAGE" and node.image is not None:
            if node.image.packed_file is not None:
                return True
    return False


def enhance_material(mat, asset_key: str):
    if mat is None:
        return
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    bsdf = nodes.get("Principled BSDF")
    if bsdf is None:
        return

    name_lower = mat.name.lower()
    if any(token in name_lower for token in ("glow", "emission", "eye", "iris")):
        return

    # Idempotent: preserve valid packed texture links on subsequent repair runs.
    if _has_image_link(bsdf, "Base Color") and _has_image_link(bsdf, "Roughness"):
        return

    color = original_color(bsdf)
    rough_socket = bsdf.inputs.get("Roughness")
    rough_value = rough_socket.default_value if rough_socket else 0.5
    texture_key = asset_key + ":" + mat.name
    base, rough = make_pixels(
        "HW_BC_" + hashlib.sha256(texture_key.encode()).hexdigest()[:12],
        color,
        float(rough_value),
    )
    base.pack()
    rough.pack()

    tex = nodes.new("ShaderNodeTexImage")
    tex.name = "HW_BaseColor_Texture"
    tex.image = base
    tex.interpolation = "Linear"
    tex.extension = "REPEAT"

    rough_tex = nodes.new("ShaderNodeTexImage")
    rough_tex.name = "HW_Roughness_Texture"
    rough_tex.image = rough
    rough_tex.image.colorspace_settings.name = "Non-Color"
    rough_tex.interpolation = "Linear"
    rough_tex.extension = "REPEAT"

    links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    if rough_socket is not None:
        links.new(rough_tex.outputs["Color"], rough_socket)


def read_glb_json(path: Path) -> dict:
    data = path.read_bytes()
    if len(data) < 20 or data[:4] != MAGIC:
        raise RuntimeError(f"{path}: exported file is not a valid GLB2 header")
    version, total_length = struct.unpack_from("<II", data, 4)
    if version != 2 or total_length != len(data):
        raise RuntimeError(f"{path}: invalid GLB2 header/version/length after export")
    chunk_length, chunk_type = struct.unpack_from("<II", data, 12)
    if chunk_type != JSON_CHUNK:
        raise RuntimeError(f"{path}: first GLB chunk is not JSON")
    raw = data[20:20 + chunk_length].rstrip(b" \t\r\n\x00")
    return json.loads(raw.decode("utf-8"))


def verify_exported_pbr(path: Path) -> None:
    """Verify the serialized GLB, not only the in-memory Blender scene."""
    doc = read_glb_json(path)
    images = doc.get("images", [])
    if not images:
        raise RuntimeError(f"{path}: post-export verification found no embedded texture images")
    if any(isinstance(image, dict) and "uri" in image for image in images):
        raise RuntimeError(f"{path}: post-export verification found an external image URI")
    if any(
        not isinstance(image, dict) or "bufferView" not in image
        for image in images
    ):
        raise RuntimeError(f"{path}: post-export verification found a non-embedded image")

    textures = doc.get("textures", [])
    if not textures:
        raise RuntimeError(f"{path}: post-export verification found no glTF texture objects")
    for index, texture in enumerate(textures):
        if not isinstance(texture, dict):
            raise RuntimeError(f"{path}: post-export verification found malformed texture {index}")
        source = texture.get("source")
        if not isinstance(source, int) or source < 0 or source >= len(images):
            raise RuntimeError(f"{path}: texture {index} does not resolve to an embedded image")
        image = images[source]
        if not isinstance(image, dict) or "uri" in image or "bufferView" not in image:
            raise RuntimeError(f"{path}: texture {index} resolves to a non-embedded image")

    for material in doc.get("materials", []):
        if not isinstance(material, dict):
            raise RuntimeError(f"{path}: malformed material in exported GLB")
        name = str(material.get("name", ""))
        lower_name = name.lower()
        if any(token in lower_name for token in ("glow", "emission", "eye", "iris")):
            continue
        pbr = material.get("pbrMetallicRoughness")
        if not isinstance(pbr, dict):
            raise RuntimeError(f"{path}: material {name!r} has no PBR block after export")
        for label in ("baseColorTexture", "metallicRoughnessTexture"):
            entry = pbr.get(label)
            index = entry.get("index") if isinstance(entry, dict) else None
            if not isinstance(index, int) or index < 0 or index >= len(textures):
                raise RuntimeError(
                    f"{path}: material {name!r} lost its {label} texture after export"
                )
            source = textures[index].get("source") if isinstance(textures[index], dict) else None
            if not isinstance(source, int) or source < 0 or source >= len(images):
                raise RuntimeError(
                    f"{path}: material {name!r} {label} does not resolve to an embedded image"
                )


def enhance_file(path: Path):
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for block in (
        bpy.data.meshes,
        bpy.data.curves,
        bpy.data.materials,
        bpy.data.images,
        bpy.data.armatures,
    ):
        for item in list(block):
            if item.users == 0:
                block.remove(item)

    bpy.ops.import_scene.gltf(filepath=str(path))
    for obj in list(bpy.context.scene.objects):
        ensure_uv(obj)
    imported_materials = list(bpy.data.materials)
    for mat in imported_materials:
        enhance_material(mat, path.relative_to(ROOT).as_posix())

    # Preserve the exact GLB location and embed generated images inside GLB.
    bpy.ops.export_scene.gltf(
        filepath=str(path),
        export_format="GLB",
        export_image_format="AUTO",
        export_keep_originals=False,
        use_selection=False,
    )
    verify_exported_pbr(path)
    print("PBR texture pass + serialized verification: PASS:", path)


def main():
    files = sorted(ROOT.rglob("*.glb"))
    print("Honour War embedded PBR texture pass: {} GLBs".format(len(files)))
    if len(files) != 53:
        raise SystemExit(f"Expected exactly 53 generated GLBs, found {len(files)}")
    for path in files:
        enhance_file(path)
    print("Honour War PBR texture pass complete: all 53 GLBs verified with embedded PBR textures")


if __name__ == "__main__":
    main()
