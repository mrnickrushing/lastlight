# Milestone 2 playtest runbook

This runbook is the remaining exit evidence for the implemented First Light
slice. Automated validation proves source and DataModel invariants; only Roblox
Studio and real devices can prove rendering, streaming, physics, input, and
human comprehension.

## Build under test

Before every evidence run:

```bash
git switch main
git pull --ff-only origin main
npm run bootstrap
npm test
```

Use one of these paths:

1. Run `rojo serve default.project.json`, open the intended place in Roblox
   Studio, connect the Rojo plugin to port `34872`, and sync.
2. Run `npm run build` and open `build/LastLightTest.rbxlx` for the integration
   assertions or `build/LastLight.rbxlx` for normal play.

Do not use an old downloaded `.rbxl` file as evidence for current source.

## Automated Studio assertion

Open `build/LastLightTest.rbxlx`, start a server with one player, and require all
of the following in Output:

- `[Last Light] PASS FoundationIntegration`;
- `server_boot_complete` with build `0.5.0` and `services=9`;
- no red errors, infinite yields, or DataStore production writes.

The integration assertion verifies the runtime remotes, world-ready signal,
arrival spawn, Mara, Heartwood, construction plot, First Lantern, eight
interactions, streaming, and Input Action System rollout.

## Critical solo journey

Start from a reset profile and record screen/video plus elapsed time.

| Step | Player action | Required result |
|---|---|---|
| Join | Press Play once | bounded custom loader exits; player stands on solid ground; no sky fall |
| Rescue | follow the lit trail and free Mara | objective advances once; Mara moves a few steps but remains available to late joiners; toast confirms safety |
| Gather | gather the glowing Heartwood stump | exactly 3 Heartwood appears; objective advances once |
| Tool | choose axe, hammer, or torch | selected tool is named; choice is not described as permanent |
| Build | use the marked construction plot | 3 Heartwood is consumed; a solid barricade appears |
| Prepare | light the First Lantern | authored dusk begins once and phase countdown is visible |
| Defend | use the selected tool on Rootlings | server validates range; Rootling takes three hits; distant hits reject safely |
| Survive | remain through the full night | night lasts 120 seconds after dusk; lantern cannot permanently fail |
| Reveal | follow the dawn beacon | Bramblewake reveal appears; tutorial reaches `complete` |
| Return | leave and rejoin the published staging place | tutorial remains complete; no duplicate reward or forced replay |

Expected time is dominated by the fixed 15-second dusk and 120-second night.
The slice must remain understandable without a developer speaking.

## Input matrix

Repeat rescue, gathering, tool choice, build, sprint, and attack with:

| Input | Expected bindings and UI |
|---|---|
| Touch | large contextual button; hold RUN button; STRIKE during night; no overlap with thumbstick or jump |
| Keyboard/mouse | `E` interact, hold `LeftShift` sprint, left mouse attack |
| Controller | `X` interact, hold left stick click sprint, right trigger attack |
| Live switch | connect/use controller after touch or keyboard; prompt labels and touch buttons update without resetting progress |

Roblox's default movement, camera, jump, and reserved menu controls must remain
familiar and usable. Test with the Controller Emulator and a physical
controller.

## Recovery matrix

At each tutorial stage:

1. reset the character;
2. walk off any reachable edge and verify recovery rather than an infinite fall;
3. close/rejoin a private published staging server;
4. repeat the last valid action twice rapidly;
5. submit an action while too far from its target.

Required: stage never moves backward, duplicate actions never double-grant,
out-of-order actions show the current objective, sprint resets on respawn, and a
rejoin resumes the saved stage. Local/test Studio intentionally uses session
data; published staging is required for DataStore evidence.

## Mobile and accessibility matrix

Record screenshots at minimum:

- smallest supported phone portrait;
- notched phone portrait;
- representative Android phone;
- tablet;
- desktop 16:9;
- controller emulator;
- largest Roblox preferred text setting.

Verify:

- the Roblox top bar does not cover phase, objective, or compact control;
- every required touch target remains at least 72 equivalent pixels;
- objective, interaction target, player, Mara, Rootling, and lantern stay
  visible;
- compact mode hides detail and dialogue but keeps phase, active objective,
  primary action, and night health;
- no required meaning relies only on amber, green, red, motion, or audio;
- the baseline phone reaches interactive play without loading the whole forest.

Capture MicroProfiler frame time, client memory, join-to-interactive time, and
largest-text screenshots. A subjective “looks smooth” is not performance
evidence.

## Ten-new-tester gate

Use people who have not seen the design or code. Do not explain controls or
objectives during the run.

| Tester | Device/input | Finished unaided | Stuck point | Time | Defect links |
|---|---|---|---|---:|---|
| 1 |  |  |  |  |  |
| 2 |  |  |  |  |  |
| 3 |  |  |  |  |  |
| 4 |  |  |  |  |  |
| 5 |  |  |  |  |  |
| 6 |  |  |  |  |  |
| 7 |  |  |  |  |  |
| 8 |  |  |  |  |  |
| 9 |  |  |  |  |  |
| 10 |  |  |  |  |  |

Milestone 2 closes only when all ten finish without verbal help and every
blocker, critical, or high-severity finding is fixed and rerun.
