# Honour War — Unity 6.6 engine migration

Honour War is now developed and tested against **Unity 6.6 (6000.6.3f1)** instead of Unreal Engine 5.8.

## Permanent engine baseline

- Unity Hub: **3.21.3**
- Unity Editor: **6000.6.3f1**
- Unity line: **Unity 6.6**
- Target: Windows 64-bit

The version is locked in project metadata and the build/runtime test scripts. Normal development must not change it.

## Current Unity playable baseline

`Unity/` contains the Unity project with:

- Unity 6.6 project metadata.
- Windows player settings.
- HonourWarMain startup scene.
- Register/login entry screen.
- Character/class selection.
- Seven classes: Warrior, Mage, Archer, Thief, Acolyte, Merchant, Ranger.
- Eight initial skills per class.
- Ragnarok-style click-to-move controls; WASD movement is not used.
- Right-mouse camera rotation and mouse-wheel zoom.
- Monster targeting/combat.
- Automatic local save/resume.
- `@help` and `@go 0 230:220` command path.
- Tier-5 skill-rest gate.
- F9 real runtime framebuffer screenshot capture.

## Runtime testing rule

Static contract validation is not gameplay evidence. A real gameplay result requires Unity 6.6 or a packaged Unity 6.6 player to execute the game.

Runtime reports must distinguish Unity runtime exceptions/errors, crashes/player termination, class-selection failures, movement failures, skill failures, command-routing failures, save/load failures, and camera/player initialization failures.

## Real gameplay screenshot

Run the Unity project and enter gameplay. Press **F9**. The game calls Unity's `ScreenCapture.CaptureScreenshot` against the live rendered game window and writes a PNG under `Application.persistentDataPath/HonourWarScreenshots/`. This is a runtime capture, not a generated mock-up.

## Unreal transition

Unreal 5.8 is no longer the active engine. The active Unreal source/config artifacts have been removed from the working tree. Their design logic is represented by the Unity C# implementation under `Unity/Assets/Scripts/`; Git history preserves the previous Unreal implementation.

.NET 10.0.401 is used for standalone migration/QA tooling. Unity gameplay scripts run under Unity 6.6's supported managed runtime.
