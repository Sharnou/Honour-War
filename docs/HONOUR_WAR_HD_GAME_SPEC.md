# Honour War — HD Game Specification

## 1. Core presentation contract

Honour War is a fully 3D HD MMORPG/ARPG. The permanent production art pipeline is:

**Blender → Substance 3D Painter → GLB/GLTF → Godot 4**

The game uses a stylized low-poly/high-texture visual language: simple silhouettes and efficient geometry are combined with saturated anime-style PBR textures, painted architectural details, readable silhouettes, and restrained post-processing.

The world is not converted to 2D. Procedural geometry remains a fallback until production GLB/GLTF assets replace it through `HDAssetRuntime`.

## 2. Camera and movement contract

- Perspective 3D world presented as an isometric-style miniature diorama.
- Orthographic presentation is used by the current HD shell for deterministic MMO readability; production camera can use perspective without changing gameplay coordinates.
- Horizontal camera rotation: 360°.
- Vertical camera pitch: restricted to approximately -56° to -28°.
- First-person and straight-up views are prohibited.
- Left mouse button: move hero / select monster.
- Clicking a monster moves the hero to the class engagement distance and begins combat automatically.
- Middle mouse drag: free camera orbit.
- `A` / `D`: camera yaw only.
- `W` / `S`: camera pitch only.
- Keyboard movement never writes hero position.
- `ESC`: cancel destination/selection.
- Hero and monster positions are snapped to a strict 1 × 1 simulation grid.

## 3. Combat distance model

All authored distances are specified in meters and converted to the legacy map coordinate system by `WORLD_SCALE = 0.055`.

| Class | Engagement | Map units | Attack cadence |
|---|---:|---:|---:|
| Swordsman / Warrior | 2.4 m | 43.636 | 0.72 s |
| Mage | 7.5 m | 136.364 | 0.86 s |
| Archer | 12.0 m | 218.182 | 0.78 s |
| Ranger | 13.5 m | 245.455 | 0.74 s |
| Thief | 2.2 m | 40.000 | 0.64 s |
| Acolyte | 5.0 m | 90.909 | 0.90 s |
| Merchant | 2.4 m | 43.636 | 0.80 s |

**Swordsman/Warrior rule:** the hero must approach to approximately **2.4 m** before the basic attack can land. A distant target cannot be damaged by melee auto-attack.

**Archer/Ranger rule:** the hero can remain at long range and fires a visible projectile presentation. The projectile is presentation-only; authoritative damage remains in `CombatRuntime`.

## 4. Pet attack model

Every playable character automatically owns a combat pet. Pets do not require feeding to remain active. Pet progression includes levels, skills, equipment/refinement-compatible stats, and role behavior.

| Pet archetype | Role | Attack distance |
|---|---|---:|
| Falcon | Ranged | 9.0 m |
| Wolf | Melee | 2.6 m |
| Wolf Cub | Melee | 2.4 m |
| Dragon | Caster | 10.0 m |
| Guardian | Tank | 2.8 m |
| Sprite | Healer | 6.0 m |
| Shadowcat | Assassin | 3.0 m |

Pet AI chooses targets through role-aware threat logic. Guardian/Tank pets can intercept monster attacks; Healer pets sustain the hero; Assassin pets prioritize damage/status pressure; ranged/caster pets attack without forcing the hero into melee range.

## 5. Monster distance model

- Normal melee monster: approximately 2.4 m.
- Ranged monster: approximately 9.0 m.
- MVP/boss melee: approximately 3.5 m.
- Monsters chase only inside their configured chase radius.
- Monsters stop at their actual attack distance instead of a universal placeholder distance.
- Monster `attack_range_map` is authored by `CombatRules` and stored on the runtime monster state.

## 6. Combat architecture

`CombatRuntime` is the single authoritative simulation owner for:

1. Target acquisition.
2. Class-specific engagement checks.
3. Hero auto-attacks.
4. Pet auto-attacks.
5. Monster attacks.
6. Monster movement/chasing.
7. Status effects.
8. SP regeneration.
9. MVP skills.
10. Death/respawn.
11. Loot/save calls.

`CombatRules` is the central rule table. Presentation systems must not invent their own damage or range values.

### Event pipeline

`CombatRuntime`
→ `CombatEventBus`
→ animation timing / reaction director
→ combat feedback / VFX / floating numbers
→ optional projectile or skill presentation.

Damage is authoritative at the simulation layer. VFX and UI never apply a second copy of the damage.

## 7. Hero + Pet Bond

