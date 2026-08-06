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

- **The Watch defender (#227)** — posted at the Meadow Gate plot on a solo
  town night, three studs off the ring as designed, and stood down at
  dawn. Confirmed on night two, after the tutorial completed.
- **Gear care labels (#229)** — a freshly crafted Amber Edge carries its
  rolled trait and condition through to the client (`KEEN`, `sound`), and
  the whet target stays absent until something is worn. **Defect found
  and fixed while equipping it**: the equip and whet toasts read the raw
  item id out loud ("EQUIPPED GEAR_AMBER_EDGE"), which is how an
  underscore in a database row ends up in a player's face. Both now use
  the catalog's display name.

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
  **The whole plot loop is verified live.** On an empty purse the real
  stake answers "SETTING THE SNARE TAKES 1 HEARTWOOD AND 2 MEADOW FIBER";
  with materials banked it answers "THE MEADOW GATE SNARE IS SET — 2
  BITES IN IT", spending exactly 2 fiber and 1 heartwood and lighting the
  ember; and at nightfall the first wave answers "THE SNARE BITES —
  BRIARBACK IS HELD" with the ember going cold on the second charge.
  **A defect fell out of that last step** (#255): the trap gated on the
  service's own night flag, which only TownNightService raises, so an
  armed snare could never bite during the tutorial's first night -- three
  plots sat lit while creatures walked their rings. It now asks the enemy
  service where the walker is, which is true on any night.
- **Delve and Fen enemy silhouettes (#233, #237)** — all twelve built and
  photographed. **Six were wrong** and are fixed in #251: four parts sized
  on the wrong cylinder axis (the Slag Spitter's pool standing as a bar
  through its body, the Bog Bell's ground marks floating as bars, the
  Rail Hound's wheels buried inside its chassis so it read as a plank,
  the Crank Guard's mechanism a squashed tube), the Gas Bloomer's petals
  pitched before yaw so the bloom read as a saucer, and the Mire Leech's
  mouth. Re-photographed after the fix.
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

**Still open, and what each one needs:**

Everything left here needs a **town night**, which sits behind tutorial
completion (free Mara, gather, choose a tool, raise the barricade, hold
the first night). Materials are no longer the obstacle -- see the
stocking hook below.

- Gear care: the WHET press itself, which needs a weapon that has
  actually dulled -- roughly thirty landed strikes across a night. The
  rest of the chain is verified: a crafted Amber Edge reports its rolled
  trait (KEEN) and condition (sound) in the session payload, and the
  whet target is correctly absent while nothing is worn.
- Gear care: the WHET press and the worn equip-label read on a profile
  that has actually dulled a weapon.
- Delve/Fen enemies: telegraph read at night (the silhouettes are done).
- The M7 exit gate's continuous fresh-save path through chapter III,
  which needs the geometry half of the milestone first.
- Every device-hardware item (baseline phone performance, touch reach,
  safe areas) — Studio's emulator cannot close these, per
  STUDIO_MCP_SETUP's own honest split.

## Stocking a profile for a verification run

`ProfileService` honors a `LastLightStockProfile` attribute on the
DataModel: set it to a number and every loaded profile is granted that
many of each launch material, immediately. It exists because the session
above spent itself discovering that a two-second interaction was gated
behind a full playthrough, every time.

```lua
-- in the running server, mid-session
game:SetAttribute("LastLightStockProfile", 12)
```

Three guards, all of which must hold: Studio only (`RunService:IsStudio`),
non-persistent environments only (production runs with persistence on and
refuses it), and a loud log line every time. It grants materials, which
are earned and spent in play; it cannot grant progress, chapters,
professions or gear, because those are what a verification run is
supposed to actually perform.

## A note for whoever drives Studio next

Two things cost this session real time and are worth knowing:

1. **Mouse coordinates are screen space, not viewport space.**
   `Camera:WorldToViewportPoint` returns a point ~36px above where the
   mouse must actually go (the GUI inset). Use `ScreenPointToRay` to
   confirm a target before clicking, or check `Mouse.Target` after
   hovering — a click that lands on terrain looks exactly like a dead
   ClickDetector, and that is how an hour disappears.
2. **GUI buttons are best clicked by `instance_path`**, which resolves
   the coordinates itself and sidesteps the above entirely.

## Basic profession kits: verified complete

The roadmap's "remaining basic profession kits" line was satisfied by
M6 wave A (#206): all seven professions carry an ability, ability
visuals, and mastery specializations. Nothing was owed here beyond
verification, which wave H performed.

## The Delve's geometry, wave one

`IronrootBuilder` holds the region's own visual vocabulary — shoring
timber, rail and sleepers, ore carts, cut rock, spoil, coalglass seams,
glow fungus, lamp posts — and nine module visuals assembled from it:
the gate, the daylight shaft, the ore gallery, the coalglass seam, the
fungus terrace, the main incline, the rail walk, the dark stretch, and
the Bellows approach.

The shape that does the most work is `shoring`: every module carries a
low roof on posts. That is what makes a place read as underground while
the sky is still technically there — it cuts the horizon down to head
height and throws the module into its own shadow, so the Delve's light
comes from lamps and coalglass rather than from the sun.

The second wave completed the set: oil works, echo vault, flooded stope,
abandoned face, scaffold climb, collapse scramble, winch crossing, mite
nest, slag channel, guard round, gas pocket, echo gallery, shored drift,
junction round, rail siding, air door, foreman's office, miners' rest,
memorial drift, signal room and flood locks — with the primitives they
needed (pipe runs, flood pools, scaffolds, machinery, collapses, air
doors, notice boards). **All thirty of the Delve's module visuals now
have geometry.**

`IronrootBuilderCoverage.spec` is what keeps that true. It reads the
builder's source and fails if any visual the catalog can place has no
case, because a module drawn into a manifest with no geometry behind it
is an empty cell a player walks into — and no other test in the suite
can see that (the builder is full of `Instance.new`, so Lune cannot run
it). The same spec pins `enabled = false` on the region, so the flag and
the coverage move together.

`buildModuleVisual` still returns false for a key it does not know, and
the region stays disabled until its runtime lands: `RegionAccess` refuses
a disabled region, and `ExpeditionService`'s boot assert refuses it
louder.
