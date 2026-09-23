# Honour War - HD Visual / Camera / Sky-Fog / Audio Lock

The Unreal Engine 5.8 presentation baseline is frozen.

## Camera and mouse controls
- default pitch -50 deg, yaw 45 deg, roll 0 deg
- camera arm 900
- wheel zoom 550-1350 in 120-unit steps
- right mouse drag rotates the camera
- WASD moves the hero
- left click ground moves the hero
- left click monster selects the target
- Q resets the camera

## Sky and fog
Permanent daylight remains enabled.
- sun intensity 9.5; color 1.0 / 0.94 / 0.84; rotation -52 / -32 / 0 deg
- captured-scene sky light intensity 1.9
- exponential fog density 0.0025; height falloff 0.28
- bloom 0.55; threshold 1.2; vignette 0.18; motion blur 0

No weather or day/night replacement is introduced.

## HD 3D MMORPG/ARPG target
High-resolution colorful anime-stylized MMORPG readability with the classic Ragnarok Online presentation target: bold silhouettes, expressive proportions, strong class identity, saturated controlled materials, detailed clothing/armor accents, layered terrain/foliage/architecture, clear contact shadows and restrained post effects.

Honour War assets remain original. Do not copy Ragnarok Online meshes, textures, maps, characters, UI art, logos, recordings or music.

## Audio
8 original gameplay/UI SFX and 7 original class piano loops are stored as 16-bit mono PCM WAV source files at 11.025 kHz. Unreal can import them under Content/Audio and create SoundWave assets during editor import/cooking.
