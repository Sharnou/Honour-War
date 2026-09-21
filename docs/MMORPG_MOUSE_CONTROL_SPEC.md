# Honour War — MMORPG Mouse Control & Camera Specification

## Locked interaction identity

Honour War uses a Ragnarok Online-inspired desktop MMORPG interaction model while remaining an original Unreal Engine 5.8 game.

## Locked primary interaction

### Left mouse

Click ground → move toward the clicked world location.

Click a living monster → select the monster and move into the class-specific engagement range. Once inside range, the character automatically performs the basic attack through the authoritative combat component.

### Right mouse

Hold and drag → rotate the perspective/isometric camera horizontally and vertically.

### Mouse wheel

Scroll up/down → smoothly zoom the camera within the bounded gameplay range.

### Keyboard compatibility

W/A/S/D movement and 1–8 skill inputs remain available as secondary controls. Mouse control is not dependent on a bottom skill bar.

## Camera framing

The camera uses a perspective, elevated isometric-style MMORPG presentation:
- default pitch approximately -50°;
- default yaw approximately 45°;
- complete hero framing is required during normal gameplay;
- legs and feet must remain visible rather than being cropped by default;
- right-drag changes yaw and pitch;
- zoom remains bounded so the game does not lose readable MMO scale.

## Targeting

Monster click selection is performed through an Unreal visibility collision query under the cursor. The world and monster collision layers must therefore expose valid visibility hits.

## Regression contract

Any visual or gameplay development cycle that changes the camera, movement, targeting or HUD must re-check this specification and the Unreal contract QA before the cycle can be accepted.


## Cycle rule

Any visual or gameplay development cycle that changes the camera, movement, targeting or HUD must re-check this specification and the Unreal contract QA before acceptance.
