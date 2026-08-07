# Wave plan — Milestones 8 through 10

The owner's directive (2026-08-06): *"continue 7-10 without stopping. Get
it done."* This is the queue that makes that possible without a check-in
between waves. Every entry names its files, its shape, and the gate that
says it is done, so a session picks up cold and starts warm.

Milestones 7, 8 and 9 are complete. Milestone 7's runbook is
[MILESTONE_7_REGION_WAVE_A.md](MILESTONE_7_REGION_WAVE_A.md); milestone 8
shipped as #274–#282 (v105–v113) and milestone 9 as #284–#290
(v114–v120).

**Next up: Bramblewake's two gaps, then M10 B and C.**

## The rhythm

`branch → implement → npm run test → PR → poll checks → merge → npm run
publish → handoff header → next wave`, no pause between. Docs update in
the same wave that earns them; deferring them breaks the only knowledge
sync this project has across sessions.

## Owner-gated, outside the PR stream

These cannot be closed by writing code, and implementation never waits on
them:

- **Live Studio passes** for anything a camera has to judge. The ledger
  of what is open lives in the M7 runbook.
- **The gear art pass.** 82 of the 90 craftable items draw a derived
  plan: the family's silhouette in the region's palette, marked
  `derived = true`. Nothing is invisible and nothing claims to be
  authored. Replacing them is an art pass on the same footing as the
  regions' mesh dressing.
- **The WHET press** on a genuinely dulled weapon (~30 landed strikes).
- **Device-hardware items** — baseline phone performance, touch reach,
  safe areas. Studio's emulator cannot close these.
- **Flipping a region's `enabled` flag.** Three gates guard it and the
  third (readiness) is honest about what is missing; the flip itself is
  the owner's call once a live session walks the region end to end.

## Milestone 8 — Region production wave B

| Wave | Scope | Done when |
|---|---|---|
| A ✅ | Tempest Reach catalog (30 modules, 12 POIs, 8 events, 5 materials) | Shipped #274 |
| B ✅ | Reach roster, Lighthouse Eater, Admiral Wreck, Tidebound Titan | Shipped #275 |
| C ✅ | **Reach geometry** — `TempestBuilder`, 30 visuals. Identity: exposure. Primitives: jetty deck, breakwater block, wreck hull, rigging, signal mast, storm rail, grounding rod, spray. Register in `RegionBuilders` + `NodeMaterials` + `Wayfinding` | `RegionBuilderCoverage` green for `region_tempest` |
| D ✅ | **Frostmere Vale catalog** — chapter V. Identity: warmth as a resource. Materials: frostmere ice, thawed iron, ember moss, wool, aurora salt | Its own spec passes 2,000 seeds; Bramblewake still `2b08c29f` |
| E ✅ | **Vale roster + elites + White Howler** — catalog names `enemy_*` for Frostmere; elites per CONTENT_CATALOG; boss `boss_white_howler` (3 phases: manage noise, share warmth, track aurora) | Encounter spec: kill switch, verb order, outcomes, no shared telegraph |
| F ✅ | **Vale geometry** — `FrostmereBuilder`, 30 visuals | Coverage spec green for `region_frostmere` |
| G ✅ | **Chapters IV–V** — extend `ChapterCatalog` with `chapter_four` (region_tempest, boss_tidebound_titan, outcomes navigable/scoured/broken) and `chapter_five` (region_frostmere, boss_white_howler). No schema bump: `story.chapters` already generic | `ChapterProgress` spec extended; resident arrival still gated |
| H ✅ | **Eight more residents** — four from the Reach, four from the Vale, into `ResidentRoster` with `arrivesInChapter` 4 and 5, jobs on real buildings, one quest each | `ResidentRoster` spec: 19 residents, no shared building/quest/title |
| I ✅ | **Town tiers 4–5** — extend `TownProgression` ceiling to 5 behind chapter IV, floor at 4 behind chapter V | Tier spec extended; nights alone still cap at 3 |

Wave I shipped before H, because eight residents need eight buildings to
work in and the town only had five unclaimed. Tiers four and five brought
six more (16 → 22), built as procedural shells rather than authored
meshes: the mesh pipeline is a separate art pass, and a tier a player can
reach has to have something standing in it the day it opens.

## Milestone 9 — Region production wave C and finale

| Wave | Scope | Done when |
|---|---|---|
| A ✅ | **Cinderfall Crown catalog** — chapter VI. Identity: memory made physical (false statues, authentic memories) | Spec green |
| B ✅ | **Crown roster + elites + Ash Regent** (4 phases: expose authentic memories, break false statues) | Encounter spec green |
| C ✅ | **Crown geometry** | Coverage green |
| D ✅ | **The Hollow Below** — authored finale rather than a procedural region: 7 POIs, no event pool, `boss_nameless_night` in five scenes (defend, pursue, rescue, witness, choose) | Finale spec: five scenes, three endings reachable, each idempotent |
| E ✅ | **Three ending states + epilogue** — stored like chapter outcomes; every chapter-decision combination maps to valid finale content | Spec walks every combination |
| F ✅ | **Final eight residents including Orin**; postgame resident states | Roster spec: 27 residents |
| G ✅ | **Town tiers 6–7 and all 28 buildings** — extend `TownProgression` and `TownConstruction` | Tier spec; building count spec |

