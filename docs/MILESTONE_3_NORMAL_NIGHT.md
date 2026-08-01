# Milestone 3 Normal Night town cycle

## Scope

Build `0.15.0` gives the town a repeating day/dusk/night cycle once First Light
completes, instead of stopping forever at the tutorial's single authored
night, and now survives a server restart:

```text
First Light completes
  → day (12 min) → dusk (2 min) → night N (6 min, escalating enemy waves)
  → dawn, night count advances
  → repeat indefinitely
```

This is the counting-and-defense half of the seven-night structure the launch
design calls for. It intentionally does **not** gate or auto-launch the
Bramblewake Blackout. An earlier decision deliberately let testers reach the
Blackout by walking into Bramblewake any time after First Light, without
simulating six additional town nights first — that fast path is unchanged.
This increment adds the repeating night alongside it, not in front of it.
Production content differentiation between nights (unique enemies, town-tier
growth, resident schedules, art/audio) remains later work; this increment
repeats the existing six-enemy Bramblewake roster with escalating wave counts
instead of adding new content.

The increment includes:

- a server-owned `TownNightService` day → dusk → night loop with a feature
  kill switch (`town_night_cycle_enabled`);
- a deterministic `TownNightSchedule` wave generator that scales 3 → 8 waves
  across nights 1 through 6 (capped), reusing the existing six-enemy
  Bramblewake roster rather than adding new enemies;
- night-count tracking and a `blackoutDue` flag surfaced as a toast on every
  seventh night, purely informational — it does not touch Bramblewake or
  Blackout access;
- reuse of the existing lantern/enemy HUD fields (`phase`, `phaseEndsAt`,
  `nightActive`, `lanternHealth`, `enemyCount`) so the existing client HUD
  needs no changes to render the repeating cycle;
- the existing "return to daylight before switching profession" rule extended
  to also cover a normal night, not just the first night;
- save-schema-v5 `town.nightNumber` on every player's own profile, updated
  whenever a night completes and restored — as the highest value among
  present players — the next time a server starts, so the count survives a
  restart without inventing a new town-wide save;
- pure Luau tests for the wave schedule's escalation, bounds, roster coverage,
  determinism, and the night-number migration/persistence contract.

Further content differentiation beyond the four tactical profiles, later town-tier growth, resident schedules,
and all Studio/device evidence remain open — see the Scope honesty row below.

The follow-on [town-condition increment](MILESTONE_3_TOWN_CONDITION.md) now
captures lantern health before the dawn reset, persists bounded building damage,
and adds physical daylight repair work. This runbook retains the original cycle
contract; the follow-on owns consequence and repair evidence.

## Flow and authority

The server owns the phase, the phase clock, the night count, and every enemy
wave — exactly as the first night already does. `TownNightService` waits for
`PhaseService:hasCompletedFirstNight()` before it starts its own loop, then
runs day/dusk/night indefinitely using `Config.NormalDaySeconds`,
`Config.DuskSeconds`, and `Config.NormalNightSeconds`. Each night it hands the
existing `EnemyService` a beat schedule from `TownNightSchedule.beats(duration,
nightNumber)` — the same `spawn`/`breach`/`warning` beat shape the first
night's `NightSchedule` already uses, so no new client protocol, remote, or
enemy-attack code was needed. The client never drives the phase, the wave
count, or the night number; it only renders the snapshot the server publishes.

## Wave schedule

`TownNightSchedule.waveCount(nightNumber)` returns `clamp(2 + nightNumber, 3,
8)`: night 1 opens with 3 waves, and the roster reaches its 8-wave ceiling by
night 6 — the night immediately before the seventh-night Blackout threshold.
Waves are spread deterministically across the middle 80% of the night
(`5%–85%` of its duration) and cycle through the same six enemies
(`enemy_rootling`, `enemy_briarback`, `enemy_pollen_wisp`, `enemy_hollow_crow`,
`enemy_snapvine`, `enemy_bark_ram`) in a fixed order, with one `breach` beat
placed after the midpoint wave. No randomness is involved, so a given night
number always produces the same schedule — the same determinism guarantee the
Bramblewake expedition generator and the first-night schedule already keep.

## Decoupling from the Blackout

`TownNightService` increments its own night counter and exposes
`blackoutDue = (nightNumber % Config.BlackoutInterval == 0)` in its snapshot,
purely so the town can say "the seventh night has arrived" in a toast. It does
**not** call into `BramblewakeBlackoutService`, gate Bramblewake entry, or
change what happens when a player interacts with the Blackout Lantern. Reaching
the Blackout today still means: finish First Light, then walk into
Bramblewake. This is a deliberate decision recorded in
[DECISIONS.md](DECISIONS.md) — wiring the two together (so the Blackout only
becomes available, or auto-starts, on an actually-survived seventh night) is
explicitly future work, once the town cycle itself has Studio/device evidence
and the recurring cadence is the tested default rather than a parallel system.

