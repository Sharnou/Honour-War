# Honour War — Unreal Engine 5.8 HD Art Direction

Honour War is a premium stylized medieval/fantasy MMORPG/ARPG. The visual target is controlled by the repository Screenshot references and implemented as original real-time 3D assets in Unreal Engine 5.8.

## Hero language

Six base classes:
- Warrior — layered armor, strong silhouette, large melee weapon.
- Mage — robes, staff/orb, magical focal points.
- Archer — bow, quiver, light armor and practical leather.
- Thief — asymmetric dark clothing, dual blades.
- Acolyte — ceremonial cloth, healing motifs and sacred accents.
- Merchant — reinforced trade clothing, packs and practical equipment.

Ranger is an advanced combat class.

Every hero must remain full-body readable with face, hair, hands, legs, feet, clothing layers and equipment visible at normal gameplay distance.

## Environment language

Maps are authored environments, not flat templates. The target includes:
- terrain variation and ground breakup;
- stone/dirt roads with borders and transitions;
- complete medieval buildings with walls, roof structures, windows, doors, trim and signs;
- markets and lived-in props;
- fences, banners, lamps, carts, benches, barrels and crates;
- layered trees, branches, leaves, bushes, grass and flowers;
- walls, towers, gates and distant landmarks;
- map-specific landmarks for towns, fields and dungeons.

## Material language

Use production PBR materials for skin, hair/fur, cloth, leather, wood, stone, metal, crystal/glass, water and magic. Author Base Color, Normal, Roughness, Metallic, AO and Emissive as appropriate.

## Lighting

The current baseline is bright daylight. Use a strong directional sun, skylight, readable contact shadows, ambient occlusion and atmospheric depth. Avoid overexposure and excessive bloom.

## Camera

Perspective third-person with an isometric-style composition. Default baseline is roughly 45° yaw and -48° pitch, with readable pitch limits between -62° and -28°. The hero's face and feet must remain visible in ordinary gameplay framing.

## Combat

Attacks should communicate anticipation, contact and recovery. Hit presentation uses readable impact VFX, hit reactions, damage feedback and distinct class skill effects. Ranged classes use visible projectile travel.

## UI

The player-facing HUD is dark/translucent with warm metallic-gold accents, strong typography and compact spacing. The center-bottom 8-slot COMBAT SKILLS bar is the primary combat interaction surface. No developer/command toolbar is visible.

## Production interchange

Visual RAG → Neural4D or Blender → Substance 3D Painter → FBX/OBJ → Unreal Engine 5.8.

GLB, GLTF, Meshy and Godot are permanently rejected for Honour War runtime production.

## Quality floor

The final game must not regress to sparse terrain, primitive-only actors, flat unlit geometry, missing full-body characters or generic UI. A real Unreal runtime frame is required for final visual acceptance.
