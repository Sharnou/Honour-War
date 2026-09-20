# Honour War — Godot 4 HD MMORPG/ARPG

> **Development status:** Active production development. The repository is being upgraded in place toward the full Honour War design; development placeholders are progressively replaced by production-ready systems and authored HD assets.

## 📰 Game News

### 16 September 2026 — Production Upgrade Pass
- **Godot 4.7 / 4.7.2** is the project validation and Windows export target.
- The permanent visual pipeline is now enforced as **Visual RAG → Neural4D / authored DCC → FBX/OBJ → native Godot 4.7.2 → validation → runtime/build test**.
- **SS (SUPER SHAMBION)** is a rental-only AI hero. SS follows the owner, fights automatically, uses **Asura Strike**, and can automatically heal the owner and itself.
- SS rental remains **1,000,000 Zeny** and SS cannot be created from the Create New Character workflow.
- The SS runtime now has a production-asset path with a development fallback while authored assets are being completed.
- A dedicated skill-VFX runtime has been added so combat effects can move from procedural presentation to authored production VFX.
- An authoritative online-session foundation has been added as the basis for future server-authoritative MMORPG networking. The current repository is **not yet a complete live online MMORPG**.
- Game3D integrity regression checks remain part of the validation gate to prevent accidental deletion of core runtime systems.
- Windows CI includes project validation, Windows export, executable smoke testing and packaged build artifacts.
- The Daily Honour War Upgrade process now requires preservation of existing gameplay, assets and progress, prioritizes missing production systems over cosmetic placeholder work, and uses a fresh diagnostic path after repeated failed implementation attempts.

### Current production roadmap
**Production SS/Rent models → hero/class/monster models → town/field/dungeon environments → animation and skill VFX → complete character/save/UI flows → authoritative online services → Windows release regression.**

## Requirements
- Godot **4.7** development target
- Godot **4.7.2** used by CI and Windows export
- Forward+ / Vulkan recommended for the intended HD presentation

## Run
1. Install Godot 4.7.
2. Open `project.godot`.
3. Press F6 or F5 to run.
4. For the Windows production pipeline, use the repository GitHub Actions workflow.
5. Start the authoritative headless server with Godot 4.7.2:
   `Godot_v4.7.2-stable_linux.x86_64 --headless --path . --script res://scripts/HWServerBootstrap.gd -- --server-port=24567`

## Core controls
- WASD / Arrow Keys: move
- SPACE: hero + bonded pet attack
- R: refine hero equipment
- T: refine pet equipment
- Q: complete a quest
- C: craft
- B: buy Phracon
- F9: cycle graphics quality

## Core game foundation
- Six classes with automatic class-bonded combat pets
- Class-specific pet roles and tactical behavior
- Pets fight alongside the hero automatically
- Pet progression, skills, equipment, crafting materials and refinement +0 to +15
- Hero progression up to level 250
- Monsters up to level 300
- Online-time hero aging
- Age-based progression bonuses
- Monsters and MVPs with combat, EXP, cards, items and Zeny drops
- Quests, crafting, fast transmission and automatic save/resume
- Chat, combat feedback, target lock, combo and pet skill systems
- Top-100 item and card progression system

## SS (SUPER SHAMBION) rental system

SS is a special AI companion obtained **only by renting from the Rent NPC**.

- Class: **SS (SUPER SHAMBION)**
- Rental cost: **1,000,000 Zeny**
- Rental-only; not available in Create New Character
- Starts at level 0 and can progress to level 250
- Uses the owner's character age
- Follows the owner automatically
- Fights nearby enemies automatically
- Uses **Asura Strike** as its top combat skill
- Automatically heals the owner when the owner's HP is low
- Automatically heals itself when its own HP is low
- Owner can edit SS equipment and status points
- **GO** in the Equip interface ends the rental
- SS rental state is designed to persist with the hero save

The SS AI implementation is kept separate from player-character creation so renting
SS never silently creates an additional player character.

## Important design rule: removed systems

The current Honour War design does **not** use the previously proposed soldier/army,
bank-occupation, soldier-production or tower-defense systems. Those systems must not
be reintroduced by future upgrade passes unless the game design is explicitly changed.

## Character progression and age

- Hero maximum level: **250**
- Monster maximum level: **300**
- Hero starts at age **18**
- Character age advances from accumulated online time
- Age affects progression, appearance, basic skill effects, refinement and selected economy/drop mechanics
- At age 60, the established Top-100 age bonus is **+4.2%**
- Stored Top-100 base rates remain age-independent

## Top-100 database

Honour War maintains two independent pools:

- **100 Top Items**
- **100 Top Cards**
- Rank 1 base rate: **0.100000%**
- Rank 100 base rate: **0.010000%**
- Each pool totals **5.5%** base probability
- Combined base Top-100 pool: **11%**
- Age bonus is applied separately from the stored base rates

## Production HD art rule

**Visual RAG → Neural4D / authored DCC → FBX/OBJ → native Godot 4.7.2 → validation → runtime/build test**

The authoritative visual references are:

- `Screenshot/ChatGPT Image Sep 16, 2026, 12_22_47 AM.png`
- `Screenshot/image_a4469f29.jpg`

These repository references are the permanent visual contract for daily upgrades. They are not optional inspiration. The visual target is the detailed Honour War presentation represented by these files, and daily passes must perform visual gap analysis against them before making art or visual implementation decisions.

