# TestRoGame Combat System

Production-ready, server-authoritative melee combat MVP for Roblox (R15-compatible), built with Luau modules and Rojo.

## Folder Placement

These files are mapped to Roblox services via `default.project.json`:

- `ReplicatedStorage/Combat/Config.lua`
- `ReplicatedStorage/Combat/CombatTypes.lua`
- `ReplicatedStorage/Combat/SharedUtil.lua`
- `ReplicatedStorage/Combat/Remotes.lua`
- `ServerScriptService/Combat/CombatService.lua`
- `ServerScriptService/Combat/HitboxService.lua`
- `StarterPlayerScripts/Combat/CombatController.client.lua`
- Startup hooks:
  - `src/server/main.server.lua`
  - `src/client/main.client.lua`

## Setup

1. Build or sync with Rojo:

```bash
rojo build -o "TestRoGame.rbxlx"
# or
rojo serve
```

2. Open the place in Roblox Studio and run with at least 2 players (Test tab).
3. Combat is active by default without extra UI or tools.

## Controls

- **M1**: Light attack combo (4-hit chain)
- **M2**: Heavy attack
- **LeftShift**: Sprint (hold)
- **H**: Toggle local debug flag print (client debug keybind)

## System Architecture

### Client (`CombatController.client.lua`)

- Handles input and immediate local responsiveness.
- Sends only **intent** (`attackKind`, timestamp) through `Combat_AttackRequest`.
- Plays predicted animation once server broadcasts `Combat_PlayEffect`.
- Listens for `Combat_ServerCorrection` and gracefully cancels/re-syncs predicted state.

### Server (`CombatService.lua` + `HitboxService.lua`)

- Owns authoritative state per player: `Idle`, `Attacking`, `Stunned`, `Sprinting`.
- Validates every request:
  - payload shape + attack kind
  - server-time delta guard
  - alive character check
  - stun, cooldown, and anti-spam state checks
  - combo window/reset enforcement
- Performs hit detection server-side with `workspace:GetPartBoundsInBox`.
- Applies damage, stun, and knockback on server only.
- Replicates VFX/SFX hooks to all clients using `Combat_PlayEffect`.
- Sprint is server-authoritative via `Combat_SprintRequest` and is validated against stun/attack/non-movable states.
- Sprint/attack interaction is configurable via `Config.Movement.stopSprintOnAttackAttempt`.

## Security Decisions (Exploit Resistance)

- No `DealDamage` remote exists.
- Client cannot submit hit targets or damage values.
- Server independently computes hitbox overlap and target filtering.
- Team/self-hit prevention enforced on server (`AllowFriendlyFire` configurable).
- Single-swing multi-hit prevention via per-swing de-duplication table.
- Cooldowns and state machine are server-owned.

## Extending Moves / Weapons

All tunables are in `ReplicatedStorage/Combat/Config.lua`.

To add a weapon:

1. Add an entry under `Config.Weapons`.
2. Define:
   - `lightComboWindow`, `comboResetTime`
   - `lightMoves` list
   - `heavyMove`
3. Per move, tune:
   - `damage`, `knockback`, `stunTime`
   - `windup`, `activeTime`, `endlag`, `cooldown`
   - `hitbox.size`, `forwardOffset`, `heightOffset`
4. Replace placeholder `animationId` values with real IDs.
5. Set `Config.DefaultWeapon` or add weapon equip logic.

## Notes

- R15-compatible by targeting `Humanoid` + `HumanoidRootPart`.
- Debug logging is controlled by `Config.Debug`.
- Optional server hitbox debug visualization can be toggled via `Config.DebugHitboxesDefault`.

## Configuration highlights

- `Config.Movement.normalWalkSpeed`: baseline movement speed.
- `Config.Movement.sprintWalkSpeed`: movement speed while sprinting.
- `Config.Movement.stunWalkSpeed`: movement speed while stunned.
- `Config.Movement.sprintKeyCode`: sprint keybind (defaults to `LeftShift`).
- `Config.Movement.stopSprintOnAttackAttempt`: if `true`, attack input while sprinting only cancels sprint; if `false`, attacks are ignored while sprinting.
