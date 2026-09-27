# Honour War runtime asset policy

Honour War uses Sharnou-IDE for authoring/intake automation and SharnouEngine for canonical runtime validation and execution.

## Runtime representation

- .gltf / .glb are the canonical 3D scene/model containers.
- .ktx2 is the canonical 3D texture container and glTF textures use KHR_texture_basisu.
- .avif is the canonical shipped 2D/raster visual format for UI, menus, backgrounds, skyboxes, and similar raster content.

## Source intake

The Sharnou-IDE intake boundary is format-neutral. FBX/OBJ and other registered source formats may be inspected, converted, and validated before canonical runtime packaging. Original sources remain preserved as authoring/interchange material.

## Pipeline

source intake -> Sharnou-IDE -> SPP -> SharnouEngine canonicalization/validation -> Honour War runtime

External game engines, external IDE authoring, automatic toolchain downloads, and external programming-tool bootstrap are not part of the Honour War runtime pipeline.
