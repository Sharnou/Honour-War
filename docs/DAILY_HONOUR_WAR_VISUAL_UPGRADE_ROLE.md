# Daily Honour War Upgrade — Permanent Visual Fidelity Role

## Authority

This document is a permanent production rule for every Daily Honour War Upgrade.
The authoritative visual references are the saved project images:
- `Honour War Fantasy MMORPG Showcase.png`
- `Honour War Fantasy MMORPG Interface.png`

These references define the **minimum visual information density and presentation quality**. They are the target to reproduce with original Honour War assets and implementation; they are not optional inspiration.

## Role

Every Daily Honour War Upgrade must operate as all of the following at once:

**Visual Fidelity Engineer + Fantasy MMORPG Art Director + Gameplay Presentation QA + Asset Completeness Reviewer**

The job is to continuously move the actual playable game toward the reference visual level, not merely add scripts or UI labels.

## Reference analysis contract

### Overall image quality
- High-resolution, crisp fantasy MMORPG presentation.
- Detailed anime/fantasy character rendering with strong silhouettes.
- Richly modeled environments instead of primitive blocks.
- Clear material separation: skin, hair, metal, leather, cloth, wood, stone, fur and magic.
- Strong contrast and controlled fantasy color accents.
- Small visual details remain readable at gameplay distance.
- Clean, polished blue/navy fantasy HUD panels with crisp white/gold headings and icons.

### Heroes
Six core classes must remain immediately distinguishable:
- **Warrior:** heavy armor, broad silhouette, large sword, metal/leather detail and red/warm accents.
- **Mage:** layered blue/purple robes, staff/orb focal point and magical illumination.
- **Archer:** green/leather outfit, bow/quiver and agile silhouette.
- **Thief:** dark asymmetric clothing, hood/scarf language and dual blades.
- **Acolyte:** ceremonial white/cream layered robes, sacred/healing motifs and staff.
- **Merchant:** reinforced practical clothing, pack/tools/goggles and trade equipment.

The hero must show face, hair, hands, clothing layers, weapon, legs and feet. Normal gameplay framing must not crop the face or lower body. Character progression must be visible through actual model/equipment/material changes, not only a level number.

### Pets
Permanent combat pets need distinct silhouettes and species identity. Reference examples include Dire Wolf, Astral Sprite, Royal Falcon, Night Panther, Blessed Poring and Merchant Companion.

Every pet needs readable idle, locomotion, attack, skill, hit and death presentation, with growth/equipment/refinement communicated visually without destroying proportions.

### Monsters and MVPs
The reference requires a broad visual roster including Poring, Goblin, Orc, Skeleton, Zombie, Wolf, Mantis, Golem, Evil Druid and Dragon, plus stronger threats such as Bloody Knight/Dark Lord-class enemies.

Each monster must have unique proportions, silhouette, face/body construction, materials, attack behavior, hit reaction, death behavior, HP/name/level presentation and attack VFX. Distinct monster IDs must not collapse to the same generic model.

### Equipment and items
The reference visibly presents Sword, Spear, Axe, Bow, Dagger, Staff, Wand and Hammer, plus Helmets, Armor, Cloaks, Shoes, Shields and Accessories.

Items/cards/equipment are visual assets, not text-only records. Models and icons must remain crisp and recognizable. Refinement must have visible progression:
- +0–+4 normal;
- +5–+7 subtle premium treatment;
- +8–+10 visible energy accents;
- +11–+13 strong rarity treatment;
- +14–+15 prestige-grade glow/effects.

### Quest/UI iconography
Quest categories in the reference include Main, Side, Daily, Repeatable, Guild, Story, Event, Hunt, Crafting and Building. Icons must have clear silhouettes and readable frames at their actual UI size.

### Maps and world detail
Reference locations include Prontera-style main city, Morroc desert, Payon forest, Geffen magic city, Juno, Alberta snow, dungeon/underground, Izlude port and Rune-Midgarts-style adventure land.

Every map must have:
1. **Primary detail:** terrain, architecture, roads, water and major landmarks.
2. **Secondary detail:** buildings, roofs, bridges, walls, vegetation, rocks, signs, furniture, market props, lamps, docks and gameplay landmarks.
3. **Tertiary detail:** material breakup, decals, flowers, grass variation, debris, particles, fog and storytelling props.

