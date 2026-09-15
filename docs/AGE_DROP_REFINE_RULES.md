# Honour War — Permanent Character Age Drop & Refinement Rules

## Canonical rule
These values are permanent Honour War design rules and must be preserved by future Daily Honour War Upgrades unless the game design is explicitly changed.

### Character aging
- New characters start at age **18**.
- Every **3 accumulated online days** grants **1 permanent character year**.
- Age is gameplay state and must not be shown in the floating character nameplate.

### Age 60 milestone
A character reaching age 60 has earned:
- **42 earned years**: 60 − 18.
- **126 accumulated online days**: 42 × 3.
- **+42% refine-success bonus**.
- **+4.2% Top-100 item/card drop bonus**.
- **+21% stat-growth multiplier bonus** under the current age system.

### Drop-rate interpretation
The age system defines the Top-100 bonus separately from the ordinary drop rate. At age 60, the character receives **+4.2% to the Top-100 item/card drop calculation**. This must not be interpreted as a universal +4.2% bonus to every ordinary item or monster drop unless a future design change explicitly adds such a rule.

### Formula source of truth
The implementation is `scripts/OnlineAgeSystem.gd`:
- `DEFAULT_STARTING_AGE = 18`
- `DAYS_PER_YEAR = 3.0`
- `REFINE_SUCCESS_PER_YEAR = 0.01`
- `TOP_100_DROP_PER_YEAR = 0.001`
- `STAT_GROWTH_PER_YEAR = 0.005`

For an age `A` character with starting age 18:
- earned years = `A - 18`
- refine bonus = `(A - 18) × 1%`
- Top-100 drop bonus = `(A - 18) × 0.1%`
- stat-growth bonus = `(A - 18) × 0.5%`

## QA requirement
Daily Honour War Upgrade must verify that age progression and these formulas remain intact. UI changes must not expose age in the floating character display. Age may remain available to gameplay systems, character data, status/equipment interfaces, and progression calculations.
