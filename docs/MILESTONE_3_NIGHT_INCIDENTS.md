# Milestone 3 normal-night incidents

Build `0.24.0` adds a short, physical cooperative emergency to every normal
night. Enemy waves remain active while three incident sites appear around
Emberhollow, forcing the team to split attention between the First Lantern and
the town itself.

## Incident rotation

| Theme | Incident | Required response |
|---|---|---|
| Emberfall | Rooftop Cinders | smother three charred cinder nests |
| Miretide | Choked Drains | pull three root clogs from stone drains |
| Rootmoon | Root Anchors | sever three heavy roots feeding the assault |
| Ashen Veil | Dark Watchfires | relight three cold metal braziers |

Each incident uses the same archive, workshop, and inn coverage triangle, but
the authored object silhouettes, materials, prompt verbs, labels, and fiction
change with the night theme. These are world objects with recognizable parts,
not floating glyphs or screen-only chores.

## Timing and consequence

`TownNightSchedule` places exactly one deterministic incident beat at 58% of the
night. `TownNightIncident` opens a 42-second shared window and requires all
three unique sites. Repeated delivery to a resolved site is idempotent and two
players cannot claim the same progress twice.

Completing all sites clears the incident with no lantern loss. Letting the
window expire applies one bounded 12-point First Lantern pressure event, never
more than once and never below the existing 18-health emergency floor. Partial
progress reduces the failure summary's unresolved count but does not erase the
team consequence.

The incident is optional in the strict progression sense: failing it never
blocks the night, profession progression, town repair, expedition access, or
the Blackout. It is still consequential because ending lantern health feeds the
existing persistent town-damage calculation at dawn.

## Authority and cleanup

- The server chooses the incident from the frozen night theme and owns its
  deadline, resolved-site set, completion, failure, and lantern pressure.
- Clients submit only the normal interaction ID. The server verifies the live
  prompt, range, player survival state, action ID, and site payload.
- Physical prompts disappear site by site. Completion, failure, dawn, and the
  next incident all remove the remaining model, prompts, registry entries, and
  replicated world attributes.
- `TownNightService.snapshot()` exposes only the server snapshot: incident ID,
  title, instruction, deadline, resolved/required counts, and status.

## Automated validation

Pure Luau tests cover all four unique theme mappings, deterministic timing,
three-distinct-site completion, repeated-site idempotence, deadline failure,
single bounded penalty, unknown-site rejection, late input, and one incident
beat per night. The full suite also runs formatting, lint, type checks, 1,000
expedition seeds, both deterministic place builds, and built DataModel
verification.

## Studio, multiplayer, and device exit gate

1. Shorten the day/dusk timers locally and enter each of four consecutive normal
   nights. Require the correct incident title, prompt verb, and physical object
   family for that theme.
2. Resolve three different sites before the deadline. Require `SECURED` feedback
   per site, one completion toast, no lantern penalty, and full cleanup.
3. Have two players trigger the same site together. Require exactly one progress
   step and a harmless stale-input rejection for the second request.
4. Resolve one site, let the timer expire, and require two unresolved sites in
   the failure message and at most 12 lantern damage exactly once.
5. Attempt an interaction while downed, outside range, after expiry, and after
   dawn. Require no progress and no stale prompt.
6. Complete and fail incidents while enemies are attacking. Require enemy AI,
   dodge, revive, profession abilities, breach pressure, and dawn persistence to
   continue without deadlock.
7. Repeat on baseline phone, tablet, keyboard/mouse, and controller. Require the
   existing context action to remain reachable with no new permanent HUD button.

Automated checks establish the deterministic contracts and generated-place
inclusion. Recorded engine, multiplayer, latency, readability, and device
evidence remains required before this exit gate is closed.
