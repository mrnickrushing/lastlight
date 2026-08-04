# Project status

The living handoff between working sessions. **Read this first when starting a
session, and update it before you finish.** This project is developed across
many short AI-assisted sessions on more than one account; anything not written
here is invisible to the next session. The sibling repository learned this the
hard way — the same feature was once built twice in parallel because nothing
recorded that it was already in flight.

Last updated: 2026-08-04, at `main` = `bcb0fb4` (PR #182), build `0.49.1`,
save schema 13, 20 services.

---

## Where the project is

**Milestone 3 (Bramblewake vertical slice)** is implemented in source; its
Studio and device exit gates remain pending owner playtest evidence.

**Milestone 4 (persistent town platform)** is actively in flight and most of
its deliverables have landed. The authoritative checklist is
[PRODUCTION_ROADMAP.md — Milestone 4](PRODUCTION_ROADMAP.md); read the gate
there, not a copy here. Note the gate's own caveat: the layout validator only
guards footprint clearance from source — the gate itself still needs a live
Studio pathfinding pass.

## Recently landed (PRs ~#151–#181)

Verified against `git log`, newest first:

- **(in flight, this branch: `agent/bramblewake-audit`)** Level-2 playability
  and visual audit, driven live through a connected Studio session. The
  headline: **chapter one had become uncompletable, and is fixed.** The
  `part()` tap-to-interact change (#173) left the Old Growth AmberHeart and
  Warden Stag MemoryHeart non-queryable once the enemy-visual pass hid them,
  and both services' line-of-sight checks required the strike ray to hit the
  heart part first — so every strike on either encounter failed "behind the
  trunk", forever. Nobody had fought either live since the mesh pass. Fixed
  three ways (hearts marked `KeepVisibleOnReplacement`, the enemy-visual hide
  pass now honours that flag, both LOS checks exclude the creature's own body
  and test only world cover), then **proven by playing chapter one end to end
  in-session**: tutorial → night (3 defeats) → entry → relay 3/3 → Old Growth
  (3 phases, 2 fire breaks, +3 sap) → Warden Stag (3 phases, 9 roots, 0
  antlers, preserved) → solo vote → immutable `chapter_1` transaction →
  Wayhome banking; then all 8 events run to completion in one pass (25 steps
  accepted, 8 rewards persisted, second settlement banked exactly the award
  table's 23 materials).

  Also fixed in the same branch: the elite/boss rails no longer leak a
  full-health "PHASE 1/3 · 360/360" for dormant encounters (the Blackout
  relay's farm root sits beside the arena, so every carrier saw it one stage
  early — both runbooks forbid it); the DEPARTURE lobby panel is
  proximity-gated to its platform (it used to follow any player who left the
  yard without departing, through the tutorial, the night, and the whole
  expedition); the objective card holds two wrapped lines ("TAKE ROOTFIRE
  FROM THE BLACKOUT LANTERN" rendered as "TAKE ROOTFIRE FROM THE"); the
  chapter-resolution copy no longer leaks raw snake_case IDs
  ("SHARED_AGROFOREST"); the committed places now set
  `TextChatService.ChatVersion = TextChatService` — it defaulted to Legacy
  in rojo-built places, which left every `/command` the playtest runbooks
  depend on silently dead; and the Studio test's final assertion no longer
  reads the engine-removed `PlayerScriptsUseInputActionSystem` rollout gate
  raw (that error killed the test one statement before its PASS line).
  `[Last Light] PASS FoundationIntegration` was then seen to print with zero
  errors — the first time since #180.

  Flagged for the owner, deliberately not acted on:
  - **Bramblewake reads very dark at dawn/day mid-route** in the test place;
    the test place does not set `Lighting.Technology = Future` (the game
    place does), so judge lighting there before tuning anything.
  - **A solo Blackout leaves the town lantern undefended** through however
    many normal nights elapse — it hit the 18-health floor during this run,
    which means three damaged buildings at dawn. Design tension, not a bug.
  - The Blackout `RootedWall` barriers read as flat translucent green panes;
    the market-stall canopies (restyled from fairground red to deep moss
    Fabric) read near-black in shade; the archive/board notice-board mesh is
    placed roughly half-buried (its visible height is right, the method is
    odd). All three are taste calls needing the Future-lighting pass.

  The first fruits of the same audit, from before the live playthrough:
  - **The town's main street was invisible.** Its top face (0.33) was exactly
    coplanar with the courtyard's, z-fighting where they overlapped, its
    18-stud foundation was fully buried (top −0.02), and its worn center
    line disappeared under the 0.80-tall plaza pad. Every player and NPC also
    sank shin-deep in that pad, because it is a non-colliding skin and
    characters walk on the terrain through it. The whole town surface stack
    was re-layered as thin skins over the walk plane (street 0.56, wear 0.64,
    foundation 0.44, square pad 0.38), documented in `WorldService.luau` at
    the street builder. Cabin entry paths (floating 0.4), three tutorial spur
    paths (floating 0.35), the square edge stones, district-road foundations
    (buried), and the arrival road's foundations (buried) were re-seated in
    the same pass; the First Lantern mesh — whose authored plinth was
    swallowed by the old pad, reading almost a stud shorter — now stands its
    full height.
  - **Two stale Studio-test assertions** fixed: the arrival-road height check
    still asserted the pre-#180 `Y >= 2` compensation (now measured against
    `TerrainBuilder.valleyFloorTop()`), and the interaction census expected
    81 prompts against the world's real 90 — the per-module resource nodes
    reached their full two-per-module count (22) after that line last ran.
  - **New `restyleParts` registry mechanism** (same declarative pattern as
    `stripDecals`): recolors/re-materials matching source parts at template
    load. First use: the two 23-stud Creator Store market stalls whose
    fairground-red plastic canopies flanked the town gate now wear moss-green
    canvas and rain-dark timber.
- **#181** Full audit of the night-defense combat system: every combat source
  file read end to end, then live-tested by firing the real gameplay remotes
  (spawn, strike, profession, incident) through a connected Studio session,
  including driving the real `TownNightService` day/dusk/night cycle through
  five consecutive real nights. Two bugs found:
  - **Enemies floating or sinking relative to the ground.**
    `enemySpawnPosition()` held a stale hardcoded `Vector3.new(0, 2, -153)`
    left over from before the #180 datum fix below, so every enemy in every
    night defense fought ~2 studs above the ground for its whole encounter.
    Separately and independently — proved algebraically: the sink is
    `lift - groundOffset`, and the spawn origin's Y has always equaled the
    rendered terrain height on both sides of the datum fix, so the gap
    between them was never affected by it — four of six enemy species'
    authored visual meshes were sinking ~2 studs *into* the ground.
    `groundOffset` in `placeEnemyVisual` was each species' fallback-core
    Y-lift plus 2.0 more, too consistent across four unrelated species to be
    separate tuning mistakes. Both fixed; verified live that all six species
    now land within ~0.1 studs of true ground.
  - **Silent lantern damage from the hollow crow.** Its `spark_theft` status
    effect — the most frequent source of lantern-health pressure in a night,
    firing on every unblocked hit — mutated `_lanternHealth` with no log
    line, unlike every other lantern-pressure path (incident failure, a
    direct lantern impact, a Last Stand spend). Traced live: watched the
    lantern crash from 100 to its floor of 18 with nothing in the server log
    to explain it. Added the same `lantern_pressure_applied` event the other
    paths already emit; no behavior change, confirmed by the same trace.
  - Also live-verified with no changes needed: Town Guard Last Stand's four
    branches (successful recovery, lantern-too-weak falling back to the
    standard bleedout timer, already-spent-this-night rejection, and the
    once-per-night reset), the Drowsy and Spark Theft status effects, and the
    Warden/Engineer profession combat hooks.
- **#180** The world's vertical datum fix, both levels' glass removal, the
  town square move, and the Bramblewake part-budget re-derivation — see
  "Known open threads" below for the mechanics of each; they stay there
  because they are still worth checking against, not because they are
  unresolved. Two more fixes from the same PR that belong here instead,
  because they are fully closed:
  - **Three of eight Bramblewake events had never existed.** A module can
    carry both a point of interest and an event, and the builder placed them
    on `if`/`elseif` — the POI always won and the event was silently
    dropped. `ExpeditionService` logged `events=8` from the manifest while
    the world held 5. Split into separate `if` blocks; verified 8 sockets,
    25 steps.
  - **One transient asset-fetch failure condemned an asset for the whole
    server session**, silently dropping every instance of it rather than
    just the one placement. `MeshTemplateLoader` now retries a failed
    `LoadAsset`/`LoadAssetAsync` up to three times with backoff before
    condemning it — this is what finally produced a clean boot
    (`fallbacks=0` across all three asset groups).
- **#179** The first visual sweep done through a connected Studio session, and
  the first time the committed Studio integration test has ever been watched
  all the way through. Five things a player could see were wrong, and none of
  them were visible from source alone:
  - **All eight illustrated first-world notices were invisible.** Both the
    Greenward Archive board and the Town Board are mesh-replacement fallbacks,
    so `hideProceduralPlaceholder` blanked every notice paper to
    `Transparency = 1` and switched off every artwork `SurfaceGui` the moment
    the authored Creator Store board loaded — and that board is bare wood. A
    player walked up to two blank planks. This is the fourth time this exact
    failure has shipped (First Lantern flame, dawn beacon flame, the three tool
    displays), so the fix is declarative rather than another hoist: a part
    marked `KeepVisibleOnReplacement` and everything under it is skipped by the
    blanking pass. Set on the notice papers, pins, wax seals, and header plate.
  - **A glass slab was tinting the whole starting town.** `LowMorningMist` was
    a 190 x 250 stud `Enum.Material.Glass` part floating at y = 2.3 over the
    entire first playable area. Glass renders a refractive pane whatever
    `Transparency` says, so it washed every road stone, building, and patch of
    grass a flat cyan-green and ended in a hard rectangular seam at
    x = ±95 / z = -211. Nothing ever toggled it either, so a "morning" mist sat
    over the town at dusk and through the night. Removed; `LastLightAtmosphere`
    already does aerial perspective properly and is eased per phase.
  - **The town leaked authored meshes on every rebuild.** `_rebuildTownProgression`
    destroyed `GreenwardConsequence` and `TownProgressionBuildings` but not the
    authored placements the previous pass had parented straight to the world,
    so duplicates stacked at identical coordinates. Not rare: a profile load
    rebuilds twice back to back, and every construction contribution rebuilds
    again. Measured 17 stray models against 16 real placements before the fix,
    0 after. They now live in a `TownAuthoredMeshes` container that one
    `Destroy` clears.
  - **"DO NOT ENTER — THIS RESTRICTED CLEARANCE AREA"** in modern yellow-and-black
    hazard type, on the two barricades flanking the tutorial's opening path,
    at the exact moment the objective card says to follow the lantern path.
    Baked-in decals on the Creator Store barricade model. New registry flag
    `stripDecals` (honoured in `MeshTemplateLoader.sanitize`) drops `Decal` and
    `Texture` off that asset; the geometry is kept.
  - **Two HUD panels bypassed `SafeCanvas`.** `LobbyPanel` and `ActionProgress`
    were parented to the `ScreenGui` rather than the canvas, so they were the
    only bottom-anchored controls that never received the `UIScale` the canvas
    carries — exactly the class of mobile layout bug that comment was written
    about. Reparented.

  The Studio test itself had never printed
  `[Last Light] PASS FoundationIntegration` — it aborted at the notice check,
  and everything past that line had gone unexercised long enough to rot. See
  the runbook note below.
- **#178** Setup for connecting an AI session directly to Roblox Studio through
  Studio's own built-in MCP server, including a Wine wrapper for Linux hosts
  running Studio under Vinegar. **This is the thing that moved the project's
  binding constraint** — the visual and DataModel half of every runbook gate
  can now be closed by a session that can see Studio, while the device and
  human half cannot. Read [STUDIO_MCP_SETUP.md](STUDIO_MCP_SETUP.md) before
  claiming a gate closed; it draws that line explicitly. The runbooks'
  journeys are renamed from "Windows Studio journey" to "Studio journey" — the
  owner develops on Linux, and the operating system was never what those steps
  depended on. **Proven out since, not just wired up:** #179, #180, and #181
  above were each done through a live connected session — spawning real
  enemies, firing the actual gameplay remotes instead of mocking them, driving
  several real day/dusk/night cycles end to end, and reading Studio's own
  console output — not just DataModel inspection. See "Session gotchas" below
  for what that surfaced about testing this way.
- **#177** Two construction-site fixes to #176, found by
  CodeRabbit review after it merged. Both were reachable on ordinary paths:
  an explicitly empty damageable roster fell back to "every building", so a
  tier-zero town — which is entirely construction sites — would have had all
  sixteen buildings damaged on a new save's first night; and a migrated
  schema-12 profile could raise a REPAIR prompt on a construction lot, because
  the renderer checked that a building had a recorded placement but not that it
  was actually standing.
- **#176** Per-building town damage and repair. Storm
  damage stopped being one town-wide integrity number and became a property of
  each building, chosen by night number, repaired one building at a time
  through a prompt that carries its building's ID as a baked payload. Schema
  13; a schema-12 town-wide integrity spreads to every building on migration.
  Caught a live regression on the way: `TownPermissions.resolveCondition` read
  a `value.integrity` field that stopped existing, which would have silently
  turned the visitor guard off — it now takes the integrity reader as an
  injected dependency and requires it. Details and the Studio gate in
  [MILESTONE_4_PER_BUILDING_DAMAGE.md](MILESTONE_4_PER_BUILDING_DAMAGE.md).
- **#175** Profile backups and an audited restore —
  the last unimplemented piece of M4's persistence deliverable, plus the write
  half of its admin-tooling deliverable. Snapshots go to a separate
  `LastLightProfileBackup_v1` store; the load path photographs the raw stored
  bytes *before* `normalize` migrates them, which is the case
  TECHNICAL_ARCHITECTURE asks for a backup before. `/backups` lists, `/restore`
  rolls back to the newest copy, refuses while a live server holds the profile,
  and copies the replaced profile first so running it twice undoes it. Details
  and the DataStore exit gate in
  [MILESTONE_4_PROFILE_BACKUPS.md](MILESTONE_4_PROFILE_BACKUPS.md).
- **#174** Refreshed this handoff and stopped eight runbooks hard-coding build,
  schema, and service-count literals that had gone thirty-plus PRs stale; they
  now defer to `Config.luau`. `validate-plan.mjs` checks this file's own
  `Last updated` line against source, so a version bump that forgets it fails
  `npm test`.

- **#172** Fixed the committed Studio test's stale version assertions (it
  still asserted build `0.46.1`/schema `11` after the bump to `0.47.0`/`12`,
  so it failed its first line whenever a tester pressed Play); added a
  drift guard to `scripts/verify-build.luau` so `npm test` catches the next
  forgotten bump instead of the owner's Studio session.
- **#173** First owner-playtest fix pass on the tutorial-night first-town
  slice — five reports, four fixed in source with file:line evidence, one
  investigated and explicitly not acted on:
  - **Dawn beacon missing / dark panel on the road** — fixed. The "wall/sign"
    the owner saw was the memory-reliquary mesh itself, half-buried by two
    already-documented failure modes stacking: its flame lived inside
    `beaconFallback`, so `hideProceduralPlaceholder` blanked it dark the
    moment the reviewed mesh loaded (same class of bug as the First Lantern
    fix, see DECISIONS.md); and its authored position sat at the pre-lift
    road height, so the raised cobblestone visual skin buried its lower ~2
    studs. Hoisted a `BeaconCore` neon part out of the fallback (mirrors
    `FirstLanternCore`) and reseated the reliquary, `DawnPathMarker`s,
    `DawnGateStep`s, and the reveal pulse above the road surface. Also fixed
    a pre-existing dead assertion in `FoundationIntegration.server.luau`
    that checked a Creator-Store-prefixed key
    (`mesh_creator_memory_reliquary_a`) nothing ever placed under — the real
    ID has no `creator_` prefix since the reliquary is a generated original
    asset — so it always read 0 and always failed.
  - **Arch between the First Lantern and the beacon** — removed outright, in
    the same edit as the beacon fix (both lived in the same construction
    block). `mesh_creator_wood_arch_a` stays registered in
    `MeshAssetRegistry` (unplaced, same status as other reviewed-but-retired
    assets) but is no longer placed anywhere.
  - **Mobile combat callout clutter** — fixed, one line.
    `EnemyService._stepAttack` was re-writing the world-space attack label
    with the full `"name\ninstruction · Ns"` two-line caption every tick of
    the windup, duplicating the HUD threat banner exactly (a prior commit,
    2856375, only fixed the label's *initial* text, not this per-tick
    overwrite). Now writes `"name · Ns"` only; the instruction lives in the
    HUD banner, matching the documented one-alert contract.
  - **Crow enemy vanishes/respawns and is nearly untappable** — fixed. Not
    designed motion: `placeEnemyVisual` computed the authored mesh's
    placement `CFrame` from the enemy core's position *before* the
    asset-load yield, so a fast mover (the crow, speed 9, fastest in the
    roster) kept flying during the load and the visible mesh landed at a
    stale, permanently-offset position from the actual (invisible)
    authoritative hitbox — reading as vanish-then-respawn, and making taps
    miss. Now re-pivots from the core's current frame right after the load
    resolves. Also: fallback parts other than the hitbox core now get
    `CanQuery = false` (they were silently swallowing taps with no
    detector attached), and the `StrikeClick` `ClickDetector` moved from the
    core part to the enemy model itself, so a tap anywhere on the model's
    visible geometry can register.
  - **Near-black morning shadows at the first-level start** — fixed. Raised
    `DAY_AMBIENT`, day-phase `OutdoorAmbient`, and
    `EnvironmentDiffuseScale`; reduced (less negative) day
    `ExposureCompensation`; lowered day `ColorCorrectionEffect.Contrast`;
    raised `ShadowSoftness`. Changed in both places these values are
    duplicated (`_configureLighting` and `_applyTownLighting`'s day branch —
    the file's own comments warn a one-sided edit silently reverts on the
    first day/dusk transition). Night's separate, much lower floor is
    untouched.
  - **"Move the First Lantern back to the town square center"** — investigated,
    not acted on. Source already places `FirstLanternCore` at `(0, 6.3,
    -112)`, exactly the plaza center (`PLAZA = Vector3.new(0, 0, -112)`,
    `PLAZA_HALF = 36`) that `scripts/validate_town_layout.py`'s own
    docstring calls a "long-established fixed landmark." No evidence in
    source explains the report; flagged back to the owner rather than
    guessed at. Possible explanations worth checking next: a stale
    published place versus this source revision, or the report referring to
    something else entirely.
- **#170** Construction orders now cost resources; existing towns grandfathered.
- **#169** M4 unlock plus town layout: town buildings generated, prepared,
  uploaded, and placed (PR titles said eleven of sixteen staged;
  `validate_town_layout.py` passes for fourteen as of this update -- trust the
  validator's current count over any number written here); a safe lock-clear
  command; building footprint clearance guarded from source.
- **#168** Read-only admin save inspection with audit logging.
- **#167** Bramblewake fall-through floor fixed, entry quieted, tools lit.
- **#165/#166** Persistence: session locking on the autosave beat with tests
  for the five failure modes (forced crash, contention, write failure, stale
  revision, shutdown), visitor-cannot-modify-host-town enforcement.
- **#162–#164** Exploit-gate test suites reconciled and a performance budget
  harness (client frame/memory telemetry against a baseline-phone ceiling).
- **#154–#161** Visual/creature pass: borrowed third-party creature models
  retired in favour of meshes *generated around the parts each fight is read
  from* — see the rule and its reasoning at the tail of
  [DECISIONS.md](DECISIONS.md) (stag antler stubs, elite chest cavity, facing
  measured via Blender −Y → Roblox +Z). Plus level-2 story landmarks, enemy
  art, POI voice, memory reliquary, Bramblewake legibility fixes, and admin
  TextChat fix.

Earlier context (PRs #95–#115, the first visual-correction wave: buried roads,
sign facing, lantern light, cylinder axis, source-yaw cancellation, lantern
safe-zone regen) is recorded in
[ASSET_COVERAGE_AUDIT.md](ASSET_COVERAGE_AUDIT.md) and the PR history.

## Blocked on the owner

None of these can be completed from a session.

1. **Studio and device playtest evidence** — the M3 exit gates, the M4 gate's
   live pathfinding pass, and visual confirmation of the placement-correction
   wave. **Unblocked for the Studio half, and now demonstrated rather than just
   wired up:** a session running on the machine that runs Studio can close the
   Studio half through the MCP server — see
   [STUDIO_MCP_SETUP.md](STUDIO_MCP_SETUP.md). #179, #180, and #181 each did
   this for real, across two separate sessions. It cannot run on a cloud
   session, because MCP over stdio has no address to dial. What remains
   strictly human: the baseline-phone pass, the ten-tester gate, DataStore
   behaviour across servers, real multiplayer, and whether the slice is fun.
2. **`ROBLOX_API_KEY` per session** — containers lose it on reset. It is
   needed only for asset upload/download (`scripts/upload_mesh_assets.py`,
   `scripts/download_creator_store_model.py`), never committed or logged.
3. **Codex review credits are exhausted.** Codex caught two real shipped bugs
   during the visual wave (beds below the floor; lantern regen cancelling
   revives). CodeRabbit still reviews, but expect nothing from Codex until
   credits are topped up.

## Known open threads

- **The world's vertical datum was wrong by two studs, and is now fixed --
  re-read anything that reasons about height.** Roblox renders a terrain
  surface half a voxel (2 studs) above the top face of the fill that made it.
  `TerrainBuilder` reported the valley floor at `GROUND_Y = 0` while the engine
  put it at 2, so every authored `Vector3` written against y = 0 was two studs
  underground. Consequences that had been live for a long time: the town square
  (top face 0.80) was **buried and had never once rendered** at either 72 or
  112 studs across, and Mara and all three residents stood shin-deep with their
  legs swallowed. The road network looked correct only because it had been
  nudged to 2.2-2.5 one layer at a time -- `WorldService` still carried a
  comment diagnosing this as a road problem and adding a "+1.77 visual skin".

  Fixed at the source: fills are now placed at `FILL_Y = GROUND_Y -
  VOXEL_SURFACE_RISE`, so the rendered surface lands on the authored plane
  (measured 0.02 across the valley, was 2.00). Every compensation was then
  removed -- arrival road stack, town main street, district roads, road edge
  stones, cobblestone layer, `ROAD_SURFACE_Y` 2.45 -> 0.53. **If you find
  height arithmetic anywhere that looks like it is dodging the ground, it is
  probably another one of these; check it against the datum rather than nudging
  it.**
- **Bramblewake was being viewed through glass.** Thirteen `BlueGroundMist`
  Glass slabs, one per module plus the Blackout arena, covering about 1.8
  million square studs at knee height. Glass renders a refractive pane whatever
  Transparency says, so the whole expedition came out flat blue-grey and from
  any raised angle the slab edges read as the edge of a void. Removed, same as
  `LowMorningMist` over Emberhollow. Both regions already have tuned
  `Atmosphere` doing this properly.


- **The town square moved and grew; three things now stand on it.** `TOWN_CENTER`
  is (0, 0, -80) and `PLAZA_HALF` is 56, so the square spans z -24..-136 and
  reaches Mara's clearing. Mara and the starter tool yard were authored to stand
  on grass at y 0 and are now lifted onto the pad by `PLAZA_SURFACE_Y`; the
  Heartwood gather node and the First Lantern's own plinth still embed ~0.8
  studs in the paving, which reads as set-in rather than sunk but has not been
  owner-reviewed. If the Heartwood stump on a paved plaza looks wrong, reseat it.
- **`RouteGuideMarker` is a taste call nobody has made.** 26 Neon foxfire
  waypoint inlays run the length of the critical route. Their rationale is
  documented and deliberate -- they are the only thing that says "this way" in
  the dark -- but in daylight they read as saturated cyan rectangles lying on
  the paving. Left untouched. Decide whether daylight should dim them.


- **Bramblewake's part budget was never breached; the test was measuring the
  wrong thing.** Recorded here previously as "3.3x over budget" -- that was
  wrong, and the correction matters because it nearly cost the generator its
  one working constraint. `PartBudget` (640) bounds the *manifest*: the sum of
  the chosen modules' planning allowances, checked by
  `ExpeditionGenerator.validate`. The preview seed totals **427** against it and
  always has. `GeneratedPartCount` (**2330**) counts *built* BaseParts, which is
  a different quantity entirely -- a module with a planning allowance of 44
  legitimately builds several hundred real parts. The Studio test compared the
  two, and summed in the boss-arena and Blackout allowances on top, though both
  are built after that count is taken. Split into `PartBudget` (unchanged) and
  a new `BuiltPartBudget` (2600 = measured 2330 + ~12%), derivation recorded in
  `BramblewakeExpedition.luau`. **Still owed:** `BuiltPartBudget` is a
  regression guard, not evidence 2330 parts is affordable on a phone. The
  Milestone 3 device capture has still never been taken.
- **Two selected Creator Store assets were never actually adopted.**
  `mesh_creator_hollow_rootling_a` and `mesh_creator_predatory_flower_a` are
  listed in `assets/meshes/candidates/creator-store-full-pass/selection.json`
  and `scripts/generate_mesh_kit.py`, but neither was ever promoted into
  `MeshAssetRegistry` and nothing places them. The Studio test asserted four of
  the first and two of the second, so those assertions could not have passed in
  any build ever made; they have been removed rather than left as permanent
  red. **The content gap is real and still open:** the Warden and Blackout
  living-root objects and the Old Growth root hearts have no sourced art. Decide
  whether to adopt these two candidates or retire them explicitly, the same
  question `mesh_creator_first_lantern_a` is waiting on below.
- `mesh_creator_first_lantern_a` is in the manifest but genuinely undecided —
  retire it explicitly or place it. Details in
  [ASSET_COVERAGE_AUDIT.md](ASSET_COVERAGE_AUDIT.md) §Intentionally unplaced.
- **Checked (2026-08-04) against source, not just commit history:** resident
  jobs/injury/relationships/crisis framework and storage/decoration caps are
  **absent**. Residents exist only as ambient NPCs
  with day/dusk/night positions and duty labels (`WorldService.luau`
  ~8207-8250); no storage or decoration system exists to cap. Multiple
  grep patterns tried per item, all zero-hit — see the roadmap gate for what
  "done" means here. Also weaker than the deliverable wording implies: "town
  visit flow" is only implicit first-arrival hosting on a shared server (no
  deliberate visit/teleport mechanic); damage/repair is one town-wide
  integrity value (`TownCondition.luau`), not per-building — **addressed by #176
  above**; eleven of the
  sixteen buildings are staged shells with construction prompts, not yet
  functionally distinct.

## Getting caught up, in order

1. This file.
2. [README.md](../README.md) — vision and the long-form current-status recap.
3. [AGENTS.md](../AGENTS.md) — operating rules, delivery workflow, gates.
4. [PRODUCTION_ROADMAP.md](PRODUCTION_ROADMAP.md) — Milestone 4 gate.
5. Tail of [DECISIONS.md](DECISIONS.md) — the newest recorded decisions.
6. Before any visual work: [VISUAL_QUALITY_STANDARD.md](VISUAL_QUALITY_STANDARD.md)
   (includes how to pick, thumbnail-check, and place assets) and
   [ASSET_COVERAGE_AUDIT.md](ASSET_COVERAGE_AUDIT.md).
7. [DEVELOPMENT.md](DEVELOPMENT.md) — toolchain and daily commands.

## Session gotchas that live nowhere else

Hard-won, each one cost a real session real time:

- **Remote containers: the toolchain can be installed, and the old note here
  was wrong about why it could not.** Rokit's installer resolves releases
  through `api.github.com`, which the egress policy denies (403) — but
  `github.com/<org>/<repo>/releases/download/...` is allowed, so the five
  pinned tools can be fetched directly and dropped on `PATH`:

  ```bash
  # rojo 7.7.0, lune 0.10.5, stylua 2.5.2, selene 0.31.0, luau-lsp 1.69.0
  curl -sSL -o t.zip https://github.com/rojo-rbx/rojo/releases/download/v7.7.0/rojo-7.7.0-linux-x86_64.zip
  unzip -o t.zip -d ~/.lltools/bin   # repeat per tool, then chmod +x
  ```

  That gets six of `npm test`'s seven steps running locally, **including
  `npm run build`** — so place artifacts can be regenerated and committed from
  a container after all. Only `selene` still cannot run, and not for a network
  reason: it fetches the Roblox API dump with a bundled root store and rejects
  the proxy CA (`invalid peer certificate: UnknownIssuer`). `curl` reaches the
  same URL fine and the CA *is* in the system store; `SSL_CERT_FILE`,
  `SSL_CERT_DIR`, `CARGO_HTTP_CAINFO`, and `REQUESTS_CA_BUNDLE` are all ignored
  by it. Let CI cover lint; run everything else locally.
- **`.rbxm` is globally gitignored** while reviewed Creator Store candidates
  are deliberately committed — new candidate downloads need `git add -f`.
- **`scripts/validate_mesh_assets.py` reads a fixed 520-character window**
  after each registry `id` marker. A comment inside a registry entry body
  pushes later fields out of the window and fails validation with a
  misleading "differs from manifest" error. Keep rationale in commits, not in
  entry bodies.
- **Place files are build artifacts.** After any `src/` change:
  `npm run build`, then commit both `build/LastLight.rbxlx` and
  `build/LastLightTest.rbxlx` from that exact revision.
- **Creator Store models are routinely saved rotated off-axis.** Run
  `lune run scripts/measure_source_yaw <model.rbxm>` before placing a new
  source model, and record a non-zero modal yaw as `sourceYawDegrees` in
  `MeshAssetRegistry` — otherwise the asset places turned *and* undersized,
  silently.
- **Version literals live in `Config.luau`, not in runbooks.** The playtest
  runbooks used to hard-code the build, schema, and service count a tester
  should see in Studio Output; they drifted, and a tester following one would
  have failed the first line of their evidence run against a build that had not
  existed for thirty-plus PRs. They now defer to `src/shared/Config.luau` and
  `src/server/init.server.luau`. The `Last updated` line in *this* file is the
  one place those numbers are still written out, and `scripts/validate-plan.mjs`
  checks it against source — so a version bump that forgets this file fails
  `npm test`. Keep the line's shape (build `X`, save schema `N`, `N` services).
- **A passing guard is not evidence until it has been made to fail.** Inject
  the regression, watch the test fail, restore. Several checks in this
  project's history read correctly and verified nothing.
- **An unreachable assertion rots silently, and this file's own runbooks were
  built on one.** `FoundationIntegration` aborted at its Town Board notice
  check on every run, because that check counts a board that only exists after
  a profile load and the script runs at server boot. Everything after that line
  — roughly two thirds of the test — had therefore never executed, and five
  separate assertions had drifted out of agreement with the game while still
  reading as if they passed: a tool-yard roof part renamed to a rafter frame
  thirty commits earlier, a corner-post count that demanded completed buildings
  a tier-zero save cannot have, a town asset census that silently started
  counting Bramblewake once the expedition was dressed from the same library,
  two assertions naming assets that were never registered, and a
  fallback-visibility rule that directly contradicted the notice check beside
  it. Ten milestone runbooks ask for `[Last Light] PASS FoundationIntegration`
  as gate evidence; none of them could ever have got it. **When a gate line has
  never been seen to print, treat every assertion behind it as unverified.**
