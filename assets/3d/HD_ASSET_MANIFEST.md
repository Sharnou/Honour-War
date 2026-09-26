# Honour War — Unreal 5.8 HD Asset Manifest

The production visual library is imported into Unreal Engine 5.8 from FBX/OBJ assets and authored texture maps.

## Hero library

hero_warrior
hero_mage
hero_archer
hero_thief
hero_acolyte
hero_merchant
hero_ranger

Each hero requires full body, face, hair, hands, legs, feet, equipment layers, class weapon and animation sets for idle, movement, combat, hit and death.

## Pet library

pet_falcon
pet_wolf
pet_wolf_cub
pet_dragon
pet_guardian
pet_sprite
pet_shadowcat

## Monster library

Normal, Elite and MVP families, each with unique silhouette, material treatment, attack profile, hit reaction and death animation.

## Environment library

Map families:
- town;
- forest field;
- mountain pass;
- desert ruins;
- snow region;
- arcane dungeon.

Each map requires primary, secondary and tertiary dressing passes.

## Props

Barrels, crates, carts, benches, market stalls, lamps, banners, fences, signs, wells, fountains, bridges, gates, flowers, rocks, trees and map-specific landmarks.

## Materials

Skin, hair/fur, cloth, leather, wood, stone, metal, glass/crystal, water and magic/emissive.

Required texture channels where applicable:
Base Color, Normal, Roughness, Metallic, AO, Emissive.

## Intake policy

Approved: FBX, OBJ.

Rejected: GLB, GLTF, Meshy and Godot runtime assets.

Procedural geometry in the C++ world bootstrap is development scaffolding only and must eventually be replaced by authored production assets.

## Runtime packaging formats

- Scene/model container: glTF 2.x (`.gltf` / `.glb`).
- 3D material texture container: KTX2 (`.ktx2`). Use `KHR_texture_basisu` for Basis Universal KTX2 textures referenced by glTF.
- 2D/UI/distribution raster: AVIF (`.avif`).
- Authoring/interchange inputs: FBX/OBJ; convert before runtime packaging.
- Do not ship PNG/JPEG/WebP/GIF/BMP/TGA/DDS as runtime raster textures.
