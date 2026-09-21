# Honour War — HD 3D MMORPG / Anime-Inspired Style Contract

Status: PERMANENT / RELEASE-BLOCKING

## Identity

Honour War is an HD 3D anime-inspired medieval/fantasy MMORPG/ARPG.

This identity controls the visual language of every development visual cycle:
- full-body 3D anime-inspired heroes and NPCs;
- visible face, hair, hands, legs and feet;
- layered equipment and class-specific weapon silhouettes;
- expressive animation and readable hit reactions;
- dense authored towns, fields, mountains, rivers, ruins, snow regions and dungeons;
- PBR materials, detailed terrain and props;
- bright daylight with strong contact shading;
- readable combat VFX;
- compact MMORPG HUD.

## Permanent gameplay/camera identity

Honour War uses a Ragnarok Online-inspired desktop MMORPG interaction pattern:
- left-click ground = click-to-move;
- left-click living monster = select target and engage;
- right-mouse drag = camera orbit;
- mouse wheel = bounded zoom;
- W/A/S/D = secondary movement;
- 1–8 = gameplay skills;
- Q = camera reset.

Camera presentation:
- perspective projection;
- elevated isometric-style framing;
- approximately -50° default pitch;
- approximately 45° default yaw;
- complete hero body readable during normal play.

## Visual regeneration rule

Every completed visual cycle must use this contract as an invariant. The cycle may improve quality, density, materials, models, animation, VFX and environments, but it must not drift away from the locked MMORPG/anime-inspired identity or the mouse-first camera/control pattern.

Pipeline:
Visual RAG → gap register → brief regeneration → Neural4D/Blender → Substance 3D Painter → FBX/OBJ → Unreal Engine 5.8 → runtime validation → real EXE screenshot → reference comparison.

This is a development-cycle contract only. It does not activate unattended daily upgrades.

## Exclusions

Godot, GLB, GLTF, Meshy, generic primitive-only final art, strategy-game HUD/presentation and futuristic/scifi/robot/factory/space themes are not part of the target.
