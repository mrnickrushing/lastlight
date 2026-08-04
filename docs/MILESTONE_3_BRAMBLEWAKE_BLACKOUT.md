# Milestone 3 Bramblewake Blackout and chapter resolution

## Scope

Build `0.13.0` integrates the existing Bramblewake expedition, Old Growth elite,
and Warden Stag into the first complete server-authoritative chapter flow:

```text
first unresolved Bramblewake entry
  → nine-minute Blackout target clock begins
  → take rootfire from the Blackout Lantern
  → carry it through three distinct living-root relays
  → cleanse Old Growth
  → resolve the Warden Stag and its antler consequence
  → every present participant votes on the Greenward's future
  → save one permanent chapter-one result per participant
```

This is the vertical-slice preview cadence. It intentionally starts on the first
unresolved Bramblewake entry after First Light so Windows and device testers can
reach the complete flow without simulating six additional town nights. The
production seven-night recurring town scheduler remains later work; the runtime
still uses the canonical nine-minute duration and seventh-night interval
configuration.

The increment includes:

- stable `blackout_bramblewake` state and a feature kill switch;
- a four-stage relay → Old Growth → Warden → resolution contract;
- an 18-second carried-rootfire window with three distinct stable relay IDs;
- chaining fire from any lit living root so every route remains traversable;
- rooted-wall world silhouettes, written labels, a Blackout lighting layer, and
  low-cost anchored geometry;
- gates preventing Old Growth or the Warden from being completed out of order;
- recoverable overtime after the nine-minute target instead of a progress wipe;
- shared participant and late-join state;
- a present-participant vote among restored farmland, wild regrowth, and shared
  agroforest;
- a deterministic shared-agroforest default when the vote ties;
- save-schema-v4 migration and an idempotent, immutable chapter-one transaction;
- `blackout_started`, `blackout_stage`, `blackout_result`, and
  `chapter_completed` telemetry;
- a compact mobile Blackout rail with stage, clock, relay, carried-fire, vote,
  consequence, and completion text;
- seven streamed interaction targets, pure tests, Studio assertions, and built
  DataModel verification.

Final Greenward geometry variants, recipes/events affected by the decision,
town-tier 0→1, the production seven-night loop, cinematic animation, captions,
audio, and production VFX remain open.

## Blackout flow and authority

The server owns stage, time, participants, carriers, delivered roots, encounter
gates, votes, selected decision, Warden outcome, and save transaction. A client
can only request the existing generic context interaction by stable interaction
ID. The server then rechecks:

- the prompt exists and is currently enabled;
- the player is in range and inside Bramblewake;
- the player is active rather than downed;
- the interaction belongs to the active Blackout stage;
- carried fire is present and unexpired;
- the relay ID or decision ID is from the fixed allowlist;
- the voter participated and is still present in the expedition;
- the chapter profile is writable and not already resolved.

Client time, stage, fire, node, encounter, vote totals, outcome, and profile data
are never trusted.

## Rootfire relay

The Blackout Lantern at expedition entry is the first fire source. Three living
roots are placed at stable route positions:

| Stable ID | World label | Function |
|---|---|---|
| `blackout_root_farm` | Farm Root | first relay |
| `blackout_root_mill` | Mill Root | middle relay |
| `blackout_root_cathedral` | Cathedral Root | final relay |

Taking rootfire starts an 18-second server timestamp. Delivering to an unlit root
consumes that carried fire and permanently lights the root for the server run.
An already-lit root becomes the next fire source, creating a readable chain
instead of requiring an impossible sprint back to expedition entry. Repeated
delivery cannot add progress.

Lighting all three roots advances to Old Growth. The relay source and prompts
then disable, while the already-earned relay state remains in the Blackout
snapshot.

## Encounter integration and recovery

Old Growth cannot activate until the relay is complete. The Warden's Seal cannot
unlock until Old Growth is complete and the Blackout has advanced to the Warden
stage. The existing server-owned health gates, attacks, down/revive behavior,
rewards, antler outcome, and encounter kill switches remain unchanged.

The Blackout clock is a target clock, not a destructive deadline. At nine
minutes:

- the HUD says `BLACKOUT · OVERTIME`;
- the time rail remains full and changes to the written danger state;
- relays, encounter health, roots, antlers, participants, and rewards remain;
- players can revive, regroup, and finish without a paid recovery;
- no result is saved until the boss and chapter vote complete.

Leaving the arena naturally pauses encounter attacks because there is no valid
target. A late joiner enters the shared Blackout without resetting it. A
disconnecting participant does not block the vote because eligibility is
calculated from present expedition participants and reconciled when presence
changes. If that participant reconnects before the server closes, the stable
chapter transaction can still be saved.

## Permanent Greenward vote

After the Warden resolves, three clearly written world choices enable:

| Decision ID | Label | Planned visible consequence |
|---|---|---|
| `restore_farmland` | Restore Farmland | cultivated fields and farm-focused recipes/events |
| `wild_regrowth` | Allow Wild Regrowth | denser wild routes and forage-focused recipes/events |
| `shared_agroforest` | Create Shared Agroforest | mixed public growing space and shared routes |

Every present participant casts one server-recorded vote. The vote resolves when
all present participants have voted. A unique plurality wins. Any tie selects
`shared_agroforest`, the care-focused compromise, and the HUD states this rule
before the vote.

