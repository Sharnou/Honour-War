# Honour War — Default Gameplay Rules

**Status:** Canonical gameplay baseline
**Scope:** Persistent design defaults for future Honour War development
**Note:** Numerical prototype values are subject to simulation and playtesting unless explicitly marked as a hard rule.

## 1. Core progression

- Hero level cap: 250.
- Monster level cap: 300.
- Automatic class advancement follows the established five-tier class progression at levels 1, 25, 50, 100 and 200, while preserving the character's base class.
- Hero age advances from online-day progression.
- Age affects basic-skill scaling, refinement success, refinement-material consumption, Zeny/item pricing and visual appearance.
- Hero death has no death-count limit; hero respawns at the city near the base building.
- Autosave is mandatory.

## 2. Pets

- Every character automatically owns a combat pet; no feeding requirement.
- Pet level cap: 250.
- Pets have skills, equipment, refinement and progression comparable to characters.
- Class identity influences pet species/role; e.g. Archer uses a falcon-style combat companion.

## 3. Soldiers and cities

- Soldier level cap: 50.
- Every soldier has two automatic combat skills.
- Cities/bases produce soldiers.
- Soldiers can occupy guarded map banks and generate income only after the guarding monster is defeated.
- Every five soldier deaths trigger respawn at the production point.
- Cities support soldier production, card mixing, weapon upgrades, hero basic-skill upgrades and tower defense.
- Base visual upgrade includes a one-level mini-map overlay enhancement.

## 4. Travel and map rules

- Fast travel command is `@go [map]`; coordinate suffixes are not part of the default fast-travel command.
- Towns, fields and dungeons have connected warp points back to towns.
- World remains constant daylight for the current production phase.

## 5. Combat

- PvE is the primary balance target.
- PvP is a separate balance layer and must not silently inherit PvE damage multipliers where that would create exploits.
- Hero, pet and monster HP bars must remain readable.
- Combat outcomes, damage, loot, progression and currency are server-authoritative in multiplayer.

## 6. Equipment rarity

Exactly six rarities are valid:

1. Common
2. Uncommon
3. Rare
4. Epic
5. Legendary
6. Mythic

No additional rarity tier should be introduced without an explicit design revision.

## 7. Rune Sockets

- Equipment may have 0–4 Rune Sockets.
- Four-slot equipment is not automatically best-in-slot.
- Four-slot equipment receives a deliberate lower base-power budget and/or meaningful opportunity-cost trade-off.
- Socket count is part of item identity and power-budget calculation, not a free bonus.
- Socket insertion/removal and rune state must be server-authoritative.
- Duplicate-socket/rune manipulation, negative-cost states and client-side stat injection must be rejected.

## 8. Core attributes

- Might
- Finesse
- Resolve
- Insight
- Spirit
- Fortune

## 9. Secondary-stat library

Health, Mana, Stamina, Physical Power, Spell Power, Weapon Damage, Armor, Guard, Ward, Accuracy, Evasion, Critical Chance, Critical Severity, Attack Speed, Cast Speed, Move Speed, Cooldown Recovery, Healing Power, Barrier Power, Life on Hit, Mana on Hit, Threat, Loot Fortune, Status Potency, Status Resistance, Fire Resistance, Frost Resistance, Storm Resistance, Earth Resistance, Shadow Resistance, Poison Resistance, Bleed Resistance and Control resistance.

## 10. Status library

Bleed, Burn, Chill, Shock, Poison, Weaken, Expose, Mark, Root, Slow, Silence, Stagger, Fracture, Curse, Dread, Blind, Barrier, Guarded, Haste, Focus, Regeneration, Emberbrand, Frostbite, Static Charge, Thornbound, Moonlit and Sunbound.

## 11. Refinement

- Equipment refinement runs from +0 through +15.
- Refinement uses the established Honour War material economy: Phracon, Zeny, Emveretarcon and Oridecon.
- Age-based bonuses may improve success probability and reduce material/currency requirements according to the progression model.
- Refinement must use deterministic server-side validation and transaction-safe inventory/currency changes.
- Failed upgrades must never duplicate, delete, or create unauthorized equipment.

## 12. Itemization principles

- Four-slot items must trade base power for customization potential.
- A zero-slot boss item may have the highest raw base budget without being universally superior.
- Crafted two-slot items should provide efficient customization/value.
- Fast weapons should trade per-hit damage for attack cadence and compatible scaling.
- Restricted-socket unique items should trade flexibility for distinctive effects.
- Affixes must have explicit slot eligibility, tier/range, stacking behavior, PvP behavior, synergy rules and anti-exploit constraints.

## 13. Loot and economy

- Drops must be fair, deterministic from server-side seeds/state where applicable, and resistant to reroll abuse.
- Boss/raid rewards should be powerful without making ordinary progression obsolete.
- Loot Fortune must improve opportunity rather than directly bypassing rarity ceilings or guaranteed progression gates.
- Currency generation must be monitored against item sinks and repair/refinement costs.
- Bank income is gated by defeating the local guarding monster.

## 14. Cards

- Monster cards are original Honour War IP.
- Cards use controlled effect budgets and explicit stacking rules.
- Card effects must specify PvE/PvP behavior, eligible sockets/equipment, proc rules and anti-exploit constraints.
- Mandatory card effects must be detected and validated by the server before activation.

## 15. Multiplayer/security

The server is authoritative for:

- Character level/class/age
- Pet progression
- Equipment ownership and stats
- Rune sockets and inserted runes
- Refinement
- Cards and card effects
- Loot rolls
- Currency
- Combat results
- Cooldowns
- Trade state
- Party/raid rewards

Clients may request actions but may not authoritatively assign resulting state.

## 16. Visual production baseline

The target is a detailed original MMORPG presentation, not primitive/placeholder/Roblox-like presentation.

Required production pipeline:

**Visual RAG → Blender → Substance 3D Painter → GLB/GLTF → Godot 4**

Visual RAG must precede Blender asset passes. If Visual RAG is unavailable, it must not be represented as having run.

Visual goals include full-body characters, readable faces and body language, detailed environments, material definition, controlled exposure, shadows/contact detail, combat VFX and hierarchical MMORPG UI.

## 17. Technical baseline

- Godot 4.2.2 is the currently validated local runtime target.
- Production renderer: Forward+/Vulkan, with compatibility fallback only when production startup fails.
- Runtime scripts must avoid properties unsupported by the target Godot version.
- Generated GLB assets should be preferred over procedural fallback assets when available.
- Binary assets must pass structural and semantic validation before being treated as production-generated assets.

## 18. Development rule

Future upgrades extend this baseline rather than restarting Honour War. Existing systems, assets and gameplay contracts must be inspected before replacement. Any numerical balance value not yet validated by simulation is explicitly a prototype value requiring simulation and playtesting.
