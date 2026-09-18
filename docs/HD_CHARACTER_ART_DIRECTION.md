# Honour War HD Character Art Direction and Progression

## Purpose

This document is the canonical visual-art direction for the six playable Honour War MMORPG character families: Warrior, Mage, Archer, Thief, Acolyte and Merchant. It is intended to be handed to an AI concept-painting workflow and then used as the visual reference for Blender, Substance 3D Painter, GLB/GLTF export and Godot 4.7.2 integration.

Honour War is an HD online MMORPG/ARPG. Characters must read as complete three-dimensional people rather than floating heads, low-poly placeholders, billboard sprites or cropped torsos. Every production character must show the complete body, face, hair, hands, footwear, equipment silhouette, class identity and readable animation deformation. The camera must not hide the legs or feet during normal gameplay. Materials should have physically readable differences between skin, cloth, leather, wood, painted metal, polished metal, glass, gems and magical energy.

The visual target is high-detail fantasy MMORPG presentation inspired by the readability, proportions and class identity of classic Ragnarok Online character design, while remaining an original Honour War production asset. Do not copy a copyrighted character, sprite, logo or exact costume. Preserve the six-class fantasy archetypes and their strong silhouettes.

## Universal anatomy and model requirements

Each hero needs a full humanoid body with a clean production topology, separate face/eye/hair/cloth/armor/weapon geometry where useful, and enough deformation quality for walking, running, attacking, casting, sitting, hit reactions, death and revival. Feet must be complete meshes with visible soles and ankle articulation. Hands must have individually readable fingers when the camera is close enough to see them. The face needs eyelids, brows, lips, nose bridge, ears and a controlled facial silhouette. Hair should use layered meshes or cards with enough depth to avoid a flat wig appearance.

Skin should have subtle roughness variation, natural subsurface response where appropriate, micro-normal detail, and carefully controlled specular response. Eyes should have a sclera, iris, pupil, wet cornea and catchlight. Teeth should not look like a single white block. Lips should have a distinct material transition. Ears must not be omitted. Hair needs root-to-tip color variation and several large silhouette locks before secondary strands are added.

The clothing stack should be physically believable: inner garment, tunic/robe/underlayer, outer garment, armor, straps, belts, pouches and accessories should not z-fight or occupy exactly the same surface. Seams, stitching, hems, buckles, rivets, embossed symbols, scratches, dust, worn edges and material roughness are important because these micro details prevent the world from looking like untextured primitives.

Every character gets class-bound equipment progression. Equipment slots are weapon, shield, head_upper, head_middle, head_lower, armor, garment, shoes, accessory_1 and accessory_2. Up to four cards may be socketed into supported equipment. Refinement reaches +15 and uses Phracon, Emveretarcon and Oridecon. Equipment visual upgrades should remain readable at each major progression tier without destroying the base class silhouette.

## Global progression visual language

Level 1 Foundation: the character looks capable but newly established. Equipment is practical, lightly worn and visually simple. The silhouette is immediately recognizable by class.

Level 25 Specialization: class identity becomes stronger. Branch equipment and accessories begin to appear. Warlord, Guardian, Berserker and Dragoon Warrior branches must look different; the same principle applies to all six classes.

Level 50 Advanced: the character has a mature class silhouette, upgraded materials and visibly stronger equipment. Weapon shape, armor construction, class ornaments and spell effects become more elaborate.

Level 150 Fourth Job / Mastery: this is a major visual transformation. The character must look like an experienced high-level adventurer with advanced materials, refined equipment, stronger aura treatment and distinctive fourth-job motifs. Fourth jobs are Transcendent Knight, Transcendent Wizard, Transcendent Ranger, Transcendent Assassin, Transcendent Saint and Transcendent Forge Master.

Level 200 Fifth Job / Transcendence: this is the second major transformation. Fifth-job identity is unmistakable and should include a signature weapon silhouette, refined costume construction, controlled aura, unique ornaments and premium material treatment. Fifth jobs are War Emperor, Arcane Sovereign, Celestial Ranger, Shadow Emperor, Divine Saint and Forge Overlord.

Level 250: final playable level. The character keeps the fifth-job silhouette but receives maximum-detail refinement, mature equipment wear, high-tier effects and the strongest normal progression presentation. Do not turn the character into a generic glowing silhouette; anatomy, clothes and equipment must remain visible.