**GLB and GLTF are rejected from all daily updates and from the production/runtime asset intake. Meshy is permanently rejected.** Neural4D may use **FBX** for rigged/animated assets and **OBJ** for approved static assets. Final runtime presentation uses native Godot 4.7.2 scenes/resources.

See `VISUAL_REFERENCE_CONTRACT.md` for the mandatory micro-detail fidelity gate and daily visual QA rules.

Procedural geometry remains only as a development fallback. It is not the final
Honour War art direction.

## HD runtime architecture

`HDAssetRuntime.gd` detects production assets by stable ID and replaces the corresponding procedural actor without changing gameplay references. This lets art production progress independently while combat, AI, pets, skills, HUD and progression continue using the same runtime architecture.

The production asset contract is documented in:
- `ART_PIPELINE.md`
- `VISUAL_REFERENCE_CONTRACT.md`
- `assets/3d/HD_ASSET_MANIFEST.md`
- `tools/blender/honour_war_hd_asset_builder.py`

## Visual target

Honour War targets the high-detail, stylized fantasy MMORPG presentation established by the repository screenshot references: detailed full-body class silhouettes, visible faces and legs, expressive pets, recognizable monsters/MVPs, layered equipment, PBR materials, rich town/field/dungeon environments, atmospheric lighting, readable combat effects and polished animation.

The target is not generic HD/MMORPG art. Daily passes must use the authoritative repository references and explicitly track macro and micro visual gaps rather than substituting a generic art direction.

## Multiplayer scope

The repository now contains an authoritative online-session foundation plus live
world-presence replication for authenticated players. Clients receive server-owned
player map/position/class/level/vital snapshots at a bounded cadence and render
remote players with generated HD class assets. The repository now includes server-authoritative gameplay execution for movement,
combat, skills/items, loot, shops, refinement, warps and persistence, in addition to
authoritative online sessions and live remote-player world replication. It is still
not a fully operated commercial-scale live MMORPG: production deployment services,
anti-cheat, scalable world hosting/streaming, production account/database operations,
matchmaking/live operations, audio and the remaining authored art library are still
release blockers. The Windows release candidate is generated by the Godot 4.7.2
export workflow and must pass script validation, EXE export and launch smoke testing.

## Daily Honour War Upgrade policy

Every future upgrade pass, whether manually triggered or automatic, must:

1. **Run Visual RAG / multimodal visual-reference analysis FIRST.** No Blender generation, Neural4D generation, code visual implementation or art decision may begin before the current visual target/gap analysis exists.
2. Use the newest real Honour War gameplay screenshot when available and compare it against the two authoritative repository references: `Screenshot/ChatGPT Image Sep 16, 2026, 12_22_47 AM.png` and `Screenshot/image_a4469f29.jpg`.
3. Review visually similar high-quality references only as supporting evidence; the repository references remain authoritative and generic HD/MMORPG substitutions are not accepted.
4. Identify the highest-impact visual deficits and convert the findings into concrete asset/model/material/lighting/animation/camera/VFX/UI/gameplay-presentation requirements before implementation.
5. Continue from the current repository rather than restarting the project.
6. Preserve existing working mechanics, assets, options, saves and progress.
7. Prefer real authored production assets over procedural placeholders.
8. After Visual RAG, use the approved asset path **Neural4D / authored DCC → FBX/OBJ → native Godot 4.7.2**.
9. **Never introduce, generate, import or depend on GLB/GLTF in a daily update.** Meshy remains permanently rejected.
10. Apply the reference-fidelity gate to all six base classes and advanced classes, pets, monsters/MVPs, equipment, towns, dungeons, terrain, props, VFX, animation, lighting, camera, UI and gameplay presentation.
11. Match relevant reference details at both macro and micro levels: silhouettes, body proportions, visible faces/legs, clothing and equipment layers, materials, textures, surface response, terrain, props, lighting, shadows, atmosphere, camera framing, animation timing, attack/hit effects, VFX, HUD/UI scale and presentation.
12. Validate asset imports, materials, skeletons/animations, runtime integration, lighting/camera presentation, gameplay behavior and build/runtime stability before declaring completion.
13. Real visual QA screenshots must come from the actual Main3D runtime/build; concept art or generated mockups do not count as gameplay evidence.
14. When Visual RAG, Neural4D, Blender, Substance 3D Painter or another external art tool is unavailable, perform the available Visual RAG/reference analysis first, then improve manifests, asset specifications, generation scaffolding, import/runtime integration and validation without pretending the unavailable stage was completed.
15. Record incomplete or unavailable stages explicitly and never claim an asset, feature, build or test is complete unless verified.
16. Use independent engineering/AI review when an implementation problem requires another technical perspective.
17. After three failed attempts at the same approach, stop repeating it and use a fresh diagnostic/implementation path.

## Daily HD visual acceptance rule

Every Daily Honour War Upgrade permanently includes a real-HD presentation pass covering characters, maps, cities, monsters/MVPs, animation, attack anticipation/contact/impact/recovery, hit reactions, skill VFX, equipment appearance, boss presentation, camera framing and UI polish. The pass must begin with the authoritative Visual RAG/reference gap analysis and then use the Neural4D/FBX/OBJ → native Godot 4.7.2 pipeline, followed by validation and real runtime screenshot/build regression. Existing MMORPG/ARPG gameplay must be preserved.

## Copyright

© Sharnou — Honour War
