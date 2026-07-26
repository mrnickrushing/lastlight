# Technical architecture

## Architecture goals

- A player reaches interactive Emberhollow within a few seconds on a baseline phone.
- The entire world never needs to load before play begins.
- The server owns every valuable or competitive state transition.
- Content is data-driven, versioned, validated, feature-flagged, and kill-switchable.
- Save writes, receipt processing, teleports, reconnects, and rewards are idempotent.
- Systems remain testable without requiring a full Studio world.
- Mobile performance is a design constraint, not a late optimization pass.

## Roblox universe topology

The target universe uses separate places only when they reduce risk:

1. **Emberhollow start place**
   - personal/host town instance;
   - onboarding, town management, party formation, visiting, store, training;
   - 1–8 active party members, with controlled visitor capacity if scale permits.
2. **Expedition place**
   - reserved server seeded with region, party, contract, town tier, and feature flags;
   - deterministic assembly from authored modules;
   - reconnect token and safe extraction.
3. **Finale place**
   - authored chapter-seven sequence with tighter asset and scripting control;
   - unlocked only through server-validated chapter state.
4. **Test place**
   - unpublished/internal place for content galleries, encounter harnesses, device
     budgets, admin tools, and destructive migration rehearsal.

The vertical slice starts as one streamed place to minimize early teleport
complexity. A decision gate after profiling determines when expedition separation
becomes necessary. This avoids prematurely paying the operational cost of multiple
places while preserving the launch topology.

## Source layout target

```text
src/
  first/
    LoadingController.client.luau
  shared/
    Config.luau
    Types.luau
    Net/
      Actions.luau
      Schemas.luau
    Content/
      Regions/
      Enemies/
      Buildings/
      Items/
      Quests/
      Residents/
    Util/
  server/
    Bootstrap.server.luau
    Services/
      DataService.luau
      ProfileService.luau
      FeatureFlagService.luau
      PartyService.luau
      TeleportService.luau
      PhaseService.luau
      ExpeditionService.luau
      WorldAssemblyService.luau
      TownService.luau
      BuildingService.luau
      ResidentService.luau
      InventoryService.luau
      CraftingService.luau
      CombatService.luau
      EnemyDirectorService.luau
      QuestService.luau
      ProfessionService.luau
      CompanionService.luau
      CommerceService.luau
      AnalyticsService.luau
      ModerationService.luau
      AdminService.luau
  client/
    Bootstrap.client.luau
    Controllers/
      InputController.luau
      HUDController.luau
      InteractionController.luau
      CameraController.luau
      InventoryController.luau
      BuildController.luau
      EffectsController.luau
      AudioController.luau
      AccessibilityController.luau
```

Names are a target, not permission to create empty service sprawl. A service is
added when its milestone has an interface, ownership boundary, and test.

## Server authority

### Client may request

- begin or stop an input action;
- interact with a server-known target;
- choose a dialogue, build, craft, quest, or loadout option;
- submit camera aim or movement intent within rate and sanity limits;
- request inventory/page data;
- acknowledge UI or tutorial state.

### Client never decides

- damage, healing, status application, down/revive, or enemy death;
- item/currency gain or loss;
- recipe validity, construction completion, or structure health;
- quest completion or story state;
- profession XP or mastery rewards;
- teleport destination payload;
- purchase grant or receipt completion;
- trade completion;
- admin privilege;
- event seed, boss completion, or leaderboard score.

### Remote contract

Each remote action declares:

- stable action ID and schema version;
- argument types, size bounds, enums, and string length;
- player state prerequisites;
- per-action and global rate limit;
- ownership, distance, line-of-sight, and phase checks where relevant;
- idempotency token for transactional actions;
- structured rejection reason safe for client display;
- analytics sampling and security severity.

Unknown fields are rejected for transactions. Client-facing errors do not reveal
anti-exploit thresholds.

## Save model

### Profile domains

The save is split logically even if stored in one profile envelope:

```text
meta
  schemaVersion, createdAt, updatedAt, revision
identity
  accountRank, settings, accessibility, tutorial
progression
  chapters, regions, professions, recipes, codex
inventory
  items, materials, equipment, loadouts, currencies
town
  tier, plots, buildings, damage, decorations, residents, decisions
relationships
  resident bonds, companion bonds, completed arcs
commerce
  entitlements, processedReceipts, ownedCosmetics
social
  recentParty, visitPermissions, tradeLocks
experiments
  assignments and exposure versions
```

### Data rules

- Use a schema version and ordered migration pipeline.
- Each migration is pure, repeatable, logged, and tested on fixture saves.
- Profile session locking prevents two servers from mutating one profile.
- Autosaves are staggered; important transactions also mark the profile dirty.
- Shutdown uses `BindToClose` with bounded concurrency and observability.
- A save failure puts affected transactions into a clear retry/pending state.
- Never grant a purchase from a client purchase-finished event; use receipt
  processing and return the correct decision only after durable idempotent grant.
- Keep a bounded processed-receipt ledger and a durable entitlement truth source.
- Backups and export tooling are required before migrations that alter inventory
  or commerce.

### Transaction pattern

For crafting, rewards, building, trades, and purchases:

1. validate request and current revision;
2. derive deterministic transaction ID;
3. reserve or verify inputs;
4. calculate output from server content version;
5. apply exactly once;
6. append audit event;
7. persist or mark safely pending;
8. return the authoritative result.

Retries return the original result rather than duplicating output.

## Expedition generation

### Inputs

- region ID and content version;
- server-generated seed;
- party capabilities and accessibility-safe defaults;
- contract and chapter requirements;
- town tier and unlocked traversal tools;
- recent seed/POI history;
- feature flags and disabled-content list.

### Assembly

1. Choose required spine: arrival, at least one objective, landmark, extraction.
2. Choose length and risk branches from the contract budget.
3. Place modules by typed connectors, bounding volumes, slope, and streaming cells.
4. Place POIs and events only when spatial and incompatibility rules pass.
5. Bake or verify navigation, traversal affordances, encounter volumes, and
   recovery route.
6. Run invariant validator.
7. Publish seed manifest to server systems and a redacted summary to clients.

### Mandatory invariants

- arrival and extraction are connected;
- every required objective is reachable without a premium or profession ability;
- no critical path crosses an unstreamable gap;
- every fall volume has recovery or intentional death handling;
- encounter and safe volumes do not overlap illegally;
- bosses have enough arena clearance;
- spawned resources meet quest minimums;
- module and effect budgets fit the region profile;
- no disabled content ID appears;
- deterministic replay reproduces the same manifest.

Failed generation is discarded before players enter. After a bounded number of
attempts, use a known-good authored fallback seed and alert telemetry.

## Phase and encounter state

`PhaseService` is an explicit server state machine:

```text
Boot → Dawn → Day → Dusk → Night → Resolution → Dawn
                          ↘ Blackout → ChapterResolution
```

Transitions have entry/exit hooks, deadlines, readiness policy, reconnect
behavior, and rollback-safe reward checkpoints. UI consumes a replicated phase
snapshot with server timestamp and does not maintain its own authoritative clock.

The enemy director receives budgets by role, lane, party size, recent performance,
town defense, and device-safe entity caps. It cannot spawn arbitrary models by
name; all encounters reference validated content definitions.

## Input architecture

Gameplay verbs are defined once through Roblox's current cross-platform input
action facilities:

- move, camera, jump, sprint;
- primary, alternate, dodge/guard;
- contextual interact;
- profession ability;
- companion command;
- hotbar selection;
- ping;
- open/close inventory, build, map, and party.

The client detects preferred input changes during play and updates prompts without
resetting action state. Touch buttons avoid default movement zones. PC and
controller bindings are remappable where Roblox permits. Input prompts never
hardcode only one platform's key.

## Streaming and join flow

- `Workspace.StreamingEnabled` is enabled from project creation.
- The arrival room, first lantern, immediate paths, and essential collision use
  appropriate atomic/persistent streaming modes sparingly.