Hero age begins at 18. Every three accumulated online days adds one year. Age changes appearance progressively, not by replacing the entire model. The face should mature, hair and skin details should change subtly, posture can become more experienced, and equipment mastery should be reflected visually. Age is also a gameplay modifier in Honour War and must remain connected to the canonical age system.

## Warrior — complete art specification

The Warrior is the stalwart close-range protector. The base silhouette is broad through the shoulders and chest, balanced through the hips, with strong legs designed for grounded combat. The body should look athletic and trained rather than exaggerated into a bodybuilder.

Face: square or slightly angular jaw, firm mouth, pronounced but natural cheek structure, straight nose, strong brows and focused eyes. Expression is courageous and determined. Eye colors can include steel grey, deep blue or restrained crimson. Hair is short, spiky and swept backward, with dark brown, cobalt, black or restrained crimson variants. Hair must have individual layered locks rather than one solid helmet-like mass. A small scar can appear on the cheek or jaw at advanced progression.

Foundation clothing: fitted dark-blue or charcoal under-tunic, practical trousers, leather belt, simple boots and a modest shoulder guard. The chest should show fabric folds and reinforced seams. Level 25 specialization adds branch-specific shoulder, belt and weapon details.

Advanced armor: segmented steel chest protection, leather under-padding, articulated pauldrons, bracers, gauntlets, tassets and greaves. The armor needs bevels, rivets, recessed seams, brushed-metal roughness and controlled edge highlights. The Prontera-inspired shield motif should be original to Honour War rather than copied.

Fourth Job Transcendent Knight: heavier but elegant plate construction, a layered blue cape or scarf, refined crest geometry, articulated sabatons, reinforced gauntlets and a premium sword. The cape must simulate cloth movement rather than behave like a rigid plane.

Fifth Job War Emperor: royal-warrior silhouette with a monumental but playable greatsword or signature blade. Armor becomes more ornate with gold/steel accent pieces, engraved plates, deep-blue cloth and a controlled martial aura. The weapon should have a readable guard, fuller, grip wrap and pommel. Effects may include restrained blue-white energy around attack arcs, but never hide the character.

Pet: a permanent class-bound combat companion with its own armor/equipment progression, level cap 250 and skills. The Warrior pet should visually support strength and protection without becoming another oversized character.

## Mage — complete art specification

The Mage is an arcane scholar whose silhouette is defined by layered cloth, staff geometry, spellbook elements and magical energy.

Face: refined oval or slightly pointed face, calm expression, large intelligent eyes with violet, magenta, electric blue or deep amethyst irises. Eyelids, brows and eye highlights must remain visible. Hair can be lavender, midnight blue, deep violet or controlled magenta, with layered flowing locks.

Foundation clothing: simple inner robe, fitted waist, soft boots and small satchel. Level 25 specialization adds elemental ornaments according to branch.

Advanced clothing: double-layered robe, high collar, shoulder mantle, wide sleeves, reinforced sash and decorated staff. Cloth must show weave and fold compression. The robe should not become a single painted texture.

Fourth Job Transcendent Wizard: elaborate arcane coat/robe, stronger mantle, gemstone brooch, improved staff crystal and floating spellbook. Magical runes can orbit the caster during skills. Use transparent layered particles, emissive runes and volumetric light carefully.

Fifth Job Arcane Sovereign: sovereign arcane silhouette with premium violet/blue materials, refined gold filigree, a signature astral staff and controlled constellation-like spell geometry. The face and body remain clearly visible through effects.

Pet: an arcane companion with crystalline or spirit-like visual language, scaled as a complete animated creature rather than a particle cloud.

## Archer — complete art specification

The Archer is an agile ranged hunter. The silhouette should remain light, athletic and mobile. Long hair, ponytail or braid can emphasize movement, but must be physically separated from the torso and simulated or animated correctly.

Face: alert eyes, natural brows, focused expression and a subtle asymmetry caused by aiming. Eye colors include forest green, hawk yellow or clear blue. Skin may show warm outdoor exposure and small freckles.

Foundation clothing: lightweight earthy tunic, short split garment or practical trousers, flexible leggings, leather belt and soft boots. A shoulder or chest guard protects the bow-string side.

Advanced gear: asymmetric leather chest protection, reinforced bracer, three-finger shooting glove, hip quiver with visible arrow shafts and varied arrowhead materials. The bow must have a real string, grip, limbs and nocking point.

