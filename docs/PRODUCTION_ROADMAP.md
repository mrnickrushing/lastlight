# Production roadmap

## How to use this roadmap

Milestones are gates, not calendar promises. Work may overlap when dependencies
allow, but a later milestone cannot hide an unfinished earlier gate. The vertical
slice is the quality bar for the full game.

Every milestone closes with:

- scoped code/content merged through a green pull request;
- automated checks;
- recorded Studio and device playtest evidence;
- updated content and decision documents;
- known issues triaged;
- performance, accessibility, save, security, and analytics impact reviewed;
- a playable build tag or private Roblox version.

## Milestone 0 — Blueprint and repository

### Deliverables

- complete game, world, content, technical, UX, art/audio, economy, roadmap, and
  QA documents;
- Rojo project mapping;
- source directories and bootstrap stubs;
- validation workflow;
- original-IP, ethical monetization, mobile, and delivery rules.

### Exit gate

- `npm test` passes locally and in GitHub Actions;
- all documents link correctly;
- repository `main` is clean and default-ready;
- the README states clearly that implementation has not begun.

## Milestone 1 — Toolchain and executable foundation

### Deliverables

- pin Rojo, StyLua, Selene, Luau language/test tooling, and package manager;
- local bootstrap command and CI cache;
- test framework with one pure and one Studio integration test;
- typed service/bootstrap pattern;
- content schema validator and stable-ID registry;
- environment configuration: local, test, staging/private, production;
- feature flag and logging interfaces;
- place creation/publishing runbook without committing binary place files.

### Exit gate

- clean clone can install, validate, build a place, and serve to Studio;
- boot completes without warnings or infinite yields;
- intentional lint/type/test failures fail CI;
- tool versions and upgrade process are documented.

## Milestone 2 — Graybox first ten minutes

**Implementation status (2026-07-25):** source, automated tests, game/test-place
builds, and DataModel verification are implemented. The exit gate remains open
until the Windows Studio, real-device, reconnect, accessibility, performance,
and ten-new-tester evidence in
[MILESTONE_2_PLAYTEST.md](MILESTONE_2_PLAYTEST.md) is recorded. Do not promote
this milestone to complete from CI alone.

### Deliverables

- arrival area and bounded loader;
- touch, keyboard/mouse, and controller movement/actions;
- one gather node, one rescue, one tool choice, one construction plot;
- Mara's tutorial behavior;
- one enemy and one two-minute authored night;
- first reveal and persistent tutorial completion;
- context-sensitive HUD prototype plus compact fallback;
- basic analytics funnel.

### Exit gate

- 10 new testers can finish without verbal help;
- no player falls forever, spawns outside loaded collision, or waits for the world;
- tutorial survives death, disconnect, input change, and rejoin;
- baseline phone reaches interactive play and performance targets;
- largest supported text does not obscure required controls.

## Milestone 3 — Bramblewake vertical slice

**Increment status (2026-07-26):** the expedition foundation, first active
event layer, and durable extraction settlement are implemented in source: 12
representative modules, four POIs,
four active events with 13 shared steps, deterministic assembly, a known-good
fallback, 1,000-seed invariants, streamed preview geometry, beacon entry,
recovery, timeout-safe optional routes, schema-v2 unbanked/banked materials,
run-specific reward and settlement tombstones, Wayhome return, kill switch,
telemetry, and HUD progress. Profession kits, full inventory/crafting/quests,
the remaining enemies, elite, boss, normal night, Blackout, town tier, final
art/audio, and all Studio/device/group evidence remain open. See
[MILESTONE_3_EXPEDITION_FOUNDATION.md](MILESTONE_3_EXPEDITION_FOUNDATION.md) and
[MILESTONE_3_BRAMBLEWAKE_EVENTS.md](MILESTONE_3_BRAMBLEWAKE_EVENTS.md), and
[MILESTONE_3_INVENTORY_EXTRACTION.md](MILESTONE_3_INVENTORY_EXTRACTION.md).

### Deliverables

- one complete region with 12 representative modules, 4 POIs, and 4 events;
- deterministic expedition assembly and known-good fallback;
- Scout, Warden, Engineer, and Medic basic kits;
- six Bramblewake enemies, Old Growth elite, Warden Stag boss;
- one normal night and one Bramblewake Blackout;
- town tier 0→1, eight starter buildings, four residents;
- inventory, crafting, gear, quests, codex, dialogue recap;
- down/revive, extraction, failure/recovery;
- day/dusk/night art, music, captions, reduced effects;
- server-authoritative validation and exploit instrumentation.

### Exit gate

