#!/usr/bin/env python3
"""Deterministic, dependency-free glTF 2.x scene/dependency inspector for SharnouEngine."""
from __future__ import annotations

import argparse
import json
import struct
from dataclasses import dataclass, asdict
from pathlib import Path

GLB_MAGIC = 0x46546C67
JSON_CHUNK = 0x4E4F534A
BIN_CHUNK = 0x004E4942

@dataclass(frozen=True)
class Dependency:
    kind: str
    index: int
    uri: str
    asset_id: str


def _asset_id(uri: str) -> str:
    return Path(uri.replace("\\", "/")).as_posix()


def _load_gltf(path: Path) -> dict:
    if path.suffix.lower() == ".gltf":
        return json.loads(path.read_text(encoding="utf-8-sig"))
    if path.suffix.lower() != ".glb":
        raise ValueError(f"unsupported scene extension: {path.suffix}")
    data = path.read_bytes()
    if len(data) < 20:
        raise ValueError("GLB is truncated")
    magic, version, length = struct.unpack_from("<III", data, 0)
    if magic != GLB_MAGIC or version != 2 or length > len(data):
        raise ValueError("invalid GLB header")
    offset = 12
    while offset + 8 <= min(length, len(data)):
        chunk_len, chunk_type = struct.unpack_from("<II", data, offset)
        offset += 8
        chunk = data[offset:offset + chunk_len]
        offset += chunk_len
        if chunk_type == JSON_CHUNK:
            return json.loads(chunk.rstrip(b" ").decode("utf-8"))
    raise ValueError("GLB contains no JSON chunk")


def inspect_scene(path: str) -> dict:
    scene_path = Path(path).resolve()
    document = _load_gltf(scene_path)
    asset = document.get("asset") or {}
    if asset.get("version") != "2.0":
        raise ValueError("scene is not glTF 2.0")

    deps: list[Dependency] = []
    for kind, key in (("buffer", "buffers"), ("image", "images")):
        for index, item in enumerate(document.get(key, [])):
            uri = item.get("uri", "")
            if uri:
                deps.append(Dependency(kind, index, uri, _asset_id(uri)))
            elif kind == "buffer":
                deps.append(Dependency(kind, index, "<embedded>", f"{scene_path.name}#buffer:{index}"))
            else:
                deps.append(Dependency(kind, index, "<embedded-or-bufferView>", f"{scene_path.name}#image:{index}"))

    return {
        "schema": "sharnou.gltf-scene.v1",
        "project": "honour-war",
        "engine": "SharnouEngine",
        "source": str(scene_path),
        "asset_version": asset.get("version"),
        "generator": asset.get("generator", ""),
        "counts": {
            "scenes": len(document.get("scenes", [])),
            "nodes": len(document.get("nodes", [])),
            "meshes": len(document.get("meshes", [])),
            "primitives": sum(len(m.get("primitives", [])) for m in document.get("meshes", [])),
            "materials": len(document.get("materials", [])),
            "textures": len(document.get("textures", [])),
            "images": len(document.get("images", [])),
            "buffers": len(document.get("buffers", [])),
            "bufferViews": len(document.get("bufferViews", [])),
            "accessors": len(document.get("accessors", [])),
            "skins": len(document.get("skins", [])),
            "animations": len(document.get("animations", [])),
        },
        "dependencies": [asdict(d) for d in deps],
        "default_scene": document.get("scene"),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="SharnouEngine glTF 2.x scene inspector")
    parser.add_argument("scene")
    parser.add_argument("--output", "-o")
    args = parser.parse_args()
    try:
        result = inspect_scene(args.scene)
        text = json.dumps(result, indent=2, sort_keys=True) + "\n"
        if args.output:
            out = Path(args.output)
            out.parent.mkdir(parents=True, exist_ok=True)
            out.write_text(text, encoding="utf-8")
            print(f"[SharnouGLTF] PASS source={Path(args.scene).resolve()} output={out.resolve()}")
        else:
            print(text, end="")
        return 0
    except (OSError, ValueError, json.JSONDecodeError, struct.error) as exc:
        print(f"[SharnouGLTF][ERROR] {exc}")
        return 1

if __name__ == "__main__":
    raise SystemExit(main())
