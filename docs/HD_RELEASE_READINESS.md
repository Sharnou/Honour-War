# Honour War HD — Release Readiness Contract

## 1. Player controls

- Left mouse: click terrain to move; click a monster to select and approach it.
- Right mouse: cancel current destination/target.
- Middle mouse drag: rotate the camera horizontally and vertically within the restricted MMO range.
- A/D: horizontal camera rotation only.
- W/S: vertical camera tilt only.
- ESC: cancel movement and target selection.
- No keyboard action changes hero position directly.

## 2. World model

- Simulation coordinates use a strict 1 x 1 tile grid.
- Movement destinations are snapped to integer map coordinates.
- Production art is fully 3D and follows Blender → Substance 3D Painter → GLB/GLTF → Godot 4.
- Procedural geometry is fallback/prototype geometry, never the production art contract.
- Camera uses an elevated orthographic presentation to produce a perspective-like isometric diorama feel while preserving a fully 3D world.

## 3. Camera contract

- Horizontal rotation is unrestricted through 360 degrees.
- Vertical tilt is restricted to approximately -56 to -28 degrees.
- First-person and straight-up views are intentionally impossible.
- Camera ownership is centralized in MovementStabilityFix.
- Game3D must not implement a second camera-follow loop.

## 4. Combat contract

CombatRules is the single source of distance definitions.

### Hero engagement distances

| Class | Distance |
|---|---:|
| Swordsman / Warrior | 2.4 m |
| Mage | 7.5 m |
| Archer | 12.0 m |
| Ranger | 13.5 m |
| Thief | 2.2 m |
| Acolyte | 5.0 m |
| Merchant | 2.4 m |

### Pet attack distances

| Pet | Role | Distance |
|---|---|---:|
| Falcon | Ranged | 9.0 m |
| Wolf | Melee | 2.6 m |
| Dragon | Caster | 10.0 m |
| Wolf Cub | Melee | 2.4 m |
| Guardian | Tank | 2.8 m |
| Sprite | Healer | 6.0 m |
| Shadowcat | Assassin | 3.0 m |

### Monster distances

- Normal melee: 2.4 m.
- Ranged monster: 9.0 m.
- MVP/boss melee: 3.5 m.

CombatRuntime is authoritative for target acquisition, attack timing, range validation, damage, status effects, monster movement, pet attacks, MVP attacks, death, loot and persistence. Presentation systems may animate or display an event but must not create a second damage simulation.

## 5. Combat presentation

- Hero attack events flow through CombatEventBus.
- Pet attack events flow through CombatEventBus.
- Animation systems consume events and present impact frames.
- Archer attacks use visible projectile presentation without applying duplicate damage.
- Floating combat text is attached to the 3D actor/world position.
- Critical, miss, heal and MVP feedback remain visually distinct.
- Hero + Pet Bond uses the term `Bonding`; obsolete `Building` wording is forbidden.

## 6. Environment

- Terrain, buildings, trees, roads and background are 3D.
- Low-poly geometry is intentional and performance-oriented.
- Surface detail belongs primarily in authored PBR/hand-painted textures.
- Towns receive distinct material palettes and landmark silhouettes.
- Distant geometry is simplified to protect frame time.
- Tile-grid accents are subtle world dressing, not a debug overlay.

## 7. UI and icons

The HD UI is non-diegetic and intentionally separate from world geometry.

Required icon families:

- Combat / Character
- Bonded Pet
- Skills
- Inventory
- Equipment
- Refinement
- System

Icons are SVG assets under `assets/ui/icons/` and are loaded by HDUIStyleDirector. Windows use reusable StyleBoxFlat styling, compact spacing, readable labels, restrained borders and tooltips.

## 8. Asset quality gate

Production GLB/GLTF assets must satisfy the existing HD asset manifest and validator. Stable IDs, correct folders, readable geometry, material assignments, collision/interaction requirements and runtime replacement compatibility are mandatory.

## 9. Performance tiers

- LOW: reduced environment population and effects.
- HIGH: default desktop presentation.
- ULTRA: maximum supported environment detail.
- Gameplay simulation must remain deterministic across visual tiers.
- Cosmetic effects may be reduced without changing combat results.

## 10. Test checklist

1. Launch `Main3D.tscn`.
2. Confirm no parse errors.
3. Confirm the hero and bonded pet appear in 3D.
4. Click empty ground: hero moves and snaps to grid coordinates.
5. Hold W/S: only camera tilt changes.
6. Hold A/D: only camera yaw changes.
7. Middle-drag: camera rotates without moving the hero.
8. Click a nearby Warrior target: hero stops around 2.4 m away and attacks.
9. Click a distant Archer target: hero approaches to approximately 12 m and attacks with projectile presentation.
10. Verify Falcon/Wolf/Dragon/pet role ranges affect attack eligibility.
11. Verify monsters stop at their configured attack range.
12. Verify damage numbers, criticals, misses and pet effects are visible.
13. Verify no `Building` text appears in the Hero + Pet Bond HUD.
14. Open each UI icon and confirm it does not move the camera or hero accidentally.
15. Rotate the camera to its limits and verify there is no first-person/sky view.
16. Verify town buildings, terrain, trees and distant backdrop are 3D.
17. Run the existing HD asset validator before production asset import.

## 11. Renderer policy

Production target: Godot 4 Forward+ / Vulkan.

Compatibility/OpenGL is the local fallback for older GPUs that cannot initialize Vulkan. It does not change the production art or gameplay architecture.