- a fresh save plays start to chapter-one resolution;
- solo, 2-player, 4-player, and 8-player passes complete;
- 1,000 automated seeds pass connectivity and content invariants;
- duplicate reward, remote spam, damage spoof, and invalid build tests fail safely;
- no critical placeholder UI/audio/art remains in the slice;
- target device meets frame, memory, join, and network budgets for a 30-minute run.

**Decision gate:** approve full production only if the slice is fun, readable,
technically healthy, and shows credible D1 intent in closed testing.

## Milestone 4 — Persistent town platform

### Deliverables

- versioned profile, locking, autosave, shutdown, migrations, backups;
- Emberhollow tiers 0–3 and functional district loop;
- 16 initial buildings through their first functional tiers;
- resident schedules, jobs, injury, relationships, and crisis framework;
- construction orders, damage, repair, storage, and decoration caps;
- host/visitor permissions and town visit flow;
- reconnect and conflict handling;
- admin save inspection and safe repair tooling with audit logs.

### Exit gate

- migration fixtures cover every released schema;
- forced crashes, lock contention, write failure, stale revision, and shutdown pass;
- visitors cannot modify or steal without permission;
- town remains navigable under every allowed building state;
- no functional progress requires premium cosmetics.

## Milestone 5 — Expedition platform

### Deliverables

- full 30-module Bramblewake set and production authoring tools;
- seed history and repetition control;
- contracts, risk modifiers, weather, extraction, recovery cache;
- reserved-server teleport and reconnect tokens if multi-place decision approved;
- module gallery and automated validator;
- event compatibility, encounter sockets, navigation verification;
- streaming-safe objective and interaction lifecycle.

### Exit gate

- 10,000 headless graph manifests and 1,000 Studio assemblies pass invariants;
- teleport failure returns parties safely without duplicated rewards;
- a target sample of expeditions stays within length and repetition budgets;
- all traversal objectives have default, profession-independent solutions;
- content can be disabled by ID without breaking generation.

## Milestone 6 — Complete systemic foundation

### Deliverables

- all seven professions through rank 10;
- six weapon and eight tool families;
- crafting, equipment traits, repair, loadouts, status/reaction system;
- companion behavior and commands;
- enemy director with solo/group complexity scaling;
- defense plots, lanes, traps, resident defenders;
- complete quest types and relationship framework;
- safe restricted trading if it survives risk review.

### Exit gate

- each profession finishes slice content solo and contributes in every party size;
- no single family dominates success beyond balance threshold;
- every transaction is idempotent and exploit tested;
- combat telegraph, cancel, hit validation, and latency tests pass;
- NPC and companion navigation recover from blocked and streamed paths.

## Milestone 7 — Region production wave A

### Scope

- Ironroot Delve and Mireglass Fen;
- chapters II and III;
- eight named residents;
- remaining basic profession kits;
- 60 modules, 24 POIs, 16 events, 12 enemies, 4 elites, 2 bosses;
- town tiers 2–4 and associated buildings.

### Exit gate

- continuous fresh-save path through chapter III;
- region transitions, saves, and decisions persist;
- every module passes mobile, art, collision, navigation, and performance review;
- both Blackouts pass solo and group recovery tests;
- no region is a reskin: traversal, hazards, resource decisions, and boss structure differ.

## Milestone 8 — Region production wave B

### Scope

- Tempest Reach and Frostmere Vale;
- chapters IV and V;
- eight named residents;
- 60 modules, 24 POIs, 16 events, 12 enemies, 4 elites, 2 bosses;
- town tiers 4–5, observatory, harbor, weather, cold infrastructure.

### Exit gate

- continuous path through chapter V;
- water, wind, lightning, snow, warmth, noise, and weather have low-end variants;
- captions and reduced-flash tests cover storms and silence mechanics;
- streaming and physics remain within budgets.

## Milestone 9 — Region production wave C and finale

### Scope

- Cinderfall Crown and The Hollow Below;
- chapters VI and VII, three ending states, epilogue;
- final eight residents including Orin;
- 30 surface modules, 12 POIs, 8 events, authored finale;
- 12 standard enemies, 4 elites, 2 bosses;
- town tiers 6–7 and all 28 buildings;
- postgame region and resident states.

### Exit gate

- start-to-finish fresh save with every ending variation;
- all chapter decision combinations map to valid finale content;
- finale resumes safely from each checkpoint after disconnect;
- ending rewards are idempotent and continued play retains the town;
- no placeholder critical content.

## Milestone 10 — Content completion

### Deliverables

- all 180 recipes;
- all 18 companions;
- all 24 resident arcs;
- 42 mysteries, 36 contract templates, 18 crises, 21 mastery trials;
- all building tiers and earned cosmetic sets;
- codex, archive recap, tutorials, practice, achievements;
- complete sound, music, VFX, animation, icon, and localization source coverage.

