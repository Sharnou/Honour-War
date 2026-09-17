# Honour War — Primary Visual/UI Reference

Status: **Permanent Daily Upgrade Rule**

## Canonical reference image
The primary Honour War visual/UI reference supplied for this project is the repository image:

- File: `ChatGPT Image Sep 16, 2026, 12_22_47 AM.png`
- GitHub: https://github.com/Sharnou/Honour-War/blob/main/ChatGPT%20Image%20Sep%2016%2C%202026%2C%2012_22_47%20AM.png

Use this reference whenever the game UI, item icons, skill icons, character framing, combat presentation, map density, or overall presentation is upgraded.

## Accepted visual direction
Match the reference's visual information density, fantasy MMORPG composition, readable full-body characters, equipment and skill presentation, combat framing, and polished UI language using original Honour War implementations and assets. The reference is a visual target, not permission to copy proprietary game artwork or source code.

## One permanent Honour War exception
The reference is accepted with this explicit player-world identity behavior:

1. Local character name: completely hidden in the 3D world.
2. Remote character names: hidden by default; never permanently floating above or below players.
3. A remote player's real character name becomes visible only when the mouse hovers the player, when the player is relevant to party/PvP context, or when an explicit social/chat reveal is active.
4. Never use a class name such as `Swordsman` as a permanent player nameplate.
5. Player HP/SP bars are hidden from normal world-foot presentation; player health can be represented in dedicated party/PvP/target UI.
6. Enemy combat HP bars remain permitted where they communicate a combat target.
7. The real character name remains authoritative in chat, party, PvP, right-click player context, and equipment/status inspection UI.

## Daily upgrade enforcement
Every Daily Honour War Upgrade must retain this reference and exception. Visual regressions in world identity/HUD are release-blocking until corrected.

## Production pipeline
Use the permanent production path: Blender → Substance 3D Painter → GLB/GLTF → Godot 4.7 Forward+.
