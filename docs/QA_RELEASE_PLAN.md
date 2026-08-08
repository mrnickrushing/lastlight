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

The executable first-session checks and evidence table are in
[MILESTONE_2_PLAYTEST.md](MILESTONE_2_PLAYTEST.md).

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
- archived receipt replay after hot-ledger compaction;
- cosmetic preview/equip and low-effects behavior.

A canceled platform prompt produces no receipt and no grant. A completed
platform purchase remains pending with `NotProcessedYet` until it produces
exactly one durable grant and an archived `PurchaseId` tombstone. Duplicate
delivery, cross-server retry, shutdown, full inventory, and archive replay must
return the original result without a second grant. UI must never declare success
before authoritative receipt processing.

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
- original-IP and asset provenance, against [ASSET_PROVENANCE.md](ASSET_PROVENANCE.md);
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

This is the checklist `scripts/validate_launch_checklist.py` reads, and it is a
table rather than prose bullets for one reason: **a bullet cannot be unticked.**
"Complete launch checklist" is M14's deliverable, and a prose list is completed
by whoever says it is.

Four things a row can say, and the vocabulary is the whole design:

- **`check`** — the repository decides this one. The evidence column names a
  check that runs in `npm run test`, and the validator confirms that check still
  exists. An item whose check was renamed away stops being satisfiable on the
  day of the rename rather than on release day.
- **`done`** — a human did it and the evidence column records what they did.
- **`open`** — not done.
- **`n/a`** — deliberately out of scope, with the reason in the evidence column.
  A reason is required because `n/a` is the cheap way past a blocker.

**Nothing here fails a build until a launch candidate is declared.** Almost every
row below is owner-gated — a Creator Dashboard is not a thing a validator can
tick — so a checklist enforced from the day it lands would fail `npm run check`
forever and be switched off within a week. `Config.LaunchCandidate` is `nil`
today, exactly the way `Config.SaveSchemaFreeze` is, and setting it turns the
blocking rows into a gate. What *is* live from day one is the structure: every
row parses, every `check` row names a check that exists, every `done` and `n/a`
row carries evidence, and the counts are pinned so a blocker cannot be quietly
downgraded into `n/a` or into somebody's opinion.

Declaring a candidate also requires the schema freeze to be set. A launch
candidate whose save schema is still moving is the exact failure M14 wave A
exists to prevent, and the two declarations are one act.

### Code and content

| Item | Blocking | Status | Evidence |
|---|---|---|---|
| `release_checks_green` | yes | check | `npm run test` |
| `content_schemas_and_counts` | yes | check | `ContentCensus.spec` |
| `save_schema_frozen` | yes | check | `scripts/validate_schema_freeze.py` |
| `monetization_guard_holds` | yes | check | `scripts/validate_monetization.py` |
| `asset_provenance` | yes | check | `scripts/asset_provenance.py` |
| `main_synchronized` | yes | open | Owner: release branch merged, local and remote `main` at the release revision |
| `release_tag_and_manifest` | yes | open | Owner: tag the release commit and record the build manifest |
| `blocker_critical_zero` | yes | open | Owner: triage record showing no open blocker or critical defect |
| `known_high_issues_resolved` | yes | open | Owner: every open high defect explicitly resolved or stop-ship |
| `feature_flag_defaults_reviewed` | yes | open | Owner: [BETA_ROLLOUT.md](BETA_ROLLOUT.md) read row by row against the shipping config |

### Roblox configuration

Every row here is a Creator Dashboard field. None of them can be read from this
repository, which is why they are all owner rows: a validator that claimed to
have checked a thumbnail would be worse than one that says it cannot.