## Persistence

No town-wide save exists anywhere in this codebase — every server rebuilds
the same generic Emberhollow from scratch, and only player profiles persist.
Night count follows that pattern rather than inventing a new one: it lives as
`town.nightNumber` on each player's own save-schema-v5 profile, the same
DataStore/profile mechanism already used for `story.chapterOne`, inventory,
and profession. This is a recorded decision — see
[DECISIONS.md](DECISIONS.md).

`TownNightService:ensureStarted(nightNumber)` is called once per player,
either when a fresh player finishes First Light this session or when a
returning player's already-complete profile loads, each passing that
player's own stored `nightNumber`. The service takes the highest value seen
via `SaveSchema.withNightNumber`'s monotonic update — it only ever advances,
never regresses, so a returning veteran's progress is preserved even in a
party of newcomers. Whenever a night completes, every currently connected
player's profile is updated to the new count, regardless of who was present
when that night started. A bump after the loop has already started only
affects nights that haven't begun their wave schedule yet, so it never
retroactively changes a night already in progress.

## Windows Studio journey

1. Download the merged repository ZIP from GitHub and extract it.
2. Open `build/LastLightTest.rbxlx`, press Play, and require
   `[Last Light] PASS FoundationIntegration`, build `0.15.0`, schema `5`, and
   no red errors.
3. Open `build/LastLight.rbxlx`, finish First Light, and require the phase
   capsule to read `DAY` with a counting-down clock instead of freezing on the
   post-tutorial reveal state.
4. Wait through day and dusk (or shorten `Config.NormalDaySeconds`/
   `DuskSeconds` locally for faster iteration). Require the phase to switch to
   `NIGHT`, the lantern health rail to appear, and enemies to spawn on the same
   cadence the first night already used.
5. Survive night 1. Require a "DAWN BREAKS — NIGHT 1 SURVIVED" toast, the
   phase returning to `DAY`, and the next night's wave count visibly larger
   once night 2 arrives.
6. Attempt to switch profession mid-night. Require the same
   "RETURN TO DAYLIGHT BEFORE SWITCHING PROFESSION" rejection the first night
   already enforces.
7. Let the cycle reach night 7. Require a "THE BLACKOUT LOOMS IN BRAMBLEWAKE"
   toast, and separately confirm that walking into Bramblewake at any point
   before or after night 7 still starts the Blackout exactly as before this
   change — night count and Blackout entry must not block each other.
8. Disable `town_night_cycle_enabled`. Require the town to remain frozen at
   the post-tutorial reveal state (matching pre-`0.14.0` behavior) while First
   Light, Bramblewake, events, and the Blackout stay fully available.
9. Survive at least one night, then stop the server and start a fresh one
   with the same player. Require the cycle to resume from the persisted
   `nightNumber` (visible in the wave count and the dusk/night toasts)
   instead of restarting at night 1.
10. Repeat step 9 with two players who have different saved night counts.
    Require the server to resume at the higher of the two, and require the
    lower player's own profile to catch up once the next night completes
    rather than staying behind.

## Exit and abuse gate

| Gate | Required evidence |
|---|---:|
| Sequence | day → dusk → night → dawn cannot be skipped or reordered; the loop only starts after First Light completes |
| Escalation | wave count increases with night number and never exceeds the eight-wave roster ceiling |
| Determinism | the same night number always produces the same wave schedule |
| Authority | phase, clock, night count, and wave spawns are server-owned; the client only renders the published snapshot |
| Profession gate | switching is rejected during a normal night the same way it is during the first night |
| Kill switch | disabling `town_night_cycle_enabled` leaves First Light, Bramblewake, events, and the Blackout fully available |
| Independence | night count and `blackoutDue` never gate, block, or auto-start Bramblewake/Blackout access |
| Readability | phase, countdown, and lantern health reuse the existing HUD fields without requiring new client code |
| Persistence | night count survives a server restart, resumes from the highest present player's record, and never regresses |
| Scope honesty | per-night content differentiation, town-tier growth, resident schedules, recurring multi-chapter Blackouts, and all Studio/device evidence stay open |

Automated checks establish the wave schedule's escalation, bounds, roster
coverage, determinism, and the night-number migration/persistence contract as
pure Luau tests. Only recorded Studio, multiplayer, and real-device runs
(multi-night pacing, latency, reconnect mid-night, and mobile performance
across a long-running server) can close the rest of this milestone's exit
gate.
