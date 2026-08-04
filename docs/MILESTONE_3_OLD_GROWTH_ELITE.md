# Milestone 3 Old Growth elite

## Scope

Build `0.11.0` turns the authored Old Growth Approach into the first complete
expedition elite encounter. It extends the existing combat, rescue, profession,
inventory, extraction, analytics, and mobile-HUD contracts without introducing a
new client authority path or a required profession.

Implemented in source:

- stable elite, interaction, attack, and reward IDs;
- a server-run 360-health state machine with exposed phases at 360–240,
  240–120, and 120–0 health;
- an explicit required-module contract so every valid representative manifest
  contains the authored Old Growth arena before world construction begins;
- hard shield stops at 240 and 120 so excess strike damage cannot skip a phase;
- one shared lantern-fire carrier with a 15-second server timer;
- dormant fire-source and root-heart prompts enabled only during a shield;
- a 32-stud Cathedral Roots lane with a 1.35-second windup, 20 damage, and a
  bounded 1.6-second `ROOTED` movement slow;
- a 10-stud Canopy Fall ring with a 1.55-second windup and 28 damage after the
  first shield;
- an original procedural Old Growth silhouette, heart state, mark state, world
  telegraphs, and no external asset dependency;
- contextual mobile-safe health, phase, shield instruction, and carried-fire
  timer that disappear outside the arena;
- Scout telegraph slowing, Warden mitigation, generic Medic support, and a
  profession-independent normal-strike path;
- three unbanked Amber Sap for every participant through stable, idempotent
  reward transactions and the existing Wayhome settlement;
- activation, attack, phase, result, completion, and reward logs plus a feature
  kill switch;
- pure state/effect tests and Studio DataModel/model/interaction assertions.

The Warden Stag boss, encounter navigation, final animation, audio, VFX,
localization, production balance, and real-device evidence remain open.

## Encounter flow

```text
active expedition player enters Old Growth arena
  → server activates one shared encounter and records participant
  → exposed heart: normal strikes reduce health
  → threshold reached: health clamps and root shield closes
  → one player takes lantern fire
       ├─ reaches root heart within 15s: shield burns
       └─ timer expires: flame clears and another can be taken
  → second exposed phase adds Canopy Fall
  → second fire break opens the final phase
  → health reaches zero
  → every participant receives one +3 Amber Sap transaction
  → pouch remains unbanked until Wayhome extraction
```

The server selects the attack, target, locked area, windup, hit, damage, status,
phase, fire carrier, timer, participant set, and reward. Clients submit only
normal tool use or a proximity-prompt interaction. Model attributes, lights,
world markers, and HUD snapshots are presentation only.

## Counterplay and recovery

| Pressure | Required tell | Default counter |
|---|---|---|
| Cathedral Roots | named green lane, world label, targeted HUD, countdown | leave the lane or dodge before resolve |
| Rooted hit | `ROOTED` text, remaining time, stamina-rail state | keep moving at bounded reduced speed; effect expires automatically |
| Canopy Fall | named amber ring, world label, targeted HUD, countdown | clear the ring or dodge |
| Root shield | boss rail says `SHIELDED`; fire and heart prompts wake | take fire, cross the arena, burn the heart |
| Carried fire | boss rail shows exact remaining seconds; character gains amber light | reach the heart before 15 seconds |

Old Growth never collides with or traps the character. Attacks cancel when the
target disappears, leaves the expedition, or becomes unable to act. Solid world
cover may block an attack. A downed player uses the existing crawl/revive/retreat
flow. Encounter health remains shared for the current server run so routine
failure does not force a complete restart. Every phase is solo-passable with the
base strike and interaction controls, and no paid item changes damage, timing,
recovery, or reward.

## Reward and disconnect contract

The transaction format binds `elite_old_growth`, server run ID, deterministic
manifest hash, and participant user ID. Repeated completion delivery cannot
duplicate the grant. A connected participant is also persisted into the
save-schema-v4 unbanked pouch; the server-session ledger remains the fallback
when a profile write is unavailable. Wayhome performs the same atomic banking
and tombstone flow used by event rewards.

A participant who disconnects before completion is retained in the current
server-run participant set. The session ledger can settle the reward if that
player rejoins the same server. Cross-server encounter migration is not claimed
by this single-place slice and remains part of the later expedition platform.
A player who first enters after completion sees the cleansed route but is not
shown or granted a participant reward.

## Mobile and accessibility direction

