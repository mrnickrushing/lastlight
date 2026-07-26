# Milestone 3 Warden Stag boss

## Scope

Build `0.12.0` implements the first complete chapter-boss encounter source for
the Bramblewake vertical slice. The Warden Stag is an original, server-run,
three-phase boss in a streamed Warden's Seal annex connected to Old Growth
Approach.

This increment includes:

- a stable `boss_warden_stag` encounter contract and feature kill switch;
- a gate that opens only after the shared Old Growth encounter is complete;
- a bounded original stag silhouette with an exposed memory-heart weak point;
- three shared health phases at 480→320→160→0;
- two, three, and four distinct living-root cleanses before each exposed window;
- a clearly labeled antler-breaking shortcut that changes the outcome;
- preserved, scarred, and harmed result states;
- Rootbound Charge, Antler Arc, and Memory Stampede telegraphs;
- server-owned damage, dodge, guard mitigation, rooted pressure, and phase state;
- late-join participation and no-reset down, retreat, or disconnect recovery;
- five unbanked Amber Sap per participant through the existing durable,
  idempotent expedition pouch and Wayhome settlement path;
- `boss_phase`, `boss_result`, attack, start, rejection, and reward telemetry;
- a contextual mobile boss rail, existing targeted attack card, world shapes,
  input-aware context action, and compact-HUD compatibility;
- a six-target streamed arena, automated pure tests, Studio DataModel
  assertions, and build verification.

The nine-minute Bramblewake Blackout schedule, permanent saved chapter choice,
future traversal-ally behavior, chapter-resolution scene, final rig animation,
audio, captions, and production VFX remain later integration work. The encounter
is exposed after Old Growth now so its mechanics can be tested independently
without claiming the complete Blackout chapter flow.

## Encounter flow

```text
Old Growth complete
  → Warden's Seal unlocks; all boss prompts remain server-owned
  → player enters the annex; shared encounter starts
  → phase 1: cleanse 2 distinct living roots
       └─ optional: hold BREAK ANTLER to expose early and record harm
  → exposed memory heart: normal strikes reduce 480 to the 320 gate
  → phase 2: cleanse 3 distinct living roots
       └─ the remaining antler can be broken once as a harmful shortcut
  → exposed memory heart: normal strikes reduce 320 to the 160 gate
  → phase 3: cleanse all 4 distinct living roots
  → exposed memory heart: normal strikes reduce 160 to zero
  → outcome:
       ├─ 0 antlers broken: preserved
       ├─ 1 antler broken: scarred
       └─ 2 antlers broken: harmed
  → each participant receives one +5 Amber Sap unbanked transaction
  → Wayhome banks the same durable pouch exactly once
```

Normal strike, dodge, context interaction, revive, and walking are sufficient.
Scout mark slows telegraph cadence and improves marked strikes, Warden guard
mitigates a hit, and Medic can heal, but no profession is required. Engineer has
no boss-specific shortcut. No premium item, paid revive, paid power, rapid tap,
or client-reported damage can advance the encounter.

## Choice and fairness contract

Living-root cleansing is the recommended default and the only path to the
preserved outcome. The alternate antler prompt:

- says `BREAK ANTLER`;
- labels itself `Harmful Shortcut`;
- requires a longer hold than root cleansing;
- immediately exposes the current phase;
- can break each of the two antlers only once;
- cannot bypass the third phase after both antlers are gone;
- records the shared server outcome without increasing the reward.

The shortcut is not stronger monetized power. It trades future story state for
speed, uses no Robux, and grants the same five Amber Sap. The permanent chapter
save is not claimed until the later Blackout integration persists and consumes
the outcome.

## Attack and recovery contract

| State | Readable pressure | Default counter |
|---|---|---|
| Root cleansing | phase-specific root count remains written on the HUD while attacks continue | move between enabled amber nodes and hold the context action |
| Rootbound Charge | long green lane, world label, attack card, and 1.55-second minimum | cross out of the lane or dodge |
| Antler Arc | amber ring, world label, attack card, and 1.7-second minimum | leave the ring or dodge |
| Memory Stampede | wider lane, world label, attack card, and 1.9-second minimum | cross the lane; a hit applies a bounded root |
| Exposed heart | exact health and `HEART EXPOSED` text | move within 15 studs and strike the visible heart |
| Player down | existing 30-second crawl, ally alert, and revive interaction | crawl toward light; any ally can revive |

Shared health, phase, cleansed roots, broken antlers, and participants do not
reset when a player is downed, retreats, or disconnects. If no active player is
inside the arena, attack pressure pauses naturally because there is no valid
target. A late joiner who enters while the encounter is active joins the
participant set without changing existing progress. Cross-server encounter
migration is not claimed in this increment.

## Mobile and accessibility direction

