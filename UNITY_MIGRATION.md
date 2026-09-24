# Honour War — Unity 6.0 LTS engine migration

Honour War is now being developed and tested against **Unity 6.0 LTS (6000.0.x)** instead of Unreal Engine 5.8.

Unity 6.0 LTS is the selected engine baseline. Unity's official documentation identifies Unity 6.0 LTS as the 6000.0 release line and supports Windows 10 21H1+ for the Editor. Unity 6.0 LTS remains an LTS release through October 2026.

## Current Unity playable baseline

`Unity/` contains a clean Unity project with:

- Unity 6.0 LTS project metadata.
- Windows player settings.
- HonourWarMain startup scene.
- Register/login entry screen.
- Character/class selection.
- Seven classes: Warrior, Mage, Archer, Thief, Acolyte, Merchant, Ranger.
- Eight initial skills per class.
- Third-person runtime camera.
- Live player movement.
- Monster test population.
- Automatic local save/resume.
- `@help` and `@go 0 230:220` command path.
- Tier-5 skill-rest gate placeholder.
- F9 real runtime framebuffer screenshot capture.

## Local run on the user's Windows PC

The user has Unity Hub 3.21.3 and Unity 6 installed.

Open:

`Unity/`

with the installed Unity 6.0 LTS Editor.

Or from PowerShell at the repository root:

`powershell -ExecutionPolicy Bypass -File Build/Run-Unity-HonourWar.ps1 -OpenEditor`

Build a Windows executable:

`powershell -ExecutionPolicy Bypass -File Build/Run-Unity-HonourWar.ps1 -Build`

The resulting executable is written to `Build/Unity/HonourWar.exe`.

## Real gameplay screenshot

Run the Unity project and enter gameplay. Press **F9**. The game calls Unity's `ScreenCapture.CaptureScreenshot` against the live rendered game window and writes a PNG under:

`Application.persistentDataPath/HonourWarScreenshots/`

The F9 image is therefore a runtime capture, not a generated mock-up or concept image.

## Runtime testing rule

Static contract validation is not considered gameplay evidence. A real gameplay result requires the Unity Editor or a packaged Unity player to execute the game.

Runtime reports must distinguish:

- Unity runtime exceptions/errors.
- Crashes/player termination.
- Class-selection failures.
- Movement failures.
- Skill failures.
- Command-routing failures.
- Save/load failures.
- Camera/player initialization failures.

## Unreal transition

Unreal 5.8 GitHub Actions workflows have been removed from the active CI path. The active Unreal 5.8 project/source/config artifacts have now been removed from the working tree. Their design logic is represented by the Unity C# equivalents under `Unity/Assets/Scripts/`; Git history preserves the previous Unreal implementation.

The user has also installed .NET 10.0.401. It is used for standalone migration/QA tooling in `Tools/`; Unity gameplay scripts target the Unity 6 managed runtime rather than forcing the Unity Editor to use the .NET 10 SDK.
