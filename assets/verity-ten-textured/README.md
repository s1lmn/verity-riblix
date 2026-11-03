# First ten approved-base Verity looks

Open Verity_FirstTen_Textured.rbxmx in Studio via Insert from File, or insert individual files from models/. These are static, ready-positioned models with real cloud mesh/texture IDs. They contain no scripts. The common approved face style is preserved in eight expressions, now on transparent images so any body pigment works.

01 Sunny / 02 Mango / 03 Cherry / 04 Bubblegum / 05 Grape / 06 Blue / 07 Cyan / 08 Mint / 09 Lime / 10 Golden.

Each model has Body, Face.SharedFace (SpecialMesh) and Integration metadata with eight texture IDs. Change the SpecialMesh TextureId to swap expression; keep the shell white and change Body.Color for pigment. Keep Face at Body.CFrame. Each export is ALREADY scaled with shared LevelConfig; do not multiply its size again. Face mesh scale includes the 1.004 separation to avoid overlap artifacts.

The integrated game renderer uses the same assets/config with idle flight, smooth color/growth transitions and an expansion pulse. Full server integration and accepted limits: ../../docs/VERITY_COMPANION.md. No action-selection UI or automatic economy changes. No Play tests were run for this pack.

Rebuild source PNGs/import GLB and ten model exports:
`python tools/build_verity_first_ten_textured.py` (Pillow required).
The authoring import GLB contains transparent face shells only, not the colored bodies; it is not the final model pack. roblox-assets.json records the actual uploaded IDs. levels.json records the ten authored looks and their applied sizes.
