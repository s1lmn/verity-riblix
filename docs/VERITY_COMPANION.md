# Textured Verity companion — one base character

One uploaded UV sphere, eight uploaded textures, smooth following and idle. No changes to map, house geometry, existing UI controllers or economy. Old native prototypes and the 100-level renderer are not replaced or tagged onto this model.

## Run the current build

Open the complete place and press Play in Roblox Studio. Shared.VerityCompanionConfig.StudioPreview is true: every Studio player gets one base Verity and eight review buttons. These controls are ONLY available in Studio. Normal live creation remains Core-owned; no unlock, cash or save state is fabricated.

## Core integration

```luau
local Companion = require(game.ReplicatedStorage.World.VerityCompanionService)
Companion.Attach(player) -- after confirmed unlock/restoration, not before
Companion.SetEmotion(player, "Love", 3) -- confirmed earning reaction
Companion.SetEmotion(player, "Playful", 2) -- confirmed combat reaction
Companion.Detach(player) -- PlayerRemoving already cleans up
```

Attach is idempotent. SetEmotion accepts Joy, Love, Playful, Wink, Laugh, Surprise, Confident, Stars. An optional 0..10-second duration resets to Joy; later reactions supersede earlier reset timers. Duration zero/nil persists until changed. No client economy events are invented. Core must call these operations after its real validations. The service is server-only.

CompanionBootstrap creates the empty ReplicatedStorage.VerityCompanions root immediately, even in a published server; delayed box opening therefore works after the client initially starts. In Studio it also enables the explicit preview. The Studio-only remote accepts only known emotion strings for the calling owner, at most four per second. It does not exist in a live server.

Each descriptor carries OwnerUserId and Emotion. Clients render one anchored noncolliding Part+SpecialMesh per owner using the SAME mesh; expressions swap only TextureId. One RenderStepped connection at up to 30 Hz follows visible players with exponential interpolation, teleport catch-up, a small idle bob, distance culling, camera proximity/first-person hiding and missing-character/death hiding. Respawn reconnects by player identity. Surface casts help avoid solid walls and floors. Facial orientation faces the viewing camera horizontally for readability. ReducedMotion disables bobbing. No per-frame remote position traffic. Removal disconnects the per-model signal; script teardown destroys local visuals and controls.

Base size is 2.8 studs. There is no level-dependent growth in this one-character milestone. The existing shared LevelConfig is unchanged; large companion sizes need a later design/geometry pass before connecting progression.

## Assets

Real imported IDs: src/shared/VerityCompanionConfig.luau and assets/verity-hero/roblox-assets.json. The importer deduplicated the same mesh across all expression imports. Source textures/GLB/OBJ and an offline review viewer are in assets/verity-hero. No temporary file URIs, runtime EditableMesh/EditableImage calls, external code or missing numeric IDs.

Assets were uploaded by the logged-in Studio account. A game under a different creator/group may need asset permissions in Creator Dashboard. This work does not establish published-game permissions or multiplayer/device performance.

## Validation

Compilation/build and the previous 14 pure test groups pass; new world-client code is compiled separately. Actual imported mesh+image IDs were read back from Studio objects. Studio log confirms a real PlayServer, PlayClient and player join for the delivered v1 build, without companion script errors in that recorded run. That is startup evidence, not proof of movement, collision handling, eight emotions or respawn. Exact additional checks and remaining limits are in assets/verity-hero/companion-checks.json.
