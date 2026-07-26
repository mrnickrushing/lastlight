# Milestone 3 Bramblewake enemy roster

## Scope

Build `0.10.0` turns the first defense from repeated Rootling spawns into the
complete six-enemy standard Bramblewake roster. It preserves one active enemy at
a time so the authored tutorial remains solo-passable, readable on a phone, and
inside the low-end part/network budget.

Implemented in source:

- stable runtime IDs matching `CONTENT_CATALOG.md`;
- a deterministic six-spawn, two-minute first-night schedule;
- a bounded queue when the current enemy survives into the next authored beat;
- six original procedural silhouettes with no external asset dependency;
- server-owned health, range, line of sight, shield angle, damage, status, light
  pressure, queue progression, and night cleanup;
- locked circle and lane telegraphs with attack name, action instruction, and
  countdown;
- a contextual targeted HUD callout and temporary `DROWSY` state inside the
  existing stamina rail;
- generic enemy analytics with the stable enemy ID;
- pure roster, schedule, geometry, shield, and status-effect tests plus Studio
  integration assertions.

This increment does not implement the Old Growth elite, Warden Stag boss,
simultaneous swarms, general navigation/pathfinding, final animation, audio,
VFX, localization, or real-device evidence.

## Roster and counterplay

| Order | Stable ID | Mechanic | Solo counterplay |
|---:|---|---|---|
| 1 | `enemy_rootling` | readable circular swipe | leave the ring or dodge |
| 2 | `enemy_briarback` | strong frontal shield and lane sweep | move to its side/back; frontal hits still deal bounded damage |
| 3 | `enemy_pollen_wisp` | broad sleep cloud and 3-second movement slow | leave the cloud before resolve; keep moving while `DROWSY` |
| 4 | `enemy_hollow_crow` | quick swoop that steals an exposed lantern spark | step out of the narrow lane and intercept the low-health crow |
| 5 | `enemy_snapvine` | stationary route-denial ring | approach, bait the bite, retreat, and strike during recovery |
| 6 | `enemy_bark_ram` | long charge lane and high structure pressure | clear the lane and defeat it before repeated lantern impacts |

The Hollow Crow uses a temporary First Lantern spark as its stealable,
unbanked defense value in this first-night slice. It does not delete banked
inventory or durable player progress. Loose expedition-bundle theft remains a
later encounter integration when physical bundle pickups exist.

No counter requires a profession. Scout mark, Warden guard, Engineer repair,
and Medic heal remain optional team utility.

## Authoritative flow

```text
NightSchedule emits stable enemy ID
  → EnemyService validates ID
  → spawn now, or queue behind the one active enemy
  → server picks target and locks circle/lane area
  → world marker + targeted HUD show attack, instruction, shape, countdown
  → target leaves area/reaches cover/dodges: miss
  → otherwise server applies bounded damage and optional temporary effect
  → defeat waits 1.25 seconds, then advances the queue
  → dawn/reset/disconnect-safe cleanup removes enemy, attack, and queue
```

The client never submits enemy ID, target, health, angle, hit, damage, status,
lantern damage, or queue position. Enemy model attributes are presentation only.

## Mobile and accessibility direction

The implementation follows the
[Bramblewake Mobile Combat Callouts report](https://www.lazyweb.com/report/lazyweb/094ebe85-c65a-4a8a-908f-b1b209ecc935/?source=create).
The initial search had weak genre coverage, so unrelated reference screens were
not treated as direct evidence. The hosted report's contextual callout direction
was used because it extends the existing threat card and avoids a new permanent
panel:

- only the targeted player receives the combat callout;
- attack name and an imperative instruction remain readable without color;
- circle versus lane geometry communicates the escape direction in the world;
- the countdown is duplicated in the marker and existing threat card;
- `DROWSY` uses text, remaining time, and a stamina-rail state, not color alone;
- no center-screen dimmer, hold-to-peek gesture, paid recovery, or thumb-zone
  panel was introduced.

At most one enemy model and one attack marker are active. Each procedural model
uses a small anchored part set, no particle emitter, no per-frame client
animation loop, and a bounded 20 Hz server movement step.

## Windows Studio journey

1. Synchronize `main`, run `npm run bootstrap`, then run `npm test`.
2. Open `build/LastLightTest.rbxlx` and require
   `[Last Light] PASS FoundationIntegration`, build `0.10.0`, `services=12`, and
   no red errors.
3. Open `build/LastLight.rbxlx` or connect Rojo and complete First Light to dusk.
4. For each enemy, capture the silhouette, targeted threat card, world shape,
   countdown, miss/dodge path, one hit, defeat, and next queued spawn.
5. Strike the Briarback from front and rear. Require the explicit shield/flank
   messages and a possible solo defeat from either side.
6. Let one Pollen Wisp cloud hit. Require sprint cancellation, slower movement,
   visible `DROWSY` time, natural expiry, and normal speed restoration.
7. Let one Hollow Crow swoop hit. Require only temporary lantern damage—never
   banked inventory loss.
8. Approach the Snapvine from every side. Require a reachable strike position,
   an escapable ring, no collision trap, and no stalled night cleanup.
9. Let the Bark Ram reach the lantern, then evade its charge lane. Require high
   but recoverable structure pressure and the Mara emergency spark fallback.
10. Finish and fail the night with queued enemies remaining. Require dawn/reset
    to destroy models, markers, statuses, and queue state.
11. Repeat solo, two-player, eight-player, touch, keyboard/mouse, controller,
    live input switching, high latency, largest text, reduced motion, and muted
    audio.

## Exit and abuse gate

| Gate | Required evidence |
|---|---|
| Completion | every enemy is defeatable solo with no profession and no paid item |
| Readability | name, attack, instruction, shape, and time remain understandable without color, motion, or audio |
| Touch | threat card and stamina rail avoid Roblox top bar, thumbstick, jump, STRIKE, DODGE, ability, and context controls |
| Geometry | circle/lane visuals match server hit areas at every orientation and terrain height |
| Briarback | frontal shield never creates invulnerability; flank detection cannot be forged |
| Pollen Wisp | drowsy expires, cannot stack into immobility, and clears on respawn |
| Hollow Crow | only temporary lantern light is stolen; inventory and profile remain unchanged |
| Snapvine | reachable from the trail and every strike position has an escape route |
| Bark Ram | charge is avoidable and lantern failure remains recoverable |
| Queue | every authored ID appears once, no duplicate race occurs, and dawn/reset clears pending work |
| Multiplayer | one active enemy remains legible at eight players; targeted warnings do not leak to unrelated players |
| Performance | one enemy, one marker, 10 Hz status/stamina step, and procedural part count stay inside baseline-phone budgets |
| Analytics | spawn, telegraph, result, defeat, shield result, and stable enemy ID contain no profile contents |

Do not mark this increment device-tested or Milestone 3 complete from headless
validation alone.