The selected land decision and the shared Warden result
(`preserved`, `scarred`, or `harmed`) are saved together. Save schema v4 accepts
only those allowlisted values and one stable transaction:

```text
chapter_1:<server run id>:<manifest hash>:<user id>
```

Retries of the same transaction are idempotent. A different later transaction
cannot rewrite a completed chapter. Persistent environments require a confirmed
save before the service considers a participant durable.

## Mobile and accessibility direction

The implementation follows the
[Bramblewake mobile Blackout event-layer report](https://www.lazyweb.com/report/lazyweb/558b7278-8455-4639-bf62-bd4ebb97a034/?source=create).
The quick search produced moderate adjacent live-event coverage rather than an
exact Roblox Blackout match, so it was used only for event hierarchy.

- the device-safe phase capsule becomes the authoritative Blackout clock;
- one separate top-center rail shows written stage, stage count, time progress,
  relay count, carried-fire seconds, encounter instruction, vote, or result;
- the existing objective card retains the next actionable instruction;
- existing elite/boss and targeted-attack rails stack below the Blackout rail;
- touch Strike, Dodge, sprint, jump, profession, and context actions stay in
  their existing reserved zones;
- the rail remains present in compact HUD mode;
- overtime, fire, stage, vote, and outcome never rely on color, audio, particles,
  or animation alone;
- no modal, screen dimmer, camera takeover, rapid tapping, paid recovery, or
  profession-only action is introduced.

The world layer uses one atomic streamed model, seven interaction targets, nine
root-wall parts, one optional carried-fire light per player, and one
ColorCorrection effect. All geometry is anchored.

## Windows Studio journey

1. Download the merged repository ZIP from GitHub and extract it.
2. Open `build/LastLightTest.rbxlx`, press Play, and require
   `[Last Light] PASS FoundationIntegration`, the build version, save schema,
   service count, and world version for the commit under test (see
   `src/shared/Config.luau` and `src/server/init.server.luau`), and no red
   errors.
3. Open `build/LastLight.rbxlx`, finish First Light, and use the Bramblewake
   beacon. The first unresolved entry should start one Blackout automatically.
4. Require the top phase capsule to show `BLACKOUT · 09:00` and the separate rail
   to show `ROOTFIRE RELAY · 0/3` without covering the objective or controls.
5. Approach Old Growth before finishing the relay. Require no elite activation,
   prompt, attack, health rail, or damage.
6. Take rootfire at entry. Require a written 18-second countdown, carried light,
   and no progress until an unlit relay receives the fire.
7. Deliver to the Farm Root, take fire back from that lit root, then repeat for
   Mill and Cathedral. Require exactly `1/3`, `2/3`, `3/3`; duplicate delivery
   must not count.
8. Let carried fire expire once. Require the light and carrier state to clear,
   then take fresh fire from the nearest already-lit root.
9. Complete Old Growth. Require the Warden stage to unlock only afterward.
10. Complete one clean Warden run and require the Greenward choice seedlings to
    enable only after the boss result.
11. In solo play, vote for each decision in a fresh server and require it to
    resolve immediately. In two-player play, split the vote and require shared
    agroforest. In larger groups, verify a unique plurality wins.
12. Re-submit the selected prompt, reconnect, and re-enter. Require the same
    chapter transaction, decision, Warden outcome, and completion timestamp,
    with no rewrite.
13. Run beyond nine minutes and require recoverable `OVERTIME`, retained
    progress, and normal completion.
14. Repeat down/revive, retreat, reset, disconnect/rejoin, late join, touch,
    keyboard/mouse, controller, live input switching, largest text, reduced
    motion, muted audio, high latency, and baseline-phone profiling.
15. Disable `bramblewake_blackout_enabled`. Require regular Bramblewake travel,
    events, extraction, and banking to remain available while all Blackout value,
    lighting, relay, gated encounters, vote, and chapter save stay disabled.

## Exit and abuse gate

| Gate | Required evidence |
|---|---|
| Sequence | relay, Old Growth, Warden, and vote cannot advance out of order |
| Traversal | each lit root becomes a fire source; every carry is possible with base movement |
| Time | nine-minute target and overtime use server timestamps and never erase progress |
| Vote | only present participants vote; ties resolve deterministically and visibly |
| Save | one allowlisted decision and Warden result persist idempotently and cannot be rewritten |
| Recovery | down, retreat, reset, disconnect, late join, expiry, and overtime cannot trap the chapter |
| Touch | all event, encounter, threat, objective, and action layers remain usable at supported insets |
| Readability | time, stage, relay, fire, boss, vote, and result remain written without color/audio dependence |
| Authority | forged time, fire, node, stage, participant, vote, result, or transaction data is rejected |
| Kill switch | disabling the Blackout leaves ordinary expedition travel, events, banking, and extraction intact |
| Performance | one atomic layer, bounded parts/lights, 10 Hz orchestration, and existing encounter caps meet the phone budget |
| Scope honesty | recurring seven-night cadence, town transformation, content consequences, final audio/VFX, and cinematic stay open |

Automated checks establish the pure flow, migration, idempotency, stable IDs,
service/build tree, tag counts, prompt defaults, atomic streaming, and mobile part
budget. Only recorded Studio, multiplayer, and real-device runs can close
physics, route timing, UI overlap, latency, readability, balance, persistence,
and performance.
