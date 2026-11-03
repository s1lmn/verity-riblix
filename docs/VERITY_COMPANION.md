# Textured Verity — first ten looks

Ten bright plastic spheres based on the approved hero. No stripes, extra appendages, early-level neon or new UI. All ten reuse one UV mesh and eight transparent expression images; their native sphere body supplies the independent pigment. Each companion has two anchored, noncolliding local Parts. The old opaque yellow hero textures remain historical sources, not the current runtime textures.

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

Existing display-frame flight interpolation, independently smoothed heading/facing, bobbing, teleport catch-up, distance culling, first-person hiding and respawn recovery remain. ReducedMotion disables idle bob and expansion pulse and uses a linear color/size transition. Every visible owner shares one client render connection; there is no per-frame network transform traffic. Removing a descriptor destroys both Parts and disconnects its signals.

## Assets and Studio files

`assets/verity-ten-textured/Verity_FirstTen_Textured.rbxmx` contains all ten static models. The models subfolder contains each separately. They already have their level's size: do not apply LevelConfig a second time. The Integration configuration records Level, AppliedScale, AlreadyScaled and all eight emotion IDs. To change a static model's face, set Face.SharedFace.TextureId to its corresponding Integration string value. Runtime animation is in src/world-client/VerityCompanion.client.luau; the static models contain no scripts.

Canonical current cloud IDs: src/shared/VerityCompanionConfig.luau and assets/verity-ten-textured/roblox-assets.json. Transparent PNGs and the reproducible import GLB are included. Their eight actual texture IDs were read from imported Studio MeshParts on 2026-11-03. The approved mesh ID is reused. No runtime EditableImage/EditableMesh or local-file URI dependencies.

Assets belong to the logged-in Studio account. A different experience creator/group may need the normal asset permission grant. Published-game access and device performance were not verified.

## Build and verification boundary

The complete Rojo build includes the new shared palette, service API and renderer. StudioPreview still creates a level-1 companion only in Studio; production creation remains Core-owned. No progression is fabricated. Historical prototype renderers/factories must not be attached to these models.

This update is checked by Luau compilation and offline Rojo packaging only. Textures were uploaded/read back in Studio Edit mode. No Play, movement test, emotion playback test, multiplayer session or mobile profiling was run, per the user's request. Earlier hero checks describe the earlier build and are not evidence for this update.
