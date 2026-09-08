# Honour War — Production HD Asset Manifest

This directory tree is the visual source of truth for the final game.

## Mandatory production pipeline

**Blender → Substance 3D Painter → GLB/GLTF → Godot 4**

Do not replace this with primitive meshes as the final art pipeline.
Procedural geometry is allowed only as a development fallback when the
corresponding production asset has not yet been imported.

## Character assets

`assets/3d/characters/hero_warrior.glb`
`assets/3d/characters/hero_mage.glb`
`assets/3d/characters/hero_archer.glb`
`assets/3d/characters/hero_thief.glb`
`assets/3d/characters/hero_acolyte.glb`
`assets/3d/characters/hero_merchant.glb`

Each hero should contain:
- game-ready humanoid mesh
- UVs and PBR materials
- Skeleton3D-compatible rig
- armor/equipment attachment points
- idle, walk/run, attack, hit, skill and death animations
- sensible material slots for equipment overrides

## Pet assets

Use `pet_<stable_id>.glb`.

Required initial production set:
- `pet_royal_falcon.glb`
- `pet_astral_sprite.glb`
- `pet_blessed_poring.glb`
- `pet_dire_wolf.glb`
- `pet_night_panther.glb`
- `pet_merchant_companion.glb`

Pets require their own idle, locomotion, attack, hit and death animation set.

## Monster and MVP assets

Use:
- `monster_<stable_id>.glb`
- `mvp_<stable_id>.glb`

Production MVP examples include Orc Lord, Baphomet, Evil Druid, Fire Dragon,
Ice Titan, Queen Ant, Ancient Golem, Thanatos and Moonlight Dragon.

## Material contract

Substance 3D Painter should author:
- Base Color
- Normal
- Roughness
- Metallic where applicable
- Ambient Occlusion
- Emissive where applicable

Textures must be imported into Godot with appropriate color-space handling.
Avoid unnecessarily large textures; use 4K selectively for hero/MVP focal assets
and 2K/1K tiers for ordinary actors and props according to screen importance.

## Performance contract

Production assets should support:
- LOD0 hero/MVP quality
- LOD1 gameplay quality
- LOD2 distance quality
- GPU-friendly material counts
- baked/efficient secondary detail where appropriate
- clean collision/proxy geometry

## Runtime integration

`res://scripts/HDAssetRuntime.gd` automatically detects production GLB assets
when they are present and replaces the corresponding procedural visual while
preserving the existing gameplay actor references.

This lets gameplay development continue without blocking on every art asset,
while ensuring imported production art becomes the runtime representation as
soon as it is committed.
