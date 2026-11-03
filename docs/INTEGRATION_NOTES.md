> Исторический документ. Актуальная локальная сборка и запуск: LOCAL_FINAL.md и README.md.

# Core handoff

Updated integration: World baseline origin/main31649dd is now combined with Core on
integration/core-world. The user selected5x progression. Follow CORE_WORLD_INTEGRATION.md
and the updated API_CONTRACT.md for actual marker paths and InteriorTransition. The older
handoff text below describes the pre-integration boundary and is retained for context.

API_CONTRACT.md is the source contract for World and UI. Share the same files rather
than independently reimplementing formulas or inventing remotes. The common Rojo mapping
currently includes Core/Shared only, preserving unknown Studio children. Agree on the
World/UI mappings before modifying default.project.json.

## World

Use PlotService:GetLayout and the CorePlots anchors. Core owns plot allocation/release,
respawn position and delivery state. World owns visual delivery, houses, Verity and effects.
No visual completion callback is required to unlock the delivered box; Core's timer and
checked fallback prompt keep it usable if an animation fails.

The initial model envelope is 4x4x5 studs at scale1; recheck the configured reservation
before replacing the model. Persistent stage visuals must be derived from current level,
not from replaying milestone events on join. Physical/camera clipping and visibility of
16/24 models at scale15 remain World integration checks.

Register each task's anchored BasePart with WorldIntegration. The platform target defines
the actual standable rectangle; root position must be above its top within 6 studs.
For button prompts, call Start then Complete through TaskService, never EconomyService.
Core uses server-observed positions on classic character replication. It does not claim
to prove that a human swiped or to provide a complete movement anti-cheat.

## UI

Connect listeners before RequestSync. Serialize actions with a single increasing operationId
sequence shared by all eight request remotes. Honor nextOperationSequence after a local UI
reload; replayed responses must not replay success effects. Handle profile-not-ready and
flood timeouts explicitly. A failed action consumes its operation ID too.

Use snapshots for amounts, prices, next scale/income, task status and tutorial steps.
Use serverTime/Workspace:GetServerTimeNow for cooldown display. Phone animations can be
local; payment popups wait for confirmed non-replayed ActionResult.reward.
UI settings/12 feed cards/audio assets are outside Core ownership.

## Shared changes

Core owns GameConfig, EconomyConfig, LevelConfig, HouseConfig, TaskConfig, RemotesConfig,
Numeric and NumberFormatter. FeedConfig and AudioConfig belong to their respective UI/World
owners. No existing UI/World source was copied or overwritten by this Core bootstrap.

The repository initially had an unborn main branch and a staged sample main.py. Core work
is placed on agent/core; the user's existing Python file/index entry is preserved. Core's
local baseline commit contains only the owned project files. Remote pushes, merges and
releases are separate from this local handoff.

## Observed handoff checks

The actual Studio integration place passed34 assertions with one local player, plus566
standalone assertions. See studio-smoke-report.json and VALIDATION.md. The current source
fixes an engine spawn-order race and keeps safe operationIds in malformed-request replies.
Both are relevant to integration: World must leave character loading to Core, and UI
must settle rejected requests by operationId instead of waiting for a success snapshot.

The normal Core build excludes the test client/server bridge and all test seeds. The smoke
place is only for Studio Memory tests. Actual2-client and8-client runs also passed35/101
assertions, including a real disconnect and a new client taking the released plot.
Final World/UI,16/24-client load, production DataStore and mobile visual acceptance remain
separate integration work.
