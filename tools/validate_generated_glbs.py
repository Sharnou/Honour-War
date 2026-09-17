#!/usr/bin/env python3
"""Semantic, binary, inventory, and PBR validation for generated GLB assets."""

from __future__ import annotations

import json
import struct
import sys
from pathlib import Path

ROOT = Path("assets/3d/generated")
MAGIC = b"glTF"
JSON_CHUNK = 0x4E4F534A

HERO_CLASSES = {"Warrior", "Mage", "Archer", "Thief", "Acolyte", "Merchant"}
HERO_TIERS = {"Foundation", "Specialization", "Advanced", "Mastery", "Transcendence"}
HERO_WEAPONS = {
    "Warrior": "Sword",
    "Mage": "Staff",
    "Archer": "Bow",
    "Thief": "Dagger",
    "Acolyte": "Mace",
    "Merchant": "Hammer",
}
PET_ASSETS = {
    "Acolyte_pet.glb",
    "Archer_pet.glb",
    "Clockwork.glb",
    "Falcon.glb",
    "Mage_pet.glb",
    "Panther.glb",
    "PoringAngel.glb",
    "Thief_pet.glb",
    "Warrior_pet.glb",
    "Wolf.glb",
    "ArcaneOrb.glb",
    "Merchant_pet.glb",
}
MONSTER_ASSETS = {
    "monster_Poring.glb",
    "monster_Goblin.glb",
    "monster_Wolf.glb",
    "monster_Skeleton.glb",
    "monster_Zombie.glb",
    "monster_Orc.glb",
    "monster_Mantis.glb",
    "monster_Golem.glb",
    "monster_Evil_Druid.glb",
    "monster_Dragon.glb",
    "monster_Bloody_Knight.glb",
}


def read_glb_json(path: Path) -> dict:
    data = path.read_bytes()
    if len(data) < 20:
        raise ValueError(f"{path}: file too small for a GLB header")
    if data[:4] != MAGIC:
        raise ValueError(f"{path}: invalid GLB magic")

    version, total_length = struct.unpack_from("<II", data, 4)
    if version != 2:
        raise ValueError(f"{path}: expected GLB version 2, got {version}")
    if total_length != len(data):
        raise ValueError(
            f"{path}: header length {total_length} does not match file size {len(data)}"
        )

    first_chunk_length, first_chunk_type = struct.unpack_from("<II", data, 12)
    if first_chunk_type != JSON_CHUNK:
        raise ValueError(f"{path}: first GLB chunk is not JSON")
    start = 20
    end = start + first_chunk_length
    if end > len(data):
        raise ValueError(f"{path}: JSON chunk exceeds file length")

    raw_json = data[start:end].rstrip(b" \t\r\n\x00")
    try:
        return json.loads(raw_json.decode("utf-8"))
    except Exception as exc:
        raise ValueError(f"{path}: invalid JSON chunk: {exc}") from exc


def node_names(doc: dict) -> set[str]:
    return {
        node["name"]
        for node in doc.get("nodes", [])
        if isinstance(node, dict) and isinstance(node.get("name"), str)
    }


def has_named_part(names: set[str], token: str) -> bool:
    return any(name == token or name.startswith(token) for name in names)


def validate_embedded_images(path: Path, doc: dict) -> None:
    images = doc.get("images", [])
    if not images:
        raise ValueError(f"{path}: no embedded texture images found")
    external = [i for i in images if isinstance(i, dict) and "uri" in i]
    if external:
        raise ValueError(f"{path}: external texture URI detected; GLB must embed textures")
    missing_buffer_view = [i for i in images if isinstance(i, dict) and "bufferView" not in i]
    if missing_buffer_view:
        raise ValueError(f"{path}: texture image without embedded bufferView detected")


def validate_pbr_materials(path: Path, doc: dict) -> None:
    """Require actual embedded base-color and metallic-roughness textures."""
    textures = doc.get("textures", [])
    if not textures:
        raise ValueError(f"{path}: no glTF texture objects found")

    for mat in doc.get("materials", []):
        if not isinstance(mat, dict):
            raise ValueError(f"{path}: malformed material entry")
        name = str(mat.get("name", ""))
        lower_name = name.lower()
        if any(token in lower_name for token in ("glow", "emission", "eye", "iris")):
            continue
        pbr = mat.get("pbrMetallicRoughness")
        if not isinstance(pbr, dict):
            raise ValueError(f"{path}: material {name!r} has no PBR metallic-roughness block")
        base = pbr.get("baseColorTexture")
        rough = pbr.get("metallicRoughnessTexture")
        if not isinstance(base, dict) or not isinstance(rough, dict):
            raise ValueError(
                f"{path}: material {name!r} is missing embedded base-color or metallic-roughness texture"
            )
        for label, entry in (("base-color", base), ("metallic-roughness", rough)):
            index = entry.get("index")
            if not isinstance(index, int) or index < 0 or index >= len(textures):
                raise ValueError(
                    f"{path}: material {name!r} has invalid {label} texture index {index!r}"
                )