Fourth Job Transcendent Ranger: precision-crafted bow, reinforced ranger mantle, enhanced quiver and distinctive natural motifs. Branch variants must distinguish Sniper, Falconer, Trapper and Ballista visual identities.

Fifth Job Celestial Ranger: premium longbow with celestial engraving, refined green/gold/sky materials, elegant cloak or mantle and a restrained star/sky aura. Arrows can carry elemental trails, but the projectile remains readable.

Pet: the Archer receives a permanent falcon-like combat companion. It must have complete wings, talons, beak, eyes, feather layering, flight animation, combat animation, equipment progression and level 250 progression.

## Thief — complete art specification

The Thief is the agile shadow archetype. The body is lean and athletic with a low center of gravity. The silhouette should communicate speed rather than heavy armor.

Face: sharp eyes, narrow predatory gaze, controlled expression and optional small scar. Hair is dark, layered and irregular, with black, deep violet or slate variants. A bandana or mask may cover the lower face, but the character's facial rig must still exist beneath it.

Foundation clothing: close-fitting dark top, flexible trousers, light boots, leather belt and simple dagger sheaths. Fabric should compress naturally around elbows, knees and hips.

Advanced equipment: asymmetrical chest guard, shoulder protection, arm wraps, tactical harness, pouches, poison containers, smoke pellets and dual daggers. Daggers need real blade geometry, bevels, grip texture and sheath construction.

Fourth Job Transcendent Assassin: darker premium materials, stronger asymmetrical armor, dual-blade silhouette and controlled poison/shadow effects. Assassin, Phantom, Venomblade and Shadow Dancer branches require different equipment motifs.

Fifth Job Shadow Emperor: elite shadow-warrior silhouette with premium black-violet armor, refined blade geometry and a controlled dark aura. Cloaking effects must never erase the body permanently; use transparency only as a gameplay effect.

Pet: a permanent shadow-themed combat companion with complete anatomy, readable eyes and attack animations.

## Acolyte — complete art specification

The Acolyte is the divine support and holy-combat archetype. The silhouette should communicate serenity, movement and spiritual authority rather than heavy armor.

Face: gentle oval face, calm expression, empathetic eyes and subtle smile. Eye colors include sapphire, soft violet or warm blue. Hair is silver-white, platinum, pale blonde or another restrained luminous tone, with smooth layered geometry.

Foundation clothing: clean white or cream robe, simple belt, modest sandals and a small holy accessory. Fabric needs visible weave, hems and natural compression.

Advanced clothing: high collar, embroidered stole, gold-thread holy symbols, layered scapular, wide sleeves, ceremonial cord and refined mace/staff. Gold embroidery should be physically represented through normal/roughness detail and selective geometry where appropriate.

Fourth Job Transcendent Saint: more elaborate white/gold/blue ceremonial layers, stronger holy weapon, floating scripture/runes and healing aura. Priest, Saint, Exorcist and Oracle branches must have distinct symbols and accessory silhouettes.

Fifth Job Divine Saint: premium sacred silhouette, refined gold filigree, blue-white cloth, a signature Heaven Gate Mace or holy staff, controlled halo geometry and divine particles. Effects should illuminate the face and hands without washing out the model.

Pet: a permanent divine guardian companion with complete body, wings or sacred anatomy as appropriate, combat skills and level 250 progression.

## Merchant — complete art specification

The Merchant is a practical trader and crafting combatant. The character should look energetic, resourceful and physically capable of traveling with equipment.

Face: confident expression, expressive eyes, slightly mischievous smile, warm amber/hazel eyes and natural freckles. Hair is copper-orange, chestnut or warm brown with layered boyish locks and a small stray crown lock.

Foundation clothing: cream canvas tunic, leather vest, rolled sleeves, utility belt, trousers and rugged traveling boots. The cloth and leather should show dust and wear.

Advanced equipment: reinforced tan leather vest, brass rivets, tool loops, suspenders, heavy belt, fingerless gloves, wrist wraps and multiple pouches. A merchant cart is a recognizable class prop and must be a properly modeled object with wheels, wood grain, metal brackets and visible cargo.

Cart cargo: rolled textiles, potion bottles, small boxes, tools, coins and trade goods. Items should be individually modeled enough to create readable silhouettes.

