# Sharnou IDE integration

This folder is the authoritative Honour War integration point for Sharnou-IDE.

The project opens and validates through Tools/SharnouIDE/SharnouIDE.ps1. The runner has no package manager, compiler downloader, Visual Studio launcher, MSBuild invocation, Windows SDK installer, Unity invocation, Unreal invocation, CMake invocation, or vcpkg bootstrap.

The runner only performs three classes of work:

1. Validate the Sharnou Project Protocol manifest and repository policy.
2. Execute an already-built SharnouEngine.exe for self-test/runtime-test.
3. Launch the same SharnouEngine.exe for the game runtime.

The IDE repository itself remains the canonical editor implementation. Because the connected GitHub integration currently reports Sharnou/Sharnou-IDE as empty and denies write access, this integration layer is staged in Honour War until that repository can accept the generated IDE sources.

A native C++ executable cannot be created from C++ source without some compiler backend. This integration therefore treats the engine executable as a runtime artifact and does not falsely advertise a compiler-free native rebuild.
