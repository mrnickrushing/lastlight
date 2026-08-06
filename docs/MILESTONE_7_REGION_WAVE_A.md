# Milestone 7 — Region production wave A: state of the milestone

Written 2026-08-06, after waves A–I shipped (PRs #231–#245, place
versions 80–88), all merged and published, all under the no-Studio
constraint. This runbook records what exists, what remains, and every
live check the constraint deferred — so the next Studio session opens
with a checklist instead of an excavation.

## What exists (merged, published, spec-pinned)

| Wave | PR | Ver | Delivered |
|---|---|---:|---|
| A | #231 | 80 | Ironroot Delve catalog (30 modules, 12 POIs, 8 events); region-agnostic ExpeditionGenerator; 5 Delve materials in the ledger |
| B | #233 | 81 | Delve's six enemies; merged EnemyCatalog over all regions; six builder silhouettes |
| C | #234 | 82 | Foreman Echo + Iron Widow encounter rules |
| D | #235 | 83 | Bellows Maw (reroute → vent → strike; vent = chapter II's decision) |
| E | #237 | 84 | Mireglass Fen entire: catalog, six enemies + silhouettes, Many-Face, Drowned Caller, Lantern Witch |
| F | #239 | 85 | Eight named residents; ResidentRoster; 8 quests, 5 derived signals |
| G | #241 | 86 | ChapterCatalog; story.chapters; schema 19 → 20; chapterProgress |
| H | #243 | 87 | Town tiers 2–4, story-gated; roster-driven cast; merge eviction bug fixed |
| I | #245 | 88 | RegionAccess: enabled/dependency/chapter gates; ExpeditionService region seam |

Tests grew 553 → 608 passing across the stretch. Bramblewake is proven
bit-identical through the generator seam (400 seeds + fallback, zero
hash mismatches).

## The one-flag contract

Everything is arranged so that **a region becomes reachable by flipping
its `enabled` flag in `Content/Definitions/Regions.luau`** — and nothing
else. The chapter gate, dependency chain, generator, catalog, enemy
roster, and encounter rules are already behind that flag. A load-bearing
assert in ExpeditionService fails the boot in plain words if a region is
enabled before its builder is wired, so the flag cannot be flipped
prematurely by accident.

## What remains (the geometry half)

These are the M7 exit-gate items that want a live Studio session — both
to build well and because their gate criteria (mobile, art, collision,
navigation, performance review) are literally live checks:

1. **Delve module visuals** — 30 `visual` keys in IronrootExpedition
   need geometry (grade-and-dark identity: inclines, scaffolds, rail
   walks, an unlit stretch). BramblewakeBuilder's `buildModuleVisual` is
   the pattern; a `DelveBuilder` sibling is the shape.
2. **Fen module visuals** — 30 keys, trust-of-surfaces identity (reed
   mats, mirror fords, water that lies).
3. **Elite services + arenas** — ForemanEchoService, IronWidowService,
   ManyFaceService, DrownedCallerService, following OldGrowthService's
   pattern (state module drives; service owns models, clicks, telegraph
   visuals, reward settlement via the deterministic transaction ids).
4. **Boss services + arenas** — BellowsMawService, LanternWitchService,
   following WardenStagService; chapter resolution flows through
   `SaveSchema.withChapterResolution` (already merged, wave G).
5. **Resident placement** — the eight new residents need placement
   definitions in WorldService's resident table (they are already in the
   cast list; unknown ids are skipped safely until placed).
6. **Region transition flow** — how a party chooses the Delve at the
   departure lodge once it is buildable (RegionAccess.available is the
   menu's data source).

## Live checks: closed 2026-08-06, and what is still open

A Studio session on 2026-08-06 (place versions 89–90) closed the first
block of these. What it found is the argument for driving every blind
wave as soon as a session is available: three defects, none of which any
test could see, because every part of them a test can read was correct.

**Closed:**

- **Companions (#225)** — hound builds (15 parts), stands at its keeper's
  flank 4.0 studs off and 0.17 above the floor, closes a 30-stud gap in
  under 2.5 seconds and settles at 3.5 without jitter. FOLLOW/STAY
  verified end to end by pressing the real button.
  **Defect found:** the order had no button at all. CompanionCommand
  existed server-side complete with contract, handler and toasts, and
  nothing on the client ever sent it — half the feature was unreachable
  in the shipped game (fixed, #249).
- **Defense plots (#227)** — three plots stand on their three lanes at
  exactly 46 studs from the lantern, each with six ring stones, stake,
  ember, and a 42-stud ArmClick; `defense_plots_built lanes=3` at boot.
- **Departure panel** — **defect found:** pressing a party size still
  showed nothing. #219 had fixed the payload half; the selection half was
  never implemented, so a press made off the platform (which the server
  correctly refuses) left the panel pixel-for-pixel unchanged. That is
  the owner's "no number is selected", finally whole (fixed, #248).
- **FoundationIntegration** — **two defects found:** the interaction
  census and the rotor-motion check both asserted fixtures the generator
  had not selected for this seed, so the suite failed on most seeds.
  Both terms are now derived from the placed manifest (fixed, #248).
  `PASS FoundationIntegration` live on a fresh boot.
- **Gear care rules (#229)** — verified live at the module level: worn at
  72 points reports `worn` and halves effectiveness, repair costs half
  the recipe, the trait roll resolves to KEEN with its label.

**Still open:**

- Defense plots: arming by tap with real materials, the bite toast
  mid-fight, and the Watch defender's silhouette on a solo night.
- Gear care: the WHET button press and worn equip-label read on a
  profile that has actually dulled a weapon.
- Delve/Fen enemies (#233, #237): silhouette and telegraph read at night.
- Everything in "What remains" above, end to end, including the M7 exit
  gate's continuous fresh-save path through chapter III.
- Every device-hardware item (baseline phone performance, touch reach,
  safe areas) — Studio's emulator cannot close these, per
  STUDIO_MCP_SETUP's own honest split.

## Basic profession kits: verified complete

The roadmap's "remaining basic profession kits" line was satisfied by
M6 wave A (#206): all seven professions carry an ability, ability
visuals, and mastery specializations. Nothing was owed here beyond
verification, which wave H performed.
