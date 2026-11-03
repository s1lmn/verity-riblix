# VERITY Core API v1

Status: source contract, 3 November 2026. Core owns this contract and `src/shared`.
World and UI should request contract changes rather than editing server payouts.

## Runtime layout and ownership

| Location | Owner | Purpose |
|---|---|---|
| `ReplicatedStorage.Shared` | Core | Pure configs, progression, number formatting, request validation |
| `ReplicatedStorage.Remotes` | Core | RemoteEvents, created by ServerBootstrap |
| `ServerScriptService.Core` | Core | Server services and Runtime integration module |
| `Workspace.CorePlots.Plot_01` etc. | Core | Stable ownership, state attributes and interaction anchors |
| `src/world` | World | Final map, Verity, houses, VFX, lighting, audio |
| `src/client` | UI | HUD, feed, gestures, tutorial presentation, settings |

The Core Rojo project deliberately does not own World/UI containers. Add their mappings
in a coordinated change; `$ignoreUnknownInstances` preserves unrelated Studio children.

## Requests

All are client-to-server **RemoteEvents**. Pass exactly one plain table. Every request
requires `operationId`: a positive, canonical decimal integer encoded as a string
(`"1"`, `"2"`, ...; maximum `1e15`). One increasing sequence per local player connection,
shared across all actions. Never reuse an ID for a new action. Retry a timed-out action
with the identical ID and payload. Serialize outstanding requests so packets on
different remotes cannot race each other. A new Roblox connection starts a new sequence.

| Remote | Additional fields | Checks |
|---|---|---|
| `RequestSync` | none | Ready profile; returns own state and WorldSnapshot |
| `RequestOpenBox` | none | Loaded profile, assigned plot, owner alive within 12 studs, Delivered |
| `RequestUpgradeVerity` | none | Box opened, cash, level <100 |
| `RequestUpgradeSwipe` | none | Box opened, cash, swipe level <40 |
| `RequestPhoneSession` | `open: boolean` | Box opened for opening; close always permitted when ready |
| `RequestSwipe` | none | Open phone session, unlocked Verity, >=0.75 seconds since paid swipe |
| `RequestTaskStart` | `taskId` | Valid task, own cooldown, unlocked Verity |
| `RequestTaskComplete` | `taskId` | Active task, alive character, server spatial/hold check |

`taskId` is `PRESS_BUTTON`, `REACH_POINT`, or `STAND_ON_PLATFORM`. Amount, level, PlotId,
owner, client timestamps, arbitrary fields, nested payloads and extra arguments are rejected.
State/rules never come from client values. Server methods behind these handlers do not yield.

Before rendering, attach all listeners, then call RequestSync. If NOT_READY, retry with
a fresh operationId after a short delay. On STALE_OPERATION use nextOperationSequence
from ActionResult. A stale/reordered request is never executed. Duplicate responses have
`replayed=true`: reconcile state, do not celebrate/pay again. Cached results live 120s,
bounded to 256/player; a monotonic watermark rejects older IDs even after eviction.
Limits: a global per-player bucket, burst 20, refill 8/s. Flood packets are dropped silently.

## Server-to-client events

`ActionResult = {protocolVersion=1, action, operationId?, status, reward=number,
replayed=boolean, stateRevision=number, nextOperationSequence=number}`.
Reward is the actual awarded amount; for purchases it is zero. Replay echoes the original
result and cannot change cash. `OK` alone means success. Common failures:
`NOT_READY`, `INVALID_PAYLOAD`, `INVALID_OPERATION_ID`, `UNEXPECTED_FIELD`, `INVALID_OPEN`,
`INVALID_TASK`, `OPERATION_CONFLICT`, `STALE_OPERATION`, `BUSY`, `INSUFFICIENT_CASH`,
`MAX_LEVEL`, `BOX_NOT_OPENED`, `NOT_DELIVERED`, `ALREADY_OPENED`, `TOO_FAR`, `COOLDOWN`,
`PHONE_CLOSED`, `NOT_ACTIVE`, `ALREADY_ACTIVE`, `HOLD_REQUIRED`, `INTERNAL_ERROR`.
The server echoes a syntactically valid operationId even when another payload field is
rejected. Missing/invalid operation IDs cannot be echoed. Do not show a successful reward
for rejection. A schema rejection does not consume the monotonic sequence watermark.

