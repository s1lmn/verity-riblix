# Titan jump and native purchase prompts — 5 November

User reported Titan Leap doing nothing and requested standard purchase buttons instead of custom E buttons.

Leap previously called Humanoid.ChangeState on the server without owning character simulation. It now claims server ownership for launch, waits one physics step, switches to Freefall and applies an impulse targeting 115 studs/s vertically (previous power 68). Falling velocity is compensated without stacking extra upward speed. Ownership returns automatically after 0.2 seconds; Stop/death/equip cleanup releases ownership only when the ability claimed it. Delayed callbacks require the same active ability and living character. Server purchase, level, cooldown and ownership checks remain authoritative. Flight marks its existing ownership lease for cleanup as well.

All circular purchase stations now use Roblox ProximityPromptStyle.Default and its keyboard/touch/gamepad interaction. Removed the custom Billboard E button, hold event handlers and input forwarding. Decorative neon rings, affordability colours, labels and existing server purchase handlers remain. Native prompt offset separates it from the descriptive label.

Source edits and Rojo packaging only. No automated tests, Luau compilation, Studio Play or runtime confirmation under the user restriction. Jump behaviour still requires a player check in the newly opened build.

API reference: https://create.roblox.com/docs/reference/engine/classes/Humanoid#ChangeState

## Pull integration

Merged origin/main through c21872e, preserving the team's sustained dash, extended flight and steering timeout, flight ride/takeoff/landing, physical owner doors, parkour, card showcase, delivery event and full 100-level appearance progression. Leap uses the shared server-ownership preflight with our delayed launch, falling compensation and short ownership return; flight keeps the flight flag/Drive/watchdog required for steering. The native prompt controller preserves the team's exterior door-side restriction with a local root lookup; custom E buttons remain removed. No Play/tests performed during integration.
