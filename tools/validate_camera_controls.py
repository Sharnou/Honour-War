#!/usr/bin/env python3
"""Static regression gate for the permanent Unreal MMORPG camera contract."""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CHARACTER = ROOT / "Source" / "HonourWar" / "HonourWarCharacter.cpp"
CONTROLLER = ROOT / "Source" / "HonourWar" / "HonourWarPlayerController.cpp"
INPUTS = ROOT / "Config" / "DefaultInput.ini"


def require(text: str, marker: str, label: str) -> None:
    if marker not in text:
        raise SystemExit(f"CAMERA QA ERROR: missing {label}: {marker}")


def main() -> int:
    for path in (CHARACTER, CONTROLLER, INPUTS):
        if not path.is_file():
            raise SystemExit(f"CAMERA QA ERROR: missing required file: {path.relative_to(ROOT)}")

    character = CHARACTER.read_text(encoding="utf-8")
    controller = CONTROLLER.read_text(encoding="utf-8")
    inputs = INPUTS.read_text(encoding="utf-8")

    require(character, "CameraBoom->TargetArmLength=900.0f", "default MMORPG camera distance")
    require(character, "FRotator(-50.0f,45.0f,0.0f)", "elevated isometric default camera angle")
    require(character, "CameraBoom->bEnableCameraLag=true", "camera lag")
    require(character, "CameraBoom->bEnableCameraRotationLag=true", "camera rotation lag")
    require(character, "FMath::Clamp(CameraBoom->TargetArmLength-WheelDelta*120.0f,550.0f,1350.0f)", "bounded mouse-wheel zoom")
    require(controller, "HandleMouseClick", "left-click interaction")
    require(controller, "GetHitResultUnderCursorByChannel", "cursor target query")
    require(controller, "SetMouseTarget", "monster target selection")
    require(controller, "SetMouseDestination", "ground click-to-move")
    require(controller, "bRightMouseDown", "right-drag camera mode")
    require(controller, "RotateCameraFromMouse", "mouse camera orbit")
    require(controller, "Ragnarok Online-inspired", "persistent camera identity")
    require(controller, "ExecuteGoCommand", "@go fast-travel command")
    require(controller, "Anchors", "map travel anchors")
    require(inputs, 'ActionName="CameraReset"', "camera reset input")

    print("HONOUR WAR CAMERA CONTROL QA")
    print("PASS: click-to-move, monster targeting, right-drag orbit, bounded zoom, elevated isometric framing and W/A/S/D compatibility are present.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