- Distant scenery uses lower detail and does not contain required interactions.
- `ReplicatedFirst` displays a bounded progress state, not “building every world.”
- The client can play in the arrival/tutorial area while optional district assets
  stream.
- Every interaction tolerates a target streaming out or being destroyed.
- Teleports show progress and a cancel/recovery path when Roblox returns failure.
- Join and teleport metrics distinguish network, asset, data, generation, and
  client initialization time.

## Performance budgets

Budgets are finalized on the baseline device during the vertical slice. Initial
targets:

| Metric | Target | Hard investigation threshold |
|---|---:|---:|
| Interactive join, warm network | ≤ 5 seconds | > 8 seconds |
| Client frame rate, normal play | stable 45+ FPS baseline | sustained < 30 FPS |
| Client frame time spikes | rare and < 50 ms | repeated > 100 ms |
| Server heartbeat | stable 30+ Hz | sustained < 20 Hz |
| Client memory | profiled device headroom ≥ 20% | OOM/reload risk |
| Active combat enemies | director/device tier budget | no unbounded spawn |
| Remote traffic | event-specific budget | per-frame reliable spam |

The team records actual numbers, device model, graphics level, server size, and
content seed. Studio emulator is for layout and controls, not trusted memory data.

### Performance rules

- Pool high-churn effects and cap particles by quality tier.
- Cosmetic VFX run locally when no authoritative state depends on them.
- Avoid expensive unbounded `RunService` work.
- Use spatial queries and tagged collections rather than whole-world scans.
- Use collision groups and simple collision proxies.
- Disable shadows on minor lights/parts according to art budget.
- Use automatic/performance render fidelity and model LOD.
- Stream audio and preload only the first critical set.
- No system waits for every asset in the universe.

## Security and abuse resistance

- Rate-limit by player, action, and server.
- Validate distance, ownership, state, cooldown, inventory, and monotonic counters.
- Keep admin commands in a separate permissioned server module with audit logs.
- Do not ship test teleport, skip, currency, or item grants to public users.
- Development commands require Studio/private-server allowlist plus server-side
  user ID and environment checks.
- Detect impossible movement as evidence, not automatic permanent-ban proof.
- Quarantine suspicious rewards and escalate graduated enforcement.
- Trade uses locked snapshots and atomic two-party confirmation.
- User-generated text uses platform filtering and bounded display.
- External/Open Cloud operations use least privilege and never expose secrets to
  clients or repository.

## Feature flags and kill switches

Every high-risk content/system release supports:

- percentage or allowlist rollout;
- environment and place targeting;
- server-cached last-known configuration;
- default-safe behavior if configuration fails;
- content-ID kill switch;
- economy grant disable;
- purchase offer disable;
- event disable;
- procedural fallback seed;
- client UI hiding plus server enforcement.

Flags cannot be client-authoritative. Assignment is stable per player when an
experiment requires it.

## Observability

Structured events include:

- join stages and failure reason;
- save load/write/migration latency and failure;
- teleport attempt/result/recovery;
- phase start/end and director budget;
- expedition seed manifest hash and validation retries;
- quest objective and reward transaction;
- craft/build/trade/purchase transaction ID and outcome;
- remote rejection counters by category;
- client FPS/memory tier samples with consent/platform policy;
- crash/disconnect context available through Roblox analytics;
- content kill-switch activation.

Never log raw chat, secrets, full save payloads, or unnecessary personal data.

## Test boundaries

Pure modules cover:

- content schema and references;
- economy math and recipes;
- quest transitions;
- profession calculations;
- generator graph and invariants;
- phase state machine;
- save migrations and transaction idempotency;
- rate limit and remote validation.

Studio integration covers:

- streaming and interaction destruction;
- replication and late join;
- multiplayer combat and revive;
- physics, navigation, building, and enemy behavior;
- receipt and teleport mocks;
- device UI and input switching.

Production canaries verify real data, teleport, scale, analytics, and commerce
without exposing unfinished content broadly.

