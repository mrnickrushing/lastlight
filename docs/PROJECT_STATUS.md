# Project status

The living handoff between working sessions. **Read this first when starting a
session, and update it before you finish.** This project is developed across
many short AI-assisted sessions on more than one account; anything not written
here is invisible to the next session. The sibling repository learned this the
hard way — the same feature was once built twice in parallel because nothing
recorded that it was already in flight.

Last updated: 2026-08-04, at `main` = `370bcfe` (PR #173), build `0.47.0`,
save schema 12, 20 services. No pull request or issue is open.

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

## Recently landed (PRs ~#151–#173)

Verified against `git log`, newest first:

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
   wave all need a human in Studio and on a phone. Sessions verify geometry
   arithmetically and via asset thumbnails; neither substitutes for the gate.
2. **`ROBLOX_API_KEY` per session** — containers lose it on reset. It is
   needed only for asset upload/download (`scripts/upload_mesh_assets.py`,
   `scripts/download_creator_store_model.py`), never committed or logged.
3. **Codex review credits are exhausted.** Codex caught two real shipped bugs
   during the visual wave (beds below the floor; lantern regen cancelling
   revives). CodeRabbit still reviews, but expect nothing from Codex until
   credits are topped up.
4. **First Lantern position report vs. source** — an owner playtest report
   asked for the First Lantern to move "back towards the center of town in
   the city square." Source already has it exactly there (see the
   2026-08-04 entry above) with no history of it being elsewhere. Needs the
   owner to say what they're actually seeing in the published/Studio game —
   a stale published place, a different landmark entirely, or something a
   session genuinely cannot see from source.

## Known open threads

- `mesh_creator_first_lantern_a` is in the manifest but genuinely undecided —
  retire it explicitly or place it. Details in
  [ASSET_COVERAGE_AUDIT.md](ASSET_COVERAGE_AUDIT.md) §Intentionally unplaced.
- **Checked (2026-08-04) against source, not just commit history:** resident
  jobs/injury/relationships/crisis framework, storage/decoration caps, and
  profile backups are all **absent**. Residents exist only as ambient NPCs
  with day/dusk/night positions and duty labels (`WorldService.luau`
  ~8207-8250); no storage or decoration system exists to cap; `ProfileService`
  has a single DataStore write path with no secondary/backup write. Multiple
  grep patterns tried per item, all zero-hit — see the roadmap gate for what
  "done" means here. Also weaker than the deliverable wording implies: "town
  visit flow" is only implicit first-arrival hosting on a shared server (no
  deliberate visit/teleport mechanic); damage/repair is one town-wide
  integrity value (`TownCondition.luau`), not per-building; eleven of the
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

- **Remote containers:** `selene` cannot fetch the Roblox API dump through the
  proxy and `luau-lsp` may be absent, so `npm test` cannot fully pass locally
  there. Run what runs; say plainly which checks CI must cover. `lune` may not
  be on `PATH` — find the binary before concluding it is missing.
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
