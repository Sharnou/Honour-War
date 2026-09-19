#!/usr/bin/env python3
"""Strict serialized GLB material validation for Honour War.

This gate runs after Blender export and before Godot import. It rejects mesh
primitives without a valid material, invalid material indices, materials without
PBR data, and texture references that do not resolve to embedded images.
"""
from __future__ import annotations

import json
import struct
import sys
from pathlib import Path

MAGIC = b"glTF"
JSON_CHUNK = 0x4E4F534A


def read_json(path: Path) -> dict:
    data = path.read_bytes()
    if len(data) < 20 or data[:4] != MAGIC:
        raise RuntimeError(f"{path}: not a GLB2 file")
    version, total = struct.unpack_from("<II", data, 4)
    if version != 2 or total != len(data):
        raise RuntimeError(f"{path}: invalid GLB2 header")
    length, kind = struct.unpack_from("<II", data, 12)
    if kind != JSON_CHUNK:
        raise RuntimeError(f"{path}: first chunk is not JSON")
    return json.loads(data[20:20 + length].rstrip(b" \t\r\n\x00").decode("utf-8"))


def validate(path: Path) -> list[str]:
    doc = read_json(path)
    materials = doc.get("materials", [])
    meshes = doc.get("meshes", [])
    textures = doc.get("textures", [])
    images = doc.get("images", [])
    errors: list[str] = []

    for mi, material in enumerate(materials):
        if not isinstance(material, dict):
            errors.append(f"material[{mi}] is not an object")
            continue
        name = str(material.get("name", f"material[{mi}]"))
        pbr = material.get("pbrMetallicRoughness")
        if not isinstance(pbr, dict):
            errors.append(f"{name}: missing pbrMetallicRoughness")
            continue
        for key in ("baseColorTexture", "metallicRoughnessTexture"):
            ref = pbr.get(key)
            if ref is None:
                errors.append(f"{name}: missing {key}")
                continue
            ti = ref.get("index") if isinstance(ref, dict) else None
            if not isinstance(ti, int) or ti < 0 or ti >= len(textures):
                errors.append(f"{name}: invalid {key} texture index {ti!r}")
                continue
            source = textures[ti].get("source") if isinstance(textures[ti], dict) else None
            if not isinstance(source, int) or source < 0 or source >= len(images):
                errors.append(f"{name}: {key} does not resolve to an image")
                continue
            image = images[source]
            if not isinstance(image, dict) or "bufferView" not in image or "uri" in image:
                errors.append(f"{name}: {key} image is not embedded")

    for mesh_i, mesh in enumerate(meshes):
        primitives = mesh.get("primitives", []) if isinstance(mesh, dict) else []
        if not primitives:
            errors.append(f"mesh[{mesh_i}]: no primitives")
            continue
        for pi, primitive in enumerate(primitives):
            if not isinstance(primitive, dict):
                errors.append(f"mesh[{mesh_i}].primitive[{pi}]: not an object")
                continue
            if "material" not in primitive:
                errors.append(f"mesh[{mesh_i}].primitive[{pi}]: missing material assignment")
                continue
            material_i = primitive["material"]
            if not isinstance(material_i, int) or material_i < 0 or material_i >= len(materials):
                errors.append(f"mesh[{mesh_i}].primitive[{pi}]: invalid material index {material_i!r}")

    return errors


def main() -> int:
    root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("assets/3d/generated")
    files = sorted(root.rglob("*.glb"))
    if not files:
        print(f"ERROR: no GLBs found under {root}")
        return 1
    failed = False
    for path in files:
        errors = validate(path)
        if errors:
            failed = True
            print(f"FAIL: {path}")
            for error in errors:
                print(f"  - {error}")
        else:
            print(f"PASS: {path}")
    if failed:
        print("GLB primitive/material validation: FAILED")
        return 1
    print(f"GLB primitive/material validation: PASS ({len(files)} GLBs)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
