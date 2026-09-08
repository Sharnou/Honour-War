# Honour War — HD Polish Roadmap

This document defines the production direction for the existing Godot prototype.

## Visual target

Honour War uses an original high-definition fantasy MMORPG presentation inspired by the readability, charm, and social density of classic Ragnarok-style games. Do not copy proprietary assets, names, maps, or code.

- Orthographic/isometric-friendly camera with smooth zoom and edge-safe framing.
- PBR materials where useful, hand-authored stylized textures, clean silhouettes, and readable team/enemy colors.
- Soft global illumination, contact shadows, atmospheric fog, bloom used sparingly, and strong time-of-day lighting.
- Distinct town, field, dungeon, and boss visual identities.
- Animation priorities: locomotion, attack anticipation, impact, hit reaction, death, casting, gathering, refining, and pet synchronization.
- Every combat action must communicate target, range, damage type, status effect, cooldown, and result.

## UX and chat requirements

- Dockable chat window with tabs: General, Party, Guild, Whisper, System, Combat, Trade.
- Commands: `/w name message`, `/reply message`, `/party message`, `/guild message`, `/clear`, `/help`.
- Server-authoritative timestamps and message IDs.
- Rate limiting, profanity filtering hooks, mute/block controls, report action, and anti-spam cooldown.
- Chat history persists per character session; private messages never appear in public channels.
- Chat must remain usable while moving, fighting, opening inventory, or viewing the skill tree.

## Combat and pet presentation

- Character and pet share a party frame but retain separate health/resource bars.
- Pet auto-summons on character login and never requires feeding for baseline combat participation.
- Pet AI states: Follow, Assist, Defend, Aggressive, Hold Position, Return.
- Pet skill casts use telegraphs, audio cues, cooldown icons, and combat-log entries.
- Skill-tree nodes require level, class, or prerequisite checks and expose exact numerical effects.

## Quality gates

1. No UI panel may block movement or combat input without an explicit modal state.
2. All actions have success, failure, and cooldown feedback.
3. All network-facing commands are validated server-side.
4. Every new system has a deterministic offline test path.
5. Performance target: stable frame pacing in towns and during multi-entity combat.
6. Accessibility: scalable UI, readable fonts, remappable shortcuts, color-independent status indicators.

## Implementation order

1. Chat service and chat dock UI.
2. Unified notification/toast and combat feedback layer.
3. Camera, lighting, environment, and material polish.
4. Pet AI/skill-tree integration and synchronized VFX.
5. Inventory, equipment, refining, cards, and crafting UX pass.
6. Town/dungeon travel, coordinates, party/guild/social systems.
7. Multiplayer authority, persistence, telemetry, and automated regression tests.