`PlayerStateUpdated` is an absolute snapshot for its recipient. Fields:

```text
protocolVersion, balanceVersion, stateRevision, serverTime, ownerUserId,
PlotId, Cash, TotalEarned, VerityLevel, VerityUnlocked, DeliveryState,
SwipeUpgradeLevel, TutorialStep, TutorialCompleted, HouseTier, VerityScale,
NextVerityScale?, NextMilestoneLevel?, IncomePerSecond, NextIncomePerSecond?,
SwipeIncome, NextSwipeIncome?, NextVerityUpgradeCost?, NextSwipeUpgradeCost?,
BoostMultiplier, BoostExpiresAt, PhoneOpen, NextOperationSequence,
Tasks = {[taskId] = {Active, CooldownUntil, HoldStartedAt?}}
```

Times are Unix seconds on `Workspace:GetServerTimeNow()`'s clock, including fractional
seconds. Cooldowns are session-only. Defaults for task IDs absent from Tasks: inactive,
zero cooldown. Maximum-level next values are nil/absent. UI must display MAX, not cost 0.
Income/Swipe values include the currently confirmed boost. Ignore snapshots older than
the last applied stateRevision for that owner's current plot assignment.
Snapshots are coalesced to 2/s for passive updates and immediate for actions.
Tutorial: 1 wait for delivery, 2 open box, 4 explain passive income/highlight phone,
5 swipe once, 6 upgrade Verity, 7 completed. Steps 3 and 4 are one confirmed unpack action;
UI can present the short explanation locally without another server mutation.

`NotificationEvent = {protocolVersion=1, code=string, source=string}` for prompt results.

## World events

Core broadcasts WorldEvent to all clients and the server-only `WorldSignal` BindableEvent.
Clients cannot initiate WorldEvent. Header (except WorldSnapshot):
`{protocolVersion=1, type, eventId, ownerUserId, plotId, stateRevision?}`.

| type | Additional fields | Presentation |
|---|---|---|
| `PlotAssigned` | `state` full owner snapshot, `presentation=false` | Apply current form |
| `PlotReleased` | none | Remove old owner's visuals/queued effects |
| `DeliveryStarted` | `duration` | Optional delivery animation; gameplay independent |
| `BoxOpened` | none | Unpack |
| `VeritySpawned` | `level` | Create Lv1 form |
| `VerityLevelChanged` | `oldLevel,newLevel,oldScale,newScale,milestoneLevel?` | One confirmed level animation |
| `HouseTierChanged` | `houseTier,purchaseEventId,presentation=false` | Same purchase; no duplicate celebration |
| `MilestoneReached` | `milestoneLevel,purchaseEventId,presentation=false` | Same purchase; no duplicate celebration |
| `WorldSnapshot` | `plots` full owner snapshots, `presentation=false` | Recipient-only resync, no past celebrations |

`getVerityScale(L)=1+14*((L-1)/99)^0.85`, exact unrounded scale.
99 ordered increases, 1 through 100 only. Deduplicate live events by eventId, queue all
confirmed transitions per owner. At streaming/rejoin/resync apply exact current form
without replaying historical effects. Correlate house/milestone with purchaseEventId.
On PlotReleased/PlotAssigned clear previous owner/revision state for that physical plot.
Anchor attributes carry current state for recovery if a client missed a remote.
Separate attributes are eventually replicated: StateRevision is a hint, not an atomic
snapshot barrier. Use RequestSync for a consistent complete snapshot.

