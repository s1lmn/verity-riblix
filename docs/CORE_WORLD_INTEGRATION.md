# Core and World integration

World baseline: origin/main e81e404 (two-storey interior v2), including map v4 from31649dd.
Core baseline: agent/core d48ddee. Both histories are preserved by the integration merges.
The user's staged main.py remains in the original
checkout and is excluded from integration.

## Decisions

- User explicitly selected the team's5x progression for this integration. Scale uses
  milestones1:1,10:1.4,25:2,50:3,75:4,100:5, with strict growth between every adjacent level.
- The approved brick-floor-4 map and all World source/assets are preserved. Core adds only
  invisible interaction markers, prompts, ownership/state attributes and separate room copies.
- The actual17x17 Verity platform supports a2x2 base footprint at5x with1.15 animation
  expansion and2 studs effect margin per side:15.5x15.5. World must size the eventual asset
  within this envelope. A Verity asset is not delivered by the map snapshot.
- One server bootstrap owns world construction, allocation, economy and character loading.
  Preview MapBootstrap remains unchanged on disk and is disabled in the integrated Rojo tree.
- Personal interiors use the supplied StandardInterior template, cloned lazily per owner.
  ServerStorage owns the template; Workspace.PlayerInteriors owns session copies. No furniture
  data or room location is written into persistent player profiles.
- The latest v2 template contains375 parts and a50x70x32-stud two-storey envelope. Its
  existing EntryPoint/ExitPoint/pivot contract is unchanged;128-stud slots retain clearance.
- InteriorTransition is a private server-to-client event for the UI owner. Core does not
  implement the final fade controller or require client acknowledgement to move a player.

## Core interfaces

WorldIntegration.ReadLayouts reads the approved Lawn, VerityPlatform and markers.
CorePlots mirrors ownership and exposes SpawnLocation; delivery/Verity/upgrade references
point to actual World objects. World plot attributes mirror confirmed state for presentation.
InteriorFactory adds only missing invisible entry/return points without moving source parts.

InteriorService registers owned entrance/exit prompts, checks the current profile, plot,
character, distance, cooldown and transition token, streams the destination, clears seated
state/velocity and performs the server move. Late operations after death/removal cannot
teleport a new character. An8s watchdog terminates the operation; the UI must also time out
its own fade. Rooms are Atomic and are not made permanently loaded for all clients.
Foreign characters observed inside a room are returned to their own outdoor point.

## Verification

Executed against this integrated source:

- 572 standalone assertions, full Luau bytecode compilation and Rojo source roundtrip.
- 88 actual single-player Studio assertions against the v2 template, including all1549 original World parts checked
 against the approved recipe,5x final scale, private-room entry/exit, private UI event phases,
 continuing income inside, and20 repeated entry/exit cycles reusing the same room.
- 45 assertions with2 clients and123 with8, both on template v2. Separate rooms per owner, rejected
 foreign entrance/exit, intruder returned outside, death inside, room cleanup on disconnect
 and replacement-client allocation passed. StreamingEnabled was active; profiles were Memory.

Machine-readable evidence: integrated-single-report.json, integrated-multiplayer-2-report.json
and integrated-multiplayer-8-report.json. These are real engine tests with separate client
DataModels, not a16-player published-server or mobile performance test. Test money and late
progression levels are explicit test seeds, not a real complete progression playthrough.
Earlier Core-only reports remain historical evidence for their recorded source.

Still open: real DataStore on a published test place;16/24 real concurrent clients; injected
streaming timeout/death-during-stream cases; final camera/mobile/FPS/accessibility acceptance;
and UI's fade/timeout controller. No public publishing, purchase activation or Git push was
performed by this local integration.

The supplied map is not a finished simulator: UI, Verity model/effects, house upgrades and
final visual task targets remain separate World/UI work. Core's current task completion
requires World to register three physical targets; test targets are isolated to smoke tests.
