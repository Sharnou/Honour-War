# Honour War HD Assets

Honour War uses Sharnou Engine as its sole runtime.

Production asset path:
Visual RAG → Neural4D or Blender → Substance 3D Painter → FBX/OBJ private authoring/interchange → SharnouEngine native runtime compilation → AVIF visual delivery.

Runtime geometry is compiled into SharnouEngine-native representation. External shipped raster/visual assets use AVIF only. GLTF, GLB and KTX2 are permanently rejected. FBX/OBJ remain private authoring/interchange inputs. Meshy and Godot are permanently rejected.

See:
- assets/3d/HD_ASSET_MANIFEST.md
- assets/3d/visual_rag/LATEST_VISUAL_BRIEF.md
- Content/HonourWarArt/ART_ASSET_MANIFEST.json
