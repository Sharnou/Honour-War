# Honour War — Sharnou IDE Universal Asset Automation

## Purpose

Sharnou-IDE is the format-agnostic intake and automation controller for Honour War + SharnouEngine.

The IDE accepts source material in any file format at the input boundary. Acceptance does not mean every source format is rendered natively. The IDE detects, validates, classifies, preserves, routes and canonicalizes each input before SharnouEngine validation.

## Canonical stack

Honour War -> Sharnou-IDE -> SharnouEngine -> Honour War runtime

The project id is always honour-war.

## Automatic job router

For each new, changed or requested file:

1. Detect format from extension/content.
2. Classify the source.
3. Validate before processing.
4. Select the registered Sharnou-IDE adapter.
5. Preserve the original source.
6. Generate the required intermediate/canonical representation.
7. Apply the Honour War runtime format policy.
8. Validate the generated representation with SharnouEngine.
9. Record provenance, source hash and generated hash.
10. Synchronize the project graph and diagnostics.
11. Do not download an external programming tool.

## Canonical runtime output

The runtime asset roles are complementary:

- .gltf / .glb: glTF 2.x 3D scene/model containers.
- .ktx2: Basis Universal 3D material textures, referenced from glTF with KHR_texture_basisu.
- .avif: shipped raster/2D visuals such as UI, HUD, icons, portraits, cards, menus, backgrounds and skyboxes.

AVIF-only therefore means the shipped raster/2D boundary. It does not prohibit glTF/GLB or KTX2.

FBX/OBJ are approved source/interchange model inputs. Any other format may enter at the IDE boundary and is converted when a registered Sharnou adapter can safely process it.

## Automatic project jobs

Honour War uses automatic jobs for format inspection, conversion/canonicalization, texture/material dependency resolution, SPP generation/compilation, project-graph synchronization, engine compatibility checks, incremental rebuilds, stale-output detection, runtime smoke/self-test, runtime-test, diagnostics and real-runtime evidence capture.

## Independence rules

The active Honour War path does not use, invoke, install or download another game engine or another IDE. It also does not bootstrap Visual Studio, MSBuild, Windows SDK development packages, CMake, vcpkg, Unity, Unreal Engine, or unrelated external programming tools.

Legacy IDE metadata is migration input only. Legacy IDE executables are never runtime controllers.

## Job record

Each job should preserve:

- job id
- project id
- source path/format
- source SHA-256
- job type
- adapter id
- target format/path
- target SHA-256
- engine contract
- status
- diagnostics
- created/completed timestamps

This makes format conversions reproducible and keeps Honour War synchronized with the Sharnou IDE + SharnouEngine contracts.
