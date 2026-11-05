# Verity Elemental — approval models v1

Six static model samples matching the selected elemental concept:
Aqua10, Frost25, Magma50, Cyber75, Rainbow100; Cosmic75 is an alternative.
This mapping is provisional pending design approval. Intermediate levels unchanged.
No live renderer, gameplay, animations, map or progression files were changed.

## Open in Roblox Studio

1. Open your complete Verity project in Edit mode.
2. Use Studio's 3D Importer to open `Verity_Elemental_Gallery.glb` for all six
   samples, or any individual file in `models/`. Skins/face image data are embedded.
3. Inspect/approve these static samples. They are normalized in size for comparison;
   level names do NOT mean the model is already grown to gameplay size.

The gallery/individual GLBs have Body and an independent FacePreview plane with Joy
for design inspection. Face is NOT baked into the skin. For integration import
`Verity_Elemental_Bodies_Import.glb` instead: it contains only the six skinned bodies.

Optional existing-game adapter: put `ElementalImportAdapter.luau` in a ModuleScript,
then call `Adapter.Prepare(importedModel,"Aqua")` (or the other skin name).
It connects the existing World.VerityFaceUI and the game's uploaded eight expression
images. `Adapter.SetEmotion(model,"Love")` changes the independent expression.
Prepare strips FacePreview if present and sets anchoring/noncolliding properties.
Use only after 3D import into the full project. It is an approval adapter, not a
second companion controller. No auto-start or gameplay tags are installed.

## Integration after approval

Reuse existing Root/attachments, Follow, ScaleTo, animation, spawn/growth visibility,
FaceUI and cosmetics. Body uses white tint to preserve skin color. Existing
Factory currently recolors VerityTint parts: do not mark the skinned body as tinted.
Use shared LevelConfig for growth; base diameter1.7, forward−Z, origin at bottom.
Swap body appearance only at approved levels, with the same renderer owning motion.
No intermediate skins or automatic runtime selection are added in this sample pack.

## Budget and sources

Each sphere:2208 triangles/1225 UV-seam vertices, one1024×512 RGB skin texture.
The preview face adds2 triangles; production uses the existing normalized SurfaceGui.
Bodies-only importer shares vertex/index/UV buffers across its six materials.
Six1024×512 skins occupy9MiB uncompressed RGB in total (GPU format/mips vary).
Eight existing shared faces are included unchanged for portability. Textures are
procedurally authored, not cropped from the generated reference. No paid generators.

`preview-render.png` is a software rasterization of the exported GLB geometry,
embedded materials and UVs, not another generated concept or Studio screenshot.
Blender render helper is supplied but this machine's Blender failed on GPU startup;
no Blender rendering or FBX export is claimed. GLBs were structurally validated.
Studio was not connected, so upload/asset permissions/import/rendering in Roblox
remain unverified. No asset IDs for the six skins have been fabricated.
No Play was run. This pack is not yet a replacement for the live Rojo game.
