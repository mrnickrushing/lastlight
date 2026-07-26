# Milestone 3 player survival and rescue

## Scope

This increment adds the first server-authoritative player failure and cooperative
rescue loop to the Bramblewake slice. It is a dependency for professions,
additional enemies, bosses, Blackouts, and expedition failure; it does not mark
those systems or Milestone 3 complete.

Implemented in source:

- immutable 100-health player state owned by the server;
- Rootling contact strikes for 24 damage on a bounded 1.5-second cadence;
- a 30-second downed window instead of Roblox character death;
- reduced crawl speed with jumping, sprinting, attacking, and interactions disabled;
- an automatic help signal with text, direction, distance, and countdown;
- one highlighted in-world ally target and a custom revive prompt;
- a 2.5-second revive channel validated for player identity, target state,
  range, line of sight, reviver state, and uninterrupted position;
- cancellation when either player leaves, the reviver is damaged or downed, the
  target is no longer downed, or reachability changes;
- revival at 35 health with a three-second light ward;
- safe retreat after bleedout at 50 health with a five-second light ward;
- reset/respawn handling as a 50-health safe retreat rather than a defeat bypass
  or full heal;
- expedition retreat through the existing streamed town-return path;
- a non-modal self-downed rescue rail, compact ally-down alert, and contextual
  health pill that preserve the mobile playfield;
- touch, keyboard/mouse, and controller revive semantics through the existing
  contextual action;
- down, revive, recovery, and cancellation telemetry;
- a feature kill switch, runtime attributes, pure state/channel tests, and
  Studio/build assertions.

Not implemented by this increment:

- partial loss of unbanked materials or a recovery cache/contract;
- a full-party defeat state, spectating, guard recovery, or boss-specific defeat;
- Medic profession modifiers, consumable healing, armor, status effects, or
  reviving more than one target;
- enemy navigation, the remaining Bramblewake roster, elite, boss, or Blackout;
- final animation, audio, VFX, localization, or real device/multiplayer evidence.

There is no paid revive, extra life, or loss protection.

## Authoritative contracts

The client never submits health, damage, revive duration, target distance, or
revive results. It only requests the server-created interaction ID. The server
owns:

```text
active (100 health)
  ↓ validated damage
downed (30 seconds, crawl only)
  ├─ valid uninterrupted ally channel → active (35 health, 3-second ward)
  └─ timer expires → safe retreat (50 health, 5-second ward)
```

`SurvivalState` is immutable and makes damage, down, revive, recovery, and
invulnerability deterministic. `ReviveFlow` makes channel timing and every
interruption reason independently testable. Player attributes replicate only
the presentation snapshot:

- `LastLightHealth` and `LastLightMaxHealth`;
- `LastLightDowned` and `LastLightBleedoutAt`;
- `LastLightReviveEndsAt` and `LastLightReviverUserId`.

Those attributes are not accepted back as authority.

## HUD direction

The implementation follows the
[Co-op Rescue HUD report](https://www.lazyweb.com/report/lazyweb/01fb79d9-741c-4685-8786-831be744e372/?source=create):

- a downed player gets one full-width bottom rescue rail rather than a modal;
- an active player gets one compact top-center alert for the most urgent ally;
- the world marker and contextual action remain the precise rescue target;
- text, shape, time, direction, and distance carry the state without requiring
  color perception;
- the help signal is automatic so a touch player is not forced to find a small
  ping button while crawling.

The rail stays above the action controls, toasts shift above the rail, Roblox
safe insets remain enabled, and combat/store actions disappear while downed.

## Windows Studio journey

1. Run `npm test` and open `build/LastLightTest.rbxlx`.
2. Start a local server with two players and confirm Output contains
   `[Last Light] PASS FoundationIntegration`.
3. Finish First Light, enter Bramblewake, and reach the authored night.
4. Keep one player beside a Rootling for five attack cadences.
5. Confirm health steps down, the Humanoid does not die, and the player enters
   crawl-only downed state with a 30-second rail.
6. On the other client, confirm the ally alert identifies direction, distance,
   and remaining time.
7. Approach the outlined player and use the `REVIVE` contextual action.
8. Stay within 12 studs with clear line of sight for 2.5 seconds. Confirm the
   target returns at 35 health and immediate damage is briefly rejected.
9. Repeat, then walk away during the channel. Confirm the channel cancels,
   feedback appears, and a fresh interaction can start.
10. Repeat and allow the timer to expire. Confirm a safe town return at 50
    health with the unbanked pouch retained.
11. Reset the downed character. Confirm the revive channel clears and the reset
    resolves as a safe retreat rather than a full-health bypass.
12. Repeat with touch, keyboard/mouse, controller, and live input switching.

For solo validation, allow Rootlings to down the only player and verify safe
retreat. Do not edit the replicated health attributes as a test shortcut; they
are presentation state and must not drive gameplay.

## Exit and abuse gate

| Gate | Required evidence |
|---|---|
| Solo | downing never creates an infinite death/respawn loop; bleedout returns to loaded town collision |
| 2/4/8 players | the most urgent ally is readable and only one channel owns a target |
| Touch | rescue rail, jump, movement, sprint, strike, and contextual action never overlap |
| Keyboard/mouse | `E` starts revive and ordinary movement cleanly interrupts it |
| Controller | `X`/Square starts revive and prompts update after live input switching |
| Accessibility | timer, text, direction, distance, marker, and action remain usable without color or audio |
| Exploit | self-revive, forged IDs, distant revive, blocked line of sight, repeated request, and client health edits fail safely |
| Disconnect | either participant leaving cancels without a stuck prompt or attribute |
| Streaming | downed target marker and safe retreat survive cell streaming |
| Performance | eight downed markers and HUD snapshots remain inside target phone frame/network budgets |
| Analytics | down, revive, recovery, duration, source, and cancellation reason appear without profile contents |

Do not mark this increment playtested or Milestone 3 complete from headless
validation alone.
