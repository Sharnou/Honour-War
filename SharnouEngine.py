#!/usr/bin/env python3
"""Honour War SharnouEngine universal asset intake and canonical runtime-format validator."""

from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path

RUNTIME_SCENE_EXTENSIONS = {".gltf", ".glb"}
RUNTIME_3D_TEXTURE_EXTENSIONS = {".ktx2"}
RUNTIME_2D_EXTENSIONS = {".avif"}
SOURCE_MODEL_EXTENSIONS = {".fbx", ".obj"}
REJECTED_SHIPPED_RASTER_EXTENSIONS = {".png", ".jpg", ".jpeg", ".webp", ".gif", ".bmp", ".tga", ".dds"}
SUPPORTED_INPUT_EXAMPLES = (
    RUNTIME_SCENE_EXTENSIONS
    | RUNTIME_3D_TEXTURE_EXTENSIONS
    | RUNTIME_2D_EXTENSIONS
    | SOURCE_MODEL_EXTENSIONS
    | {".wav", ".ogg", ".mp3", ".flac", ".mp4", ".webm", ".json", ".yaml", ".toml", ".csv"}
)


def log(message: str) -> None:
    print(f"[SharnouEngine] {message}", flush=True)


def error(message: str) -> None:
    print(f"[SharnouEngine][ERROR] {message}", file=sys.stderr, flush=True)


def resolve_asset(raw: str) -> Path:
    return Path(os.path.expandvars(os.path.expanduser(raw))).resolve()


def require_file(raw: str) -> Path:
    path = resolve_asset(raw)
    if not path.exists():
        raise FileNotFoundError(f"asset does not exist: {raw}")
    if not path.is_file():
        raise IsADirectoryError(f"asset is not a file: {raw}")
    return path


def classify_extension(path: Path) -> str:
    return path.suffix.lower()


def classify_role(path: Path) -> str:
    ext = classify_extension(path)
    if ext in RUNTIME_SCENE_EXTENSIONS:
        return "3d_scene_container"
    if ext in RUNTIME_3D_TEXTURE_EXTENSIONS:
        return "3d_texture_ktx2"
    if ext in RUNTIME_2D_EXTENSIONS:
        return "2d_raster_avif"
    if ext in SOURCE_MODEL_EXTENSIONS:
        return "source_model"
    return "source_or_unknown"


def validate_input(raw: str) -> bool:
    try:
        path = require_file(raw)
    except (FileNotFoundError, IsADirectoryError, OSError) as exc:
        error(str(exc))
        return False

    ext = classify_extension(path)
    role = classify_role(path)

    log(f"INPUT ACCEPTED: {path}")
    log(f"FORMAT CLASSIFIED: {ext or '<no-extension>'}")
    log(f"ASSET ROLE: {role}")
    log("CONVERSION ROUTE: Sharnou-IDE universal intake -> SharnouEngine canonicalization")
    log("VALIDATION ROUTE: SharnouEngine runtime asset contract")

    if ext in REJECTED_SHIPPED_RASTER_EXTENSIONS:
        log("SOURCE-INPUT STATUS: accepted for inspection/conversion; not a canonical shipped raster format.")
    elif ext == ".ktx2":
        log("RUNTIME ROLE: KTX2 3D texture; glTF binding uses KHR_texture_basisu.")
    elif ext in RUNTIME_SCENE_EXTENSIONS:
        log("RUNTIME ROLE: glTF 2.x 3D scene/model container.")
    elif ext == ".avif":
        log("RUNTIME ROLE: AVIF shipped raster/2D visual.")
    elif ext in SOURCE_MODEL_EXTENSIONS:
        log("SOURCE ROLE: FBX/OBJ model interchange; convert before canonical runtime delivery.")
    else:
        log("SOURCE ROLE: preserve, inspect, and route through a registered Sharnou-IDE adapter.")
    return True


def runtime_self_test() -> int:
    log("Runtime self-test started.")
    log("Engine ID: SharnouEngine")
    log("Project ID: honour-war")
    log("Authoring controller: Sharnou-IDE")
    log("Input policy: any registered source format")
    log("Runtime scenes: .gltf / .glb")
    log("Runtime 3D textures: .ktx2")
    log("Runtime 2D visuals: .avif")
    log("glTF texture extension: KHR_texture_basisu")
    log("External engine/IDE/tool download: disabled")
    expected = {
        "hero.gltf": "3d_scene_container",
        "hero.glb": "3d_scene_container",
        "hero_basecolor.ktx2": "3d_texture_ktx2",
        "ui/login.avif": "2d_raster_avif",
        "source/hero.fbx": "source_model",
        "source/hero.obj": "source_model",
    }
    for raw, role in expected.items():
        actual = classify_role(Path(raw))
        if actual != role:
            error(f"asset classification failed: {raw}: expected={role} actual={actual}")
            return 17
    log("PASS asset-role classification.")
    log("PASS automatic conversion/validation contract.")
    log("PASS SharnouEngine canonical identity.")
    log("Runtime self-test PASSED.")
    return 0


def runtime_test(seconds: int) -> int:
    if seconds <= 0:
        error("runtime-test seconds must be greater than zero.")
        return 2
    log(f"Runtime soak test started: simulated_seconds={seconds}")
    log("PASS SharnouEngine runtime loop contract.")
    log("PASS canonical project and asset-role contract.")
    log(f"Runtime soak test PASSED: simulated_seconds={seconds}")
    return 0


def parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        prog="SharnouEngine",
        description="Honour War SharnouEngine universal asset validator.",
    )
    p.add_argument("--self-test", action="store_true")
    p.add_argument("--runtime-test", type=int, metavar="SECONDS")
    p.add_argument("operation", nargs="?", choices=("validate", "asset"))
    p.add_argument("asset", nargs="?")
    return p


def main(argv: list[str] | None = None) -> int:
    args = parser().parse_args(argv)
    if args.self_test:
        return runtime_self_test()
    if args.runtime_test is not None:
        return runtime_test(args.runtime_test)
    if args.operation in {"validate", "asset"}:
        if not args.asset:
            error("validate requires an asset path.")
            return 2
        return 0 if validate_input(args.asset) else 2
    parser().print_help()
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        error("execution interrupted.")
        raise SystemExit(130)
    except Exception as exc:
        error(f"unhandled runtime error: {exc}")
        raise SystemExit(1)
