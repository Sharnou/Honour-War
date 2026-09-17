#!/usr/bin/env python3
"""Self-healing orchestration for the Honour War generated GLB quality gate.

The tool never weakens validation. It only repairs a known, deterministic
failure class (missing/non-embedded PBR texture data) with the Blender texture
pass, then runs the complete semantic/PBR validator again.

It also exercises the hero-path parser regression contract before accepting a
successful gate, so a future ``characters/<class>/<tier>.glb`` parser regression
fails immediately instead of misclassifying every hero as ``characters``.
"""

from __future__ import annotations

import argparse
import importlib.util
import subprocess
import sys
from pathlib import Path


TEXTURE_FAILURE_MARKERS = (
    "no embedded texture images found",
    "no gltf texture objects found",
    "external texture URI detected",
    "texture image without embedded bufferView detected",
    "missing embedded base-color or metallic-roughness texture",
    "invalid base-color texture index",
    "invalid metallic-roughness texture index",
)

PARSER_CASES = {
    "Acolyte": "assets/3d/generated/characters/Acolyte/Advanced.glb",
    "Archer": "assets/3d/generated/characters/Archer/Foundation.glb",
    "Mage": "assets/3d/generated/characters/Mage/Mastery.glb",
    "Merchant": "assets/3d/generated/characters/Merchant/Specialization.glb",
    "Thief": "assets/3d/generated/characters/Thief/Transcendence.glb",
    "Warrior": "assets/3d/generated/characters/Warrior/Advanced.glb",
}


def run(cmd: list[str], label: str) -> tuple[int, str]:
    print(f"AUTO-REPAIR: {label}")
    completed = subprocess.run(cmd, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    print(completed.stdout, end="" if completed.stdout.endswith("\n") else "\n")
    return completed.returncode, completed.stdout


def load_validator(path: Path):
    spec = importlib.util.spec_from_file_location("honour_war_glb_validator", path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"could not load validator module from {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def check_parser_contract(validator_path: Path) -> None:
    validator = load_validator(validator_path)
    parser = getattr(validator, "hero_class_and_tier", None)
    if parser is None:
        raise RuntimeError("validator is missing hero_class_and_tier parser contract")

    for expected_class, raw_path in PARSER_CASES.items():
        actual_class, _tier = parser(Path(raw_path))
        if actual_class != expected_class:
            raise RuntimeError(
                "hero path parser regression: "
                f"{raw_path} resolved to {actual_class!r}, expected {expected_class!r}"
            )

    print("AUTO-REPAIR: hero path parser contract: PASS")


def is_texture_failure(output: str) -> bool:
    lowered = output.lower()
    return any(marker in lowered for marker in TEXTURE_FAILURE_MARKERS)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--validator",
        type=Path,
        default=Path("tools/validate_generated_glbs.py"),
        help="path to the semantic/PBR GLB validator",
    )
    parser.add_argument(
        "--repair-script",
        type=Path,
        default=Path("tools/blender/enhance_generated_glbs.py"),
        help="Blender texture repair script",
    )
    parser.add_argument(
        "--blender",
        type=Path,
        default=None,
        help="Blender executable; may also be provided by BLENDER_EXECUTABLE",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="validate only; never invoke the repair pass",
    )
    parser.add_argument(
        "--fix",
        action="store_true",
        help="allow the known deterministic PBR texture repair pass",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.check and args.fix:
        print("AUTO-REPAIR ERROR: --check and --fix are mutually exclusive")
        return 2

    validator = args.validator.resolve()
    repair_script = args.repair_script.resolve()
    if not validator.is_file():
        print(f"AUTO-REPAIR ERROR: validator not found: {validator}")
        return 2
    if not repair_script.is_file():
        print(f"AUTO-REPAIR ERROR: repair script not found: {repair_script}")
        return 2

    try:
        check_parser_contract(validator)
    except Exception as exc:
        print(f"AUTO-REPAIR ERROR: {exc}")
        return 1

    code, output = run([sys.executable, str(validator)], "initial semantic/PBR validation")
    if code == 0:
        print("AUTO-REPAIR: initial GLB quality gate already passes; no mutation required.")
        return 0

    if args.check:
        print("AUTO-REPAIR: --check requested; leaving assets unchanged.")
        return code

    if not args.fix:
        print("AUTO-REPAIR: validation failed. Re-run with --fix to allow deterministic texture repair.")
        return code

    if not is_texture_failure(output):
        print("AUTO-REPAIR: failure is not a supported texture-repair class; no gate bypass or unsafe mutation will be attempted.")
        return code

    blender = args.blender
    if blender is None:
        import os

        env_value = os.environ.get("BLENDER_EXECUTABLE", "")
        blender = Path(env_value) if env_value else None
    if blender is None or not blender.is_file():
        print("AUTO-REPAIR ERROR: a valid Blender executable is required for PBR texture repair")
        return 2

    repair_code, _repair_output = run(
        [str(blender), "--background", "--python", str(repair_script)],
        "deterministic embedded-PBR texture repair",
    )
    if repair_code != 0:
        print(f"AUTO-REPAIR ERROR: Blender repair failed with exit code {repair_code}")
        return repair_code

    final_code, final_output = run([sys.executable, str(validator)], "post-repair semantic/PBR validation")
    if final_code != 0:
        if "unknown hero class characters" in final_output.lower():
            print("AUTO-REPAIR ERROR: hero validator regression detected after repair; generated asset paths were not rewritten to hide the defect.")
        else:
            print("AUTO-REPAIR ERROR: repaired assets still fail the complete quality gate.")
        return final_code

    print("AUTO-REPAIR: PASS — repaired GLBs satisfy binary, inventory, semantic, embedded-image, and PBR texture gates.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
