# VERITY GROWING SIMULATOR

Core/server foundation for the three-developer Roblox project. Core owns server state,
economy, persistence, progression, plots, delivery, tasks and network contracts.
World owns the final map/models/effects; UI owns the client interface and phone.

Start with [the integration contract](docs/API_CONTRACT.md), then [setup](docs/SETUP.md).
[Validation and limitations](docs/VALIDATION.md) separate source tests from actual playtests.

## Layout

- `src/shared`: pure progression/economy/game/task/network definitions.
- `src/server`: authoritative services and ServerBootstrap.
- `tests`: executable Luau tests with injected time, storage and spatial boundaries.
- `scripts`: test runner, build verification, balance simulation.
- `docs`: API, setup, integration notes, simulation results.

Level scale is exactly `1 + 14 * ((level - 1) / 99)^0.85`: 100 levels, 99 increases,
1x to 15x. All levels/milestones remain available without purchases. The current
price table is a simulated balance candidate and needs real player testing.

Core has no client GUI and no final map. Temporary arrival pads and delivery boxes
allow interaction integration; World replaces them once its map is ready.
The pre-existing PyCharm `main.py` is unrelated to Roblox and is preserved.

No paid product IDs are configured, no game is published, and no Git push is performed.
