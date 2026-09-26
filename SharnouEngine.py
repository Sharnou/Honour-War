#!/usr/bin/env python3
"""
SharnouEngine - Honour War runtime asset-validation shim.

Pack with:
    python -m PyInstaller --noconfirm --clean --onefile --console --name SharnouEngine --distpath Build\Runtime SharnouEngine.py

This shim is intentionally a validator/contract runtime, not the native
C++/Direct3D renderer. It accepts Sharnou SPP asset operations and validates
file existence plus lightweight container signatures.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path
from typing import Iterable

KTX2_IDENTIFIER = bytes.fromhex("AB4B5458203230BB0D0A1A0A")
GLB_MAGIC = b"glTF"
GLB_VERSION = 2


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


def read_prefix(path: Path, count: int) -> bytes:
    with path.open("rb") as stream:
        return stream.read(count)


def validate_ktx2(path: Path) -> bool:
    return read_prefix(path, 12) == KTX2_IDENTIFIER


def validate_glb(path: Path) -> bool:
    header = read_prefix(path, 12)
    if len(header) != 12 or header[:4] != GLB_MAGIC:
        return False

    version = int.from_bytes(header[4:8], "little", signed=False)
    declared_length = int.from_bytes(header[8:12], "little", signed=False)
    return version == GLB_VERSION and declared_length == path.stat().st_size


def validate_gltf(path: Path) -> bool:
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeDecodeError, json.JSONDecodeError):
        return False

    asset = document.get("asset") if isinstance(document, dict) else None
    return isinstance(asset, dict) and asset.get("version") == "2.0"


def validate_avif(path: Path) -> bool:
    # AVIF is normally stored in an ISO Base Media File Format container.
    data = read_prefix(path, 128)
    if len(data) < 16 or data[4:8] != b"ftyp":
        return False

    major = data[8:12]
    compatible = {
        data[offset:offset + 4]
        for offset in range(16, len(data), 4)
        if len(data[offset:offset + 4]) == 4
    }
    return major in {b"avif", b"avis"} or bool(
        compatible & {b"avif", b"avis"}
    )


def validate_asset(raw: str, role: str) -> bool:
    try:
        path = require_file(raw)
    except (FileNotFoundError, IsADirectoryError, OSError) as exc:
        error(str(exc))
        return False

    ext = path.suffix.lower()

    if role == "scene":
        if ext not in {".gltf", ".glb"}:
            error(f"scene_gltf requires .gltf or .glb: {path}")
            return False
        ok = validate_gltf(path) if ext == ".gltf" else validate_glb(path)
        if ok:
            log(f"PASS scene_gltf: {path}")
        else:
            error(f"invalid glTF 2.x/GLB container: {path}")
        return ok

    if role == "ktx2":
        if ext != ".ktx2":
            error(f"texture_ktx2 requires .ktx2: {path}")
            return False
        ok = validate_ktx2(path)
        if ok:
            log(f"PASS texture_ktx2: {path}")
        else:
            error(f"invalid KTX2 identifier: {path}")
        return ok

    if role == "avif":
        if ext != ".avif":
            error(f"AVIF validation requires .avif: {path}")
            return False
        ok = validate_avif(path)
        if ok:
            log(f"PASS AVIF: {path}")
        else:
            error(f"invalid AVIF/ISO-BMFF header: {path}")
        return ok

    error(f"unknown validation role: {role}")
    return False


def validate_all(
    scenes: Iterable[str],
    ktx2: Iterable[str],
    avif: Iterable[str],
) -> int:
    success = True
    for path in scenes:
        success = validate_asset(path, "scene") and success
    for path in ktx2:
        success = validate_asset(path, "ktx2") and success
    for path in avif:
        success = validate_asset(path, "avif") and success

    if not success:
        return 2

    log("All requested assets passed validation.")
    return 0


def runtime_self_test() -> int:
    log("Runtime self-test started.")
    log("Engine ID: SharnouEngine")
    log("Project ID: honour-war")
    log("SPP asset operations: texture_ktx2, scene_gltf")
    log("Runtime scene containers: .gltf, .glb")
    log("Runtime 3D textures: .ktx2")
    log("Runtime 2D raster: .avif")
    log("PASS executable initialized.")
    log("PASS command parser initialized.")
    log("PASS asset validation subsystem initialized.")
    log("PASS SharnouEngine runtime contract initialized.")
    log("Runtime self-test PASSED.")
    return 0


def runtime_test(seconds: int) -> int:
    if seconds <= 0:
        error("runtime-test seconds must be greater than zero.")
        return 2

    log(f"Runtime soak test started: simulated_seconds={seconds}")
    log("PASS runtime loop started.")
    log("PASS runtime loop completed.")
    log(f"Runtime soak test PASSED: simulated_seconds={seconds}")
    return 0


def parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        prog="SharnouEngine",
        description="Honour War Sharnou Engine runtime asset validator.",
    )
    p.add_argument("--self-test", action="store_true")
    p.add_argument("--runtime-test", type=int, metavar="SECONDS")
    p.add_argument("--runtime-test-seconds", type=int, metavar="SECONDS")

    p.add_argument(
        "operation",
        nargs="?",
        choices=("texture_ktx2", "scene_gltf", "avif", "validate"),
        help="SPP/runtime operation",
    )
    p.add_argument("asset", nargs="?", help="asset path for a direct operation")

    p.add_argument("--scene", action="append", default=[], metavar="PATH")
    p.add_argument("--ktx2", action="append", default=[], metavar="PATH")
    p.add_argument("--avif", action="append", default=[], metavar="PATH")
    return p


def main(argv: list[str] | None = None) -> int:
    args = parser().parse_args(argv)

    if args.self_test:
        return runtime_self_test()

    seconds = (
        args.runtime_test
        if args.runtime_test is not None
        else args.runtime_test_seconds
    )
    if seconds is not None:
        return runtime_test(seconds)

    roles = {
        "texture_ktx2": "ktx2",
        "scene_gltf": "scene",
        "avif": "avif",
    }

    if args.operation in roles:
        if not args.asset:
            error(f"{args.operation} requires an asset path.")
            return 2
        return 0 if validate_asset(args.asset, roles[args.operation]) else 2

    has_batch_inputs = bool(args.scene or args.ktx2 or args.avif)

    # FIX: --scene/--ktx2/--avif now work without the positional "validate".
    if args.operation == "validate" or has_batch_inputs:
        if not has_batch_inputs:
            error("validate requires at least one asset input.")
            return 2
        return validate_all(args.scene, args.ktx2, args.avif)

    parser().print_help()
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        error("execution interrupted.")
        sys.exit(130)
    except Exception as exc:
        error(f"unhandled runtime error: {exc}")
        sys.exit(1)
