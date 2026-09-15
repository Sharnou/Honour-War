# Honour War — Character Age Progression

## Authoritative gameplay rule

- **Starting age:** 18 years old.
- **Online aging:** every 3 accumulated online days grants exactly 1 character year.
- Aging is based on accumulated online time, persists through saves, and is independent of character level.
- Character age is visible in the character/status information but **never appears in the floating world character display**.

## Per-earned-year bonuses

For every year earned after age 18:

- **+0.5% effective core-stat growth** — STR, AGI, VIT, INT, DEX and LUK are scaled by `1 + years_earned × 0.005`.
- **+1 percentage point refine-success bonus** — added directly to the item's refinement success chance, subject to the system's normal maximum success cap.
- **+0.1 percentage point top-100 drop-rate bonus** — applied to the probability of receiving one of Honour War's designated top 100 items/cards.

### Examples

| Character age | Earned years | Effective stat growth | Refine bonus | Top-100 drop bonus |
|---:|---:|---:|---:|---:|
| 18 | 0 | 0.0% | 0.0 percentage points | 0.0 percentage points |
| 19 | 1 | 0.5% | +1.0 percentage point | +0.1 percentage point |
| 20 | 2 | 1.0% | +2.0 percentage points | +0.2 percentage point |
| 28 | 10 | 5.0% | +10.0 percentage points | +1.0 percentage point |
| 68 | 50 | 25.0% | +50.0 percentage points | +5.0 percentage points |

The older-adult character profile in `data/character_visual_profiles/elder_veteran_adventurer.json` is therefore treated as a **60–75 age-stage visual reference**, not the starting age.

## Implementation requirements

- `OnlineAgeSystem.gd` owns the canonical constants and calculations.
- `OnlineAgeRuntime.gd` updates persistent online days and age and applies the effective core-stat growth to the saved six core stats.
- Equipped items receive the current age refine bonus through `age_refine_success_bonus`.
- `EquipmentProgressionSystem.gd` adds that bonus to refinement chance.
- `GameplayFormula.gd` exposes age stat, refinement and top-100 drop calculations for systems that use the central gameplay formula.
- Top-100 item/card eligibility must remain deterministic and data-driven; the age bonus must never increase the chance of unrelated low-tier drops.

## UI rule

Age belongs in the combined **Character • Status + Equipment** window. Do not put age into the world nameplate. Other players should not see a player's age unless a dedicated character-information interaction explicitly exposes it.

## Balance interpretation

The requested percentages are treated as **percentage-point additions** for refine success and top-100 drop chance, and as a multiplicative `+0.5% per earned year` growth factor for core stats. This avoids compounding the bonuses exponentially.
