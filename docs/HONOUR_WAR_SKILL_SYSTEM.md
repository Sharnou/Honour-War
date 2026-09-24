# Honour War — Skill System and Tier-5 Respec (2026-09-24)

## Canonical skill count
Honour War has 7 professions × 5 job tiers × 8 authored class skills = **280 class-skill entries**. Every one of the 70 character profiles (7 classes × 5 tiers × 2 genders) inherits the exact 8-skill loadout for its job.

Skill IDs use the stable form `SKILL_<CLASS>_T<TIER>_<SLOT>`, for example `SKILL_RAN_T5_03` for the Ranger Tier-5 Machine Gun Boltstorm skill.

## Skill levels
All eight class skills begin at Lv.1. A skill can be raised to Lv.10. A character gains one Skill Point every five character levels, plus three bonus points on reaching each of Tier 2, Tier 3, Tier 4 and Tier 5. A level-200 character therefore has 52 Skill Points before spending them.

Each extra skill level adds 8% to that skill's damage/support scalar. Skill cooldowns receive a small reduction as skill level rises, while resource cost rises slightly. The player retains free allocation of the six hero stats separately.

## Monster-family impact
The runtime evaluates eight monster families: Poring, Goblin, Wolf, Skeleton, Orc, Mantis, Golem and Dragon. The effect is a multiplicative combat scalar. Values below 1.00 reduce damage; 1.00 is neutral; values above 1.00 increase damage. Tier 1–4 interpolate toward neutral, while Tier 5 uses the full class specialization matrix.

The seven Tier-5 professions are therefore differentiated in combat identity rather than all using the same generic damage tag:
- Warrior — strongest affinity around Orc/Golem.
- Mage — strong Arcane pressure on Skeleton/Mantis/Golem/Dragon.
- Archer — strong range pressure on Wolf/Mantis/Dragon, with reduced Golem efficiency.
- Thief — strong ambush/poison pressure on Goblin/Mantis/Orc, with reduced Golem efficiency.
- Acolyte — strongest anti-Undead-style pressure represented by Skeleton/Orc/Dragon/Golem bonuses.
- Merchant — strongest Trade/Forge pressure against Goblin/Orc/Golem.
- Ranger — strongest ballistic/nature pressure against Wolf/Mantis/Dragon, with reduced Golem efficiency.

The exact per-skill multipliers are stored in `data/honour_war_skill_system.json` and are the QA source for the eight-by-eight Tier-5 comparison.

## Tier-5 skill reset
At Level 200+ the character is Tier 5 and may reset the eight class-skill levels. The reset returns every class skill to Lv.1, refunds all Skill Points previously spent above Lv.1, and clears current skill cooldowns.

Runtime commands:
`@skill` or `/skill` — inspect skill levels and remaining points.
`@skill 1 1` or `/skill 1 1` — spend one point on skill slot 1.
`@skill impact Skeleton` — inspect all eight skill multipliers against the Skeleton family.
`@restskills confirm` or `/restskills confirm` — perform the Tier-5 reset.

No Tier-5 reset is available before the character reaches the Transcendence tier.
