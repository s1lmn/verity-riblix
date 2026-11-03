# Textured Verity companion — one base character

One uploaded UV sphere, eight uploaded textures, smooth following and idle. No changes to map, house geometry, existing UI controllers or economy. Old native prototypes and the 100-level renderer are not replaced or tagged onto this model.

## Run the current build

Open the complete place and press Play in Roblox Studio. Shared.VerityCompanionConfig.StudioPreview is true: every Studio player gets one base Verity without an emotion-selection menu. The automatic preview spawn is ONLY available in Studio. Normal live creation remains Core-owned; no unlock, cash or save state is fabricated.

## Core integration

```luau
local Companion = require(game.ReplicatedStorage.World.VerityCompanionService)
Companion.Attach(player) -- after confirmed unlock/restoration, not before
Companion.SetEmotion(player, "Love", 3) -- confirmed earning reaction
Companion.SetEmotion(player, "Playful", 2) -- confirmed combat reaction
Companion.Detach(player) -- PlayerRemoving already cleans up
```

Attach is idempotent. SetEmotion accepts Joy, Love, Playful, Wink, Laugh, Surprise, Confident, Stars. An optional 0..10-second duration resets to Joy; later reactions supersede earlier reset timers. Duration zero/nil persists until changed. No client economy events are invented. Core must call these operations after its real validations. The service is server-only.

CompanionBootstrap creates the empty ReplicatedStorage.VerityCompanions root immediately, even in a published server; delayed box opening therefore works after the client initially starts. In Studio it also enables the explicit preview. Manual emotion buttons and their preview remote have been removed. Only server logic calls SetEmotion; the client observes the confirmed Emotion attribute.

Each descriptor carries OwnerUserId and Emotion. Clients render one anchored noncolliding Part+SpecialMesh per owner using the SAME mesh; expressions swap only TextureId. One RenderStepped connection at display frame rate follows visible players with exponential interpolation, teleport catch-up, a small idle bob, distance culling, camera proximity/first-person hiding and missing-character/death hiding. Respawn reconnects by player identity. Surface casts help avoid solid walls and floors. Facial orientation faces the viewing camera horizontally for readability. ReducedMotion disables bobbing. No per-frame remote position traffic. Removal disconnects the per-model signal; script teardown destroys local visuals and controls.

Base size is 2.8 studs. There is no level-dependent growth in this one-character milestone. The existing shared LevelConfig is unchanged; large companion sizes need a later design/geometry pass before connecting progression.

## Assets

Real imported IDs: src/shared/VerityCompanionConfig.luau and assets/verity-hero/roblox-assets.json. The importer deduplicated the same mesh across all expression imports. Source textures/GLB/OBJ and an offline review viewer are in assets/verity-hero. No temporary file URIs, runtime EditableMesh/EditableImage calls, external code or missing numeric IDs.

Assets were uploaded by the logged-in Studio account. A game under a different creator/group may need asset permissions in Creator Dashboard. This work does not establish published-game permissions or multiplayer/device performance.

## Validation

Compilation/build and the previous 14 pure test groups pass; new world-client code is compiled separately. Actual imported mesh+image IDs were read back from Studio objects. Studio log confirms a real PlayServer, PlayClient and player join for the delivered v1 build, without companion script errors in that recorded run. That is startup evidence, not proof of movement, collision handling, eight emotions or respawn. Exact additional checks and remaining limits are in assets/verity-hero/companion-checks.json.


## Accepted feedback: action-driven reactions

The user accepted the base character, deferred movement smoothing, and rejected manual emotion selection. The test panel/remote were removed; do not re-add them to the default build. Core must call SetEmotion after its actual confirmed actions: paid swipe / earning -> Love (about 2–3 s), successful upgrade -> Stars (about 2 s), confirmed combat action -> Playful (about 1–2 s), failed action -> Surprise (about 1 s), then Joy via the existing duration timer. These are presentation mappings, not new economy or combat implementations. Core is still absent: there is no claim that earning/combat callbacks already execute. Movement-smoothing refinement is deferred per user.


Flight smoothing update: removed the visible 30 Hz transform cap. Follow position, owner heading and camera-facing rotation now have independent frame-rate-adjusted exponential filters; idle bob is applied after following without feedback. Owner teleports reset filters, and missing/dead character clears them. HeadingSpeed=6 and FacingSpeed=8 control turn softness. No Play test or device performance measurement was run for this update.
