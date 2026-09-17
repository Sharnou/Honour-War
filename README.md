# Honour War — Godot 4 HD MMORPG/ARPG

> **Development status:** Active production development. The repository is being upgraded in place toward the full Honour War design; development placeholders are progressively replaced by production-ready systems and authored HD assets.

## 📰 Game News

### 16 September 2026 — Production Upgrade Pass
- **Godot 4.7 / 4.7.2** is the project validation and Windows export target.
- The permanent visual pipeline is now enforced as **Visual RAG → Blender → Substance 3D Painter → GLB/GLTF → Godot 4.7 → validation → runtime/build test**.
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

**Visual RAG → Blender → Substance 3D Painter → GLB/GLTF → Godot 4.7**

This is the permanent Honour War visual production pipeline.

- Visual RAG: reference/visual analysis and production target definition
- Blender: production modeling, rigging, skinning, animation, UVs, LODs and export preparation
- Substance 3D Painter: PBR texturing and material variants
- GLB/GLTF: production interchange format containing meshes, materials, skeletons and animations
- Godot 4.7: Forward+ runtime, animation, lighting, atmosphere, VFX, gameplay, UI, networking and world streaming
- Validation/build: automated integrity checks, Godot validation, runtime checks and Windows export regression

Procedural geometry remains only as a development fallback. It is not the final
Honour War art direction.

## HD runtime architecture

`HDAssetRuntime.gd` detects production GLB assets by stable ID and replaces the
corresponding procedural actor without changing gameplay references. This lets art
production progress independently while combat, AI, pets, skills, HUD and progression
continue using the same runtime architecture.

The production asset contract is documented in:
- `ART_PIPELINE.md`
- `assets/3d/HD_ASSET_MANIFEST.md`
- `tools/blender/honour_war_hd_asset_builder.py`
- `tools/blender/export_honour_war_glb.py`

## Visual target

Honour War targets a high-detail, stylized fantasy MMORPG presentation:
detailed full-body class silhouettes, visible faces and legs, expressive pets,
recognizable monsters/MVPs, layered equipment, PBR materials, rich town/field/dungeon
environments, atmospheric lighting, readable combat effects and polished animation.

The goal is not photorealism and not primitive geometry. The goal is premium
real-time stylized HD game art with scalable performance tiers.

## Multiplayer scope

The repository now contains an authoritative online-session foundation, but it is
**not yet a complete live online MMORPG**. Production deployment still requires the
full server implementation, accounts/authentication, persistent server database,
world services, party/matchmaking services, anti-cheat, scalable world streaming,
live operations, production audio and the complete production art library.

## Daily Honour War Upgrade policy

Every future upgrade pass must:

1. Continue from the current repository rather than restarting the project.
2. Preserve existing working mechanics, assets, options and progress.
3. Prioritize actual missing game systems and production assets over cosmetic placeholder work.
4. Follow the Visual RAG → Blender → Substance 3D Painter → GLB/GLTF → Godot 4.7 pipeline for authored HD assets.
5. Validate before declaring a feature complete.
6. Use independent engineering/AI review when an implementation problem requires another technical perspective.
7. After three failed attempts at the same approach, stop repeating it and use a fresh diagnostic/implementation path.
8. Never claim an asset, feature, build or test is complete unless it has been verified.

## Copyright

© Sharnou — Honour War