def hero_class_and_tier(path: Path) -> tuple[str, str]:
    """Return the hero class/tier from characters/<class>/<tier>.glb.

    This deliberately uses the directory immediately below ``characters``.
    Using a fixed negative index (for example ``parts[0]``) misclassified
    every staged hero as the literal directory name ``characters``.
    """
    try:
        rel = path.relative_to(ROOT)
    except ValueError as exc:
        raise ValueError(f"{path}: hero path is outside generated asset root") from exc

    parts = rel.parts
    if len(parts) != 3 or parts[0] != "characters":
        raise ValueError(f"{path}: unexpected hero layout")

    class_id = parts[1]
    tier = Path(parts[2]).stem
    return class_id, tier


def validate_hero_path_parser() -> None:
    """Regression guard for the staged hero directory layout."""
    cases = {
        "Acolyte": Path("assets/3d/generated/characters/Acolyte/Advanced.glb"),
        "Archer": Path("assets/3d/generated/characters/Archer/Foundation.glb"),
        "Mage": Path("assets/3d/generated/characters/Mage/Mastery.glb"),
        "Merchant": Path("assets/3d/generated/characters/Merchant/Specialization.glb"),
        "Thief": Path("assets/3d/generated/characters/Thief/Transcendence.glb"),
        "Warrior": Path("assets/3d/generated/characters/Warrior/Advanced.glb"),
    }
    for expected_class, path in cases.items():
        actual_class, _tier = hero_class_and_tier(path)
        if actual_class != expected_class:
            raise AssertionError(
                f"hero path parser regression: {path} resolved to {actual_class!r}, "
                f"expected {expected_class!r}"
            )


def validate_inventory(files: list[Path]) -> None:
    """Ensure the final build contains the complete 53-asset production set."""
    relative = {p.relative_to(ROOT).as_posix() for p in files}
    expected_heroes = {
        f"characters/{class_id}/{tier}.glb"
        for class_id in sorted(HERO_CLASSES)
        for tier in sorted(HERO_TIERS)
    }
    expected_pets = {f"pets/{name}" for name in PET_ASSETS}
    expected_monsters = {f"monsters/{name}" for name in MONSTER_ASSETS}

    for label, expected in (
        ("hero", expected_heroes),
        ("pet", expected_pets),
        ("monster", expected_monsters),
    ):
        actual = {item for item in relative if item.split("/", 1)[0] == ("characters" if label == "hero" else label + "s")}
        missing = sorted(expected - actual)
        extra = sorted(actual - expected)
        if missing:
            raise ValueError(f"missing required {label} GLB assets: {', '.join(missing)}")
        if extra:
            raise ValueError(f"unexpected {label} GLB assets: {', '.join(extra)}")

    if len(relative) != 53:
        raise ValueError(f"expected exactly 53 final GLBs, found {len(relative)}")


def validate_asset(path: Path) -> None:
    if path.stat().st_size < 1024:
        raise ValueError(f"{path}: suspiciously small GLB")

    doc = read_glb_json(path)
    asset = doc.get("asset", {})
    if asset.get("version") != "2.0":
        raise ValueError(f"{path}: glTF asset.version must be 2.0")
    if not doc.get("meshes"):
        raise ValueError(f"{path}: no meshes found")
    if not doc.get("materials"):
        raise ValueError(f"{path}: no materials found")
    validate_embedded_images(path, doc)
    validate_pbr_materials(path, doc)

    names = node_names(doc)
    rel = path.relative_to(ROOT).as_posix()

    if rel.startswith("characters/"):
        class_id, tier = hero_class_and_tier(path)
        if class_id not in HERO_CLASSES:
            raise ValueError(f"{path}: unknown hero class {class_id}")
        if tier not in HERO_TIERS:
            raise ValueError(f"{path}: unknown hero tier {tier}")
        required = ["Torso", "Head", "Eye", "Iris", "Mouth", HERO_WEAPONS[class_id]]
        missing = [token for token in required if not has_named_part(names, token)]
        if missing:
            raise ValueError(f"{path}: missing required hero nodes: {', '.join(missing)}")
        if len(names) < 12:
            raise ValueError(f"{path}: hero node count too low ({len(names)})")

    elif rel.startswith("pets/"):
        if len(names) < 3:
            raise ValueError(f"{path}: pet node count too low ({len(names)})")

    elif rel.startswith("monsters/"):
        if len(names) < 2:
            raise ValueError(f"{path}: monster node count too low ({len(names)})")


def main() -> int:
    files = sorted(ROOT.rglob("*.glb")) if ROOT.exists() else []
    print("HONOUR WAR GENERATED GLB QUALITY GATE")
    print(f"Discovered GLBs: {len(files)}")

    try:
        validate_hero_path_parser()
        validate_inventory(files)
    except Exception as exc:
        print(f"ERROR: {exc}")
        return 1

    failures = []
    for path in files:
        try:
            validate_asset(path)
        except Exception as exc:
            failures.append(str(exc))

    if failures:
        print("FAILED GLB ASSETS:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    hero_count = sum(1 for p in files if p.relative_to(ROOT).parts[:1] == ("characters",))
    pet_count = sum(1 for p in files if p.relative_to(ROOT).parts[:1] == ("pets",))
    monster_count = sum(1 for p in files if p.relative_to(ROOT).parts[:1] == ("monsters",))
    print(f"Heroes: {hero_count} | Pets: {pet_count} | Monsters: {monster_count}")
    print("PASS: binary structure, glTF 2.0 JSON, complete production inventory, meshes, materials, embedded textures, PBR texture links, and semantic hero nodes are valid.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
