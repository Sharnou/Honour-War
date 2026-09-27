# Honour War — Sharnou Engine HD Asset Manifest

The production visual library is generated and compiled by **SharnouEngine only** from canonical Honour War data and locked visual references.

## Active generation authority

- Generator: SharnouEngine
- IDE controller: Sharnou-IDE
- External generation: disabled
- External DCC/art generators: disabled
- Shipped external visual format: AVIF only
- Runtime geometry: SharnouEngine-native compiled representation

Historical Neural4D/Blender/FBX/OBJ material, when retained, is archive/reference content only. It is not an active generation input.

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

## Runtime visual policy

- Raster/visual delivery: .avif only.
- External runtime geometry containers: none.
- Geometry is compiled into a SharnouEngine-native runtime representation.
- Do not ship PNG/JPEG/WebP/GIF/BMP/TGA/DDS.
- Do not ship GLTF/GLB/KTX2.

## Native generation contract

SharnouEngine must be able to generate the canonical gameplay representation directly from the repository data contracts without invoking an external model generator or DCC. The generated result is then validated in the real SharnouEngine runtime.
