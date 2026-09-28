#!/usr/bin/env python3
"""Build Honour War's canonical SharnouEngine runtime asset plan.

The generator consumes the existing gameplay catalog and creates deterministic,
valid glTF 2.0 scene containers. It never fabricates KTX2/AVIF bytes: those
binary payloads must be produced by registered Sharnou-IDE/SharnouEngine codec
adapters. Unity, Unreal, Blender, Visual Studio and MSBuild are not used.
"""
from __future__ import annotations

import argparse
import base64
import json
from pathlib import Path
from typing import Any

RUNTIME_ROOT = Path("Build/Runtime/Generated")
SCENE_ROOT = Path("assets/3d/generated")
TEXTURE_ROOT = Path("assets/3d/textures")
UI_ROOT = Path("assets/ui/generated")

# Deterministic triangle bootstrap: positions followed by uint16 indices.
BOOTSTRAP_GEOMETRY = "AAAAvwAAAAAAAAAAAAAAPwAAAAAAAAAAAAAAAAAAgD8AAAAAAAABAAIA"


def read_catalog(path: Path) -> dict[str, Any]:
    raw = json.loads(path.read_text(encoding="utf-8"))
    if isinstance(raw, dict) and isinstance(raw.get("content"), str):
        return json.loads(raw["content"])
    return raw


def safe_id(value: str) -> str:
    out = "".join(c.lower() if c.isalnum() else "_" for c in value).strip("_")
    return out or "asset"


def stable_asset_id(kind: str, item: dict[str, Any]) -> str:
    return f"{kind}/{safe_id(str(item.get('id', item.get('name', 'unknown'))))}"


def gltf_scene(name: str, role: str, material_texture: str) -> dict[str, Any]:
    """Return a valid glTF scene with an engine-owned KTX2 material binding."""
    return {
        "asset": {"version": "2.0", "generator": "SharnouEngine Honour War Runtime Generator"},
        "extensionsUsed": ["KHR_texture_basisu"],
        "scene": 0,
        "scenes": [{"name": name, "nodes": [0]}],
        "nodes": [{"name": name, "mesh": 0}],
        "meshes": [{
            "name": f"{name}_bootstrap_mesh",
            "primitives": [{
                "attributes": {"POSITION": 0},
                "indices": 1,
                "material": 0
            }]
        }],
        "buffers": [{"uri": f"data:application/octet-stream;base64,{BOOTSTRAP_GEOMETRY}", "byteLength": 42}],
        "bufferViews": [
            {"buffer": 0, "byteOffset": 0, "byteLength": 36, "target": 34962},
            {"buffer": 0, "byteOffset": 36, "byteLength": 6, "target": 34963}
        ],
        "accessors": [
            {"bufferView": 0, "componentType": 5126, "count": 3, "type": "VEC3", "min": [-0.5, 0.0, 0.0], "max": [0.5, 1.0, 0.0]},
            {"bufferView": 1, "componentType": 5123, "count": 3, "type": "SCALAR", "min": [0], "max": [2]}
        ],
        "images": [{"uri": material_texture, "mimeType": "image/ktx2"}],
        "textures": [{"source": 0}],
        "materials": [{
            "name": f"{name}_material",
            "pbrMetallicRoughness": {"baseColorTexture": {"index": 0}, "metallicFactor": 0.0, "roughnessFactor": 0.72},
            "extras": {
                "sharnou_role": role,
                "canonical_texture": material_texture,
                "texture_policy": "KTX2/Basis Universal via KHR_texture_basisu"
            }
        }],
        "extras": {
            "engine": "SharnouEngine",
            "project": "honour-war",
            "runtime_role": role,
            "authoring": "Sharnou-IDE",
            "graphics_target": "HD 3D MMORPG/ARPG",
            "bootstrap_geometry": True,
            "final_art_policy": "replace bootstrap geometry with authored SharnouEngine model while retaining canonical asset identity"
        }
    }


def write_json(path: Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def main() -> int:
    p = argparse.ArgumentParser(description="Generate Honour War SharnouEngine runtime descriptors")
    p.add_argument("catalog", type=Path, nargs="?", default=Path("data/honour_war_content_catalog.json"))
    p.add_argument("--output", type=Path, default=RUNTIME_ROOT / "honour_war_runtime_asset_plan.json")
    args = p.parse_args()

    catalog = read_catalog(args.catalog)
    collections = {
        "characters": "character",
        "monsters": "monster",
        "maps": "map",
        "equipment": "equipment",
        "cards": "card",
        "pets": "pet",
        "pet_equipment": "pet_equipment"
    }

    plan: list[dict[str, Any]] = []
    for collection, role in collections.items():
        for item in catalog.get(collection, []):
            catalog_id = str(item.get("id", item.get("name", "unknown")))
            name = str(item.get("name", catalog_id))
            stem = safe_id(catalog_id)
            scene_rel = (SCENE_ROOT / f"{stem}.gltf").as_posix()
            texture_rel = (TEXTURE_ROOT / f"{stem}.ktx2").as_posix()
            ui_rel = (UI_ROOT / f"{stem}.avif").as_posix()
            plan.append({
                "asset_id": stable_asset_id(role, item),
                "catalog_id": catalog_id,
                "name": name,
                "role": role,
                "scene": scene_rel,
                "texture_ktx2": texture_rel,
                "ui_avif": ui_rel,
                "render_target": "HD_3D_MMO_ARPG",
                "engine": "SharnouEngine",
                "authoring_controller": "Sharnou-IDE"
            })
            write_json(Path(scene_rel), gltf_scene(name, role, texture_rel))

    manifest = {
        "schema": "honour-war.runtime-asset-plan.v1",
        "project": "honour-war",
        "engine": "SharnouEngine",
        "architecture": "GFC-inspired MMORPG/ARPG runtime + SharnouEngine systems",
        "authoring": "Sharnou-IDE",
        "runtime_formats": {
            "scene": ".gltf",
            "texture_3d": ".ktx2",
            "ui_2d": ".avif",
            "gltf_texture_extension": "KHR_texture_basisu"
        },
        "no_external_engine_toolchain": True,
        "assets": plan,
        "counts": {k: len(catalog.get(k, [])) for k in collections},
        "scene_count": len(plan),
        "binary_codec_status": "required Sharnou-IDE/SharnouEngine KTX2/AVIF codec adapters are authoritative; missing codecs must fail closed rather than generate fake files",
        "bootstrap_status": "glTF scene containers include valid bootstrap geometry so runtime loading can be tested before final authored meshes are installed"
    }
    write_json(args.output, manifest)
    print(f"[SharnouRuntimeGenerator] PASS scenes={len(plan)} output={args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
