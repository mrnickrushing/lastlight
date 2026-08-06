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

## Live checks deferred by the no-Studio constraint

Recorded across waves; every item is open until a live session:

- Companions (#225): hound visual read, follow feel, FOLLOW/STAY toasts
  via real button press.
- Defense plots (#227): plot placement on real terrain, arm-by-tap on
  device, bite toast mid-fight, Watch silhouette.
- Gear care (#229): WHET press on device, worn-label read, a real
  mitigated-hit wear arc.
- Delve/Fen enemies (#233, #237): silhouette and telegraph read at
  night, on device.
- Everything in "What remains" above, end to end, including the M7 exit
  gate's continuous fresh-save path through chapter III.

## Basic profession kits: verified complete

The roadmap's "remaining basic profession kits" line was satisfied by
M6 wave A (#206): all seven professions carry an ability, ability
visuals, and mastery specializations. Nothing was owed here beyond
verification, which wave H performed.
