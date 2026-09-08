# Honour War — HD Graphic Design Direction

## Creative target

Honour War is a stylized, premium fantasy MMORPG/ARPG. The reference target is
high-resolution game presentation: detailed silhouettes, expressive characters,
readable combat, rich PBR surfaces, layered environments and cinematic effects.
The goal is not generic realism. Every asset must communicate class, faction,
rarity, role and gameplay purpose at normal gameplay distance.

## 1. Hero visual language

Six core classes:
- Warrior — heavy armor, broad silhouette, large melee weapon, strong warm metal
  and leather breakup.
- Mage — elegant layered robes, magical focal points, luminous staff/orb details.
- Archer — agile silhouette, bow/quiver identity, light armor and practical leather.
- Thief — compact asymmetric silhouette, dual-blade/stealth language, dark cloth.
- Acolyte — ceremonial layered cloth, healing motifs, sacred light accents.
- Merchant — practical reinforced clothing, tools, packs and trade equipment.

Hero LOD0 should carry the highest detail. Face, hair, hands, weapon and chest
silhouette receive priority because they dominate player recognition.

## 2. PBR material standard

Substance 3D Painter is the authoritative material authoring stage.
Every production material should define, as applicable:
- Base Color
- Normal
- Roughness
- Metallic
- Ambient Occlusion
- Emissive

Use physically plausible roughness variation rather than flat color blocks.
Edge wear must support form and material identity, not become random noise.
Metal, leather, cloth, wood, stone, skin, fur and magic surfaces must have
visibly different microstructure.

## 3. Equipment detail

Equipment is a first-class visual system. Armor, weapons and headgear should
be attachable without rebuilding the hero mesh. Rare and upgraded equipment
needs readable visual progression.

Refinement progression:
- +0 to +4: normal presentation
- +5 to +7: subtle premium treatment
- +8 to +10: visible energy accents
- +11 to +13: strong rarity treatment
- +14 to +15: prestige-grade glow and effects

Effects must remain readable without obscuring the character silhouette.

## 4. Pets

Every character has one permanent bonded combat pet.

Pet visual requirements:
- unique silhouette
- species-specific locomotion
- idle personality
- attack animation
- hit reaction
- death animation
- skill animation language
- equipment/refinement presentation where applicable
- level/bond growth communicated visually but without excessive scale inflation

Initial visual identities include Dire Wolf, Astral Sprite, Royal Falcon,
Night Panther, Blessed Poring and Merchant Companion.

## 5. Monsters and MVPs

Normal monsters need a strong silhouette and readable attack telegraph.
MVPs are spectacle assets and receive the highest non-hero art budget.

MVP requirements:
- distinctive silhouette
- LOD0 hero-quality mesh
- custom materials
- multiple attack/skill animations
- hit/death reactions
- unique emissive/VFX language
- arena/environment integration
- loot presentation

## 6. Environment design

World spaces are divided into:
- towns/cities
- forests
- fields
- caves
- ruins
- deserts
- snow fields
- end-game boss zones
- dungeons

Each zone requires three visual layers:
1. Primary architecture/terrain silhouette.
2. Secondary props, vegetation, rocks, signs, furniture and gameplay landmarks.
3. Tertiary decals, material breakup, particles, fog and small storytelling detail.

Towns should feel lived-in. Fields need navigational landmarks. Dungeons need
strong depth, controlled lighting and combat readability. Boss zones need a
clear visual escalation without destroying performance.

## 7. Lighting and atmosphere

Godot 4 Forward+ is the runtime presentation baseline.

Use:
- directional key light
- restrained fill/rim lighting
- contact/ambient shading
- SDFGI where appropriate
- SSAO/SSIL
- volumetric fog
- bloom/glow for emissive gameplay effects
- controlled exposure/tonemapping

Lighting must preserve gameplay readability. A beautiful effect that hides an
enemy telegraph is considered a failed effect.

## 8. Animation direction

Hero animation priority:
Idle → Walk/Run → Attack → Hit → Skill → Death.

Pet animation priority:
Idle → Locomotion → Attack → Skill → Hit → Death.

Animation should communicate anticipation, contact/impact and recovery. Attack
impact must line up with authoritative combat events rather than merely playing
an animation whenever a damage number appears.

## 9. Combat VFX

Combat effects use a three-layer hierarchy:
- Contact: hit spark, slash, projectile impact.
- Gameplay: telegraph, target lock, status effect, AoE boundary.
- Spectacle: ultimate, MVP phase, finisher and major world event.

Color, shape and motion should encode gameplay meaning consistently. VFX should
support the hero/pet combo system without visually merging all attacks into one
indistinguishable explosion.

## 10. Camera and composition

The default camera is an elevated isometric/orthographic-style MMO presentation.
Keep the hero, bonded pet and active target readable in the central gameplay
area. HUD occupies reserved screen regions and should not compete with combat.

Camera movement should be smooth but responsive. Target-facing must never fight
attack animation rotation.

## 11. Asset budgets and LOD

Screen importance controls budget:
- Hero / active MVP: highest detail.
- Bonded pet / elite: high detail.
- Normal monsters: medium detail.
- Distant NPCs/props: low detail.

Every production actor should be authored with LOD planning. Texture resolution
should be selected by screen coverage rather than asset prestige alone.

## 12. Import contract

Blender exports GLB/GLTF with clean transforms, game-ready naming, skeletons,
animations and material slots. Substance exports are packed into the agreed
PBR channels. Godot imports the resulting GLB/GLTF and owns runtime animation,
lighting, VFX, gameplay and streaming.

Stable IDs are mandatory:
`hero_<class>`, `pet_<id>`, `monster_<id>`, `mvp_<id>`, `weapon_<id>`,
`armor_<id>`, `map_<id>`, `prop_<id>`, `effect_<id>`.

## 13. Quality gate

An asset is not production-ready until it passes:
- silhouette/readability review
- topology/UV review
- material/PBR review
- rig/animation review
- GLB/GLTF import review
- Godot Forward+ lighting review
- LOD/performance review
- gameplay readability review

The production pipeline is permanently:

**Blender → Substance 3D Painter → GLB/GLTF → Godot 4**