The implementation follows the
[Warden Stag Mobile Boss Layer report](https://www.lazyweb.com/report/lazyweb/d5a79e5a-8f10-46e0-b0ed-8e6e09b2dccb/?source=create).
The preceding quick search had weak exact raid-boss HUD coverage, so adjacent
event-progress results were treated as directional only.

- one top-center rail appears only for an active or just-completed boss;
- name, phase, exact health, root progress, antler count, consequence, and
  outcome are written in text;
- attack urgency remains in the separate targeted card and matching world shape;
- root and antler choices use the existing thumb-sized context action;
- Strike, Dodge, profession, sprint, jump, and Roblox reserved zones keep their
  existing safe-area positions;
- the compact HUD still preserves the boss rail and urgent attack state;
- color, particles, motion, and audio are never the only phase or consequence cue;
- no modal boss tutorial, screen dimmer, camera takeover, paid recovery prompt,
  or profession-only action is added.

At most one boss model and one attack marker exist. The service steps at a
bounded 20 Hz, uses anchored geometry, and does not add per-frame pathfinding or
physics-driven NPC movement.

## Windows Studio journey

1. Download the merged repository ZIP from GitHub and extract it.
2. Open the committed `build/LastLightTest.rbxlx` in Roblox Studio, press Play,
   and require `[Last Light] PASS FoundationIntegration`, build `0.12.0`,
   `services=14`, world `warden-stag-boss-v5`, and no red errors.
3. Open the committed `build/LastLight.rbxlx`, press Play, complete First Light,
   enter Bramblewake, and follow the route to Old Growth Approach.
4. Before Old Growth is complete, approach the adjacent Warden's Seal. Require
   the seal to say Old Growth must be cleansed, all six boss prompts to remain
   disabled, and no boss model, attack, HUD rail, or reward to exist.
5. Cleanse Old Growth. Require `THE WARDEN'S SEAL OPENS BEYOND OLD GROWTH`,
   then enter the annex and require exactly one Warden Stag model and one
   contextual boss rail.
6. In phase one, cleanse one root twice and require the repeat to fail safely.
   Cleanse a second distinct root and require the memory heart to expose.
7. Strike from beyond 15 studs, behind the model, and while downed. Require no
   health change. Strike in range and line of sight until health stops exactly
   at 320 and phase two begins.
8. Cleanse three distinct roots, strike to exactly 160, cleanse four distinct
   roots, and finish. Require `CALMED`, `FOREST ALLY PRESERVED`, and exactly one
   `+5 AMBER SAP` unbanked reward per participant.
9. In a fresh server, break the left antler in phase one and the right antler in
   phase two. Require the longer hold, explicit harm warning, visually broken
   antlers, no third shortcut, a final `FOREST HARMED` outcome, and the same
   reward amount.
10. During every attack, compare the world lane/ring to the HUD attack name,
    shape, instruction, and countdown. Test walking clear, cover, dodge, one hit,
    Warden guard, Scout mark, root expiry, and Medic recovery.
11. Test a down/revive, all players outside the arena, reset, disconnect/rejoin
    in the same server, and a late join. Require shared progress not to reset and
    no attack without a valid active target.
12. Bank at Wayhome, reconnect, and require five Amber Sap banked once.
13. Repeat solo, two-player, four-player, eight-player, touch,
    keyboard/mouse, controller, live input switching, largest text, reduced
    motion, muted audio, high latency, and baseline-phone profiling.
14. Disable `warden_stag_boss_enabled` in a Studio/local flag override and
    require no unlock, activation, prompt, model, attack, HUD rail, or reward.

## Exit and abuse gate

| Gate | Required evidence |
|---|---|
| Completion | solo and every group size can finish with base strike, context, movement, and revive |
| Phase safety | damage cannot skip 320/160; a node counts once per phase; a hidden heart takes no damage |
| Choice safety | only two stable antler IDs exist; a break requires the active phase and visibly changes the outcome |
| Consequence clarity | preserve and harm options are explicit before the hold and do not rely on color or audio |
| Readability | boss name, exact health, phase, roots, antlers, attack, shape, time, and outcome remain understandable |
| Touch | the rail and threat card avoid Roblox top bar, objective, thumbstick, jump, Strike, Dodge, ability, and context controls |
| Recovery | down, retreat, no-target pause, reset, same-server rejoin, and late join cannot trap or reset the run |
| Reward | every participant receives exactly one five-Sap transaction; repeated action and extraction requests cannot duplicate it |
| Authority | forged health, damage, phase, node, antler, participant, outcome, reward, target, or attack state is rejected |
| Kill switch | disabling the boss removes all interaction and value without breaking Old Growth, route traversal, or extraction |
| Performance | one boss, one marker, anchored arena geometry, and 20 Hz stepping stay inside the baseline-phone budget |
| Scope honesty | Blackout timing, permanent chapter save, ally traversal, final art/audio/VFX, and cinematic remain listed as open |

Automated checks establish source, pure-state, build-tree, tag, interaction,
stable-ID, and model invariants. Only recorded Studio, multiplayer, and real
device runs can close the physics, camera, streaming, readability, latency,
accessibility, balance, and performance rows.
