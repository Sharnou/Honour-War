# Honour War HD Assets

Honour War uses Sharnou Engine as its sole runtime.

Production asset path:
Visual RAG → Neural4D or Blender → Substance 3D Painter → FBX/OBJ authoring/interchange → glTF 2.x runtime container → KTX2 3D textures / AVIF 2D visuals → Sharnou Engine.

Runtime 3D scenes/models use .gltf/.glb. Runtime 3D material textures use .ktx2. UI/2D/distribution raster visuals use .avif. FBX/OBJ remain authoring/interchange inputs. Meshy and Godot are permanently rejected.

See:
- assets/3d/HD_ASSET_MANIFEST.md
- assets/3d/visual_rag/LATEST_VISUAL_BRIEF.md
- Content/HonourWarArt/ART_ASSET_MANIFEST.json
