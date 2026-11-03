# Setup

## Tool versions used

- Rojo 7.7.1 (official rojo-rbx release).
- Luau 0.745 (official luau-lang release), interpreter and compiler.
- Python 3.14, standard library only.

Install tools from their official releases or use the existing local tools at
`C:/Users/IvanI/PycharmProjects/riblix/tools/rojo/rojo.exe` and
`C:/Users/IvanI/PycharmProjects/riblix/tools/luau/`. The project does not depend on
code from the other game; only these compiler/CLI executables were reused.

From the project root:

```powershell
python scripts/verify.py --luau C:/path/to/luau.exe --compiler C:/path/to/luau-compile.exe --rojo C:/path/to/rojo.exe
```

This compiles every source/test, runs actual server/shared Luau with fake engine boundaries,
reruns the deterministic simulation, builds `build/verity-integrated.rbxlx`, then verifies that
the built script sources match the source tree. No test runner goes into the live place.
This is syntax/behaviour verification, not a Roblox-aware static typecheck or playtest.

## Repeatable Studio integration smoke test

Build a separate test place (never publish this place):

```powershell
rojo build smoke.project.json -o build/verity-core-smoke.rbxlx
```

Open it in Studio and Play. It includes two test scripts outside the normal src mapping:
one drives real client remotes, the other asserts authoritative server state and actual
Instance/character behaviour. It requires Studio + Memory mode, seeds test money/levels,
creates temporary task targets and intentionally kills/respawns the test character.
The console prints VERITY_CORE_SMOKE_PASS or VERITY_CORE_SMOKE_FAIL. Detailed results
are on ReplicatedStorage.CoreSmokeBridge attributes Status/Assertions/Report/Error.
The normal default.project.json excludes all test scripts and the bridge.

For actual local multiplayer testing, execute scripts/run_studio_multiplayer.luau in the
Edit DataModel of this smoke place through Studio MCP/plugin context. Set count to2 or8.
The helper starts StudioTestService asynchronously, and the test server ends it with a
structured result. When Edit mode resumes, read DataModel attributes CoreMultiStatus and
CoreMultiReport. Each run opens one server plus the requested actual client DataModels,
verifies ownership/economy independence, death, a client leaving and a replacement joining.
StudioTestService currently supports a maximum of8 clients/session, so it does not satisfy
the separate16-player acceptance requirement. See the official
[StudioTestService reference](https://create.roblox.com/docs/reference/engine/classes/StudioTestService).

Core is explicitly mapped in both Rojo projects to exclude the World preview MapBootstrap.
After adding/removing a server source, run `python scripts/update_core_mapping.py`; it preserves
the other World/UI project nodes. Only ServerBootstrap starts the integrated map/gameplay.

Core owns CharacterAutoLoads=false and LoadCharacterAsync after assignment. Do not add
another character spawning loop in World/UI. SpawnPoint is an enabled SpawnLocation only
while its plot is owned; Core assigns Player.RespawnLocation before loading the character.
CharacterAdded is used to attach death cleanup; final placement is applied after the
engine character-loading operation, avoiding an early PivotTo overwritten by engine spawn.

`python scripts/simulate_balance.py` checks the checked-in price table.
`--calibrate` intentionally rewrites all 99 prices and the candidate boost multiplier;
coordinate any such change with Core and rerun the Luau tests.

## Studio

1. Open build/verity-integrated.rbxlx in Studio, or create a new VERITY place and connect
   Rojo to `default.project.json`. Do not sync into the unrelated OskolkiIstoka place.
2. The default StudioDataMode is `Memory`: no Roblox API access is needed, and progress
   is intentionally lost when the test server stops. This is not a persistence test.
3. Play: Core builds the approved World v4 map once, binds its supplied markers, creates
   Remotes/owned SpawnLocations, loads a profile, assigns a plot and delivers the box.
4. Open the box to enable income. Verity visuals and UI must integrate before the full game loop can
   be played through menus. There is deliberately no temporary GUI competing with UI's work.
5. World registers the three anchored task targets; until then tasks reject completion.
   The map snapshot does not contain these final targets. Temporary test targets are not in
   the normal build. Enter/Exit prompts are available at the approved house marker and the
   owner's private standard room. UI supplies InteriorTransition fade separately.
6. For live DataStore testing, use a published **test** place, Studio API access and
   StudioDataMode `StudioStore`. This writes only `<DataStoreName>_Studio` in Studio.
   Live servers use DataStoreName. Do not enable API access or publish automatically.
7. Set the experience's actual MaxPlayers to ServerCapacity in Creator Dashboard.
   PlotCount and ServerCapacity default to 16; test 24 by setting both to 24.

Core bootstrap creates no production entitlements. Configure only verified owned product
IDs in EconomyConfig.Products if purchases are later required. ProcessReceipt is owned
by Core: do not add another script assigning MarketplaceService.ProcessReceipt.

## Source references

Persistence implementation follows the Roblox [Data stores guide](https://create.roblox.com/docs/cloud-services/data-stores),
[session-locking/purchasing guidance](https://create.roblox.com/docs/cloud-services/data-stores/player-data-purchasing),
and [error handling/ambiguous writes](https://create.roblox.com/docs/cloud-services/data-stores/error-codes-and-limits).
UpdateAsync transforms do not yield; store errors retry outside the callback. Profile
leases are refreshed even when clean so another server cannot acquire an active profile.

Tunables are currently versioned source configs as requested in the specification.
Optional [ConfigService](https://create.roblox.com/docs/reference/engine/classes/ConfigService)
live-ops integration is not enabled; no live experiment/deployment is configured. Any future
override must validate the complete price table/boost rules atomically and update BalanceVersion;
it must not change an active session's growth formula.
