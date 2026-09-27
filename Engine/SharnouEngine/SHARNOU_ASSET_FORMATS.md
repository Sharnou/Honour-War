# Sharnou Engine Asset Formats

Canonical runtime asset strategy:
- glTF 2.x (.gltf/.glb): 3D scene/model structure, meshes, nodes and animations.
- KTX2 (.ktx2): shipped GPU-facing 3D material textures using Basis Universal; glTF may reference them with KHR_texture_basisu.
- AVIF (.avif): UI, 2D art, menu backgrounds, skyboxes and distribution imagery.

Authoring/interchange:
- FBX and OBJ are accepted source-model inputs.
- Sharnou-IDE may intake any registered source format and route it through automatic conversion/validation jobs.
- Runtime output is normalized to the canonical formats above.

No Unity or Unreal runtime is involved. No external IDE/toolchain is downloaded.
