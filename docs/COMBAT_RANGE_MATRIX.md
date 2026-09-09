# Honour War — Combat Range Matrix

`CombatRules.gd` is the single gameplay authority for attack and engagement distance. Gameplay systems must call it instead of maintaining local range constants.

## Hero classes

| Class | Engagement | Attack cadence | Target acquisition |
|---|---:|---:|---:|
| Swordsman / Warrior | 2.4 m | 0.72 s | 18 m |
| Mage | 7.5 m | 0.86 s | 18 m |
| Archer | 12.0 m | 0.78 s | 22 m |
| Ranger | 13.5 m | 0.74 s | 24 m |
| Thief | 2.2 m | 0.64 s | 16 m |
| Acolyte | 5.0 m | 0.90 s | 16 m |
| Merchant | 2.4 m | 0.80 s | 16 m |

## Automatic combat pets

| Pet | Role | Attack distance | Attack cadence |
|---|---|---:|---:|
| Falcon | Ranged | 9.0 m | 1.00 s |
| Wolf | Melee | 2.6 m | 0.92 s |
| Dragon | Caster | 10.0 m | 1.20 s |
| Wolf Cub | Melee | 2.4 m | 0.98 s |
| Guardian | Tank | 2.8 m | 1.00 s |
| Sprite | Healer | 6.0 m | 1.10 s |
| Shadowcat | Assassin | 3.0 m | 0.72 s |

## Monsters

- Normal melee: **2.4 m**.
- Ranged monster: **9.0 m**.
- MVP/boss melee: **3.5 m**.

## Coordinate and movement contract

- Authoring distances are in world meters.
- The legacy simulation uses `WORLD_SCALE = 0.055` map units per meter.
- Movement destinations are snapped to the **1×1 map grid**.
- The hero's movement/camera controller and combat runtime must consume these centralized values; they must not introduce a second combat loop or duplicate range constants.

## Regression test

Run the deterministic range test with Godot 4:

```text
godot --headless --path . --script res://tests/combat_rules_test.gd
```

A successful run prints `PASS: Honour War combat range regression suite` and exits with code 0.
