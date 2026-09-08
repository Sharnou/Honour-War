# Honour War Runtime Validation Checklist

## Launch
- Open the project in Godot 4.2 or newer.
- Run `Main3D.tscn`.
- Confirm there are no parser errors in the Output panel.
- Confirm the main camera is current and the scene renders at 1920x1080.

## Chat
- Press Enter to open the chat panel.
- Confirm the input field receives focus.
- Send a General message.
- Test `/w player message`.
- Press Enter again to close the panel.
- Confirm chat does not block movement when closed.

## Camera and presentation
- Confirm orthographic camera framing remains stable.
- Confirm the camera follows the configured target without snapping.
- Confirm the camera does not move when no target is assigned.

## Pet combat
- Confirm the pet can use Follow, Assist, Defend, Aggressive, Hold, and Return states.
- Confirm Hold prevents automatic repositioning.
- Confirm Return and Follow maintain the configured owner distance.
- Confirm pet movement does not modify the owner transform.

## Combat feedback
- Emit a damage event and confirm the UI layer receives it.
- Emit a telegraph event and confirm the effect layer receives it.
- Emit a skill effect event and confirm the effect identifier is preserved.
- Confirm invalid or zero-value events are ignored.

## Regression checks
- Existing movement remains functional.
- Existing skill, equipment, pet, and map controllers still load.
- No duplicate CanvasLayer or duplicate camera is introduced.
- Check the debugger for invalid NodePath, null instance, and signal connection errors.
