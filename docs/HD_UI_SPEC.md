# Honour War HD UI Specification

## Chat dock

The chat dock is a compact, resizable panel anchored to the lower-left HUD. It supports drag repositioning, resize handles, opacity, font scale, channel tabs, scrollback, timestamps, and a single-line input field.

### Channels

General, Party, Guild, Whisper, System, Combat, and Trade.

### Interaction rules

- Enter focuses the input field when the chat dock is visible.
- Escape closes input focus without closing the entire HUD.
- PageUp/PageDown scroll history.
- Tab cycles channels.
- `/w player message` sends a whisper.
- `/reply message` targets the most recent whisper sender.
- Muted and blocked users are filtered locally and must also be enforced by the server.

## Visual language

- Use consistent panel margins, 8px spacing units, and readable hierarchy.
- Use icon plus text for important states; never rely on color alone.
- Preserve a safe area around party frames, quest tracker, minimap, and skill bar.
- Avoid excessive bloom, screen shake, and floating text density.
- Provide reduced-motion and UI-scale settings.

## Feedback standards

Every action displays one of: accepted, rejected, unavailable, cooldown, or completed. Combat feedback should use animation, sound, floating numbers, and concise log text together, without obscuring the battlefield.
