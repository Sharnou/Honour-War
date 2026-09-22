import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "3d" / "visual_rag"
OUT.mkdir(parents=True, exist_ok=True)
REF_DIR = ROOT / "Screenshot"

EXPECTED = [
    "ChatGPT Image Sep 7, 2026, 03_54_35 PM.png",
    "ChatGPT Image Sep 8, 2026, 12_13_55 AM.png",
    "ChatGPT Image Sep 8, 2026, 12_30_08 AM.png",
    "ChatGPT Image Sep 14, 2026, 02_17_52 PM.png",
    "ChatGPT Image Sep 15, 2026, 11_17_00 PM.png",
    "ChatGPT Image Sep 16, 2026, 12_22_47 AM.png",
    "ChatGPT Image Sep 18, 2026, 11_57_21 PM.png",
]

TARGET = {
    "source": "Screenshot/",
    "style": "Generate Honour War from the repository Screenshot reference set; preserve the reference character, environment, composition, material, lighting, combat and UI visual language rather than substituting generic MMORPG imagery.",
    "camera": "Derive camera distance, pitch, framing, character readability and scene composition from the Screenshot reference set.",
    "lighting": "Derive daylight, exposure, contrast, shadow softness, bloom and environment response from the Screenshot reference set.",
    "characters": "Derive full-body proportions, face/head visibility, clothing, armor, weapons, pets, silhouettes and progression presentation from the Screenshot reference set.",
    "environment": "Derive terrain, architecture, vegetation, roads, props, town composition and world density from the Screenshot reference set.",
    "materials": "Derive material appearance from the reference images, then author known plausible PBR materials in Blender/Substance 3D Painter; never use mystery materials.",
    "pipeline": "Screenshot → Blender → Substance 3D Painter → FBX/OBJ → Unreal Engine 5.8",
    "negative": [
        "generic external reference images",
        "stock MMORPG screenshots",
        "box-and-cylinder placeholder look",
        "empty terrain",
        "uniform buildings",
        "flat unlit meshes",
        "Transformer-generated assets",
        "Unknown Material placeholders",
    ],
}


def main() -> None:
    if not REF_DIR.is_dir():
        raise SystemExit("VISUAL_RAG: Screenshot/ source folder is missing")

    missing = [name for name in EXPECTED if not (REF_DIR / name).is_file()]
    if missing:
        raise SystemExit("VISUAL_RAG: missing direct source image(s): " + ", ".join(missing))

    references = []
    for name in EXPECTED:
        path = REF_DIR / name
        references.append({
            "id": path.stem,
            "source_path": str(path.relative_to(ROOT)),
            "size_bytes": path.stat().st_size,
            "source_type": "repository_visual_source",
        })

    manifest = {
        "tool": "Honour War Visual RAG preflight",
        "version": 3,
        "direct_visual_source": "Screenshot/",
        "external_reference_downloads": False,
        "target": TARGET,
        "references": references,
    }

    (OUT / "LATEST_VISUAL_BRIEF.json").write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False),
        encoding="utf-8",
    )

    brief = [
        "HONOUR WAR — DIRECT VISUAL SOURCE BRIEF",
        "",
        "SOURCE: Screenshot/",
        "The complete repository Screenshot/ folder is the authoritative visual source.",
        "No external or generic reference image is permitted to replace it.",
        "",
        "STYLE: " + TARGET["style"],
        "CAMERA: " + TARGET["camera"],
        "LIGHTING: " + TARGET["lighting"],
        "CHARACTERS: " + TARGET["characters"],
        "ENVIRONMENT: " + TARGET["environment"],
        "MATERIALS: " + TARGET["materials"],
        "PIPELINE: " + TARGET["pipeline"],
        "",
        "REMOVE / AVOID:",
    ] + ["- " + value for value in TARGET["negative"]]

    (OUT / "LATEST_VISUAL_BRIEF.md").write_text(
        "\n".join(brief) + "\n",
        encoding="utf-8",
    )

    print("VISUAL_RAG: PASS")
    print("DIRECT SOURCE: Screenshot/")
    print("EXTERNAL REFERENCE DOWNLOADS: DISABLED")
    for item in references:
        print("SOURCE :: " + item["source_path"])
    print("Brief: " + str(OUT / "assets" / "3d" / "visual_rag" / "LATEST_VISUAL_BRIEF.json"))


if __name__ == "__main__":
    main()
