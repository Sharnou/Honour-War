# Honour War — SharnouEngine Runtime Asset Pipeline

## Canonical architecture

Honour War is a **3D HD MMORPG/ARPG** running on **SharnouEngine**. SharnouEngine follows a GFC-inspired game-framework architecture while adding the Honour War-specific renderer, world, gameplay, networking, persistence and authoring contracts.

`Sharnou-IDE -> Sharnou project protocol -> SharnouEngine -> Honour War runtime`

The legacy Unity tree is historical/reference content only and is not a runtime dependency.

## Correct runtime formats

| Role | Canonical format |
|---|---|
| 3D scene/model container | glTF 2.x (`.gltf`; `.glb` may be accepted by the engine) |
| 3D GPU textures | KTX2 / Basis Universal (`.ktx2`) |
| glTF texture binding | `KHR_texture_basisu` |
| UI/2D raster | AVIF (`.avif`) |
| FBX/OBJ | authoring/interchange input only; never a shipped runtime dependency |

PNG/JPEG/WebP/GIF/BMP/TGA/DDS are not canonical shipped raster formats.

## Corrected mistake: the registry is not a content generator

The earlier `indexed=1` result was not evidence that the gameplay catalog contained only one asset. It correctly reported the physical runtime files that existed in the checkout: one glTF fixture. The repository already contains substantial data catalogs, including character, monster, map, equipment, card, pet, pet-skill and pet-equipment records.

The fix is to make the **SharnouEngine runtime generator** consume those catalogs and materialize a deterministic runtime asset plan. It must not invent fake binary files merely to make the registry count increase.

Run:

```powershell
Set-Location C:\Users\AhmeD_SHarnOU\Downloads\Engine\Latest\Honour-War-main
python .\Tools\sharnou_honour_war_runtime_generator.py .\data\honour_war_content_catalog.json
python .\Tools\sharnou_asset_registry.py . --output .\Build\Runtime\honour_war_asset_registry.json
python .\Tools\sharnou_resource_cache.py .\Build\Runtime\honour_war_asset_registry.json --output .\Build\Runtime\honour_war_resource_cache.json
```

The generator creates deterministic glTF scene identities for every catalog record and records the corresponding KTX2 and AVIF runtime paths. Binary codec adapters owned by Sharnou-IDE/SharnouEngine must provide the actual KTX2/AVIF payloads. A placeholder byte sequence must never be presented as a real texture.

## HD character rule

Every character's visual identity is derived from:

- canonical character name
- class
- tier
- gender
- `visual_profile`

This controls deterministic visual accents, hairstyle/accessory families, material accents, class silhouette and tier progression without changing gameplay statistics. Clothing supports capes, coats, robes, skirts, scarves and other secondary-motion elements, with bone-driven fallback when full cloth simulation is unavailable.

## Full existing content target

The current content contract targets:

- 70 character profiles
- 7 classes × 5 tiers × male/female progression
- 256 monsters
- 24 maps
- 300 equipment records
- 300 cards
- 20 pets
- 120 pet skills
- 100 pet equipment records

The content catalog remains authoritative for gameplay data. The graphics manifest is authoritative for presentation and runtime-format rules.

## No fake screenshots

A generated descriptor, glTF placeholder scene, registry entry or test fixture is not a game screenshot. Real screenshots require a built SharnouEngine runtime rendering the actual generated assets. Validation must distinguish static contract tests from real runtime/render tests.
