# First ten approved-base Verity looks

Insert Verity_FirstTen_Textured.rbxmx into Studio, or one file from models/. These are static models with real cloud asset IDs and no scripts. Each model is ALREADY scaled with shared LevelConfig; do not scale it a second time.

01 Sunny / 02 Mango / 03 Cherry / 04 Bubblegum / 05 Grape / 06 Blue / 07 Cyan / 08 Mint / 09 Lime / 10 Golden.

Body is a solid-color MeshPart. Its FaceGui is a SurfaceGui on Front with an ImageLabel cropped from one of eight transparent face images. Change Body.Color for pigment; change Body.FaceGui.FaceWindow.Expression.Image for expression. The crop is NORMALIZED: X=.375, Y=.28125, Width=.25, Height=.5. Roblox imported these 2048x1024 sources at 1024x512, so fixed pixel ImageRect offsets must never be used. FaceWindow clips the full image using relative position (-1.5,-.5625) and size (4,2). No SurfaceAppearance, SpecialMesh or overlapping mesh shell is used. The image face is a flat tangent face on the sphere front, not UV-wrapped; AlwaysOnTop=false preserves scene occlusion.

The default Rojo project syncs Verity_FaceTemplates.rbxmx into ReplicatedStorage.VerityCompanionAssets. Runtime clones the relevant FaceGui, follows the owner, and animates color/size changes. Hiding a companion also disables its SurfaceGui. In companion-preview.project.json, the Studio-only level panel offers minus/reset/plus, levels 1..10. It cannot spend or save anything, and its remote does not exist in live servers. No emotion-selection menu.

Integration: ../../docs/VERITY_COMPANION.md. Rebuild with `python tools/build_verity_first_ten_textured.py` (Pillow required). The import GLB is the historical source for uploaded image IDs; it is not the final runtime model. No Play tests were run for this update.
