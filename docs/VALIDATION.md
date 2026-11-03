# Validation status

This document records the earlier Core-only validation. The source and5x progression have
changed during World integration. Current integrated results are recorded in
CORE_WORLD_INTEGRATION.md and integrated-*-report.json; old reports retain their original
source fingerprints and must not be treated as evidence for the new integrated build.

Date: 3 November 2026. This is a Core implementation, not a complete three-role game.

## Executed locally

- Actual Luau module tests using Luau 0.745: 7 suites, 566 assertions.
- All 100 exact growth scales, 99 increases, endpoints 1/15, no level101, 99 prices,
  monotonic base income, swipe cap40 and all six house tiers.
- No income before opening; actual elapsed-time income, no duplicate ticks, settlement
  at the old rate before an upgrade, and boost-expiry time splitting.
- Owner/distance checks for delivery through injected server spatial boundary; repeated
  unpack rejected; insufficient funds, max levels, malformed/nonfinite money rejected.
- Duplicate operations, conflicting/reordered/expired IDs, token-bucket spam limits and
  swipe cooldown. An evicted response cannot be executed again due to the watermark.
- Per-player task cooldowns, continuous platform hold with departure reset, death cancellation.
- Plot uniqueness/release/reuse at16; configuration at24 and geometric reservation separation.
- Profile roundtrip, session-lock conflict, expired/lost lease, corrupt/future data,
  failed loads without reset, concurrent saves, mutations during an in-flight save,
  UpdateAsync callback retries, and malformed lock timestamps.
- Receipt replay, failed/ambiguous grant save retry, persisted entitlement after rejoin,
  and boost expiry. Product IDs in tests are injected fakes; live product map is empty.
- Luau syntax/bytecode compile and Rojo build; built source roundtrip is checked by verify.py.

The standalone test harness injects storage/time/spatial boundaries. It executes the real
domain/service source, but does not simulate Roblox networking, physics, Instances,
throttling, or the actual DataStore backend. Warnings about simulated store outages are
expected in the failure tests.

Full Roblox-aware static typechecking is not completed: standalone luau-analyze cannot
resolve game/script/Instance imports. This is not recorded as a passed check.

## Executed in Roblox Studio

The separate verity-core-smoke.rbxlx test place passed **34 assertions** with one real
local player, real client/server RemoteEvents, engine Instances and character lifecycle.
See studio-smoke-report.json for the machine-readable observed result and test boundaries.
The test ran in Studio Memory mode. Money was seeded for purchase checks and level was
seeded to98 for the final two transitions; this is not a full progression playthrough.

Observed successful checks: correct owned SpawnLocation on first load and after death;
16 configured plots; box delivery/unpack/distance/repeat checks; real Heartbeat income;
phone/swipe reward, cooldown and deduplication; malformed request correlation; both
upgrade types; all three tasks using actual registered Parts and continuous platform
standing; ordered98->99->100 events, scale15/tier6, rejection of101; state resync after death.

The first live run exposed an early-character PivotTo overwritten by engine spawn.
Core now assigns RespawnLocation before LoadCharacterAsync and owns the respawn lifecycle.
A rejected payload initially omitted a valid operationId; the server now echoes safe IDs
on validation failures so the client can settle its outstanding request. Both fixes are
covered by the passing integration scenario; rejection correlation has a unit regression.

Actual StudioTestService multiplayer runs also passed:

| Concurrent clients | Assertions | Additional lifecycle checked |
|---|---:|---|
| 2 | 35 | One leaves; a replacement joins and reuses the free plot |
| 8 | 101 | Same replacement scenario at8 concurrent clients |

See studio-multiplayer-2-report.json and studio-multiplayer-8-report.json. These used
actual separate local client DataModels and one server, not fake Player instances.
Each client independently synced, unpacked, earned exact elapsed-time income, opened the
phone and received an idempotent swipe reward. Tests checked plot uniqueness, foreign-box
distance rejection, independent upgrades/tasks, death respawn and ownership after churn.
They still use Memory profiles and minimal Core geometry, so they do not prove production
DataStore, full World/UI performance or behaviour across published Roblox servers.

The normal Core build was also tested without any smoke scripts/bridge: its fallback
ProximityPrompt's engine input channel opened the delivered box and enabled5/sec income.
See studio-prompt-report.json. The test aimed the camera to make the prompt visible and
used the documented InputHoldBegin/End methods. Keyboard-only E activation was not verified;
an earlier off-screen camera view did not show the prompt.

## Balance simulation

See balance-simulation.json for exact inputs, milestone times, swipe expenditure and longest
purchase gaps. Costs and boost were calibrated by deterministic one-second simulation.

| Scenario | Time to100 | Swipe level reached |
|---|---:|---:|
| Passive online | 40.4983h | 0 |
| Moderate: 10 swipes/2min plus task route/2min | 39.7472h | 13 |
| Active: 45 swipes/min plus 15s route/min | 24.0000h | 33 |
| Same active policy, 5.3721x boost for4h | 3.7500h | 40 |

Every Swipe Power purchase is paid. Its policy buys when incremental payback is <=30min.
Task routes include travel/interaction time; payout frequencies respect all cooldowns.
The active scenario reaches10 at350s,25 at2947s,50 at11721s,75 at37523s,100 at86400s.
The accelerated scenario reaches10/25/50/75/100 at67/551/2182/5669/13500s.
Offline time is excluded. The boost extends duration, not multiplier; no purchase is
necessary for any level, size or milestone.

These are simulated policies, not retention estimates or real playtests. Moderate behaviour
is substantially slower than active; late active purchase gaps reach2117s (~35min).
The current formula/price table is a balance candidate, not finished progression design.
World/UI need intermediate visual/progression rewards and real route timings; recalibrate
with observed behaviour before claiming the requested game-feel and progression acceptance.

## Not executed / integration acceptance still open

- Keyboard/touch/gamepad prompt presentation/input through final World/UI remains to be checked.
- Real DataStore saves, throttling/outage/teleport/rejoin/shutdown tests on a published test place.
- Runs at16/24 actual players; final visuals/rewards under real network latency. The documented
  StudioTestService automation used here supports up to8 clients/session.
- Visual checks of every transition, especially98->99->100; milestone sequencing/dedup,
  streaming/resync, six house forms and giant model/road/neighbor clearance.
- Phone feed/gesture/UI integration, mobile safe areas and Reduced Motion/Effects.
- 16/24 giant models with effects for10min, real device/FPS/memory/network budget measurement.
- Live paid purchases: no real ProductId or catalog verification configured.
- Final map, models, UI, feed images, sounds and public release are owned by other roles.

Do not mark these checks passed based on compilation or the standalone test harness.
