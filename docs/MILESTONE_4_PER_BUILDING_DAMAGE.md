# Milestone 4 per-building damage and repair

Build `0.49.0` (fixes in `0.49.1`), save schema `13`. Storm damage stops being one number for the
whole town and becomes a property of each building.

## What was wrong with the old model

`TownCondition` held a single 25–100 integrity, and a derived 0–3 "damage level"
decided how many of three hardcoded repair piles appeared. It had a specific
tell that the shape was wrong: **repairing the inn's storm frame could make the
archive's roof brace vanish.** No repair belonged to a building — every repair
added twenty to one shared number, and which sites were visible was purely a
function of that number. A player could not damage one building and could not
fix one either.

The roadmap and the handoff both already flagged this as weaker than the
deliverable wording implied.

## The model now

State mirrors `TownConstruction`'s — a `{ [buildingId]: integrity }` map
normalized against `TownProgression.buildingIds()` — because the two describe
the same set of objects from two directions, how far built and how badly
damaged, and there was no reason to read them differently.

| Concern | Rule |
|---|---|
| How many buildings a night strikes | 0/1/2/3, from the same lantern-health thresholds the old model used to pick a damage amount — so how hard a night *feels* is unchanged; only where the damage lands is new |
| Which buildings | Chosen by night number alone, walking the sorted roster and wrapping |
| How much | 35 per struck building, floored at 25 |
| Repair | 20 to **one named building** |
| Which buildings are eligible | Whatever physically stands — a construction site cannot be storm-damaged |

**Selection is deterministic from the night number**, the same rule
`TownNightIncident` already uses and for the same reason: a replay is
reproducible and a player who reconnects cannot reroll a gentler night.

**A building is damaged, never destroyed.** Integrity floors at 25, so a bad
night creates work rather than deleting a building, its services, or the paths
around it.

**An absent building is a whole one.** Only damaged buildings are stored, which
keeps the saved map small and means a building added to the roster later starts
undamaged everywhere without a migration touching a single profile.

## Sharing one town between separate profiles

Merging still prefers the newest defended night outright. Within the same night
it now takes **the better-repaired copy of each building** rather than one
player's whole town:

> Two players who repaired different buildings on the same day both keep their
> work.

The single-number merge could not express that. It had to choose one player's
entire town over the other's, silently discarding half the repairs done that
day. A stale profile still cannot re-damage a building someone already fixed.

## The world side

Each damaged building gets a repair site beside it, at the centre that building
recorded **when it was placed** — positions are captured through
`buildingShell`/`constructionSite` as the town is built rather than copied into
a second list of coordinates, because a hand-maintained position table would
drift from those call sites the first time a lot moved. That is the exact
failure `validate_town_layout.py` exists to catch.

The prompt carries its building's ID as a baked `Payload` attribute, the same
one-object-one-outcome route the crafting benches use. **The client sends only
the interaction ID and never names a building**, so a forged payload cannot
repair something that was not there. A building with damage but no recorded
placement — which a stale profile can carry — is skipped rather than prompted
for.

## Migration, schema 12 → 13

A schema-12 profile has one town-wide integrity and no record of which buildings
were hit, because the old model never stored that. The honest migration is that
**every building inherits the town's number**: how damaged the town was, and how
much repair work is outstanding, both survive; which buildings were hit cannot
be recovered and is not invented. An undamaged schema-12 town migrates to no
stored damage at all.

This is the first schema bump since profile backups landed, so the load path's
`schema_change` trigger photographs each profile's raw stored bytes before
`normalize` folds them forward. That was the case
[MILESTONE_4_PROFILE_BACKUPS.md](MILESTONE_4_PROFILE_BACKUPS.md) was built for.

## A regression this pass nearly shipped

`TownPermissions.resolveCondition` guards the M4 exit-gate line *"visitors
cannot modify or steal without permission"* by refusing any merge that would
lower a host's integrity. Its local reader plucked `value.integrity` off the
table — a field that stopped existing when damage became per building. It would
have returned **zero for every town**, making `merged < current` false in every
case and **turning the guard off silently**. Visitors would have been able to
wreck host towns again, with no error anywhere.