Fourth Job Transcendent Forge Master: stronger smithing/engineering motifs, reinforced leather and metal armor, larger crafted weapon and upgraded cart details. Blacksmith, Alchemist, Arsenal Lord and Tactician branches need distinct tool, chemical, weapon or command motifs.

Fifth Job Forge Overlord: premium forge-master silhouette with dark steel, brass, copper and deep leather materials. The Arsenal Overlord Hammer should have real weight and detailed forging marks. The cart may receive ornate but practical reinforcement and rare cargo.

Pet: a permanent merchant-themed combat companion, fully modeled and animated, with its own equipment and progression.

## Branch visual differentiation

Warrior branches: Warlord emphasizes weapons and offensive armor; Guardian emphasizes shields and defensive plating; Berserker emphasizes aggressive asymmetry and battle wear; Dragoon emphasizes spear/lance geometry and mounted-warrior visual motifs.

Mage branches: Elementalist uses elemental color/material cues; Voidcaller uses controlled dark-violet void geometry; Astral Sage uses stars and celestial geometry; Chronomancer uses clockwork/time-ring motifs.

Archer branches: Sniper emphasizes precision optics and longbow geometry; Falconer emphasizes bird/falcon equipment; Trapper emphasizes traps, pouches and terrain tools; Ballista emphasizes heavy ranged engineering.

Thief branches: Assassin emphasizes dual blades; Phantom emphasizes stealth and illusion; Venomblade emphasizes poison vials and green-black blade effects; Shadow Dancer emphasizes flowing cloth, movement ribbons and shadow geometry.

Acolyte branches: Priest emphasizes healing and holy scripture; Saint emphasizes divine authority; Exorcist emphasizes seals and anti-undead motifs; Oracle emphasizes prophecy, eyes, stars and divination motifs.

Merchant branches: Blacksmith emphasizes forged metal and tools; Alchemist emphasizes bottles and chemical apparatus; Arsenal Lord emphasizes weapon engineering; Tactician emphasizes maps, mechanisms and tactical instruments.

## Face, hair and body QA checklist

Before a character is accepted as a production asset, verify: full head visible; both eyes correctly aligned; iris/pupil/cornea present; brows and eyelids deform; nose and lips have readable forms; ears exist; hair does not intersect the skull excessively; neck connects naturally to torso; shoulders deform correctly; elbows bend without collapsing; hands are complete; fingers do not merge; torso clothing has thickness; belts do not float; knees deform; legs are complete; boots contain feet; no body part disappears under the camera; weapons have correct hand attachment points; accessories have stable sockets.

The hero must be visible from front, back, left, right, three-quarter and gameplay camera views. The model must remain recognizable at normal combat distance. Close-up inspection should reveal material detail without requiring extreme texture resolution.

## AI painting / concept prompt direction

For concept painting, describe the subject as an original HD fantasy MMORPG character with a complete full-body three-quarter view, clean anatomy, detailed face, layered hair, physically constructed clothing, realistic material separation, high-frequency fabric and leather detail, beveled metal, engraved weapons, subtle weathering, controlled magical particles, studio-quality rim light, ambient occlusion, cinematic but readable lighting, sharp focus and neutral background. Use the class section above as the identity source.

Do not request a cropped portrait when the result is intended to become a game asset. Do not hide feet, weapons or major equipment. Generate orthographic front/back/side references after the hero concept is approved. Then produce a clean production turnaround and texture reference before modeling.

## Gameplay presentation requirements

The gameplay camera must keep the hero's full body readable whenever practical. Attack effects should originate from the actual weapon or casting hand and travel toward the target. Hit effects must align to the target's body and use elemental/color language that matches the skill. Monster impacts should show animation, particles and controlled screen response without obscuring the character.

Towns are fixed MMORPG locations and service hubs, never player-buildable strategy bases. No soldiers, soldier production, bank guards, tower-defense systems or strategy-city mechanics belong in Honour War.

## Final production pipeline

Blender is the primary modeling and rigging stage. Substance 3D Painter is the primary texture/material authoring stage. Export as GLB/GLTF with proper skeletons, animation clips, material assignments and texture references. Godot 4.7.2 is the runtime stage. Production GLB assets remain authoritative over placeholder primitive visuals. Every major character, pet, monster and NPC must pass visual QA before replacing or competing with production assets.

This document is the canonical art-direction reference for the six Honour War character families and their progression tiers.