#!/usr/bin/env python3
"""Build Honour War's canonical runtime asset plan from the content catalog.

This generator is deliberately engine-owned: it does not invoke Unity, Unreal,
Blender, Visual Studio, MSBuild, or an external asset manager.  It converts the
existing gameplay catalog into deterministic SharnouEngine runtime descriptors
and glTF scene containers.  Binary KTX2/AVIF encoding is delegated to the
registered Sharnou-IDE codec adapters when they are available.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
from typing import Any

RUNTIME_ROOT = Path("Build/Runtime/Generated")
SCENE_ROOT = Path("assets/3d/generated")
TEXTURE_ROOT = Path("assets/3d/textures")
UI_ROOT = Path("assets/ui/generated")


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
    # Valid glTF 2.0 scene container with a deterministic placeholder mesh.
    # The SharnouEngine runtime can replace the mesh payload during authoring
    # while preserving the scene/material identity and KTX2 binding.
    return {
        "asset": {"version": "2.0", "generator": "SharnouEngine Honour War Runtime Generator"},
        "scene": 0,
        "scenes": [{"name": name, "nodes": [0]}],
        "nodes": [{"name": name, "mesh": 0}],
        "meshes": [{"name": f"{name}_mesh", "primitives": [{"attributes": {}}]}],
        "materials": [{
            "name": f"{name}_material",
            "extras": {
                "sharnou_role": role,
                "canonical_texture": material_texture,
                "texture_policy": "KTX2/Basis Universal via KHR_texture_basisu",
            },
        }],
        "extras": {
            "engine": "SharnouEngine",
            "project": "honour-war",
            "runtime_role": role,
            "authoring": "Sharnou-IDE",
            "graphics_target": "HD 3D MMORPG/ARPG",
        },
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
        "pet_equipment": "pet_equipment",
    }

    plan: list[dict[str, Any]] = []
    scene_paths: list[str] = []
    for collection, role in collections.items():
        for item in catalog.get(collection, []):
            sid = stable_asset_id(role, item)
            name = str(item.get("name", item.get("id", "unnamed")))
            scene_rel = (SCENE_ROOT / f"{safe_id(str(item.get('id', name)))}.gltf").as_posix()
            texture_rel = (TEXTURE_ROOT / f"{safe_id(str(item.get('id', name)))}.ktx2").as_posix()
            plan.append({
                "asset_id": sid,
                "catalog_id": item.get("id"),
                "name": name,
                "role": role,
                "scene": scene_rel,
                "texture_ktx2": texture_rel,
                "ui_avif": (UI_ROOT / f"{safe_id(str(item.get('id', name)))}.avif").as_posix(),
                "render_target": "HD_3D_MMO_ARPG",
                "engine": "SharnouEngine",
                "authoring_controller": "Sharnou-IDE",
            })
            scene_paths.append(scene_rel)
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
            "gltf_texture_extension": "KHR_texture_basisu",
        },
        "no_external_engine_toolchain": True,
        "assets": plan,
        "counts": {k: len(catalog.get(k, [])) for k in collections},
        "scene_count": len(scene_paths),
        "note": "Generated scene containers are deterministic runtime identities; Sharnou-IDE codec adapters supply binary KTX2/AVIF payloads without changing the game contract.",
    }
    write_json(args.output, manifest)
    print(f"[SharnouRuntimeGenerator] PASS scenes={len(scene_paths)} output={args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