### Exit gate

- content validator meets every catalog count;
- every source, sink, unlock, prerequisite, and reward reference resolves;
- automated traversal checks plus human completion cover every quest;
- repetition, economy, progression, and difficulty targets pass full-save simulation.

## Milestone 11 — Social and commerce readiness

### Deliverables

- stable parties, invites, rejoin, pings, quick chat, visits, showcases;
- moderation, block/report interactions, privacy permissions;
- reviewed trade system or explicit post-launch deferral;
- cosmetic store, preview, entitlements, receipt processing, pending mailbox;
- initial direct cosmetic catalog and private-server controls;
- support/refund/removal procedures and commerce analytics.

### Exit gate

- social systems pass privacy and abuse review;
- trade cannot duplicate, swap after confirmation, or move locked items;
- every receipt scenario grants exactly once;
- store never interrupts onboarding, active defense, downed state, or defeat;
- no product grants power or confuses price/permanence.

## Milestone 12 — Internal alpha

### Objectives

Feature- and content-complete, not necessarily tuned or launch-polished.

### Work

- daily full-path playtests;
- progression and economy simulation;
- save migration rehearsal from every internal version;
- device lab and long-session soak;
- exploit and admin review;
- narrative continuity and content sensitivity review;
- crash, analytics, alert, and support dashboard validation.

### Exit gate

- no blocker/critical defects;
- all high defects have owners and bounded fixes;
- complete content path works on production-like services;
- save-loss and purchase-loss rate is zero in forced scenario suite;
- performance and disconnect targets hold under representative concurrency.

## Milestone 13 — Closed beta

### Rollout

1. team and trusted testers;
2. small allowlist across device and age-range guardian consent;
3. larger cohort with controlled feature flags;
4. creator/community test only after moderation and scale health.

### Decisions

- validate fun and comprehension before optimizing monetization;
- tune first session, first night, difficulty cliffs, group scaling, and repetition;
- remove features that create recurring confusion or operational risk;
- finalize supported languages from localization QA capacity;
- finalize launch catalog and prices after clarity review.

### Exit gate

- the closed-beta measurement window, cohort minimums, onboarding, first-night,
  retention, reliability, device-segment, generation, and commerce thresholds
  in [RELEASE_GATES.md](RELEASE_GATES.md) all pass;
- moderation, customer support, incident, rollback, and communication drills pass.

## Milestone 14 — Launch candidate

### Deliverables

- final icon, thumbnails, trailer, description, age/content disclosures;
- Creator Dashboard configuration, permissions, private servers, products;
- production places and universe links;
- final localization, captions, policy, and original-asset audit;
- frozen save schema except blocker fixes;
- release notes, known issues, dashboards, on-call contacts;
- rollback build and feature-flag matrix.

### Exit gate

- complete launch checklist in [QA_RELEASE_PLAN.md](QA_RELEASE_PLAN.md);
- canary and scale tests pass;
- fresh account, returning account, migrated account, payer, non-payer, solo, and
  group journeys pass;
- required Roblox publishing/review configuration is confirmed in Creator Dashboard.

## Milestone 15 — Staged public launch

### Stages

1. minimal discoverability with monitored servers;
2. controlled promotion after service health;
3. broader discovery assets after retention and quality health;
4. first event only after ordinary play is stable.

### Rollback triggers

- any immediate rollback trigger or sustained critical-threshold breach defined
  in [RELEASE_GATES.md](RELEASE_GATES.md);
- severe exploit affecting economy, progression, policy, or safety.

Rollback means disable affected content/system, revert to known-good version, stop
promotion, communicate status, preserve evidence, repair/migrate, and only then
resume.

## Milestone 16 — Live service

### First 30 days

- prioritize reliability, onboarding, difficulty, repetition, and device health;
- publish small fixes behind canaries;
- do not add a seasonal journal until the base loop is healthy;
- review economy and purchase support daily initially;
- gather qualitative player stories, not only session length.

### Ongoing content

- recombine systems before adding new permanent complexity;
- ship new events with kill switches and archive rules;
- add chapters without resetting towns or invalidating gear;
- maintain original-IP, accessibility, localization, and performance review;
- deprecate content through migration and communication, never silent deletion.

## Staffing and production reality

The full scope is a substantial commercial game. A realistic team eventually
needs ownership for:

- game/product direction;
- server/data/commerce engineering;
- client/UI/input engineering;
- world and encounter design;
- environment, character, UI, VFX, and animation art;
- audio/music;
- narrative and localization;
- QA, device/performance, security, analytics, economy, moderation, and support.

A smaller team can build it by holding the milestone gates and reducing concurrent
content production. It cannot make the same scope safe merely by skipping QA,
mobile work, data architecture, or content polish.
