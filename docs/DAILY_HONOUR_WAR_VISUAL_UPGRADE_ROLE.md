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

### Age-aware character visual direction
Character age is a real persistent gameplay attribute and must affect the character's visual presentation without being exposed as a floating world label.

The permanent reference profile `data/character_visual_profiles/elder_veteran_adventurer.json` defines an original older-adult character with a canonical display age of **68** and an allowed design range of **60–75**. This character is capable, active, intelligent, warm and respected.

Required dignified aging cues:
- slight balanced forward lean and gently rounded upper back;
- subtly lowered/forward shoulders;
- composed lifted gaze;
- controlled experienced steps and an appropriate staff/cane/sword/spear/staff/merchant cane/umbrella weight shift;
- mild forehead, eye-corner and mouth lines;
- gentle crow's-feet and lightly lowered eyelids;
- defined cheekbones and jaw;
- silver/gray/white/salt-and-pepper hair and optional neat gray beard;
- thick eyebrows with gray strands;
- visible story details such as rings, prayer beads, old scars, calluses, repaired seams, worn leather, scratched metal, medals, notes, scrolls, tools, pouches or family emblems;
- no helpless, sickly, grotesque or comic stereotype.

The character must remain readable from 10–25 meters in the elevated semi-isometric camera through a memorable silhouette: staff/cane/weapon/book/lantern/umbrella, layered cloak or mantle, distinctive hair/beard/hat/hood/spectacles/collar, and one asymmetric detail.

The face must be kind, alert, wise and observant with stylized expressive eyes and limited natural facial lines. Avoid pores, excessive wrinkles, extreme drooping or zombie-like features.

Use muted fantasy base colors such as faded navy, burgundy, forest green, dusty purple, warm brown leather, aged bronze, parchment cream, charcoal gray or muted teal with one controlled accent such as amber, emerald, crimson, violet, blue crystal or gold embroidery. Avoid pure-white overexposure and excessive glow.

Technical target: stylized hand-painted PBR authored directly in native Godot scenes/resources, Godot 4 Forward+, 1,500–4,000 triangles and 1024x1024 texture for an important NPC, 700–1,500 triangles and 512x512 texture for background NPCs, with LODs for busy towns. The retired HD GLB/GLTF pipeline must not be restored. Animation set includes idle, walk, talk, greeting, combat, hurt, victory and death. Test at the actual Honour War gameplay camera distance.

This character and all future age-aware characters must be **original Honour War designs** and must not copy Ragnarok Online or any other existing game's character, costume, hairstyle, equipment, art or icon.

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

### Player identity and social UI — permanent rule
- The **owner's character name is never rendered above or below their own character**.
- Other players do **not** display a permanent floating nameplate.
- A remote player's **real character name** is revealed only while the mouse is over that player, when the player is relevant to party/PvP context, or through an explicit social/chat reveal.
- Never substitute a class label such as `Swordsman` for the real player name.
- Player class and level are not displayed as permanent floating world labels.
- Character age is never displayed in the floating world identity display.
- Player HP/SP bars are never rendered as permanent world-foot bars for local or remote player avatars.
- Enemy combat HP bars remain allowed. Party/PvP player health may appear only in dedicated target/social/combat UI rather than as permanent world-foot bars.
- Right-clicking another player opens the player context UI and provides an **EQUIP** action for inspecting that player's equipment.
- Character Status and Equipment are one combined window; stat-point allocation is available in the same window as equipment.
- ESC opens exactly three top-level character choices: **Create New Character**, **Switch Characters**, and **Options**.
- Create New Character is a complete page with real character-name entry and class selection.
- Switch Characters is a character-selection page tied to the existing save system.
- Options is a dedicated settings page and must not replace the three-choice ESC structure.

### Honour War HD character asset-sheet visual specification — permanent
Every character generated or regenerated for Honour War must use this visual specification as a mandatory Daily Upgrade art-direction gate.

### Style
- Stylized 3D NPR presentation.
- Vibrant anime cel-shading with rich saturated colors.
- Clean, controlled line-art outlines.
- High-fidelity realistic anime proportions within the stylized Honour War HD aesthetic.
- The result must read as a finished game character, not a concept-only render or generic procedural placeholder.