The bond system represents the coordinated hero/pet combat relationship. The visible status is **Bonding**, not the obsolete “Building” fallback text.

Bond milestones can trigger synchronized attacks, VFX, and finishers. Bond presentation must never become a second combat simulation.

## 8. 3D environment background

Maps are fully 3D scenes containing:

- Terrain meshes.
- Low-poly buildings.
- Painted doors and windows.
- Roof silhouettes.
- Trees and vegetation.
- Roads and plazas.
- Water/fountain landmarks.
- Distant hills and town silhouettes.
- Lighting and atmospheric depth.

Geometry is intentionally efficient. Small details that do not affect collision or gameplay are painted into textures in production assets rather than modeled as dense geometry.

`HDEnvironmentDirector` adds a deterministic procedural background layer while production assets are authored.

## 9. Art direction

### Geometry

- Low polygon count.
- Strong silhouette.
- Beveled hero/prop edges only where they improve highlights.
- No unnecessary micro-geometry.

### Texture language

- Hand-painted/anime-inspired surface information.
- Saturated but controlled palette.
- PBR maps authored in Substance 3D Painter for production assets.
- Painted windows, doors, roof tiles, signs, and trim on simple meshes.

### Characters

- Chibi/anime proportions.
- Oversized readable head/eyes.
- Compact bodies.
- Clear class silhouettes.
- Equipment and refinement remain visually readable.

### Monsters

- Friendly, strange, dark, or gothic silhouettes depending on species.
- Strong scale hierarchy between normal monsters and MVPs.
- Monster color and shape communicate threat before the player reads text.

### Town palette

Each town receives a distinct identity. Medieval towns use warm stone, banners, timber, saturated roof colors, and bright daylight; rustic/forest towns use autumnal wood, moss, warm lamps, and deeper greens; later regions can use gothic, desert, snow, or arcane palettes without changing the core rendering contract.

## 10. VFX and floating combat text

- 2D/flat particle textures are allowed to exist in 3D space.
- Skill effects scale and rotate with the actor/world.
- Critical hits use stronger scale, timing, and impact feedback.
- Damage numbers rise, briefly hold readability, then fade.
- MISS, HEAL, CRITICAL, poison, slow, and MVP skill indicators use distinct visual language.
- Archer attacks use visible arrow travel from attacker to target.

## 11. UI/window system

The interface is intentionally non-diegetic: clean windows sit above the world instead of pretending to be physical objects inside it.

The HD UI style uses:

- Dark translucent panels.
- Thin gold/neutral borders.
- Strong hierarchy for titles.
- Compact icon toolbar.
- Tooltips on icon controls.
- Minimal screen obstruction.
- Consistent spacing and typography.
- Separate windows for character, pet, skills, inventory, equipment, refinement, chat, and system controls.

`HDUIStyleDirector` provides the common visual language. Existing gameplay panels can adopt its `StyleBoxFlat` styles without requiring texture-heavy UI assets.

## 12. Icons

Core icon vocabulary:

- ⚔ Combat/Character.
- ♢ Bonded Pet.
- ◆ Skills.
- ▣ Inventory.
- ◇ Equipment.
- ✦ Refinement.
- ☰ System.

Production replacement icons should be authored as clean vector/SVG or painted UI textures at high resolution and supplied at 1x/2x/4x density where appropriate.

## 13. Performance tiers

### LOW

Reduced environment object count, simpler shadows, lower VFX density, and fewer distant decorations.

### HIGH

Full town set, normal shadow distance, standard VFX and actor detail.

### ULTRA

Highest environment density, extended shadow distance, richer particles, extra foliage, and production-resolution effects.

The gameplay simulation remains identical across tiers.

## 14. Production asset contract

Every production asset must have:

- Stable asset ID.
- GLB/GLTF source.
- Blender source scene.
- Substance Painter project/material source where applicable.
- Correct scale and origin.
- Named animation clips where animated.
- LOD plan for large worlds.
- Collision plan.
- Material slot documentation.
- Runtime replacement entry in the HD asset manifest.

## 15. Quality gates

Before an asset or system is considered complete:

1. It works in the Compatibility test environment.
2. It targets Forward+ for production.
3. It has no duplicate combat damage path.
4. Camera ownership remains singular.
5. Keyboard movement never controls the hero.
6. Mouse movement/targeting remains deterministic.
7. Class and pet ranges come from `CombatRules`.
8. UI remains readable at 1920 × 1080.
9. Production GLB/GLTF can replace the procedural fallback.
10. No obsolete “Building” bond label remains.
