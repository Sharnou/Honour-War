import json
import os
import ssl
import urllib.request
from pathlib import Path

# Honour War Visual RAG preflight.
# This step MUST execute before Blender. It creates a reproducible visual brief
# from current visual references and stores the target decisions consumed by the
# downstream asset-generation pipeline.

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "3d" / "visual_rag"
OUT.mkdir(parents=True, exist_ok=True)
REF_DIR = OUT / "references"
REF_DIR.mkdir(parents=True, exist_ok=True)

REFERENCES = [
    {
        "id": "ro_prontera_square",
        "url": "https://2.bp.blogspot.com/-ZmSk9HF5Bcs/ViKYI1awm-I/AAAAAAAABYc/2bMVExN2T8k/s1600/Prontera.jpg",
        "purpose": "bright stone plaza, banners, fountain, medieval town composition"
    },
    {
        "id": "ro_hugel_market",
        "url": "https://eu-mds.4game.com/images/patchnoteimages/original/fbd599a3-5a2f-4fdb-a069-c47e740bf14d.i4g",
        "purpose": "market props, paving, umbrellas, vegetation, lived-in environment"
    },
    {
        "id": "ro_town_gathering",
        "url": "https://livedoor.blogimg.jp/utuho2008/imgs/f/1/f113c55d.png",
        "purpose": "character density, social hub composition, readable silhouettes"
    }
]

TARGET = {
    "style": "high-fidelity fantasy MMORPG with Ragnarok-inspired proportions and readable stylization; not photorealistic and not low-poly placeholder art",
    "camera": "three-quarter/isometric-friendly camera with strong depth, readable silhouettes and layered foreground/midground/background",
    "lighting": "bright daylight baseline, soft directional shadows, subtle ambient occlusion, controlled bloom, rich but coherent material response",
    "characters": "full-body production models, expressive face/hair, layered clothing/armor, distinct class silhouettes, meaningful tier progression",
    "environment": "dense authored architecture, varied roofs/walls, paving variation, props, vegetation, landmarks, water and social-space details",
    "materials": "PBR-ready albedo, roughness, metallic and normal maps; avoid flat single-color materials",
    "negative": ["box-and-cylinder placeholder look", "empty terrain", "uniform buildings", "floating equipment text over hero", "unbounded saturation", "unlit flat meshes"]
}


def _download(url: str, path: Path) -> str:
    context = ssl.create_default_context()
    request = urllib.request.Request(url, headers={"User-Agent": "Honour-War-Visual-RAG/1.0"})
    try:
        with urllib.request.urlopen(request, timeout=20, context=context) as response:
            data = response.read()
        path.write_bytes(data)
        return "downloaded"
    except Exception as exc:
        return "unavailable: " + str(exc)


def main() -> None:
    manifest = {
        "tool": "Honour War Visual RAG preflight",
        "version": 1,
        "target": TARGET,
        "references": []
    }
    for reference in REFERENCES:
        filename = REF_DIR / (reference["id"] + ".img")
        status = _download(reference["url"], filename)
        item = dict(reference)
        item["status"] = status
        item["local_reference"] = str(filename.relative_to(ROOT))
        manifest["references"].append(item)

    (OUT / "LATEST_VISUAL_BRIEF.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    brief = [
        "HONOUR WAR — VISUAL RAG TARGET BRIEF",
        "",
        "The reference pass runs before Blender and defines the next art target.",
        "",
        "STYLE: " + TARGET["style"],
        "CAMERA: " + TARGET["camera"],
        "LIGHTING: " + TARGET["lighting"],
        "CHARACTERS: " + TARGET["characters"],
        "ENVIRONMENT: " + TARGET["environment"],
        "MATERIALS: " + TARGET["materials"],
        "",
        "REMOVE / AVOID:",
    ] + ["- " + value for value in TARGET["negative"]]
    (OUT / "LATEST_VISUAL_BRIEF.md").write_text("\n".join(brief) + "\n", encoding="utf-8")
    print("Visual RAG preflight complete")
    for item in manifest["references"]:
        print(item["id"] + ": " + item["status"])
    print("Brief: " + str(OUT / "LATEST_VISUAL_BRIEF.json"))


if __name__ == "__main__":
    main()
