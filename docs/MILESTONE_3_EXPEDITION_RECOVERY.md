# Milestone 3 expedition recovery caches

Build `0.25.0` and save schema `10` replace the temporary "retain the entire
pouch" expedition retreat with a bounded partial-pouch recovery contract.
Failure now creates a reason to return to Bramblewake without deleting banked
progress or minting replacement rewards.

## Failure contract

When a player resets or bleeds out inside Bramblewake:

1. Banked materials, gear, quests, mastery, story, residents, and recipes remain
   untouched.
2. Session-only reward transactions are imported into the durable profile pouch
   before the retreat is resolved.
3. A pouch with zero or one transaction is retained in full.
4. A larger pouch keeps the first deterministic half unbanked and marks the
   remaining half `cached` under one stable recovery-cache ID.
5. The player returns safely to Emberhollow with an explicit kept/recoverable
   message.

The cache stores transaction IDs, not a second material grant. Cached rewards
are excluded from Wayhome settlement until recovery. This prevents extracting a
cached reward through the session ledger, reconnecting to duplicate it, or
claiming the physical satchel twice.

## Physical recovery

On the owner's next Bramblewake entry, a recognizable lost expedition satchel
appears beside the streamed arrival route. It has a fabric body and flap, wooden
braces, and a metal Wayhome clasp. The prompt is owner-bound and uses the normal
context action; no permanent HUD button is added.

The server verifies that the requester is inside Bramblewake, owns the prompt,
has a writable profile, and is claiming the exact active cache ID. Success moves
the original cached records back to `unbanked`, persists the profile, destroys
the physical model/prompt, and reports the recovered material total. Other
players receive a harmless ownership rejection.

Multiple active caches remain isolated and all cached transaction IDs are
excluded from settlement. The oldest active cache is presented first; a later
cache becomes available on a following entry after the first is recovered.

## Persistence and bounds

- Schema-9 and older profiles normalize into empty schema-10 recovery state.
- Cache records and cached reward links are both validated; a forged cache with
  no matching cached reward is discarded.
- At most 16 recovery tombstones are retained. Recovered tombstones rotate
  before any active cache can be displaced.
- Cache creation and recovery use synchronous save verification in persistent
  environments. Failed saves retain dirty in-memory state and explicit retry
  messaging rather than clearing the server fallback.
- Cache IDs include run ID, owner user ID, and pouch fingerprint; repeated
  failure delivery returns the same record instead of moving more value.

This vertical slice deliberately does not permanently delete common materials.
The design document's rarity-based loss split remains future work until rarity
and risk contracts exist; the implemented consequence is temporary loss of
access to half the transaction records.

## Automated validation

Pure Luau tests establish deterministic half selection, minimum-pouch safety,
pending-pouch exclusion, exact-once recovery, cache/reward link normalization,
schema-9 migration, and schema wrapper persistence. The full suite also runs
formatting, lint, type checks, 1,000 expedition seeds, both deterministic place
builds, and built DataModel verification.

## Studio, multiplayer, and persistence exit gate

1. Earn four distinct event/encounter reward transactions, then bleed out in
   Bramblewake. Require two to remain in the pouch and two to become recoverable.
2. Re-enter and require one owner-labeled physical satchel near arrival after
   streaming completes.
3. Have another player trigger it. Require an ownership rejection and no profile
   mutation. Claim it as the owner and require all four original transactions in
   the pouch with no duplicate IDs.
4. Attempt Wayhome before recovering the satchel. Require only the retained half
   to bank. Re-enter, recover, and bank the remainder exactly once.
5. Repeat with a one-transaction pouch. Require full retention and no satchel.
6. Stop and restart a private staging server between failure and recovery.
   Require the cache and owner binding to survive.
7. Force a save failure during cache creation and recovery. Require clear retry
   behavior and no disappearance or duplicate settlement.
8. Repeat reset/bleedout, reconnect, duplicate prompt, two-cache, touch,
   keyboard/mouse, controller, and baseline-phone journeys.

Automated checks establish state transitions and generated-place inclusion.
Recorded Studio, DataStore, reconnect, multiplayer, latency, streaming, and
device evidence remains required before this exit gate is closed.
