# Project status

The living handoff between working sessions. **Read this first when starting a
session, and update it before you finish.** This project is developed across
many short AI-assisted sessions on more than one account; anything not written
here is invisible to the next session. The sibling repository learned this the
hard way — the same feature was once built twice in parallel because nothing
recorded that it was already in flight.

Last updated: 2026-08-03, at `main` = `1f1bc1f` (PR #170), build `0.47.0`,
save schema 12.

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

## Recently landed (PRs ~#151–#170)

Verified against `git log`, newest first:

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

## Known open threads

- `mesh_creator_first_lantern_a` is in the manifest but genuinely undecided —
  retire it explicitly or place it. Details in
  [ASSET_COVERAGE_AUDIT.md](ASSET_COVERAGE_AUDIT.md) §Intentionally unplaced.
- The M4 deliverables not yet confirmed landed from commit history: resident
  schedules/jobs/injury/relationships/crisis framework, storage and decoration
  caps, backups. Check the roadmap gate against source before assuming either
  way — this file records that the check has *not* been done, not that the
  work is missing.

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
- **A passing guard is not evidence until it has been made to fail.** Inject
  the regression, watch the test fail, restore. Several checks in this
  project's history read correctly and verified nothing.
