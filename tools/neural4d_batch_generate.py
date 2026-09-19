#!/usr/bin/env python3
"""Batch Neural4D -> FBX/OBJ downloader for Honour War.

The API key is read only from NEURAL4D_API_KEY. No credentials are stored in
the repository. This script intentionally accepts only FBX/OBJ output.
"""

from __future__ import annotations

import argparse
import json
import os
import pathlib
import sys
import time
import urllib.error
import urllib.request

BASE_URL = "https://alb.neural4d.com:3000/api"
POLL_SECONDS = 10
MAX_WAIT_SECONDS = 900

STYLE = (
    "Honour War HD aesthetic; high-detail realistic anime fantasy MMORPG; "
    "full-body production game asset; clean readable silhouette; coherent "
    "anatomy; physically based materials; detailed fabric, leather, metal and "
    "surface response; clean normals; UV-ready; production topology; no "
    "environment; no text; no logo; no watermark; no unrelated props."
)


def api_json(path: str, token: str, payload: dict) -> dict:
    body = json.dumps(payload).encode("utf-8")
    request = urllib.request.Request(
        BASE_URL + path,
        data=body,
        headers={
            "Authorization": token if token.lower().startswith("bearer ") else "Bearer " + token,
            "Content-Type": "application/json;charset=utf-8",
        },
        method="POST",
    )
    with urllib.request.urlopen(request, timeout=60) as response:
        return json.loads(response.read().decode("utf-8"))


def download(url: str, path: pathlib.Path) -> None:
    request = urllib.request.Request(url, headers={"User-Agent": "Honour-War-Neural4D-Pipeline/1.0"})
    with urllib.request.urlopen(request, timeout=180) as response:
        path.write_bytes(response.read())


def prompt_for(asset: dict) -> str:
    category = asset["category"]
    name = asset["name"]
    tier = asset.get("tier", "")
    if category == "character":
        return (
            f"{STYLE} Honour War {name} {tier} character. "
            "Humanoid combat character in a clean A-pose or T-pose, complete face, "
            "hair, torso, arms, hands, legs, boots and class weapon visible. "
            "Class-specific costume and armor must be unmistakable and suitable "
            "for third-person MMORPG gameplay."
        )
    if category == "monster":
        return (
            f"{STYLE} Honour War {name} monster. Full creature visible from all "
            "sides, distinctive anatomy and combat silhouette, game-ready rig "
            "where animation is needed."
        )
    return (
        f"{STYLE} Honour War {name} companion pet. Full body visible, class-linked "
        "identity, expressive face, combat-companion proportions and animation-ready rig."
    )


def convert_to_format(token: str, uuid: str, export: str) -> str:
    if export not in {"fbx", "obj"}:
        raise ValueError(f"Unsupported export: {export}")
    while True:
        result = api_json(
            "/convertToFormat",
            token,
            {"uuid": uuid, "modelType": export, "modelSize": 2},
        )
        status = result.get("statusType")
        if status == 0:
            return result["modelUrl"]
        if status == -1:
            raise RuntimeError("Neural4D format conversion failed: " + str(result))
        time.sleep(POLL_SECONDS)


def generate_one(token: str, asset: dict, output_root: pathlib.Path) -> pathlib.Path:
    prompt = prompt_for(asset)
    job = api_json(
        "/generateModelWithText",
        token,
        {"prompt": prompt, "modelCount": 1, "disablePbr": 0},
    )
    uuids = job.get("uuids") or []
    if not uuids:
        raise RuntimeError("Neural4D did not return a generation UUID: " + str(job))
    uuid = uuids[0]

    deadline = time.time() + MAX_WAIT_SECONDS
    while time.time() < deadline:
        result = api_json("/retrieveModel", token, {"uuid": uuid})
        status = result.get("codeStatus")
        if status == 0:
            break
        if status == -1:
            raise RuntimeError("Neural4D API token is invalid or expired.")
        if status == -2:
            raise RuntimeError("Neural4D returned an unknown UUID.")
        if status == -3:
            raise RuntimeError("Neural4D generation failed: " + str(result))
        time.sleep(POLL_SECONDS)
    else:
        raise TimeoutError(f"Timed out waiting for {asset['id']}")

    url = convert_to_format(token, uuid, asset["export"])
    category_dir = output_root / asset["category"]
    category_dir.mkdir(parents=True, exist_ok=True)
    target = category_dir / f"{asset['id']}.{asset['export']}"
    download(url, target)
    return target


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", default="assets/3d/neural4d/GENERATION_QUEUE.json")
    parser.add_argument("--output", default="assets/3d/neural4d/incoming")
    parser.add_argument("--only", nargs="*", default=None)
    parser.add_argument("--start", type=int, default=0)
    parser.add_argument("--limit", type=int, default=0)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    token = os.environ.get("NEURAL4D_API_KEY")
    if not token and not args.dry_run:
        print("NEURAL4D_API_KEY is required.", file=sys.stderr)
        return 2

    manifest = json.loads(pathlib.Path(args.manifest).read_text(encoding="utf-8"))
    assets = manifest["assets"]
    if args.only:
        wanted = set(args.only)
        assets = [a for a in assets if a["id"] in wanted]
    else:
        assets = assets[args.start:]
        if args.limit > 0:
            assets = assets[:args.limit]

    print(f"QUEUE: {len(assets)} asset(s)")
    for asset in assets:
        print(f"- {asset['id']} -> {asset['export']}")

    if args.dry_run:
        return 0

    output_root = pathlib.Path(args.output)
    failures = 0
    for index, asset in enumerate(assets, 1):
        try:
            target = generate_one(token, asset, output_root)
            print(f"[{index}/{len(assets)}] PASS {target}")
        except Exception as exc:
            failures += 1
            print(f"[{index}/{len(assets)}] FAIL {asset['id']}: {exc}", file=sys.stderr)

    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
