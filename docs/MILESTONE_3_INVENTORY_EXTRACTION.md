# Milestone 3 inventory and extraction settlement

## Scope

This increment makes the active Bramblewake event rewards durable and adds
an authoritative Wayhome extraction flow. It is a bounded Milestone 3 slice, not
the complete inventory, crafting, equipment, or persistent
town platform.

Implemented in source:

- save schema version 2 introduced the migrated inventory domain; current
  profiles normalize through schema v3 with profession selection;
- five stable Bramblewake material IDs and bounded normalization;
- a durable unbanked expedition pouch with reward-transaction tombstones;
- server-run-specific reward IDs so repeated seeds can reward on later runs;
- one Wayhome Gate extraction interaction at the final module;
- atomic pouch-to-banked-material settlement with deterministic transaction IDs;
- settlement and reward retry idempotency;
- immediate dirty marking and queued persistence when an event completes;
- synchronous persistence verification before Wayhome consumes the session copy;
- server-session reward retention when profile load, write, or settlement fails;
- bounded server-side streaming prefetch before returning to Emberhollow;
- extraction success/failure telemetry and banked/unbanked snapshot fields;
- a follow-on schema-v10 partial-pouch failure contract and persistent physical
  recovery satchel, documented in
  [MILESTONE_3_EXPEDITION_RECOVERY.md](MILESTONE_3_EXPEDITION_RECOVERY.md);
- pure migration, normalization, retry, duplicate, and malformed-grant tests;
- Studio DataModel assertions for the extraction target and server action.

Not implemented by this increment:

- item slots, capacity, equipment, crafting, repair, loadouts, or an inventory screen;
- resource gathering beyond the four current event rewards;
- profile session locking, backups, admin repair, or the complete Milestone 4
  persistence platform;
- production DataStore, device, multiplayer, forced-write-failure, or reconnect
  evidence.

## Durable state model

The profile now separates:

```text
inventory.materials
  banked material totals

inventory.expeditionRewards
  immutable reward transaction records
  status = unbanked | settled

inventory.settlements
  extraction tombstones with source reward IDs and material totals
```

Schema-1 profiles normalize into schema 2 with the original tutorial progress
and an empty inventory. The existing `LastLightProfile_v1` DataStore name stays
unchanged so released schema-1 records remain discoverable for migration.

An event reward ID includes the server-owned expedition run ID:

```text
event_reward:<run ID>:<manifest hash>:<event ID>
```

This prevents a common seed from granting twice inside one run while still
allowing the same player to earn that event in a future server run.

Extraction settles the complete durable pouch under:

```text
expedition_settlement:<run ID>:<user ID>:<pouch fingerprint>
```

Retry returns the stored settlement. It never reapplies the source reward
transactions.

## Failure behavior

- A malformed or unknown material never enters the pouch.
- Duplicate event delivery returns the existing reward record.
- Event completion updates profile memory immediately and queues a save without
  blocking the interaction for every party member.
- Wayhome imports any session-only fallback transactions, settles the pouch, and
  verifies persistence before clearing the session ledger.
- Read-only profiles and failed writes leave rewards unbanked and keep the
  player at Wayhome with a clear retry message.
- If banking succeeds but the character transition is unavailable, the banked
  value remains safe and the transition can retry.
- Empty-pouch extraction returns the player safely without inventing a transaction.

## Windows Studio journey

1. Run `npm test`, then open `build/LastLightTest.rbxlx`.
2. Press Play and confirm Output contains
   `[Last Light] PASS FoundationIntegration`.
3. Finish First Light, enter Bramblewake, and complete at least two different
   events.
4. Confirm the HUD reports unbanked materials without counting a reward twice.
5. Reach the final module and confirm `BANK & RETURN` appears at Wayhome Gate.
6. Interact once and confirm the player returns to solid ground in Emberhollow.
7. Confirm Output contains one extraction settlement and its banked total.
8. Re-enter and interact with Wayhome again without earning another reward.
   Confirm the banked total does not change.
9. In a server with no completed event, use Wayhome and confirm the empty-pouch
   return succeeds.
10. Confirm the final module, extraction prompt, and transition remain usable
    on touch, keyboard/mouse, and controller.

Local Studio profiles are session-backed. Cross-server persistence and migration
must be tested only in a private staging place with API access enabled and a
non-production test account.

## Persistence, reconnect, and abuse gate

| Gate | Required evidence |
|---|---|
| Schema migration | a real schema-1 fixture retains tutorial state and gains an empty schema-2 inventory |
| Same-server reconnect | unbanked session rewards remain available after disconnect and rejoin |
| Cross-server reconnect | an autosaved pouch loads in a new private staging server and banks once |
| Write failure | Wayhome keeps value unbanked and succeeds once storage recovers |
| Duplicate request | repeated Wayhome and event remotes never increase materials twice |
| Conflict | a newer stored revision that lacks the settlement does not clear the session fallback |
| Empty pouch | extraction returns safely with no reward transaction |
| 2/4/8 players | each contributor banks only their own pouch while sharing event progress |
| Mobile | Wayhome action and feedback remain reachable without covering movement controls |
| Streaming | the town return never places a player over unloaded collision |
| Privacy | logs contain IDs, counts, outcomes, and latency only; never full profiles |

Do not mark this increment or Milestone 3 playtested from headless checks alone.
