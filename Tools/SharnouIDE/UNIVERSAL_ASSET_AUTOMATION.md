# Honour War — Sharnou-IDE Universal Asset Automation

Sharnou-IDE is the authoritative authoring and automation controller for the canonical honour-war project. It accepts registered source material at the intake boundary, identifies its format, validates it, routes conversion/import work through approved local adapters, and hands the canonical result to SharnouEngine.

Pipeline:

Honour War -> Sharnou-IDE -> SPP -> SharnouEngine -> Honour War runtime

Runtime roles are fixed:
- glTF 2.x / GLB: 3D scene and model containers.
- KTX2: 3D texture container bound through KHR_texture_basisu.
- AVIF: shipped 2D/raster visuals.

FBX/OBJ remain approved source/interchange inputs. The IDE may inspect and convert them; they are not the canonical shipped runtime representation.

The intake boundary is format-neutral, but runtime delivery is canonicalized to the roles above. No daily unattended upgrade mechanism is implied by this automation contract.
