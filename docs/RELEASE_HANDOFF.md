# VERITY release handoff

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