The implementation follows the
[Old Growth Elite Mobile HUD report](https://www.lazyweb.com/report/lazyweb/51156fc2-18a7-4cf0-be1b-3de54ccf33b3/?source=create).
The preceding quick search had weak mobile boss-HUD coverage, so unrelated
screens were not treated as direct evidence. The hosted report's contextual
hierarchy was applied to the existing survival HUD:

- the elite rail appears only near an active or just-completed encounter;
- name, exact health, phase, exposed/shielded state, objective, and fire seconds
  are written as text and never depend on color alone;
- targeted attack warnings remain a separate higher-urgency card;
- the narrow layout uses the existing safe canvas and full-width inset while
  preserving Roblox top bar and bottom thumb zones;
- touch uses the existing thumb-sized STRIKE, DODGE, ability, and contextual
  prompt controls; keyboard/mouse and controller keep their existing parity;
- the compact objective option remains available, and no modal boss tutorial,
  screen dimmer, particle storm, hold-to-peek gesture, or paid recovery prompt
  was added.

At most one Old Growth model, one attack marker, and one carrier light exist.
The model uses a small anchored part set, attacks step at a bounded 20 Hz, and
there is no per-frame NPC physics or pathfinding cost.

## Windows Studio journey

1. Synchronize `main`, run `npm run bootstrap`, then run `npm test`.
2. Open `build/LastLightTest.rbxlx`, start one server/player, and require
   `[Last Light] PASS FoundationIntegration`, the build version and service
   count for the commit under test (see `src/shared/Config.luau` and
   `src/server/init.server.luau`), and no red errors.
3. Open `build/LastLight.rbxlx` or connect Rojo. Complete First Light, enter
   Bramblewake, and follow the route to Old Growth Approach.
4. Before activation, require both elite prompts to be visually dormant and
   unusable. Enter the arena and require one Old Growth model and one contextual
   health rail.
5. Strike from farther than 14 studs, behind the trunk, and while downed. Require
   safe rejection with no health change. Strike in range until exactly 240.
6. Require the first root shield to stop excess damage, wake both prompts, and
   reject more direct strike damage.
7. Take fire. Require the player light and exact HUD timer. Let it expire once,
   require complete visual cleanup, then take another flame and burn the heart.
8. During Cathedral Roots, test a hit, walking out, cover, and dodge. Require
   matching lane geometry; a hit must show and naturally clear `ROOTED`.
9. During phase two, repeat for Canopy Fall and require its ring to match the
   server area. Reach 120 and complete the second fire break.
10. Finish phase three. Require one clean model state, one `+3 AMBER SAP
    UNBANKED` result per participant, and no duplicate reward after repeated
    strike/interaction requests.
11. Bank at Wayhome, reconnect, and require three Amber Sap banked once.
12. Repeat solo, two-player, four-player, eight-player, touch,
    keyboard/mouse, controller, live input switching, high latency, largest
    text, reduced motion, muted audio, down/revive, reset, disconnect/rejoin,
    and baseline-phone profiling.
13. Disable `old_growth_elite_enabled` in a Studio/local flag override and
    require no activation, model, active prompt, attack, HUD rail, or reward.

## Exit and abuse gate

| Gate | Required evidence |
|---|---|
| Completion | solo and every group size can finish with base strike/interact and no paid item |
| Phase safety | damage cannot skip 240/120 shields; fire cannot burn outside its active server timer |
| Shared fire | only one current carrier exists; disconnect, death, expiry, repeat, and forged prompt IDs fail safely |
| Readability | health, phase, objective, attack, shape, and time remain understandable without color, motion, or audio |
| Touch | elite and threat cards avoid Roblox top bar, objective text, thumbstick, jump, STRIKE, DODGE, ability, and context controls |
| Geometry | lane/ring visuals match server hit areas at terrain height and every orientation |
| Recovery | a down or retreat cannot trap the run; the encounter remains available in the current server |
| Reward | every participant receives exactly one three-Sap transaction; retries and extraction cannot duplicate it |
| Authority | forged health, damage, target, phase, fire, expiry, participant, reward, or mark state is never accepted |
| Kill switch | disabling the elite removes activation and value without breaking the expedition route or extraction |
| Performance | one elite, marker, and light stay inside the module budget with no sustained baseline-phone regression |

Automated checks establish source and DataModel invariants. Only recorded Studio,
multiplayer, and real-device runs can close the physics, readability, latency,
accessibility, balance, and performance rows.
