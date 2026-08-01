# Milestone 3 persistent town condition and repair

## Scope

Build `0.21.0` makes normal-night performance leave a durable physical mark on
Emberhollow. The First Lantern's health at dawn now determines town integrity:

```text
night ends
  → server snapshots First Lantern health before its combat reset
  → bounded damage is applied once for that night
  → schema-v9 town condition is saved for every connected player
  → damaged buildings gain broken braces, storm tarps, debris, and repair piles
  → during daylight, players hold a world-space repair interaction
  → each repair restores 20 integrity and persists immediately
```

A defense ending at 90 health or better is clean and causes no new damage.
Greater pressure causes 15–55 integrity damage, with a hard floor of 25 so a
rough night creates work without deleting buildings, services, quests, or
critical paths.

## Visible states

| Integrity | Damage level | Physical consequence |
|---:|---:|---|
| 90–100 | 0 | town restored; no repair prompts |
| 70–89 | 1 | Memory Archive roof brace and repair pile |
| 50–69 | 2 | Archive plus Lantern Workbench storm damage |
| 25–49 | 3 | Archive, Workbench, and Wayfarer Inn damage |

The damage model is rebuilt from persisted state, not remembered only as local
parts. Repair prompts disable at dusk and night. The server also rejects repair
requests while downed, out of range, outside daylight, or inside Bramblewake.

## Persistence and multiplayer reconciliation

`town.condition` stores integrity, the last recorded night, last damage, and
completed repair count. Applying the same night twice is idempotent. Schema-v8
profiles migrate to pristine condition without touching their existing night,
story, inventory, equipment, quest, or mastery progress.

As with the existing shared town tier, connected players still own individual
profiles while looking at one server town. Reconciliation therefore prefers the
condition from the newest defended night. For the same night, higher integrity
wins because it proves later repair work. A stale joining profile cannot undo
repairs already completed in that server. Every accepted repair is written to
all connected writable profiles.

## Required Studio and device evidence

1. Finish a night above 90 lantern health and confirm no damage or repair prompt.
2. Finish separate nights near 80, 60, and 30 health; confirm the correct one,
   two, and three physical repair sites appear.
3. Rejoin with damage and confirm identical integrity, props, and repair count.
4. Hold every repair on touch, keyboard/mouse, and controller. Confirm exactly
   one 20-point repair commits and the world visibly improves immediately.
5. Attempt repairs out of range, during dusk/night, while downed, and during an
   expedition. Confirm no state changes.
6. Join two profiles from different nights and confirm the newest night wins;
   join two from the same night and confirm the more-repaired town wins.
7. Spam and duplicate the repair interaction. Confirm integrity never exceeds
   100 and no stale prompt can grant phantom progress.
8. Verify the three damage sites remain navigable and stay within the baseline
   phone's part, frame, and interaction-readability budgets.

Automated checks cover damage bounds, idempotence, repair bounds, merge order,
schema migration, persistence, lint/type safety, generated places, and DataModel
verification. Studio/device evidence remains required for physical alignment and
feel.
