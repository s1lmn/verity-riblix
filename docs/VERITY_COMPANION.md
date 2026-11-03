# Verity: combined game and standalone art preview

## Current startup contract

`default.project.json` is the complete Core game, based on Ivan's integration commit 841fc96 and the team's facade/art changes. ServerBootstrap owns the world, player profiles, levels, rewards and cosmetics. VerityFactory creates one companion per owner; VerityVisualController owns its client presentation. It uses the team's first ten colors and eight shared expression images. Above level 10, Core's existing presentation remains; this update does not author another 90 models.

`companion-preview.project.json` is a separate Studio-only art review place. It uses VerityCompanionService, the standalone renderer and the minus/reset/plus level panel for 1..10. It does not run Core, spend money or save progression. The normal game uses real upgrades. Do not enable both runtimes on the same owner. ReplicatedStorage.VerityRuntimeMode is Core or Preview; startup guards prevent leftover scripts from the other Rojo project from starting. Stop Play before switching/syncing projects and restart the Rojo server if its project mapping changed.

## Confirmed face failure and fix

Source PNGs are 2048x1024. Read-only Studio AssetService inspection on 2026-11-03 confirmed that ALL EIGHT uploaded images are accessible to the logged-in account and are actually 1024x512. Joy's opaque pixels occupy approximately x=430..592, y=188..336. The old ImageRectOffset=(768,288), ImageRectSize=(512,512) therefore sampled a transparent area. The old crop was reproduced offline at the actual uploaded resolution. Earlier fixes based only on source resolution missed this.

Current faces use a clipping Frame and a full ImageLabel positioned/scaled in NORMALIZED coordinates, never pixel ImageRect offsets. Shared.VerityFaceLayout defines the source rectangle X=.375, Y=.28125, Width=.25, Height=.5. FaceWindow covers (.19,.14)–(.81,.78) of the 512-square SurfaceGui; the full image has Position=(-1.5,-.5625), Size=(4,2) relative to that window. This preserves the same artwork if Roblox resizes it again. The face is a flat image at the sphere's front tangent, not UV-wrapped.

World.VerityFaceUI configures both game and preview faces, explicitly sets Adornee/Front/FixedSize/CanvasSize, clears legacy pixel crops, and repairs older template layouts at runtime. Loading/unavailable images show a simple native GUI smile instead of a faceless sphere. Image.IsLoaded controls the temporary smile, not whether the entire GUI is enabled. Hidden companions disable their GUI; emotion changes re-enable the loading fallback until the replacement is ready. Preload failures are reported with asset/status, not silently treated as success. No runtime EditableImage/EditableMesh APIs, PBR texture packs or alpha SpecialMesh shells are required.

Core's following offset still follows the owner. Its facing rotation now follows the viewing camera horizontally so a face on local -Z is visible from the normal third-person camera, with the existing independent smoothing. Cosmetics stay attached to the same model and growth/purchase animations retain their owner. The game keeps its 1.7-stud base body and the art preview its 2.8-stud base body; both use the unchanged shared LevelConfig formula, 1 + 14*((level-1)/99)^0.85. Do not scale already-scaled static model exports a second time.

## Emotions and integration

Eight expressions: Joy, Love, Playful, Wink, Laugh, Surprise, Confident, Stars. Canonical asset IDs: src/shared/VerityCompanionConfig.luau and assets/verity-ten-textured/roblox-assets.json. Confirmed Core earning and upgrades trigger Love/Stars through WorldIntegration; actions remain server-owned. There is no manual emotion picker.

