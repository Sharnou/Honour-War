# Honour War — Godot 4 Vulkan / ICD Troubleshooting

## The error

```text
ERROR: Cannot find a compatible Vulkan installable client driver (ICD).
vkCreateInstance Failure
at: drivers/vulkan/vulkan_context.cpp:1085
```

This is a graphics-driver/runtime problem, not a gameplay script error. Honour War's production renderer is Godot 4 Forward+, which uses Vulkan in Godot 4.2.x.

## Windows — preferred fix

1. Identify the installed GPU in **Device Manager → Display adapters**.
2. Install the current driver directly from the GPU vendor:
   - NVIDIA: Game Ready/Studio driver
   - AMD: Adrenalin driver
   - Intel: current Arc/UHD/Iris graphics driver
3. Reboot Windows.
4. Verify that the GPU is not disabled in Device Manager.
5. Start Honour War again in Forward+.

Do not install a random Vulkan DLL from an unofficial download site. Vulkan ICD files belong to the graphics driver installation.

## Immediate safe launch

If the machine cannot initialize Vulkan yet, use:

`tools/run_honour_war_safe.bat`

or:

`powershell -ExecutionPolicy Bypass -File tools/run_honour_war_safe.ps1`

The launcher tries Forward+ first and automatically falls back to Godot Compatibility/OpenGL if Vulkan initialization fails.

This fallback is for development and compatibility. The final HD target remains Forward+.

## CI

GitHub Actions runners do not have a guaranteed physical Vulkan GPU. The HD CI therefore has two layers:

1. Renderer-independent Godot 4.2.2 validation using `gl_compatibility` so script/scene validation cannot fail because the runner lacks a Vulkan ICD.
2. A best-effort Forward+ Vulkan startup smoke test using the runner's available Mesa Vulkan ICD. Failure of that optional smoke test is reported as a warning rather than hiding a real script/scene failure.

The CI also installs `mesa-vulkan-drivers`, `libvulkan1`, `vulkan-tools` and `xvfb` so the runner can expose software/virtual Vulkan where available.

## Important distinction

Compatibility mode does **not** become the permanent art target. The production target remains:

**Blender → Substance 3D Painter → GLB/GLTF → Godot 4 Forward+**

Forward+ is required for the intended advanced lighting and rendering feature set. Compatibility is only the safety path for machines/runners without usable Vulkan support.
