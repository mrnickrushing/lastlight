# Milestone 6 profession-roster runbook

## Scope

This increment completes the seven-profession roster — the first Milestone 6
deliverable. Three new kits join Scout, Warden, Engineer, and Medic:

- Alchemist — **Sporebright Tonic** restores up to 30 stamina and mends half
  that much health to the caster and active allies within 26 studs;
- Beastkeeper — **Briar Hound** harries the active night threat from up to 50
  studs: for 7 seconds it hunts the keeper instead of whoever is closest, at
  slightly reduced speed (0.8x — gentler than the Scout's 0.65x mark, so the
  two stay distinct when stacked);
- Runebinder — **Still Rune** binds the active night threat from up to 45
  studs for 3.5 seconds: any telegraph in flight is cancelled and the enemy
  starts no attack, moves nowhere, and presses no lantern impact while held.
  It can still be struck — the hold is the Runebinder's window, not mercy.

Every kit follows the four originals' contract: the ability request carries no
target, amount, duration, or outcome claim; the server derives all of them.
No objective, recovery path, or reward requires a specific profession.

## Design decisions

- **Each ability maps onto an existing combat primitive** rather than a
  parallel system: the tonic is the Medic's radius pattern applied to stamina
  as well as health (`PlayerCombatService.restoreStamina` per player in
  radius), the hound is a preference in `EnemyService._closestPlayer` target
  selection plus the existing slow mechanism, and the rune is the mark's
  held-state taken to a full stop (an early return in `EnemyService._step`).
- **The hound and rune act on the town-night threat only.** They are
  deliberately not delegated to the Old Growth or Warden Stag encounter
  services the way `markNearest` is: a hound can turn a night creature, not
  an elite or a boss. During those encounters the cast reads as the ordinary
  no-target refusal.
- **One `effectAmount`, two tonic effects**: the full number is stamina, half
  is the mend, so the Brewer specialization deepens both at once and neither
  half competes with the Medic's dedicated heal (22 vs. the tonic's 15).
- **The lure ends early if the keeper stops being a legal target** — downed,
  gone to the expedition, or beyond a 120-stud sanity range — handing the
  enemy back to normal selection instead of freezing it on someone
  untouchable.

## Mastery and specializations

All three kits use the same ten-level mastery and rank names, and each adds
three level-10 paths using only the established bonus fields:

| Profession | Paths |
|---|---|
| Alchemist | Brewer (+8 effect), Catalyst (−4s cooldown), Forager (+8 radius) |
| Beastkeeper | Handler (+2.5s lure), Bondkeeper (+10 radius), Wildspeaker (−4s cooldown) |
| Runebinder | Scribe (+1.25s hold), Channeler (+10 radius), Veilwalker (−5s cooldown) |

Their mastery shrines grow the Greenward grove along its own columns:
Alchemist at (−78, −122) fills the west column's empty middle row; Beastkeeper
(78, −214) and Runebinder (−78, −214) open a third row to the south, toward
the Watch Ring. All three centres were checked against every authored building
footprint and placement before being chosen. The grove's own boot assert
guards that the authored shrine list and the runtime specialization catalog
never drift apart.

## HUD

The selector grid is three columns (was two-by-two): seven cards on one page
of the same 640×440 panel, card text at 12pt. Ability names, roles, and
descriptions all render inside their cards at a landscape-phone viewport.

## Also fixed in this increment

- `FoundationIntegration` asserted the ability-visual catalog at a hardcoded
  `== 4`; it now derives from the profession catalog, plus an explicit
  roster-of-seven assertion.
- **A pre-existing Blackout crash found live while verifying this wave**:
  `BramblewakeBlackout.snapshot` publishes `deliveredNodes` as the HUD's
  lit-count (a number), but `TutorialService._objectiveTargets` iterated it
  as the delivered-node map — throwing "attempt to iterate over a number
  value" on every snapshot publish for the whole relay stage. The snapshot
  now also carries `deliveredNodeMap`, and the objective resolver reads that.

## Automated evidence

`npm test` covers, beyond the existing profession suites (which are
catalog-derived and grew to cover the new kits automatically):

- the twenty-one-specialization catalog in stable profession order;
- the roster-of-seven with complete, unique ability contracts;
- exactly three selectable paths per new profession.

## Studio evidence recorded (connected session, this increment)

- Seven-card selector renders with every card's name, role, ability, and
  description legible; three new shrines stand at their authored grove
  positions with 21 path stones total.
- Live ability verification of all three kits against a real night threat is
  recorded in the delivery PR, driven through the real `ActionRequest`
  remotes.

## Open work

Basic kits only. Still open on the Milestone 6 profession deliverable:
profession-specific audio, boss/elite interactions for the hound and rune,
Beastkeeper's full companion behavior and commands (the roadmap's separate
companion deliverable), Runebinder terrain interactions, and balance
telemetry thresholds.