The existing `TownPermissions` suite caught it. The fix follows the module's own
injected-dependency style: `resolveCondition` now takes the integrity reader
alongside the merge function, and **requires** it rather than defaulting, so a
missing accessor is a loud programming error instead of an unprotected town.

## Automated evidence

`npm test` — 479 pure Luau tests, 24 of them the rewritten `TownCondition`
suite, plus format, lint, strict typecheck, both place builds, and DataModel
verification. The Studio integration place asserts the per-building repair
contract directly. `SaveMigration.spec`'s existing coverage guard required a
schema-12 era fixture before the bump would pass, and one was added.

Made to fail before being trusted:

| Injected regression | Caught by |
|---|---|
| a repair raises every damaged building (the old model's actual bug) | "repairing one building leaves every other building alone" |
| damage selection becomes random instead of night-derived | "which buildings are struck depends only on the night number" (+2 more) |
| the visitor guard's comparison is disabled | "a visitor from a later, wrecked town cannot break an intact one", "no arrival by anyone can ever lower integrity" |

## Studio and device exit gate

Not closed by the suite. Automated checks establish the state transitions,
migration, and generated-place inclusion; none of the following can be evidenced
without Studio and a published staging place.

1. Finish a night near 75 lantern health. Require exactly one building visibly
   damaged, with its repair site beside **that** building rather than at a fixed
   spot, and the prompt naming it.
2. Finish nights near 55 and near 20. Require two and three damaged buildings
   respectively, and confirm which ones match the night number across a server
   restart — the same night must strike the same buildings.
3. Repair one damaged building fully. Require the other damaged buildings to be
   visually **unchanged** — this is the behaviour the old model got wrong, and
   it is the single most important row here.
4. Rejoin with damage outstanding. Require identical per-building integrity,
   repair sites, and repair count.
5. Attempt repairs out of range, during dusk and night, while downed, and while
   in Bramblewake. Require no state change and no stale prompt.
6. Have two players repair different buildings on the same day, then rejoin with
   both profiles. Require both repairs to survive.
7. Join a host town as a visitor carrying a later, more damaged town. Require
   the host's buildings to stay as they were.
8. Damage a town, then take a building to a construction stage of zero. Require
   no repair prompt for a building nobody has built.
9. Confirm every damaged building remains navigable, with camera clearance and
   interaction reach intact on the baseline phone, at the maximum number of
   simultaneously damaged buildings.

## Construction-site fixes (build `0.49.1`)

Review after the first merge found two ways a building nobody has built could be
treated as damaged. Both were reachable on ordinary paths, not edge cases.

**An explicitly empty damageable roster meant "damage everything."** `afterNight`
folded `nil` and `{}` together and fell back to the full building list for both.
`WorldService.damageableBuildingIds()` returns `{}` when every building is still
a construction site — which is exactly a tier-zero town, so a new save's first
bad night would have damaged all sixteen buildings, none of which stand. `nil`
now means "no roster supplied, use every known building" and an explicit table
means exactly that set, empty included.

**A migrated profile could raise a repair prompt on an empty lot.** Schema-12
normalization marks *every* building damaged, because the old model never
recorded which were hit. The renderer checked that a damaged building had a
recorded placement, but construction sites record one too — with
`damageable = false`. `snapshot` now takes the standing roster and omits damaged
buildings outside it, so the HUD's repair count is right as well as the world;
the renderer keeps a second gate on `placement.damageable`, because the cost of
getting this wrong is a REPAIR prompt on bare ground.

Both fixes were made to fail before being trusted: restoring either old
behaviour fails the case that names it.

## Open work

- **Damage visuals are one authored assembly** — a repair pile, broken braces,
  and a storm tarp — reused at each damaged building rather than per-building
  bespoke damage geometry. That is the honest state: it satisfies the
  construction rules in `VISUAL_QUALITY_STANDARD.md`, but a workshop and an inn
  break the same way as each other today.
- Damage is uniform per hit (35). Building size, tier, and lane exposure do not
  yet change how badly a given building suffers.
- Residents do not react to a damaged building, and a damaged building does not
  yet withhold its function — the archive still works while wrecked.
