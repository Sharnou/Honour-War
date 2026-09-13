# Honour War 3D Characters

Production character assets are consumed by Godot 4 through the runtime asset bridge.

## Required art pipeline

**Blender → Substance 3D Painter → GLB/GLTF → Godot 4**

Blender owns the high-poly/source model, retopology, UVs, skeleton, rig, animation clips, and class variants. Substance 3D Painter owns physically based texture authoring. Godot consumes the final GLB/GLTF and does not replace the authored model with procedural geometry when a matching asset exists.

## Runtime naming contract

Use one of these filenames for each class:

- `hero_warrior.glb` or `hero_warrior.gltf`
- `hero_mage.glb` or `hero_mage.gltf`
- `hero_archer.glb` or `hero_archer.gltf`
- `hero_thief.glb` or `hero_thief.gltf`
- `hero_acolyte.glb` or `hero_acolyte.gltf`
- `hero_merchant.glb` or `hero_merchant.gltf`

Additional classes follow the same `hero_<stable_class_id>` rule.

## Model contract

Each hero should be a complete adult fantasy character: head/face, hair, neck, torso, arms, hands, pelvis, legs, feet/boots, class equipment, and visible weapon. The preferred animation set is `Idle`, `Walk`, `Run`, `Attack`, `Critical`, `Cast`, `Skill`, `Hit`, `Stun`, `Knockback`, `Death`, `Victory`, and `Teleport`.

Recommended presentation target: high-detail source model, 2K/4K PBR textures, normal map, roughness map, metallic map where appropriate, ambient-occlusion support, and emissive maps for magical/class effects.

When a production asset exists, `HDAssetRuntime.gd` checks `.glb` first and `.gltf` second and replaces the generated fallback actor while preserving the actor transform and gameplay state.
