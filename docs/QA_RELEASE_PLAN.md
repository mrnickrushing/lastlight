# QA and release plan

## Quality strategy

Last Light is considered healthy only when gameplay, data, commerce, input,
accessibility, performance, networking, moderation, and operations agree. Testing
one player in Studio is an early check, not release evidence.

## Severity

| Severity | Meaning | Examples |
|---|---|---|
| Blocker | release cannot proceed | save loss, purchase loss, cannot join, policy violation |
| Critical | widespread severe harm | duplication exploit, impossible story path, crash loop |
| High | major feature failure | boss cannot finish, mobile controls blocked, migration error |
| Medium | degraded but recoverable | incorrect quest marker, cosmetic clipping, audio gap |
| Low | polish issue | minor animation pop, noncritical wording |

Blocker and critical defects trigger rollback or stop-ship. High defects require
explicit triage and cannot accumulate on critical paths.

## Automated validation

### Repository

- required files and valid JSON;
- local Markdown links;
- formatting and lint;
- Luau type checks;
- pure unit tests;
- build of every place/project mapping;
- no forbidden binary place files or secrets;
- stable content ID and cross-reference validation.

### Content schemas

Validate:

- unique IDs and localization keys;
- prerequisites and unlock cycles;
- region/module/POI/event references;
- item, recipe, material, station, salvage, and source references;
- quest state graph reachability and terminal states;
- resident job/building compatibility;
- enemy encounter and boss arena requirements;
- feature flag and kill switch;
- analytics key;
- asset bundle and budget metadata.

### Pure-system tests

- phase state transitions and timer reconciliation;
- profession/gear/effect calculations;
- crafting and building transactions;
- quest idempotency;
- reward and ending idempotency;
- save migrations;
- rate limits and remote schemas;
- party contribution and scaling;
- trade atomicity;
- purchase receipt retries;
- generator graph invariants and deterministic replay.

## Procedural world tests

For every content build:

- generate at least 10,000 manifest graphs per changed region;
- assemble a representative 1,000 in the Studio harness;
- assert arrival→objective→extraction connectivity;
- assert required objective count and sources;
- assert no locked traversal dependency;
- assert safe spawn and recovery volumes;
- assert nav path and clearance;
- assert boss/elite arena bounds;
- assert streaming cells and persistent model budget;
- assert no incompatible events overlap;
- assert disabled IDs never appear;
- assert known-good fallback always builds.

Human exploratory passes sample shortest, longest, highest-risk, and rarest seeds.
Every reported impossible seed is retained as a regression fixture.

## Multiplayer matrix

Run critical content at:

- solo;
- 2 players;
- 4 players;
- 8 players;
- late join at every phase;
- disconnect/reconnect during expedition, boss, reward, teleport, and construction;
- host leave;
- mixed progression and profession levels;
- mixed device/input party;
- high simulated latency and packet loss where tooling permits.

Observe threat complexity, boss health/time, revive possibility, reward fairness,
lane coverage, resident support, and server heartbeat.

## Input and UI matrix

For every critical flow:

- touch with dynamic thumbstick;
- touch with classic thumbstick;
- touch with tap-to-move if supported;
- touch device with connected controller;
- keyboard/mouse;
- controller with focus navigation;
- input change while menu/action is active;
- smallest phone, notched phone orientations, tablet, desktop, ultrawide, console;
- largest preferred text size;
- reduced motion, reduced flash, low effects, muted audio;
- color-blind and low-vision simulations;
- long localized strings and missing localization fallback.

Test screen insets, Roblox menu overlap, thumb reach, back/cancel, double tap,
hold cancel, menu reopening, selection persistence, and network rejection.

## Gameplay completion matrix

Every chapter requires:

- clean fresh-save path;
- returning/migrated save path;
- solo and group;
- normal and assisted timing;
- each profession primary;
- no-profession-specific default solution;
- chapter decision variants;
- boss failure and retry;
- disconnect at each checkpoint;
- post-chapter town change and recap;
- content disabled fallback.

Every quest requires start, every objective order allowed by design, abandon,
failure, reconnect, completion, duplicate completion, reward retry, and migration.

## Save and migration tests

Fixtures:

- brand new;
- tutorial in progress at each step;
- each town tier;
- each chapter boundary and decision;
- full/empty inventory;
- all profession/companion/resident states;
- pending transaction;
- processed and pending receipt;
- active event;
- legacy versions;
- deliberately malformed recoverable data.

Scenarios:

- two-server profile contention;
- datastore timeout/throttle;
- crash before/after transaction apply;
- shutdown with many dirty profiles;
- migration rerun;
- migration failure and rollback;
- lost client response followed by retry;
- stale revision;
- restore from backup;
- support repair tool with audit.

No schema ships without before/after fixtures and rehearsal against a copy of
production-shaped data.

## Commerce tests

- product info unavailable;
- prompt canceled;
- platform purchase completed;
- receipt arrives before/after profile load;
- duplicate receipt;
- receipt retry across servers;
- inventory full;
- ownership already present;
- profile save failure;
- server shutdown mid-grant;
- client disconnect;
- pending mailbox delivery;
- product disabled during prompt;
- cosmetic preview/equip and low-effects behavior.

