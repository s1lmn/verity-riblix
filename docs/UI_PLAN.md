# UI implementation plan — Egor

Date: 2026-11-03. Branch: agent/ui. Role: developer 3 (UI / Phone / Game Feel).

## Selection and sources

World is occupied: existing main contains map and interior work. No Egor assignment or Core/UI branch exists in remote refs at selection. This chat takes UI; Core remains unclaimed. The supplied updated DOCX files are requirements and role references, not independent permission to launch agents or publish. New requirements supersede old 5x / short economy examples: 100 levels, exact 1x–15x curve, free 20–30h and accelerated 3.5–4h targets requiring Core simulation. Preserve existing World assets.

## Implementation sequence

1. Establish proposed client API and source ownership; keep Core signatures explicitly provisional.
2. Build mobile-first HUD, single-window navigation, design tokens and lifecycle cleanup.
3. Implement 12 procedural feed compositions, touch/drag/wheel/Next input, phone session and confirmed rewards.
4. Implement Verity / Swipe upgrades, task direction, server-driven tutorial, notifications and accessibility settings.
5. Add correlated request handling, revision filtering, event deduplication, timeout handling and interior transition overlay.
6. Compile every Luau file, build with Rojo, run pure logic tests, then verify UI in a new Studio place if connected.

## Acceptance and boundaries

- No local economy, server handlers, persistence schema, paid entitlements or invented sound/image asset IDs.
- Missing Core displays waiting state; no fake cash. Preview fixture is Studio-only and explicitly enabled.
- All 99 growth steps remain distinct; final level has no next purchase.
- Purchase timeout retains uncertain operation; no blind retry or duplicate success.
- Touch zones, small landscape and portrait, gamepad focus, respawn and repeated open/close need live verification.
- World models, 16/24-player performance and economy pacing remain integration work owned by World/Core.

## Progress

- [x] Read both updated documents and repository; selected unoccupied UI role.
- [x] Created isolated agent/ui branch.
- [x] Client implementation and proposed API.
- [x] Static/logic/build verification.
- [x] Studio verification with evidence and handoff. See UI_TEST_REPORT.md for executed checks and remaining Core/World integration gates.
