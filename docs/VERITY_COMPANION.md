# Textured Verity — first ten looks

Ten bright plastic spheres based on the approved hero. No stripes, extra appendages, early-level neon or new UI. All ten reuse one UV mesh and eight transparent expression images. Each companion is one anchored, noncolliding solid-color MeshPart with a Front SurfaceGui/ImageLabel for its expression. The image is cropped from the existing shared RGBA artwork; it is independent of mesh UVs and PBR texture packs. The face is a flat tangent image, not UV-wrapped; scene occlusion remains enabled (AlwaysOnTop=false). The old opaque yellow hero textures remain historical sources, not the current runtime textures.

## Core integration

```luau
local Companion = require(game.ReplicatedStorage.World.VerityCompanionService)
Companion.Attach(player, savedLevel) -- confirmed unlock/restoration; currently 1..10
Companion.SetLevel(player, confirmedLevel) -- after a real upgrade, not from a client claim
Companion.SetEmotion(player, "Stars", 2) -- successful upgrade reaction
Companion.SetEmotion(player, "Love", 3) -- confirmed swipe/earning
Companion.SetEmotion(player, "Playful", 2) -- confirmed combat action
Companion.Detach(player)
```

Attach is idempotent; omitting its level defaults a new companion to 1 and preserves an existing descriptor's level. SetLevel returns false if no companion is attached. Only integer levels 1..10 are authored and accepted. This milestone does not implement levels 11..100, economy, saves, unlocks or purchases. Core must supply its saved/confirmed level; no fake upgrade controls were added.

SetEmotion accepts Joy, Love, Playful, Wink, Laugh, Surprise, Confident, Stars. Optional duration 0..10 seconds returns to Joy; a later reaction supersedes an earlier reset timer. Zero/nil persists. Calls are server-only. No manual emotion menu or client emotion remote exists. Event mappings are ready for Core; this does not claim earning/combat callbacks already exist.

Descriptors have OwnerUserId, Emotion and Level. The client reacts to confirmed attributes. Changing level smoothly changes color and size with a small expansion pulse. A jump queues each intermediate look; restoration, hidden companions and level decreases apply immediately. Growth comes from Shared.LevelConfig.getVerityScale, unchanged: 1 + 14 * ((level - 1) / 99)^0.85. Level 1 diameter is 2.8 studs; level 10 is approximately 7.91 studs. Higher levels move farther from the owner and use a larger wall/floor query radius.

Existing display-frame flight interpolation, independently smoothed heading/facing, bobbing, teleport catch-up, distance culling, first-person hiding and respawn recovery remain. ReducedMotion disables idle bob and expansion pulse and uses a linear color/size transition. Every visible owner shares one client render connection; there is no per-frame network transform traffic. Removing a descriptor destroys the MeshPart and disconnects its signals.

## Assets and Studio files

`assets/verity-ten-textured/Verity_FirstTen_Textured.rbxmx` contains all ten static models. The models subfolder contains each separately. They already have their level's size: do not apply LevelConfig a second time. The Integration configuration records Level, AppliedScale, AlreadyScaled and all eight emotion IDs. Verity_FaceTemplates.rbxmx is synced by the Rojo project to ReplicatedStorage.VerityCompanionAssets. To change a static face, set Body.FaceGui.Expression.Image to the corresponding image ID. Runtime clones FaceGui from the selected template. ImageRectOffset=(768,288), ImageRectSize=(512,512); the same crop fits all eight expressions. No SurfaceAppearance, SpecialMesh or second mesh shell is used. Hiding the body also disables its FaceGui. Runtime animation is in src/world-client/VerityCompanion.client.luau; the static models contain no scripts.

Canonical current cloud IDs: src/shared/VerityCompanionConfig.luau and assets/verity-ten-textured/roblox-assets.json. Transparent PNGs and the reproducible import GLB are included. Their eight actual texture IDs were read from imported Studio MeshParts on 2026-11-03. The Joy mesh ID from the transparent-face import is used. No runtime EditableImage/EditableMesh or local-file URI dependencies.

Assets belong to the logged-in Studio account. A different experience creator/group may need the normal asset permission grant. Published-game access and device performance were not verified.

## Build and verification boundary

The complete Rojo build includes the new shared palette, service API and renderer. StudioPreview still creates a level-1 companion only in Studio; production creation remains Core-owned. The temporary Studio panel can change only the cosmetic descriptor, never Core progression, currency or saves. Historical prototype renderers/factories must not be attached to these models.

This update is checked by Luau compilation and offline Rojo packaging only. Textures were uploaded/read back in Studio Edit mode. No Play, movement test, emotion playback test, multiplayer session or mobile profiling was run, per the user's request. Earlier hero checks describe the earlier build and are not evidence for this update.

## Rendering fix after user report

The first release incorrectly used an RGBA texture on a SpecialMesh shell, producing a black sphere. It now uses one MeshPart with a pre-authored SurfaceAppearance in Overlay mode; expressions swap cloned appearances, and body pigment stays independent. PreloadAsync receives asset instances instead of a bare mesh ID (Studio logged an image-type mismatch for that untyped request). All ten static exports and the game renderer use the corrected representation.

Read-only inspection of the user's current Edit scene found only the default Baseplate and no duplicate generated world. Its position (0,-10,0) and size (512,20,512) put its studded top at Y=0, exactly equal to GeneratedWorld.Environment.Ground. MapBootstrap now parks only a root Baseplate whose flat top overlaps Ground at the same height, in ServerStorage during execution. It does not delete the Edit-time floor or alter houses. This addresses the confirmed floor overlap; the report of flickering walls has not been reproduced or verified as resolved. No Play was started for diagnosis or validation. Stop and restart after syncing the updated Rojo project; it includes a new asset mapping.

## Current rendering and preview revision

The user reported that the prior SurfaceAppearance version had no visible face. It is superseded by a direct ImageLabel on SurfaceGui, using the same uploaded image IDs without PBR texture-pack generation or imported UV mapping. This implementation has been compiled and structurally checked; visual behavior has not been verified in Play. Previous sections describing the first SurfaceAppearance fix are historical.

VerityLevelPreview.client.luau creates a small bottom-center Studio-only panel with minus, reset-to-1 and plus. It displays the server-confirmed cosmetic level, 1..10. StartStudioPreview creates StudioSetLevel only after its IsStudio/config guard. The server validates an integer range, acts only on the sender's descriptor, throttles requests to one per 0.2 seconds, and triggers Stars briefly on an increase. No production remote, no economy, no save writes and no manual emotion selection. The panel is absent when StudioPreview=false or outside Studio.

Facade correction: vertical colored side piers are split around the horizontal floor band; side strips stop at the passage wall; the lobby ceiling/roof cap stop at that wall instead of entering it. Passage frames are wider/deeper and entrance posts wider, separating their exposed faces from the wall planes. Door layout, wall colors and free walk-in circulation remain. Source generator, InteriorRecipe and standalone interior XML are updated. Offline geometry checks confirm no positive-volume intersection between corrected side piers/bands, passage wall and lobby ceiling/cap. This is not a Studio rendering or movement test.
