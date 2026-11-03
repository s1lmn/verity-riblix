# Verity Hero — textured base character

One UV sphere, 2,208 triangles, diameter 2.8 studs, center pivot, front local -Z. Eight vector-authored PNG expressions share the same UV layout. One mesh is reused; reactions swap only a texture. No native bead/ellipsoid face geometry.

The mesh and ALL eight images have now been uploaded through Roblox Studio. Actual IDs are in roblox-assets.json and src/shared/VerityCompanionConfig.luau. The full game build includes following, idle, respawn handling and eight Studio review buttons. Integration and limits: docs/VERITY_COMPANION.md. Local Studio tests do not establish asset permissions for another publishing creator/group.

Source files: VerityHero.glb embeds Joy; OBJ/MTL/textures are an alternative. PNG textures are 2048×1024 and include the yellow base color. Future colors need color-map variants; the mesh stays shared. VerityHero_StudioPreview.glb has a viewing rotation and is not the canonical forward orientation.

VerityHero_Review.html is an offline WebGL viewer of the actual exported geometry and textures, with drag rotation and emotion buttons. actual-mesh-*.png are software renders of actual OBJ triangles/UVs, not Studio screenshots. The older SetEmotion.luau is a manual MeshPart helper; the new integrated companion uses its server descriptor API and SpecialMesh.TextureId.

Eight expression IDs: Joy, Love, Playful, Wink, Laugh, Surprise, Confident, Stars. No audio, economics, paid cosmetics or 100-level progression are added here. Status/evidence: companion-checks.json. Existing prototype galleries remain historical candidates.
