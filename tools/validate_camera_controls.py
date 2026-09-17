#!/usr/bin/env python3
"""Static regression gate for Honour War camera controls.

The production scene has one camera owner: MovementStabilityFix controls the
root Camera3D. This gate verifies that the smooth zoom and 90-degree rotation
contract is still present and that the InputMap bindings remain available.
It intentionally does not create a second camera or rewrite runtime behavior.
"""

from __future__ import annotations

from pathlib import Path

PROJECT = Path("project.godot")
CAMERA = Path("scripts/MovementStabilityFix.gd")
SCENE = Path("Main3D.tscn")


def require(text: str, marker: str, label: str) -> None:
    if marker not in text:
        raise SystemExit(f"CAMERA QA ERROR: missing {label}: {marker}")


def main() -> int:
    for path in (PROJECT, CAMERA, SCENE):
        if not path.is_file():
            raise SystemExit(f"CAMERA QA ERROR: missing required file: {path}")

    project = PROJECT.read_text(encoding="utf-8")
    camera = CAMERA.read_text(encoding="utf-8")
    scene = SCENE.read_text(encoding="utf-8")

    # InputMap contract: Q/E are the authored 90-degree rotation controls.
    require(project, 'camera_rotate_left={"deadzone":0.5,"events":[Object(InputEventKey,"physical_keycode":81)]}', "camera_rotate_left Q binding")
    require(project, 'camera_rotate_right={"deadzone":0.5,"events":[Object(InputEventKey,"physical_keycode":69)]}', "camera_rotate_right E binding")

    # Smooth zoom contract.
    require(camera, '@export var zoom_min_distance:float', "zoom minimum")
    require(camera, '@export var zoom_max_distance:float', "zoom maximum")
    require(camera, '@export var zoom_step:float', "zoom step")
    require(camera, '@export var zoom_smoothing:float', "zoom smoothing")
    require(camera, 'MOUSE_BUTTON_WHEEL_UP', "wheel-up zoom input")
    require(camera, 'MOUSE_BUTTON_WHEEL_DOWN', "wheel-down zoom input")
    require(camera, 'target_camera_distance=clamp', "bounded zoom target")
    require(camera, 'camera_distance=lerp(camera_distance,target_camera_distance,zoom_alpha)', "smooth zoom interpolation")

    # 90-degree rotation contract.
    require(camera, '@export var rotation_smoothing:float', "rotation smoothing")
    require(camera, '@export var rotation_step_degrees:float = 90.0', "90-degree rotation step")
    require(camera, 'Input.is_action_just_pressed("camera_rotate_left")', "left rotation action")
    require(camera, 'Input.is_action_just_pressed("camera_rotate_right")', "right rotation action")
    require(camera, 'target_camera_yaw=wrapf(target_camera_yaw+rotation_step_degrees*step_sign,0.0,360.0)', "wrapped 90-degree yaw target")
    require(camera, 'camera_yaw=rad_to_deg(lerp_angle', "smooth yaw interpolation")
    require(camera, 'camera_path=NodePath("../Camera3D")', "single camera path")

    # Scene ownership contract: MovementStabilityFix controls the root Camera3D.
    require(scene, '[node name="MovementStabilityFix" type="Node" parent="."]', "MovementStabilityFix node")
    require(scene, '[node name="Camera3D" type="Camera3D" parent="."]', "root Camera3D")
    require(scene, 'camera_path = NodePath("../Camera3D")', "scene camera ownership")

    print("HONOUR WAR CAMERA CONTROL QA")
    print("PASS: smooth wheel zoom, bounded zoom smoothing, Q/E 90-degree rotation, smooth yaw interpolation, and single-camera ownership are intact.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