| Item | Blocking | Status | Evidence |
|---|---|---|---|
| `universe_and_start_place` | yes | open | Owner: correct universe and start place |
| `place_versions_published` | yes | open | Owner: every place version published and linked |
| `streaming_and_orientation` | yes | open | Owner: verified in the published place, not in Studio |
| `permissions_and_api_access` | yes | open | Owner: permissions and API access set for production |
| `age_and_content_disclosures` | yes | open | Owner: age and content disclosures submitted |
| `localization_configured` | yes | open | Owner: supported languages set from [BETA_ROLLOUT.md](BETA_ROLLOUT.md)'s language decision |
| `product_ids_and_prices` | yes | open | Owner: product IDs, prices, images, descriptions and active state; `Config.CommerceProductIds` filled from them |
| `test_products_separated` | yes | open | Owner: test products separated from production |
| `private_server_configuration` | yes | open | Owner: private-server configuration |
| `badges` | no | open | Owner: badges and achievements. Not blocking — the game ships without one |
| `icon_thumbnails_trailer` | yes | open | Owner: icon, thumbnails, trailer, title and description |

### Operations

| Item | Blocking | Status | Evidence |
|---|---|---|---|
| `dashboards_and_alerts_live` | yes | open | Owner: dashboards built from [MONETIZATION_LIVEOPS_ANALYTICS.md](MONETIZATION_LIVEOPS_ANALYTICS.md) and alerting |
| `save_backups_and_migration_plan` | yes | open | Owner: backup cadence and the migration plan for the release |
| `rollback_build_and_commands` | yes | check | `KillSwitches.spec` |
| `owners_named` | yes | open | Owner: support, moderation, commerce, data and performance owners named |
| `incident_channel_and_template` | yes | open | Owner: incident channel and communication template |
| `kill_switches_tested` | yes | open | Owner: content and offer kill switches exercised in a live server, per [ROLLBACK.md](ROLLBACK.md) |
| `canary_cohort_selected` | yes | open | Owner: canary cohort and servers selected |
| `known_issues_published` | yes | check | `npm run notes` |
| `patch_notes` | yes | open | Owner: patch notes in a player's language. [RELEASE_NOTES.md](RELEASE_NOTES.md) is a developer changelog and deliberately not this |

### Journey smoke tests on published candidate

These are the seven launch journeys, and they are one row each rather than one
row for the set, because "smoke tested" passing on six of seven is the shape of
every launch-day surprise.

| Item | Blocking | Status | Evidence |
|---|---|---|---|
| `journey_new_player` | yes | open | Owner: new free player, published candidate |
| `journey_returning_player` | yes | open | Owner: returning player |
| `journey_migrated_profile` | yes | open | Owner: migrated profile |
| `journey_group` | yes | open | Owner: solo and 8-player party |
| `journey_visitor` | yes | open | Owner: invited visitor |
| `journey_payer` | yes | open | Owner: one cosmetic payer and an entitlement restore |
| `journey_device_classes` | yes | open | Owner: every supported device and input class |
| `journey_teleport_reconnect` | yes | open | Owner: chapter and expedition teleport, then reconnect |
| `journey_disabled_fallbacks` | yes | open | Owner: store disabled and event disabled fallback |
| `journey_ending_and_continue` | yes | open | Owner: ending completion and continued play |

## Staged rollout

Release to progressively larger cohorts. The shared measurement window,
minimum sample sizes, promotion thresholds, pause rules, and immediate rollback
triggers are defined in [RELEASE_GATES.md](RELEASE_GATES.md) and are the
authoritative release decision. At each stage also review:

- join and save health;
- crash/disconnect and performance by platform;
- onboarding and first-night completion;
- impossible seed/generator fallback;
- reward/receipt anomalies;
- exploit and moderation signals;
- difficulty and solo/group gaps;
- player reports.

Promote only after every applicable gate has passed for the complete measurement
window. Pause expansion when any non-zero-tolerance gate fails or lacks its
minimum sample. Immediately rollback or disable the affected system for any
zero-tolerance failure. A smaller healthy audience is preferable to amplifying a
save, purchase, performance, or onboarding failure.

## Incident response

1. Confirm scope and protect evidence.
2. Activate kill switch, stop promotion, or rollback.
3. Protect saves/economy; disable risky grants or trading.
4. Communicate a plain status without guessing.
5. Repair and validate against a reproduction fixture.
6. Migrate/restore affected players idempotently.
7. Canary the fix.
8. Publish incident summary and prevention action.
