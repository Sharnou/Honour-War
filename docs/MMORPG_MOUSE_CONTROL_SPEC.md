# Honour War — MMORPG Mouse Control Specification

## Primary interaction

Honour War uses mouse-first MMORPG controls in addition to keyboard movement.

### Left mouse

Click ground → move toward the clicked world location.

Click a living monster → select the monster and move into the class-specific engagement range. Once inside range, the character automatically performs the basic attack through the authoritative combat component.

### Right mouse

Hold and drag → rotate the perspective camera horizontally and vertically.

### Mouse wheel

Scroll up/down → zoom the camera smoothly within the safe gameplay range.

### Keyboard compatibility

W/A/S/D movement and 1–8 skill inputs remain available as secondary controls. Mouse control is not dependent on a bottom skill bar.

## Targeting

Monster click selection is performed through an Unreal visibility collision query under the cursor. The world and monster collision layers must therefore expose valid visibility hits.

## Design requirement

The control scheme must feel like a conventional desktop MMORPG: the mouse operates navigation, target selection and camera framing while preserving direct keyboard controls.
