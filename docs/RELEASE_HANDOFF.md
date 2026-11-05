# VERITY release handoff

## House construction animation, 5 November

Confirmed construction purchases now play a short neon outline and rising bricks at the floor, door, roof or production module. `HouseProgression` marks progress increases for the current owner and the World client consumes fresh cues. Two effects can run at once on each client. Existing house reveals, collision handling and accessibility settings retain their roles. This pass was packaged without automated tests or Studio Play.

Door toggles now use a short local slide. The server applies access and collision when it confirms the toggle. Nearby clients display a temporary copy of the panel for 0.34 seconds. Rapid toggles continue from the panel's current position. This follow-up was packaged under the same test restriction.

## Save reliability and milestone motion, 5 November

Core uses the Roblox `UpdateAsync` callback to return the key value, associated user IDs and metadata. Each profile load has a unique lock token. Final saves wait for an active write, recognize a previously committed release on retry, and leave profiles closed for an autosave retry after a transport failure. The existing player data schema and store name are preserved. [Roblox UpdateAsync reference](https://create.roblox.com/docs/reference/engine/classes/GlobalDataStore#UpdateAsync).

The existing Verity upgrade renderer uses distinct milestone poses for hops, hover, impulse and spins. Reduced Motion still applies. See [ANIMATIONS.md](ANIMATIONS.md). No automated tests or Studio Play were run for this pass.

## Latest local expansion — powers and construction

The current local sources supersede the release below with cash-purchased, saved/equipped superhero powers, PvP/PvE, physical ability stands and staged house construction with increasing income. Homelander is a separate planned 99-Robux pass; the user explicitly deferred the real pass ID. See [POWERS_AND_CONSTRUCTION.md](POWERS_AND_CONSTRUCTION.md) for exact ownership, pricing, controls and unverified portions. These new sources have not been Play-tested or run through automated tests, according to the user's current restriction. The user requested a Git push on 5 November. The integration merges the team toy UI/admin preview commits 9b83404 and 81213b1 with the powers, construction, level-100 face correction and neon purchase pads. Roblox publishing remains deferred.

The validation section below describes the previous committed release, not this expansion.

The local game includes saved card discoveries, rarity rewards and reveals, house income upgrades, a lockable door, a furnished second floor, per-Verity abilities and level-based glow/flames/neon trails. Default language is Russian with English in settings.

## Map corrections

The sidewalk ends at the curb instead of sharing its side face. Road markings are raised above the road surface detail. The passage frame and sofa plinth have small clearances from overlapping coloured surfaces. WorldSurfaceController uses distance hysteresis for fine Studs and fades distant glass tint while preserving collisions.

## Team audio

The user's final decision is to use the team's audio in the shared Verity experience. The existing AudioConfig and UISoundController from the team are preserved. No new background music or local substitute pack is configured in this release.

Card anticipation uses the team's BoxAnticipation cue and is stopped at impact. Rare, epic and legendary impacts use the team's Milestone10, Milestone25 and Milestone100 cues. Confirmed house purchases and lock changes use existing confirmation sounds.

The team's private assets are authorized for the published experience, not a detached local file with GameId 0. They rejected that local preview context during Play. A public background track was temporarily exercised and later removed according to the user's final audio decision. Final team audio playback requires the shared experience and its permissions.

The supplied ExperienceDetails share link resolves to Verity. Collaborator access to edit that experience must be granted by its owner.

## Permanent triple money

The agreed price is 99 Robux. MoneyPassService checks UserOwnsGamePassAsync on the server at join and after a completed Roblox pass prompt. The multiplier applies to passive income, card payouts and task rewards. Income before the entitlement is verified settles at the previous rate. Repeated checks do not stack the multiplier.

The owner explicitly deferred connecting the real pass. Create a pass in Universe 10774627481, set its price in Creator Dashboard, and configure its real ID in src/shared/GameConfig.luau at MoneyPassId. The in-game button remains marked as coming soon until a real pass is configured. The client displays the current Roblox price from GetProductInfoAsync.

## Actual validation before the user stopped further checks

1391 automated assertions passed, including receipt idempotence, persistence, collection discovery, permanent multiplier settlement and reward routing. Audio lifecycle and feedback startup checks passed.

Local Studio Play confirmed Core and UI startup, house claim, opening the delivery box, a rewarded swipe, collection opening, door purchase/lock and second-floor purchase/furnishings. A native VFX exercise confirmed glow at level 1, flame at 10 and one/two/three trails at 50/75/100, including cleanup. The temporary public background track reported loaded and playing before being removed under the final team-audio decision.

Play was stopped at the user's request. Subsequent work was limited to source changes, packaging and Git integration. Multi-player runtime, mobile performance, live DataStore and real Robux purchase acceptance have not been completed. No public Roblox release was performed.

## Build

Open build/VERITY-Latest.rbxlx in Roblox Studio. builds/VerityGrowingSimulator.rbxlx is the canonical generated full-game output. Build fingerprints distinguish the current sources from previously opened files.

## Face visibility follow-up — 5 November

Bounded idle yaw, centre-based vertical camera facing and size-aware GUI distance/fallback now address the reported level-100 face issue. See [FACE_LEVEL_100.md](FACE_LEVEL_100.md). Packaged without Play or automated tests.

## Circular purchase pads and ability polish — 5 November

House/ability purchases now have local neon circles and compact custom prompt labels with affordability colours. Power effects have distinct rings, beams, particles and smooth tails. See [NEON_PURCHASE_PADS.md](NEON_PURCHASE_PADS.md). Packaged without Play, compilation or automated tests; included in the requested Git integration; no Roblox publishing.

## Team UI integration — 5 November

Preserved the team phone, task tablet, cosmetics, settings and growth/workshop toy skins and local admin preview. Added the ability shop to the same toy shell, retained workshop construction purchase buttons and income details, and combined admin preview with attack facing and the level-100 face fix. No tests, compilation or Studio Play were run for this merge under the user restriction. Unrelated user main.py remains outside the game commits.
