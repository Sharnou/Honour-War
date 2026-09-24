# Honour War — Permanent Unity Version Lock

Honour War is permanently pinned to:

- **Unity Hub:** 3.21.3
- **Unity Editor:** 6000.0.71f1
- **Release line:** Unity 6.0 LTS
- **Target:** Windows 64-bit

Do not change the Unity Editor or Unity Hub version as part of normal Honour War development, testing, bug fixing, or content work.

The project metadata is enforced by:
- `Unity/ProjectSettings/ProjectVersion.txt`
- `Build/Run-Unity-5m-Test.ps1`

The runtime test script refuses to build with a different Unity 6.0.x Editor. A future engine migration requires an explicit project-engine migration decision rather than an automatic version change.

Note: the repository can pin the required Editor version, but Unity Hub itself is an installed desktop application. This file records the required Hub baseline; the local Hub installation must remain 3.21.3.
