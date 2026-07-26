# Milestone 3 Bramblewake active-event increment

## Scope

This increment activates the four representative event sockets in the current
Bramblewake route. It does not mark the vertical slice complete. The complete
eight-event regional catalog, full inventory/crafting, professions,
combat roster, boss, nights, town tier, and final production art remain later
Milestone 3 work.

Implemented in source:

- four server-owned, optional event lifecycles with dormant, active, completed,
  failed, and disabled states;
- 13 stable interaction steps distributed across the four events;
- shared solo/group contributions with duplicate-delivery idempotency;
- deterministic reward transaction IDs derived from run, manifest, and event IDs;
- a durable unbanked profile pouch plus server-session fallback ledger;
- event start, completion, failure, rejection, and reward-grant telemetry;
- server distance, expedition-state, payload-shape, and global rate validation;
- an event-layer kill switch that disables prompts without invalidating a seed;
- live objective, step progress, time remaining, resolution, and reward feedback
  through the existing One Active Trail composition;
- distinct event props and readable completed/failed world states;
- pure lifecycle tests and Studio DataModel contract assertions.

The follow-on [inventory and extraction increment](MILESTONE_3_INVENTORY_EXTRACTION.md)
persists this pouch, migrates schema-1 profiles, and banks it at Wayhome Gate.
Recovery caches and the full inventory/crafting interface remain later work.

## Event contracts

| Event | Shared steps | Window | Session reward | Safe failure |
|---|---:|---:|---|---|
| Moving Hedge | 3 root latches | 90 s | 4 Heartwood | side cache closes; main path stays open |
| Lost Wagon | 3 wagon braces | 120 s | 3 Meadow Fiber | wagon reward is lost; no resident is removed |
| Root Bridge | 3 living knots | 105 s | 2 Amber Sap | optional shortcut closes; amber path stays open |
| Foxlight Trail | 4 foxlights | 100 s | 2 Brightcap | hidden memory sleeps; extraction stays reachable |

Every event has a default profession-independent solution. More players divide
the same work instead of increasing health or required taps. Event geometry is
placed off the critical path, so timeout, feature disable, or streamed-out props
cannot make arrival-to-extraction traversal impossible.

## Authority and retry behavior

The client sends only the stable interaction ID. The server resolves the known
prompt, verifies it is enabled and in range, rejects extra payload fields and
remote spam, checks that the player is inside Bramblewake, and advances the
matching event step.

Each step can commit once. Duplicate delivery returns the existing result and
cannot advance progress or grant again. Completion creates one transaction ID:

```text
event_reward:<run ID>:<manifest hash>:<event ID>
```

Each contributing user can receive that transaction once. Profile persistence
and the server-session fallback share the same stable transaction ID.

## Windows Studio journey

1. Run `npm test`, then open `build/LastLightTest.rbxlx`.
2. Press Play and confirm Output contains
   `[Last Light] PASS FoundationIntegration`.
3. Complete First Light, enter the Bramblewake beacon, and traverse the full
   route.
4. At each event, confirm the active objective replaces generic trail guidance.
5. Complete every marked prop and confirm progress changes exactly once.
6. Repeatedly tap an already-completed prop and confirm no extra progress or
   reward appears.
7. Complete the event and confirm remaining prompts disable, props change to the
   completed state, and the HUD returns to route guidance.
8. In a new server, start an event and let it expire. Confirm its props disable
   and the amber critical path and Wayhome Gate remain reachable.
9. In local/test Studio, override `bramblewake_events_enabled` to false before
   service start. Confirm all four sockets remain visually present, prompts are
   disabled, and the full route remains traversable.
10. Inspect server Output for event lifecycle and reward transaction logs without
    raw profile data.

## Device, multiplayer, and abuse gate

Record evidence before this increment is called playtested:

| Gate | Required evidence |
|---|---|
| Baseline phone | every event prop can be selected with one thumb; buttons do not overlap Roblox controls |
| Largest text | objective, progress, and contextual action remain usable without hiding movement |
| Keyboard/controller | live input switching updates the same contextual action without event reset |
| Solo | all four events can complete inside their windows without a profession ability |
| 2 and 4 players | different players contribute simultaneously and every contributor receives exactly one session reward |
| 8 players | prompt selection remains readable and remote traffic stays bounded |
| Timeout | every event fails clearly while the critical path and extraction remain open |
| Streaming | event props streaming out never blocks movement or grants phantom progress |
| Abuse | forged IDs, out-of-range actions, duplicate steps, extra fields, and spam fail safely |
| Performance | event props keep the generated route inside its part budget on the baseline phone |

Do not promote this increment or Milestone 3 from automated checks alone.