Standalone preview API (not the full game's progression API):

```luau
local Companion = require(game.ReplicatedStorage.World.VerityCompanionService)
Companion.Attach(player, savedLevel) -- only 1..10, after unlock/restoration
Companion.SetLevel(player, confirmedLevel)
Companion.SetEmotion(player, "Love", 3)
Companion.Detach(player)
```

Attach is idempotent. SetLevel fails when unattached and validates integer 1..10. SetEmotion duration 0..10 seconds resets to Joy, newer reactions supersede earlier timers. Its StudioSetLevel remote exists only behind the Studio/config guard, rate-limits and changes only the sender's cosmetic descriptor. Normal Core does not call this preview service or expose its debug remote.

Static ten-model pack: assets/verity-ten-textured/Verity_FirstTen_Textured.rbxmx. Each contains Body, Body.FaceGui.FaceWindow.Expression and Integration metadata. Change Body.Color for pigment and Expression.Image for an expression. The same normalized layout is generated into the eight templates and all ten exports. `tools/build_verity_first_ten_textured.py` reproduces them.

## Verification and limits

- Fast-forwarded to 841fc96; preserves one Core startup, shared 15x formula, compact UI, purchase presentation and cosmetics. Facade corrections remain untouched; user confirmed flicker resolved.
- Full source/test compilation, 678 standalone assertions (including face-loading/hiding and resized crop regression), balance simulation and Rojo source roundtrip (81 exact sources) passed.
- Both complete and preview projects build. Each contains eight expression images and exactly its own startup/renderer mapping. No fixed pixel crop remains in either exported library. All eight source images were checked at 2048/1024/512/256 widths; the previous invisible crop reproduced at 1024.
- Read-only Studio asset inspection confirmed access/dimensions; this is NOT Play or visual movement verification. No Play, multiplayer/device profiling or real purchase test was run for this change. Prior Core test reports describe their recorded versions, not this patch.
- A different experience creator/group may require normal image/mesh grants. The loading face remains visible if an expression cannot load; that does not replace granting its asset permissions.

## Personality pass

Shared.VerityPersonality samples a bounded presentation pose without engine dependencies. Visible companions lean gently with owner velocity (smoothed separately from following), then settle with a short damped nod after movement stops. The pose is layered inside the existing controller, suspended during upgrade presentation, and reset for teleports/hidden/dead owners. It does not alter physics, progression, saved size or cosmetics. Core and the standalone preview share it.

VerityFaceUI splits the normalized image into upper eyes and lower mouth clipping regions at 43% of FaceWindow. Both are affine views of the SAME full image; the resolution-independent crop remains. Only the upper image compresses during a 0.17-second blink, so the mouth stays put. Owner-specific phases avoid synchronized blinking. Blink is suppressed for Love, Stars, Surprise, Laugh, Wink and Playful to preserve their authored eyes. Use FaceUI.Image(gui), not a hardcoded descendant path, for the primary Expression image. Static exports remain unanimated.

Successful server-confirmed swipes retain Love and additionally show a bounded burst of three small pink GUI hearts beside the face. Hearts are created once per GUI; there are no per-frame instances, new asset uploads or remotes. Repeated swipes are visually limited to at most one burst per 0.55 seconds. Task reward confirmation triggers Confident; successful upgrades retain Stars and their existing purchase animation. A combat system is not present in this Core: future confirmed combat can call WorldIntegration:React(userId,"Playful",duration), without client-authorized emotion selection.

ReducedMotion suppresses blink/tilt/settle/hearts. ReducedEffects suppresses hearts while retaining ordinary motion and expressions. Distant companions skip personality motion; GUI visibility still follows the owner lifecycle. Tests cover frame-rate independence, tilt/settle bounds, authored-emotion priority, reduced motion and teleport resets. This pass passed 812 standalone assertions, full compilation and both Rojo builds. No Play or device rendering/performance measurement was run.

## Upgrade celebration

Shared.VerityUpgradeCelebration owns the common timing and limits. Normal purchased levels last 1.7 s; milestones 10/25/50/75/100 last 2.4 s. Existing authoritative ledger/Started/Completed signals still own the event; no fake level changes or purchase remotes are introduced. Model squash/growth/settling remains in VerityAnimationProfile and retains its exact final shared scale.

World effects now begin with a rotating rising spiral (12 normal / 24 milestone sparks), erupt at 45% progress (28 normal / 56 milestone / 80 final sparks), twinkle and fade. Actual star shapes are native billboard glyphs ★/✦ mixed with small Neon glitter. No uploaded particle textures or unverified asset IDs. The 128-spark client-wide pool is shared across owners, reused and bounded. A single VFX Tick advances effects; parts are anchored and noncolliding, with CanQuery/CanTouch/CastShadow=false. Existing stage auras remain separate from temporary celebration particles.

The owner's existing VerityPresentationController adds milestone-only Highlight pulse, a brief BloomEffect/ColorCorrectionEffect and a faint gold flash. Its existing Scriptable camera applies a bounded damped shake to a fresh pose (at most .055 stud horizontal, .04 vertical, .55 degree roll), never accumulating offsets. No second camera controller, no shake for neighbors or ordinary levels, no forced capture when another camera owner is active. VR skips scripted camera capture. Existing LevelUp/Milestone sound calls are retained; no new audio assets were added.

Stop/skip, death, model removal and camera replacement restore camera ownership and remove the temporary post-processing/glow. Hidden owners cancel pooled bursts. ReducedMotion and ReducedEffects suppress temporary particles and screen shake/glow; growth still completes. The standalone level preview shares spiral/burst timing and budget, but has no cinematic camera takeover or screen shake. Its reset cancels the previous burst.

Checks: 875 standalone assertions; full compilation; exact-source Rojo roundtrip (83 scripts/modules); complete and standalone builds. Added regression checks cover early-level celebration, milestone classification/timing, particle caps, bounded/disabled shake and owner-specific cancellation/pool recycling. No Play, visual camera verification, mobile FPS or multiplayer rendering test was run for this change.
