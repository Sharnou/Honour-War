# Honour War — Unreal 5.8 Visual Specification

## Target

Build an original Honour War 3D presentation driven by the locked repository references, with the density, readability and polish expected from a premium stylized fantasy MMORPG/ARPG.

## Character presentation

Every playable class needs a complete readable body:
- head, expressive face and hair;
- neck, shoulders, torso and layered clothing/armor;
- arms, hands/gloves;
- waist/belt;
- separate legs and boots;
- class-specific weapon;
- visible equipment variation;
- class silhouette that remains recognizable from normal gameplay distance.

The six base classes remain Warrior, Mage, Archer, Thief, Acolyte and Merchant. Ranger remains an advanced combat class.

## World presentation

The main town/field must never read as an empty flat plane. Use:
- shaped terrain and visible material transitions;
- stone/dirt roads with borders;
- varied medieval houses with roof structure, windows, doors, timber/stone details and signs;
- market stalls with goods;
- fountains, wells, benches, carts, barrels and crates;
- fences, banners, lamps and street dressing;
- layered vegetation with trunks, branches, leaves, bushes, grass and flowers;
- walls, towers, gates and distant landmarks;
- map-specific props and landmarks rather than copy/paste decoration.

## Materials

Production materials are authored with physically plausible response:
- skin;
- hair/fur;
- cloth;
- leather;
- wood;
- stone;
- metal;
- glass/crystal;
- water;
- magic/emissive.

Use Base Color, Normal, Roughness, Metallic, AO and Emissive where the asset benefits from them. Avoid flat color-only materials on final authored assets.

## Lighting

Maintain bright medieval daylight for the current baseline. Use strong directional sunlight, controlled skylight, contact shadows, ambient occlusion and atmospheric depth. Bloom and exposure should support readability rather than wash out the world.

## Camera

- Perspective.
- Isometric-style third-person composition.
- Approximate 45° yaw baseline.
- Approximate -48° pitch baseline, constrained between -62° and -28°.
- The hero remains visible as a complete figure during ordinary gameplay.
- The camera must not obscure the hero's feet or face at the default framing.

## Combat presentation

Attacks need anticipation, contact and recovery. Hits need:
- distinct impact moment;
- readable hit reaction;
- damage feedback;
- class-specific VFX language;
- projectile travel for ranged classes;
- stronger critical-hit feedback;
- restrained AOE indicators.

## UI

Use dark translucent panels, thin warm metallic/gold borders, clear typography, clean iconography and consistent spacing. The reference-driven profile, navigation, minimap, quest, chat and utility surfaces are the primary MMORPG interaction layers. Remove the old developer/command toolbar and bottom skill strip from the player-facing experience.

## Quality rule

The Unreal runtime may exceed the reference target but must not regress to sparse terrain, flat unlit geometry, primitive-only actors or missing full-body character presentation.
