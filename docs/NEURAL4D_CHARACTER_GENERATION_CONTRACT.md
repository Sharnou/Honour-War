# Honour War — Neural4D Character Generation Contract

## Production roster

Honour War has **60 production character assets**, not 30.

The roster is gender-complete: the character designs are generated with both gender variants. The intake gate therefore requires all 60 production character assets before the character-generation batch can be considered complete.

## Visual quality target

Every generated character must follow the Honour War HD visual specification:

- high-detail stylized 3D NPR / anime presentation;
- vibrant, saturated materials with clean cel-shaded separation;
- crisp line-art treatment where supported by the native Godot presentation pipeline;
- volumetric, chunky hair with controlled anisotropic-style highlight treatment;
- expressive stylized facial proportions and clearly readable facial planes;
- clean porcelain-like stylized skin without photorealistic pores;
- detailed PBR surfaces for clothing, leather and armor;
- woven matte fabric with fine weave detail;
- supple brown leather with controlled micro-scratch detail;
- brushed steel armor accessories with crisp, controlled highlights;
- warm volumetric sunlight and soft lavender-tinted shadows;
- no noisy photorealistic dirt or accidental texture artifacts;
- neutral presentation background during asset review.

## Pipeline rule

Neural4D is the approved generation source for this roster. Meshy-generated assets are not accepted for new Honour War production generations.

The production game runtime uses the native Godot no-GLB asset pipeline. **GLB and GLTF files are permanently rejected by asset intake.** Generated assets must enter the repository through the approved FBX/OBJ intake gate and then be converted/imported into native Godot resources as required by the runtime.

## QA requirement

A character batch is not complete merely because files exist. The final QA sequence must verify:

1. all 60 characters are present;
2. both gender variants are represented across the roster;
3. every asset passes the FBX/OBJ-only intake gate;
4. no GLB/GLTF enters the production asset tree;
5. characters render in the real game, not only in an asset preview;
6. face, hair, body, clothing, armor, materials, lighting and animation remain readable at gameplay camera distance;
7. the real-game screenshot capture succeeds before the batch is promoted.