## World server integration

Wait until `ServerScriptService.Core:GetAttribute("CoreReady") == true` (check before
subscribing to avoid a missed signal), then:

```lua
local services = require(game.ServerScriptService.Core.Runtime).GetServices()
local layout = services.PlotService:GetLayout(1)
-- World-created anchored BasePart in Workspace, with TaskId attribute:
services.WorldIntegration:RegisterTaskTarget("REACH_POINT", targetPart)
services.WorldSignal:Connect(function(event) ... end)
```

Do not mutate profile tables from World/UI. Server-only services are trusted integration
APIs, not security boundaries against other server scripts. World may call checked
DeliveryService:Open(userId), TaskService:Start/Complete(userId,taskId) from its prompts;
publish PlayerStateService afterward. Never call AddCash from visual code.

Each Core plot model has `PlotId, OwnerUserId` attributes (0 = free), plus confirmed
VerityLevel/VerityScale/HouseTier/VerityUnlocked/DeliveryState/IncomePerSecond/StateRevision.
Anchors: SpawnPoint, DeliveryPoint, UpgradeStation, VerityPoint. Do not move them after
assignment; build around their positions. World owns all visual children elsewhere.
SpawnPoint is a Core-owned SpawnLocation; it is enabled only for an occupied plot and
assigned as that player's RespawnLocation. Core disables CharacterAutoLoads, loads after
profile/plot readiness, and owns subsequent death respawns. World/UI must not introduce
a second character-loading loop or independently assign RespawnLocation.
Disable GameConfig.InteractionFallback after final pads/box interactions are integrated.
Core fallback pads and boxes are temporary integration proxies, not finished map art.
Task targets have no fallback yet; World must register all three. Core polls platform
standing every 0.1s; a death or observed departure resets the continuous hold.

## Geometry and capacity

All lengths in studs. Base model footprint 4x4, height 5; maximum 15x; animation envelope
1.15; margin 12 on each side. Reserved footprint = 93x93, reserved height 98.25.
Plot = 120x150, spacing along street 132, road width 40. 14 studs deeper from plot centre
is VerityPoint. House, delivery, UpgradeStation and passages must fit in the front strip,
outside the reserved Verity volume. World must revalidate/reconfigure if its base model
exceeds these dimensions or its effects/idle exceed this envelope. GetLayout is the
source for plot positions; alternating sides scale with configurable PlotCount.
ServerCapacity cannot exceed PlotCount. Set actual MaxPlayers separately in Dashboard.

## Persistence and optional boosts

Default fields include DataVersion=1, Cash/TotalEarned=0, VerityLevel=1, unlocked=false,
delivery NotDelivered, swipe level0, tutorial1/incomplete, BoostExpiresAt=0, Receipts={}.
Derived HouseTier/income/scale and physical PlotId are not persisted.
Record envelope `{Data=profile, Lock={SessionId,ExpiresAt}?}`. Keys `player_<UserId>`.
UpdateAsync acquires/refreshes a 180s lease; autosave 60s, fail closed 15s before expiry.
No defaults on failed/corrupt/future-version loads. Studio Memory is explicitly ephemeral;
StudioStore uses a separate `_Studio` store, never production by accident.

Products are unconfigured: Core never invents IDs or grants a client claim. Configured
server-confirmed ProcessReceipt writes entitlement and receipt ledger together before
PurchaseGranted. Multiplier affects income/swipes/tasks, never size or unlock availability.
Same multiplier does not stack; time extends up to 24h. Receipt IDs are never evicted;
at 5000 entries new purchases fail closed pending a ledger migration. Boost expiry persists
as an absolute timestamp; offline time consumes duration but earns no offline cash.

## Validation status

See VALIDATION.md and balance-simulation.json. A source test is not a Studio playtest.
World visuals, UI, multiplayer transport, production DataStore and mobile performance
must be validated after integration on an actual connected place.
