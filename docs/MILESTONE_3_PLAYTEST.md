# Milestone 3 playtest runbook

The four exit-gate items no test can close. Automated validation already proves
source and DataModel invariants, 1,000 seeds of expedition assembly, and that
the exploit boundaries hold under abuse. What remains needs Roblox Studio, real
devices, and people who have not read the code:

| Exit gate item | Closed by |
|---|---|
| a fresh save plays start to chapter-one resolution | [Chapter-one journey](#chapter-one-journey) |
| solo, 2-, 4-, and 8-player passes complete | [Party matrix](#party-matrix) |
| no critical placeholder UI/audio/art remains | [Placeholder sweep](#placeholder-sweep) |
| target device meets frame, memory, join, network budgets | [Thirty-minute device run](#thirty-minute-device-run) |

The other two items are already closed and should not be re-run by hand:
1,000-seed assembly by `tests/specs/ExpeditionGenerator.spec.luau`, and the
exploit boundaries by `tests/specs/ExploitGate.spec.luau`.

## Build under test

Before every evidence run:

```bash
git switch main
git pull --ff-only origin main
npm run bootstrap
npm test
```

Then either sync `rojo serve default.project.json` into Studio on port `34872`,
or `npm run build` and open `build/LastLight.rbxlx` for play and
`build/LastLightTest.rbxlx` for the integration assertions.

Do not use an old downloaded `.rbxl` as evidence for current source. Confirm in
Output that `server_boot_complete` reports build `0.46.1` and `services=20`
before anything below counts.

Local Studio uses session data by design. DataStore evidence — anything about
rejoining, persistence, or duplicate rewards across sessions — requires a
published staging server.

## Reaching states without playing to them

Admin commands exist to make these passes possible in an afternoon. They are
roster-gated by user ID and every argument is bounded. Everything they do the
game already does on its own schedule.

| Command | Use |
|---|---|
| `/night N` | set the night number. Town tier is `floor((N-1)/3)` clamped to 0–3, so `/night 4` is tier 1 and `/night 10` is tier 3. A blackout falls when `N % 7 == 0`, so `/night 7` is the shortest route to one |
| `/go town` / `/go bramblewake` | reach the expedition without playing to the reveal, and get back without reaching the Wayhome gate |
| `/phase day\|dusk\|night` | force a phase rather than waiting out a 12-minute day |
| `/give N` | set heartwood, for reaching a build or craft state directly |
| `/heal` | full health and stamina |
| `/perf` | print the performance verdict — see the device run below |

A pass that used an admin command to skip a step has not tested that step. Say
which commands were used in the evidence row.

## Chapter-one journey

Exit gate: *a fresh save plays start to chapter-one resolution.*

Start from a reset profile on a published staging server. Record video and
elapsed time. The slice is not complete until the profile actually carries a
resolved chapter one, which means all four of these are written:

- `story.chapterOne.status == "complete"`;
- `decision` is one of `restore_farmland`, `wild_regrowth`, `shared_agroforest`;
- `wardenOutcome` is one of `preserved`, `scarred`, `harmed`;
- a non-empty `transactionId`.

A run that reaches the last cutscene but leaves any of those unset has failed
this gate, however good it felt.

| Step | Player action | Required result |
|---|---|---|
| Join | press Play once | bounded loader exits; solid ground; no sky fall |
| First Light | complete the tutorial through the dawn beacon | tutorial reaches `complete`; Bramblewake reveal appears |
| Profession | choose Scout, Warden, Engineer, or Medic | kit is named and equipped; choice is reversible in daylight |
| Lobby | depart for Bramblewake | party size is the server's count, not the client's claim; countdown reaches a reserved server |
| Expedition | run a full route | 12 modules assemble; POIs and events are reachable; no floating or unreachable geometry |
| Enemies | meet all six | Rootling, Briarback, Zombie, Hollow Crow, Snapvine, Bark Ram each read as distinct in silhouette and mechanic |
| Briarback | strike its front, then flank it | front shield absorbs most of the hit and says so; flank does materially more |
| Old Growth | fight the elite | fire mechanic resolves; defeat or withdrawal both leave a coherent state |
| Warden Stag | reach the boss and make the choice | outcome matches intent: no antlers broken is `preserved`, two or more is `harmed` |
| Extraction | leave through the Wayhome gate | inventory survives; rewards settle exactly once |
| Resolution | make the chapter-one decision | the four profile fields above are all written |
| Town | return to Emberhollow | tier is at least 1; Tomas Reed, Pip Wren, and Ena Moss have arrived alongside Mara |
| Rejoin | leave and rejoin | chapter one stays resolved; no duplicate reward; no forced replay |

Also run one **normal night** and one **Bramblewake Blackout** (every 7th night,
9 minutes against a normal 6). Both must be survivable solo and readable on a
phone.

## Party matrix

Exit gate: *solo, 2-player, 4-player, and 8-player passes complete.*

Each row is a full expedition, not a lobby check. Eight is the configured
maximum, so it is the row most likely to fail.

| Party | Must hold |
|---|---|
| Solo | every encounter is passable alone; no mechanic requires a second player |
| 2 | down and revive works both directions; extraction waits correctly |
| 4 | one of each profession; abilities do not stack into trivialising the night |
| 8 | server heartbeat holds; no enemy or loot desync; the lobby actually fills and departs |

At every size, verify:

- a player who joins late is not stranded outside the run;
- a player who disconnects mid-expedition does not block extraction for the rest;
- rewards settle once per player, with no cross-player leakage;
- the departure countdown is the same on every client.

Record the party size, the professions present, the device mix, and the seed.

## Placeholder sweep

Exit gate: *no critical placeholder UI/audio/art remains in the slice.*

Static coverage is already tracked in
[`ASSET_COVERAGE_AUDIT.md`](ASSET_COVERAGE_AUDIT.md) — as of the 2026-08-03
re-derivation, 54 of 58 manifest assets are placed and the four that are not are
accounted for. That audit answers whether an asset is placed. It cannot answer
whether it looks right, which is what this sweep is for.

Walk the whole slice in Studio and on a phone, and look for:

- an asset at the wrong scale, rotated onto its side, or clipping through
  terrain — rotated cylinders are the known repeat offender, since a Roblox
  `Cylinder` extends along its local X axis;
- a grey or untextured surface where a reviewed asset should have loaded;
- any `mesh_asset_load_failed` in Output, which means a fallback primitive is
  on screen;
- floating world labels that duplicate an interaction prompt;
- audio that cuts, loops audibly, or is missing at a beat that needs it;
- UI text that overflows at the largest Roblox text setting.

Structural terrain, roads, floors, walls, roofs, collision shells, and invisible
interaction anchors are *supposed* to be purpose-built primitives. Do not file
those. The line is in `VISUAL_QUALITY_STANDARD.md`: inspectable props and
practical-light vessels need reviewed art; structure does not.

## Thirty-minute device run

Exit gate: *target device meets frame, memory, join, and network budgets for a
30-minute run.*

The budgets are in
[`TECHNICAL_ARCHITECTURE.md`](TECHNICAL_ARCHITECTURE.md) and are measured live
by `PerformanceService`, so this run produces numbers rather than an impression.

1. Join a published staging server on the baseline phone. Note the device model,
   graphics quality level, server size, and expedition seed — a verdict without
   those is not reusable evidence.
2. Play for a continuous thirty minutes. Include a full night, an expedition
   with combat, and at least one extraction. Idling in town does not exercise
   the budgets.
3. Type `/perf`. The toast carries the headline verdict; every line is written
   to the server log, which is where the actual table lives.

Read the result as follows:

| Verdict | Meaning |
|---|---|
| `OK` | every measured metric is inside its target |
| `WATCH` | something is between target and the hard threshold — record it, do not fail the gate on it alone |
| `BREACH` | a metric is past its hard threshold. The gate does not close. |
| `INCOMPLETE` | a metric had no samples. **This is not a pass.** Find out why nothing was sampled before rerunning. |

Two of the numbers this reports are provisional and this run is what replaces
them: `Config.BaselinePhoneMemoryCeilingMb`, and the numeric reading of the
architecture document's qualitative "OOM/reload risk" threshold. If the memory
row looks implausible in either direction, the ceiling is the first thing to
suspect — record the raw memory figure from the Developer Console alongside the
verdict so the ceiling can be corrected rather than argued about.

Repeat on a tablet and on desktop. A phone breach with a clean desktop run is
still a breach: the gate names the target device.

## Ten-new-tester gate

Milestone 2 required ten testers who had not seen the design finish unaided.
Milestone 3 is longer and branches, so the bar changes shape: ten testers who
have not seen the design must each reach **chapter-one resolution** without
verbal help, and their decisions must not all be the same one.

| Tester | Device/input | Party size | Reached resolution unaided | Decision | Warden outcome | Stuck point | Time | Defect links |
|---|---|---|---|---|---|---|---:|---|
| 1 | | | | | | | | |
| 2 | | | | | | | | |
| 3 | | | | | | | | |
| 4 | | | | | | | | |
| 5 | | | | | | | | |
| 6 | | | | | | | | |
| 7 | | | | | | | | |
| 8 | | | | | | | | |
| 9 | | | | | | | | |
| 10 | | | | | | | | |

If all ten pick the same chapter-one decision, the branch is not a choice and
that is a design finding, not a testing failure — record it either way.

Milestone 3 closes only when all ten reach resolution without help, the party
matrix passes at every size, the placeholder sweep is clean, the device run
reports no breach, and every blocker, critical, or high-severity finding is
fixed and rerun.