### Geometry
- Volumetric, chunky hair with a crisp anisotropic halo highlight.
- Expressive stylized facial structure.
- Sharp triangular nose-profile shadow for readable anime facial planes.
- Smooth, flawless porcelain complexion.
- Full body must remain visible in gameplay capture: face, hair, hands, clothing layers, legs and feet.

### Materials
- Highly detailed PBR textures.
- Robes/clothing: matte, unreflective woven-fabric texture.
- Boots/leather: supple textured brown leather with fine micro-scratches.
- Armor accessories: high-contrast brushed steel with step-clamped highlight behavior.
- Material response must remain clean and readable; avoid noisy procedural texture breakup.

### Lighting and atmosphere
- Warm volumetric ambient sunlight.
- Soft lavender-tinted shadows.
- Clean solid-grey presentation background for asset-sheet/reference captures.
- Isometric presentation perspective for asset-sheet inspection.
- No realistic skin pores, photorealistic dirt, or noisy/gritty texture treatment.
- In-game lighting must preserve the same material/color/shape language while remaining readable at the actual Honour War camera distance.

### Asset-sheet QA
For every important character, the Daily Upgrade must inspect front, side and back silhouettes plus face/profile, expressions, equipment/material details and representative combat/skill poses before approving the asset for runtime use. Class identity, tier progression, weapon silhouette, face, legs and pet relationship must remain unambiguous.

### Approved generation and runtime handoff
- Neural4D is an approved optional generation source.
- Meshy is permanently rejected.
- Neural4D GLB export is forbidden.
- Preferred handoff: FBX for rigged/animated characters, pets and monsters; OBJ for approved static assets.
- Final runtime must be native Godot 4.7.2 scenes/resources with Forward+ presentation.
- The Screenshot/ folder is the visual reference only; reference images must never be pasted into the game as fake graphics.

## Daily upgrade execution rules

For every upgrade:
1. Inspect the current implementation for visual placeholders, missing assets and duplicate-looking actors.
2. Compare the highest-impact visible mismatch against the reference contract.
3. Fix the mismatch in the actual project rather than documenting it as future work.
4. Preserve the existing Honour War gameplay architecture; do not restart the project.
5. Verify that approved non-GLB source assets (preferably Neural4D FBX/OBJ when generated) are actually normalized into native Godot resources and are not overwritten by procedural placeholder presentation.
6. Verify camera framing keeps the hero full-body and readable.
7. Verify class/pet/monster silhouettes remain distinct.
8. Verify attack/hit/skill effects visibly communicate combat.
9. Verify maps contain primary, secondary and tertiary visual detail.
10. Verify age is persisted per character and affects gameplay/visual progression without appearing in the floating world identity display.
11. Verify player identity rules: owner-hidden name, remote names hidden by default, real-name reveal only on hover/social party-PvP context/chat reveal, no floating player class/level/age, no permanent player HP/SP foot bars, and right-click Equip.
12. Verify Character Status and Equipment remain one combined window with working stat points.
13. Verify ESC exposes exactly Create New Character, Switch Characters and Options, with all three pages functional.
14. Run static/runtime/CI validation after meaningful changes.
15. When a rendered frame or Windows build is available, inspect the rendered presentation for visual regressions. Static CI must not be described as proof of visual parity.
16. Continue automatically to the next highest-impact visual deficiency instead of stopping after a single script-level fix.

## Permanent production pipeline

**Approved generation → FBX/OBJ → native Godot 4.7.2 resources/scenes → Godot 4 Forward+**

Neural4D: optional character/creature/static-asset generation source.
Blender: optional mesh, rig and animation refinement/authoring.
Substance 3D Painter: optional PBR material authoring.
FBX: preferred interchange for rigged/animated characters, pets and monsters.
OBJ: preferred interchange for approved static assets.
Godot 4.7.2: native resource/scene normalization, runtime rendering, animation integration, lighting, VFX, gameplay, UI and streaming.
GLB/GLTF generated production assets: permanently excluded.
Meshy: permanently rejected.

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
- required visual files are missing or broken;
- a player's own name is shown as a floating world label;
- another player's real name is permanently shown without hover/social context;
- `Swordsman` or another class name is used as the permanent player nameplate;
- character age is shown in the floating world identity display;
- a permanent player HP/SP foot bar is shown;
- Status and Equipment are split into competing windows;
- ESC does not present exactly the three requested character-management choices.

This role remains active for all future Daily Honour War Upgrades.