Expected result is either no charge/grant or exactly one durable grant. UI must
never declare success before authoritative receipt processing.

## Security tests

- call every remote with wrong types, missing fields, extra fields, oversized
  strings/tables, NaN/infinite numbers, and out-of-range enums;
- spam, burst, replay, and reorder requests;
- interact/build/craft/trade outside distance, ownership, phase, or capacity;
- report impossible damage, cooldown, movement, target, or reward;
- spoof admin, party host, visitor permission, or product ownership;
- modify trade after confirmation;
- replay teleport and reward tokens;
- attempt disabled content IDs;
- attempt development commands in production.

Security logging must be useful without leaking thresholds or collecting
unnecessary personal data.

## Performance testing

### Baseline hardware

Select and record:

- one low-end supported Android phone;
- one representative iPhone;
- one tablet;
- one average desktop;
- one console/controller setup.

The exact baseline is a product decision during vertical slice and remains in
the performance dashboard.

### Scenarios

- cold and warm join;
- town tier 0 and fully decorated tier 7 at cap;
- day expedition in every region;
- dusk return with streaming transition;
- maximum normal night;
- every Blackout and boss peak;
- 8-player cosmetics at allowed intensity;
- 60-minute and 3-hour soak;
- repeated menu/open-close;
- teleport loop in staging;
- low network bandwidth and latency;
- minimum and maximum graphics.

Record FPS/frame time, memory categories, server heartbeat, physics, network
send/receive, instance count, draw calls/triangles when available, script time,
join stages, streaming stalls, and disconnect/crash.

Do not use Studio emulator memory as hardware evidence.

## Accessibility review

- critical state has text/icon/shape and sound alternatives;
- captions cover danger, ally down, phase, objective, and story;
- text respects preferred size or documents unavoidable limits;
- no clipping or inaccessible scrolling;
- reduced motion/flash affects all registered systems;
- color is not the only indicator;
- timers allow assisted timing or alternate completion where appropriate;
- repeated tapping has hold/toggle alternative;
- camera and shake controls work;
- story and rewards remain available with assists.

Include disabled players or specialized reviewers when possible; simulations do
not replace lived experience.

## Narrative and content review

- continuity across chapter decisions and ending states;
- resident availability and dialogue schedule;
- no dead name/key references;
- critical fact redundancy;
- recap accuracy;
- age-appropriate fear and grief presentation;
- original-IP and asset provenance;
- localization context and cultural review;
- no premium copy exploiting loss, guilt, or urgency.

## Analytics validation

- event fires once at the correct semantic moment;
- required fields and schema version;
- experiment exposure before affected outcome;
- no raw private communication or full save payload;
- no duplicate completion/revenue from retries;
- dashboards correctly segment platform, progression, solo/group, and version;
- alert thresholds tested with synthetic events;
- kill-switch use is visible.

## Release checklist

### Code and content

- required checks green on exact release commit;
- branch merged and local/remote `main` synchronized;
- release tag and build manifest;
- all content schemas and counts pass;
- blocker/critical zero;
- known high issues explicitly resolved or stop-ship;
- feature flags and defaults reviewed.

### Roblox configuration

- correct universe and start place;
- all place versions published and linked;
- streaming and orientation settings verified in published place;
- permissions, API access, localization, age/content disclosures;
- products/passes IDs, prices, images, descriptions, and active state;
- private-server configuration;
- badges/achievements;
- icons, thumbnails, trailer, title, description;
- test products separated from production.

### Operations

- dashboards and alerts live;
- save backups and migration plan;
- rollback build and commands;
- support, moderation, commerce, data, and performance owners;
- incident channel and communication template;
- content and offer kill switches tested;
- canary cohort/servers selected;
- patch notes and known issues.

### Journey smoke tests on published candidate

- new free player;
- returning player;
- migrated profile;
- solo and 8-player party;
- invited visitor;
- every supported device/input class;
- one cosmetic payer and entitlement restore;
- chapter/expedition teleport and reconnect;
- store disabled and event disabled fallback;
- ending completion and continued play.

## Staged rollout

Release to progressively larger cohorts. At each stage review:

- join and save health;
- crash/disconnect and performance by platform;
- onboarding and first-night completion;
- impossible seed/generator fallback;
- reward/receipt anomalies;
- exploit and moderation signals;
- difficulty and solo/group gaps;
- player reports.

Promotion pauses if quality is uncertain. A smaller healthy audience is preferable
to amplifying a save, purchase, performance, or onboarding failure.

## Incident response

1. Confirm scope and protect evidence.
2. Activate kill switch, stop promotion, or rollback.
3. Protect saves/economy; disable risky grants or trading.
4. Communicate a plain status without guessing.
5. Repair and validate against a reproduction fixture.
6. Migrate/restore affected players idempotently.
7. Canary the fix.
8. Publish incident summary and prevention action.