Towns should look lived-in. Fields should have navigational landmarks and varied monster populations. Dungeons need depth and environmental storytelling. End-game zones need clear visual escalation.

### Combat / attacks / hits
The reference combat presentation shows a detailed hero fighting a large target with full silhouettes, directional attack effects, bright impact contact, damage numbers, HP/name bars, skill icons and visible environment.

All combat presentation follows:
**anticipation → contact → impact → recovery**

Use three VFX levels:
- **Contact:** slash arcs, weapon trails, hit sparks, projectile impacts.
- **Gameplay:** target markers, telegraphs, AoE boundaries, status effects, healing and critical-hit feedback.
- **Spectacle:** ultimates, boss phases, finishers and major elemental/world effects.

Reference effect language includes Slash, Fireball, Ice Nova, Lightning, Heal, Holy Light, Poison, Wind Storm, Critical Hit, Ultimate, Explosion and Teleport. Each effect must be visually distinguishable; do not use one generic explosion for every class.

### Animation
Every hero, pet and important monster should visibly support:
**Idle → Walk/Run → Attack → Hit → Skill → Death**

Animation timing must synchronize with authoritative combat events. Hit reactions must communicate actual contact. Death must complete visibly rather than instantly deleting the actor.

### HUD and world interface
The target HUD contains:
- character portrait, level, class, HP and SP;
- ATK, DEF, MATK, MDEF and age;
- pet and pet skills;
- skill tree;
- inventory/equipment/refinement;
- world map with towns/dungeons/fields/warp points;
- `@go [map]` fast travel;
- chat tabs/system messages;
- bottom action/skill bar;
- right-side functional menu.

Buttons must be functional system entry points, not decorative placeholders.

### Lighting and materials
Normal world presentation uses bright daylight fantasy lighting while preserving rich PBR detail. Production materials should use Base Color, Normal, Roughness, Metallic, AO and Emissive where appropriate. Lighting must reveal faces, armor, monsters and terrain rather than flattening them or hiding gameplay telegraphs.

## Daily upgrade execution rules

For every upgrade:
1. Inspect the current implementation for visual placeholders, missing assets and duplicate-looking actors.
2. Compare the highest-impact visible mismatch against the reference contract.
3. Fix the mismatch in the actual project rather than documenting it as future work.
4. Preserve the existing Honour War gameplay architecture; do not restart the project.
5. Verify that authored GLB/GLTF assets are actually used at runtime and are not overwritten by procedural placeholder presentation.
6. Verify camera framing keeps the hero full-body and readable.
7. Verify class/pet/monster silhouettes remain distinct.
8. Verify attack/hit/skill effects visibly communicate combat.
9. Verify maps contain primary, secondary and tertiary visual detail.
10. Run static/runtime/CI validation after meaningful changes.
11. When a rendered frame or Windows build is available, inspect the rendered presentation for visual regressions. Static CI must not be described as proof of visual parity.
12. Continue automatically to the next highest-impact visual deficiency instead of stopping after a single script-level fix.

## Permanent production pipeline

**Blender → Substance 3D Painter → GLB/GLTF → Godot 4 Forward+**

Blender: mesh, rig and animation authoring.
Substance 3D Painter: PBR material authoring.
GLB/GLTF: production interchange.
Godot 4 Forward+: runtime rendering, animation integration, lighting, VFX, gameplay, UI and streaming.

## Hard rejection conditions

A Daily Upgrade must reject or fix the result when:
- the hero becomes a primitive or loses full-body readability;
- classes become visually indistinguishable;
- monsters become generic duplicates;
- maps remain empty/primitive where production detail is expected;
- weapons/cards/items are text-only or generic placeholders;
- attacks/hits have no visible contact/impact feedback;
- production assets exist but runtime selects a low-detail substitute;
- procedural updates reset authored asset scale/grounding;
- the camera crops face/legs/feet or obscures the pet/target;
- materials are flat and indistinguishable;
- lighting destroys silhouette/readability;
- required visual files are missing or broken.

This role remains active for all future Daily Honour War Upgrades.
