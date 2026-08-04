# Milestone 4 profile backups and audited restore

Build `0.48.0` adds the last unimplemented piece of Milestone 4's first
deliverable — *"versioned profile, locking, autosave, shutdown, migrations,
**backups**"* — and the write half of *"admin save inspection and safe repair
tooling with audit logs"*, whose read half shipped as `/inspect` in PR #168.

Nothing about the profile's shape changes. Save schema stays at `12`; backups
live in their own DataStore.

## Why a separate store

A backup has to survive whatever went wrong with the profile. A ring of
snapshots kept as a field *inside* the value it protects would be destroyed by
the same bad write that made the restore necessary, so backups are written to
`LastLightProfileBackup_v1`, keyed the same way (`player_<id>`) and read
independently.

## When a copy is taken

`ProfileBackup.shouldCapture` owns the decision, and there are two triggers.

| Trigger | Reason recorded | Rate limited |
|---|---|---|
| The stored profile's schema version is not the current one | `schema_change` | **No** |
| No copy exists yet | `first_backup` | n/a |
| The newest copy is older than `ProfileBackupIntervalSeconds` (900s) | `interval` | Yes |
| A restore is about to overwrite a profile | `pre_restore` | **No** |

The schema-change trigger is the one the architecture document asks for:
*"Backups and export tooling are required before migrations that alter inventory
or commerce."* A migration in this codebase is not a numbered pipeline that can
be replayed backwards — it is `SaveSchema.normalize` folding an older profile
into the current default — so whatever a migration drops is gone with nothing
left to compare against. The load path therefore photographs the **raw stored
bytes before `normalize` runs**, not the migrated result.

Ordinary copies are rate limited because the autosave beat is the busiest write
path in the game, and a copy on every save would double its traffic to
photograph a profile that usually has not meaningfully changed.

Both captures are spawned rather than awaited. A player never waits on the join
path, or on an autosave, for a redundancy write, and a backup failure is logged
and swallowed — refusing to save because the backup failed would turn a
redundancy feature into a new way to lose progress.

## What is kept

`ProfileBackupRetained` (3) snapshots, oldest dropped first. The bound is not
arbitrary: a DataStore value has a hard size ceiling and a profile is not small,
so an unbounded history would eventually fail every write to the backup key —
taking backups down at exactly the moment the save is growing fastest.

Each snapshot records the revision, capture time, schema version, and reason,
alongside the profile itself.

## The two properties that make a restore work

Both fail silently when they are wrong, which is why they live in a pure module
with tests rather than inline in the service.

1. **A restored profile out-ranks the profile it replaces.**
   `ProfilePersistence.resolveWrite` retains the stored copy whenever its
   revision is higher. That is exactly right for two servers racing and exactly
   wrong for a restore: a restore is a deliberate move backwards in *content*
   and must still be a move forwards in *revision*. Written naively it would log
   success and change nothing. `restoredProfile` takes `max(snapshot, live) + 1`.

2. **A snapshot never carries a session lock.** Locks ride inside the saved
   profile so a crashed server leaves behind a heartbeat that stops. Copy one
   into a backup and a restore resurrects a lock held by a job that no longer
   exists, leaving the player read-only until someone runs `/unlock`. Locks are
   stripped on capture *and* on read, so a snapshot written by an older build
   cannot carry one through either.

## Admin commands

Both are roster-gated by user ID and behind `admin_commands_enabled`, like every
other admin command.

| Command | Effect |
|---|---|
| `/backups <user>` | Lists what copies exist — count, revisions, capture times, reasons. Changes nothing. Full report to Output; the toast carries the headline. |
| `/restore <user>` | Rolls the save back to its **newest** copy. |

`/backups` first, always: a restore is a deliberate move backwards in someone's
progress, and the depth and reasons are how an operator judges whether to do it.

What keeps `/restore` safe:

- **It refuses while a live server holds the profile.** Restoring under a
  session that is still writing would have that session's next autosave
  overwrite the restore, or land between the read and the write. The decision is
  made inside `UpdateAsync`, against the value actually about to be committed
  over, using the same `acquireLock` a real server uses — not a snapshot read
  beforehand, which could be stale by the time the write lands.
- **The replaced profile is copied first, so a restore is undoable.** Running
  `/restore` twice returns the player to where they started. A one-way door in a
  repair tool is how a repair becomes an incident. The `pre_restore` copy is
  taken only after the restore actually commits, so a refused restore does not
  spend a slot in the ring.
- **It never invents progress.** The only thing written is a profile this player
  already had. Nothing is merged, topped up, or granted.

Deliberately absent: any way to name *which* backup. `/restore` takes the newest
and nothing else, so the parser cannot be handed an index selecting an arbitrary
point in a player's history. Restoring further back is a real need and can have
its own command; it is not one to reach by loosening this one.

## Automated evidence

`npm test` — 462 pure Luau tests, 16 of them new in `ProfileBackup.spec.luau`,
plus format, lint, strict typecheck, both deterministic place builds, and built
DataModel verification. The Studio integration place asserts the restore
contract directly (revision advances, lock stripped).

Each of the load-bearing properties was **made to fail before being trusted**,
per the repository rule:

| Injected regression | Caught by |
|---|---|
| `restoredProfile` returns the snapshot's own revision | the three restore-ranking cases |
| capture stops stripping `sessionLock` | "a snapshot never carries a session lock" |
| the ring bound is removed | "the ring never grows past its retained count" |
| a `nil` stored schema version stops counting as a change | "a missing or malformed stored schema version counts as a change" |

## Studio, DataStore, and multiplayer exit gate

None of the following is closed by the automated suite. All of it needs a
published staging place with API access and a non-production test account —
Studio local/test is session-backed and has no durable store to copy.

1. Play far enough to bank materials, rejoin, and confirm Output reports
   `profile_backup_captured` with reason `first_backup`, then nothing further
   for fifteen minutes, then `interval`.
2. Run `/backups <self>` and require the count, revisions, and reasons in Output
   to match what step 1 produced.
3. Craft something, wait for the interval, then `/restore <self>`. Require the
   crafted item to be gone, the toast to report the revision it moved from and
   to, and a rejoin to show the restored state rather than the newer one.
4. Run `/restore <self>` again immediately. Require the *first* state back —
   this is the undo property, and it is the one most worth proving by hand.
5. With the target player online and active on another server, run `/restore`.
   Require `A SERVER IS STILL HOLDING THIS SAVE` and no change to their profile.
6. Run `/backups` and `/restore` against a user ID with no save, and against a
   user with a save but no backups. Require distinct, non-destructive refusals.
7. Run both commands as a non-roster player. Require silence — no reply, and no
   hint that the commands exist.
8. Force a DataStore failure on the backup store during a save. Require the save
   itself to still succeed and `profile_backup_failed` to appear in Output.
9. Confirm no backup log line contains profile contents — IDs, counts, revisions,
   and reasons only.

## Open work

- **Restoring to a copy other than the newest.** Needs a second argument on the
  admin parser and a way to name a snapshot; deliberately out of scope above.
- **Export tooling.** `TECHNICAL_ARCHITECTURE` names "backups and export
  tooling" together. This is the backup half only; nothing here writes a profile
  out of Roblox.
- **Migration fixtures for every released schema.** Backups make a bad migration
  recoverable, which is not the same as the exit-gate line "migration fixtures
  cover every released schema". `SaveMigration.spec.luau` covers the normalize
  path; the fixture-per-released-schema matrix remains open.
- Backups are per player, like every other piece of persistent state in this
  project. There is still no town-wide save to back up.