## Milestone 10 — Content completion

| Wave | Scope | Done when |
|---|---|---|
| A-1 ✅ | **Weapons and armour to 90** (shipped #292) — six weapon families × six regions, then five armour slots × six regions × two lines (a light line that returns stamina, a heavy line that reduces damage). `Equipment` is already fully data-driven (slot, `damageReduction`, `staminaRegenMultiplier`, `kind`, `strikeRange`/`meleeReach`/multiplier/riders), so these are data, not code | Every output has an `Equipment` definition; every stat inside the bounds combat clamps |
| A-2 ✅ | **Consumables became data** (shipped #294) — the outputs that are used rather than worn. Needs a small data-driven consumable contract first: today `gear_meadow_satchel` and `gear_amber_charm` are hardcoded branches in `TutorialService`, `HUDController` and the client, which does not scale past two | Consumable spec: every usable output resolves through one table, no bespoke branch |
| A-3 ✅ | **Three new effect kinds and the counters that use them** (shipped #296) — 122 recipes, gate moved from 180 | `ContentCensus.spec` |

### How A-3 was decided (kept, because the reasoning outlived the wave)

104 recipes exist and each one has a reason to: 36 weapons (six families
bent along a different axis per region), 54 armour pieces (five slots,
two lines, every slot offering both), and 16 consumables (three effect
kinds the services can actually apply). The gate asks for 180.

The remaining 76 cannot come from anywhere honest inside the categories
this game has. What they could come from, in descending order of how
defensible each is:

1. **New effect kinds** — each one is a service change (cure a status,
   restore lantern fuel, a timed speed effect), and each unlocks six
   consumables that genuinely differ. Three new kinds is ~18 recipes and
   real work in `PlayerCombatService` / `PlayerSurvivalService`.
2. **A tool tier per region** — tools are currently a fixed starting kit
   rather than craftable. Making them craftable is a real system and
   about 20 recipes, but it touches the tutorial's first-tool flow.
3. **A second armour line** (a third stat axis, e.g. carry capacity or
   lantern radius) — ~30 recipes, and only honest if the stat is real.
4. **Padding**: a second version of each existing item with different
   numbers. This clears the gate and nothing in the suite can tell.
   Recommended against.

The owner chose option 1 and to move the gate. What shipped was three new
effect kinds -- lantern restoration, an affliction cure, and a field
repair -- chosen by asking which threats the game already makes that a
player could not answer, plus eighteen consumables using them. 122
recipes, and `CONTENT_CATALOG.md` and `validate-plan.mjs` both now say
122 with the reasoning attached.

**What is left, and it is the best content work available:** the census
found Bramblewake carrying four points of interest where every later
region has twelve, and two armour pieces where every later region has
ten. The starting region is the thinnest in the game. Filling the POIs is
eight authored entries plus eight cases in `BramblewakeBuilder` -- note
that Bramblewake has its own builder and is not covered by
`RegionBuilderCoverage`, so a POI added without a builder case would be
invisible rather than failing a test.
| B | **Quest completion** — resident arcs to the catalog's counts, every quest a real signal | Quest spec: every quest's objective kind has a signal |
| C | **Codex/archive completion** — memory fragments to full count across regions | Fragment spec: one per region minimum, anchors resolvable |
| D ✅ | **Content census** (shipped #296) — a single spec asserting the roadmap's launch inventory: 180 modules, 79 POIs, 48 events, 180 recipes, region counts | Census spec green |

## Notes that save a session

- **Region catalogs are template work.** Copy an existing one, swap the
  doc comment, the ids, the visuals and the materials. The generator is
  region-agnostic; registering a region is one require and one line in
  `CATALOGS`.
- **Materials must be added in three places** in the same commit:
  `ExpeditionInventory.KNOWN_MATERIALS`, `ExtractionPayoff.PRESENTATION`,
  and the region's `NodeMaterials`. The spec that catches a miss is
  `RegionBuilderCoverage`'s ledger case.
- **Every new encounter must share nothing** with the ones before it:
  telegraph ids, reward materials and transaction ids are all checked.
- **A new region's builder returns false for unknown keys**, and the
  coverage spec is what turns "geometry exists" into "geometry is
  complete".
- **A new region needs an arena entry per encounter**, in
  `RegionBuilders.Arenas`, and the coverage spec's expected list has to
  grow with it. The Reach shipped three encounters with no arenas at all
  and nothing failed for two waves.
- **A new chapter changes who can reach its region.**
  `RegionAccess.chapterReached` answers true for a region no chapter
  names, so a region without a chapter is gated only by its flag.
- **A quest's objective kind must be routed in `Quests.currentValue`**
  and fed by `SaveSchema.questSignals`. An unrouted kind reads zero
  forever and nothing errors.
- **Region waves need their buildings before their residents.** Twice now
  (M8 and M9) the resident wave had to wait on the tier wave, because
  every resident needs an unclaimed building and the town only had a
  few. Ship the tier wave first.
- **`Equipment` is data-driven; consumables are not.** Anything worn can
  be added as a table entry. Anything *used* currently needs branches in
  three files, which is what M10 wave A-2 has to fix before the recipe
  count can be finished honestly.
- **The cylinder rule**: a `Cylinder` part's axis is its `Size.X`. This
  has cost six shapes so far. Thickness on X for a disc, then rotate.
