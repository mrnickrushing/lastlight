# Last Light

**Build by day. Survive by night. Bring everyone home.**

Last Light is an original 1–8 player cooperative Roblox survival-town adventure.
Players explore a changing wilderness, rescue people, gather materials, develop
professions, rebuild a persistent lantern town, and defend it from creatures that
arrive after sunset. Every seventh defense is a rule-changing **Blackout** that
advances the central mystery beneath the town.

This repository begins with a full production blueprint and is now moving
through implementation milestones. It does **not** yet claim that the complete
playable game exists.

## Current status

**Milestone 2 source implemented; Milestone 3 Bramblewake expedition foundation,
four active events, durable extraction settlement, player rescue, combat
mobility, six-enemy first-night roster, four basic profession kits, Old Growth,
the Warden Stag, the Bramblewake Blackout, permanent chapter-one resolution, a
repeating town normal-night cycle, a first pair of crafting recipes, a
first pair of consumable gear effects, and a first set of silent quest
milestones implemented; Studio and device exit gates remain pending.**

The repository currently contains:

- the complete launch vision, world, story, systems, content targets, and economy;
- a milestone-by-milestone implementation and release plan;
- mobile, accessibility, performance, security, analytics, and QA gates;
- a pinned Rokit toolchain and reproducible game/test-place builds;
- a bounded mobile loader and safe streamed arrival clearing with fall recovery;
- Mara, Heartwood gathering, three starter tools, a construction plot, barricade,
  First Lantern, six-enemy authored night, and Bramblewake reveal;
- 12 deterministic streamed Bramblewake modules, four POIs, four event sockets,
  a known-good fallback, beacon entry, route progress, and expedition fall recovery;
- four active optional Bramblewake events with 13 shared interaction steps,
  timeout-safe routes, durable unbanked rewards, kill switch, and telemetry;
- save-schema-v8 inventory/profession/mastery/story/town-night/gear/equipment/quest migration,
  run-specific reward tombstones, Wayhome extraction, atomic banking,
  retry-safe settlement, and town return streaming;
- server-owned health, six distinct readable enemy attacks, 30-second downed crawl,
  interruption-safe ally revive, and bleedout-safe town retreat;
- server-owned stamina sprint/dodge, cooldown and protection validation, plus
  circle/lane telegraphs, flank defense, temporary drowsy, and light theft;
- an original procedural Old Growth elite with three exposed phases, two
  lantern-fire shield breaks, lane roots, canopy-fall pressure, rooted movement,
  contextual mobile HUD, and idempotent shared Amber Sap rewards;
- an original three-phase Warden Stag boss gated behind Old Growth, with living
  root cleansing, an explicit harmful antler shortcut, preserved/scarred/harmed
  outcomes, recoverable pressure, and idempotent shared rewards;
- a server-owned Bramblewake Blackout with a recoverable nine-minute target,
  chained rootfire relays, elite/boss integration, present-party Greenward vote,
  and immutable chapter-one outcome persistence;
- a repeating server-owned town day/dusk/night cycle after First Light, with an
  escalating six-enemy wave schedule, a seventh-night telegraph deliberately
  decoupled from Blackout access, a feature kill switch, and a per-player
  night count that survives a server restart;
- a first pair of town crafting recipes that atomically convert banked
  expedition materials into named gear recorded on a player's own profile,
  gated to server-owned benches once First Light is complete;
- a first pair of consumable gear effects — a stacking damage-reduction
  shield and an instant stamina restore — that consume exactly one owned
  item, check their own preconditions before spending it, and are usable
  through dedicated keyboard, gamepad, and touch bindings;
- a first set of three silent quest milestones that auto-claim a material
  reward the moment their already-tracked objective (nights survived,
  items crafted, expeditions settled) is met, with no quest giver or
  accept step;
- persistent free-town selection for Scout, Warden, Engineer, and Medic, with
  server-owned reveal/slow, guard, lantern-repair, and area-heal abilities;
- server-owned tutorial ordering, input validation, sprint, combat, building,
  analytics, save normalization, and published-place tutorial persistence;
- mobile, keyboard/mouse, and controller actions through Roblox's Input Action
  System, with input-aware prompts and a fallback path;
- a context-sensitive safe-area HUD, thumb-sized controls, local compact mode,
  phase countdown, lantern health, dialogue, progress, and pickup feedback;
- typed environment, logging, feature-flag, service-lifecycle, content-registry,
  networking, save-schema, rate-limit, tutorial, and phase foundations;
- 172 pure Luau tests, including 1,000 expedition seeds, plus an expanded Studio
  integration-test place;
- automated documentation, format, lint, type, test, and build validation;
- hosted visual direction reports for the general gameplay, focused
  first-session, and cooperative rescue mobile HUD states.

Milestone 2 is not marked complete until the real engine/device exit gate passes:
ten new testers must finish without verbal help, input switching and rejoin must
survive, the baseline phone must meet the performance target, and largest text
must leave every required control usable. Follow
[the Milestone 2 playtest runbook](docs/MILESTONE_2_PLAYTEST.md).
The scoped Bramblewake foundation and its Studio/device evidence matrix are in
[the Milestone 3 expedition runbook](docs/MILESTONE_3_EXPEDITION_FOUNDATION.md).
The active-event contracts and abuse/device matrix are in
[the Bramblewake event runbook](docs/MILESTONE_3_BRAMBLEWAKE_EVENTS.md).
The save migration, banking, reconnect, and Wayhome gates are in
[the inventory and extraction runbook](docs/MILESTONE_3_INVENTORY_EXTRACTION.md).
The health, downed-state, revive, safe-retreat, and abuse gates are in
[the player survival runbook](docs/MILESTONE_3_PLAYER_SURVIVAL.md).
The stamina, dodge, telegraph, input, latency, and device gates are in
[the combat mobility runbook](docs/MILESTONE_3_COMBAT_MOBILITY.md).
The profession selection, authority, balance, persistence, and device gates are in
[the profession-kit runbook](docs/MILESTONE_3_PROFESSION_KITS.md).
The six-enemy sequence, mechanic, readability, solo-balance, and device gates are in
[the Bramblewake enemy-roster runbook](docs/MILESTONE_3_BRAMBLEWAKE_ENEMIES.md).
The three-phase elite, carried-fire, reward, accessibility, and abuse gates are in
[the Old Growth elite runbook](docs/MILESTONE_3_OLD_GROWTH_ELITE.md).
The three-phase boss, root/antler choice, reward, recovery, mobile, and abuse
gates are in
[the Warden Stag boss runbook](docs/MILESTONE_3_WARDEN_STAG_BOSS.md).
The rootfire relay, overtime recovery, chapter vote, persistence, mobile, and
abuse gates are in
[the Bramblewake Blackout runbook](docs/MILESTONE_3_BRAMBLEWAKE_BLACKOUT.md).
The wave-escalation, determinism, kill-switch, and Blackout-independence gates
for the repeating town cycle are in
[the Normal Night runbook](docs/MILESTONE_3_NORMAL_NIGHT.md).
The recipe authority, atomicity, gating, and persistence gates for the first
crafting recipes are in
[the crafting runbook](docs/MILESTONE_3_CRAFTING.md).
The consumable-effect authority, atomicity, composability, and input-parity
gates for the first gear effects are in
[the gear effects runbook](docs/MILESTONE_3_GEAR_EFFECTS.md).
The claim-authority, idempotence, and no-progress-loss gates for the first
quest milestones are in
[the quests runbook](docs/MILESTONE_3_QUESTS.md).

The current UI direction is documented in the
[Last Light mobile gameplay HUD report](https://www.lazyweb.com/report/lazyweb/a5059523-0d43-4386-b0f5-bda12ca3d7ea/?source=create).
The implementation-specific onboarding refinement is in the
[First-Ten-Minutes mobile HUD report](https://www.lazyweb.com/report/lazyweb/a34ce67d-041e-434b-acb6-0afd4ccf7ef4/?source=create).
The non-modal rescue presentation is grounded in the
[Co-op Rescue HUD report](https://www.lazyweb.com/report/lazyweb/01fb79d9-741c-4685-8786-831be744e372/?source=create).
The stamina, dodge, and targeted attack-warning layer is grounded in the
[Mobile Combat Stamina + Dodge report](https://www.lazyweb.com/report/lazyweb/4e46b6e2-7bef-4633-a7b5-ed7a872da2e8/?source=create).
The safe-town role selector and in-play ability layer are grounded in the
[Profession Selector + Ability HUD report](https://www.lazyweb.com/report/lazyweb/73595230-6584-431c-8d84-c7eb06fdeaa5/?source=create).
The six-enemy telegraph hierarchy is grounded in the
[Bramblewake Mobile Combat Callouts report](https://www.lazyweb.com/report/lazyweb/094ebe85-c65a-4a8a-908f-b1b209ecc935/?source=create).
The contextual elite health, phase, shield, and carried-fire layer is grounded in the
[Old Growth Elite Mobile HUD report](https://www.lazyweb.com/report/lazyweb/51156fc2-18a7-4cf0-be1b-3de54ccf33b3/?source=create).
The Warden Stag phase, root progress, consequence, and attack event layer is
grounded in the
[Warden Stag Mobile Boss Layer report](https://www.lazyweb.com/report/lazyweb/d5a79e5a-8f10-46e0-b0ed-8e6e09b2dccb/?source=create).
The separate Blackout clock, relay, encounter, and chapter-vote rail is grounded
in the
[Bramblewake Mobile Blackout Event Layer report](https://www.lazyweb.com/report/lazyweb/558b7278-8455-4639-bf62-bd4ebb97a034/?source=create).
The recommended default is a context-sensitive survival HUD. A compact HUD is
the accessibility and low-effects fallback, while the dramatic living-world HUD
is reserved for Blackouts and bosses.

## Game vision

The fantasy is not merely “survive another wave.” It is watching a frightened
camp become a town full of people who remember what the players did.

The four pillars are:

1. **A home worth defending** — construction changes capabilities, appearance,
   NPC behavior, and defense options.
2. **Expeditions with stories** — handcrafted modular regions create different
   routes, rescues, dilemmas, secrets, and extraction decisions.
3. **Readable cooperative pressure** — roles overlap enough for solo play while
   creating memorable rescues and coordinated defenses with friends.
4. **Ethical long-term progression** — players return for mastery, discovery,
   relationships, expression, and new chapters rather than punitive timers or
   purchased power.

Core loop:

```text
Choose priorities
      ↓
Explore → gather → rescue → discover
      ↓
Return, craft, assign villagers, and build
      ↓
Survive dusk and night
      ↓
Unlock story, professions, regions, and town capabilities
      ↺
```

A normal day/dusk/night cycle targets about 20 minutes. The first-session cycle
is compressed and authored. Every seventh night is a nine-minute Blackout with
an exclusive rule set, boss, story reveal, and permanent town decision.

## Complete launch scope

The finished launch target contains:

| Area | Launch target |
|---|---:|
| Persistent home | Emberhollow with 8 districts and 7 town tiers |
| Adventure regions | 6 surface regions plus the final under-town region |
| Story | Prologue, 7 chapters, epilogue, 3 ending variations |
| Professions | 7 professions, each with 30 mastery ranks and 3 specializations |
| Named villagers | 24 recruitable residents with jobs, bonds, quests, and crises |
| Buildings | 28 functional structures plus cosmetic variants |
| Enemy roster | 42 standard enemies, 14 elites, 7 chapter bosses |
| Expedition content | 180 modular tiles, 79 points of interest (72 surface + 7 finale), 48 surface dynamic events |
| Gear and crafting | 8 tool families, 6 weapon families, 180 recipes |
| Companions | 18 discoverable creatures with utility-focused traits |
| Quests | 7 chapter arcs, 24 villager arcs, contracts, mysteries, and events |
| Social play | Solo through 8-player parties, visiting, assists, and town showcases |
| Platforms | Mobile, tablet, keyboard/mouse, and controller from the first slice |
| Monetization | Cosmetics, emotes, housing themes, companion skins, and private servers |

“Complete” means the launch scope is fully authored, balanced, tested, localized
for the supported languages, accessible, performant, exploit-resistant, and
published. It does not mean development skips milestones or ships every planned
system at once.

## The complete world

Emberhollow is the last town still protected by a **First Lantern**, an ancient
machine that turns shared memories into light. The surrounding Veilwild is
fracturing into seven regions:

1. **Bramblewake Woods** — living forest, abandoned farms, root tunnels.
2. **Ironroot Delve** — collapsed mines, rail works, fungal depths.
3. **Mireglass Fen** — drowned villages, mirror pools, witch lights.
4. **Tempest Reach** — storm coast, ship graveyard, cliff observatory.
5. **Frostmere Vale** — frozen lake, buried monastery, aurora caverns.
6. **Cinderfall Crown** — ash forest, glass fields, ruined foundry-city.
7. **The Hollow Below** — the buried machine and source of the Long Night.

Each region has a traversal identity, resource economy, enemy ecology, rescue
stories, hazards, secrets, town unlocks, a chapter boss, and a Blackout rule.
The full geography and narrative are in [docs/WORLD_BIBLE.md](docs/WORLD_BIBLE.md).

## Player progression

Progression has five connected layers:

- **Player knowledge:** recipes, codex discoveries, route mastery, and mysteries.
- **Profession mastery:** Scout, Warden, Engineer, Alchemist, Medic,
  Beastkeeper, and Runebinder.
- **Gear expression:** sidegrades, traits, tool functions, and build presets
  rather than an endless item-level treadmill.
- **Villager relationships:** bonds unlock quests, town behavior, cosmetics,
  recipes, and alternate solutions.
- **Town restoration:** seven tiers unlock districts, systems, expeditions, and
  story decisions visible to visitors.

Failure is recoverable. Downed players can be revived. A failed expedition loses
some unbanked materials but keeps story discoveries, codex progress, rescued
villagers already extracted, and a recovery contract. There is no paid revive.

## Build order

The project is intentionally built through playable gates:

1. **Foundation** — repository, Rojo, test harness, content IDs, networking,
   save schema, feature flags, and bounded join flow.
2. **Graybox first ten minutes** — move, interact, gather, rescue, build one
   structure, survive one authored night, receive a reveal. Implemented in
   source; Studio, device, and ten-tester exit evidence remains.
3. **Vertical slice** — Bramblewake, four professions, one town tier, one normal
   night, one Blackout, one boss, mobile/PC/controller.
4. **Persistent town** — saves, villagers, jobs, districts, visiting, recovery,
   migrations, and failure handling.
5. **Expedition generator** — deterministic seeds, tile validation, events,
   extraction, reconnect, and anti-impossible-layout tests.
6. **Combat, crafting, and professions** — complete server-authoritative
   foundation and sidegrade economy.
7. **World production** — regions two through seven, story, bosses, NPC arcs,
   art, audio, and content validation.
8. **Social, progression, and ethical store** — party flow, showcases, cosmetic
   catalog, receipts, restore behavior, and parental clarity.
9. **Alpha** — complete start-to-finish game, placeholder-free critical path,
   save resets only with explicit migration rehearsal.
10. **Beta and launch** — scale tests, localization, device coverage, economy
    tuning, moderation, analytics, discovery assets, and staged rollout.
11. **Live operations** — additive chapters and events that do not erase
    permanent progress.

Every milestone and exit criterion is detailed in
[docs/PRODUCTION_ROADMAP.md](docs/PRODUCTION_ROADMAP.md).

## Definition of done

The launch is done only when all of the following are true:

- a brand-new player can complete onboarding without developer intervention;
- every region, chapter, profession, villager arc, boss, building tier, and
  ending is reachable and validated;
- no generated expedition can be impossible, disconnected, or missing its
  extraction path;
- saves survive disconnects, schema upgrades, receipt retries, server crashes,
  and teleport failures;
- mobile touch targets, reserved zones, text preferences, reduced motion,
  contrast, captions, and input switching pass the device matrix;
- the baseline low-end phone meets the agreed frame, memory, and join budgets;
- combat, rewards, crafting, building, purchases, and admin actions are
  server-authoritative and rate-limited;
- all purchases are clear, cosmetic or socially expressive, receipt-safe, and
  never required to recover from failure;
- analytics dashboards can detect onboarding loss, progression walls, economic
  inflation, exploit spikes, crashes, and unfair difficulty;
- release, rollback, moderation, incident response, and content kill switches
  have been rehearsed.

## Documentation map

- [Game design document](docs/GAME_DESIGN_DOCUMENT.md) — experience, loops,
  progression, combat, building, professions, story delivery, and player journey.
- [World bible](docs/WORLD_BIBLE.md) — geography, chapters, factions, named
  villagers, districts, endings, and lore rules.
- [Content catalog](docs/CONTENT_CATALOG.md) — launch content IDs and production
  counts for enemies, bosses, buildings, events, resources, and equipment.
- [Technical architecture](docs/TECHNICAL_ARCHITECTURE.md) — places, services,
  authority, data, networking, streaming, observability, and exploit resistance.
- [Roblox game engineering playbook](docs/ROBLOX_GAME_PLAYBOOK.md) — practical
  lessons for source truth, generated places, assets, PBR, mobile, physics,
  remotes, persistence, commerce, and publishing.
- [Mobile UX and accessibility](docs/UX_MOBILE_ACCESSIBILITY.md) — HUD, input,
  safe areas, responsive behavior, text, motion, sound, and device testing.
- [UI design direction](docs/UI_DESIGN_DIRECTION.md) — durable gameplay-HUD
  research findings, implementation rules, and locally archived visual targets.
- [Art and audio direction](docs/ART_AUDIO_DIRECTION.md) — visual language,
  biomes, lighting, VFX readability, animation, music, ambience, and asset budgets.
- [Monetization, live ops, and analytics](docs/MONETIZATION_LIVEOPS_ANALYTICS.md)
  — ethical catalog, economy, retention, experiments, events, and KPIs.
- [Production roadmap](docs/PRODUCTION_ROADMAP.md) — start-to-finish milestones,
  dependencies, deliverables, and acceptance gates.
- [QA and release plan](docs/QA_RELEASE_PLAN.md) — automated, multiplayer,
  mobile, performance, save, commerce, exploit, and rollout validation.
- [Release gates](docs/RELEASE_GATES.md) — numeric beta, canary, promotion,
  pause, and rollback criteria.
- [Development guide](docs/DEVELOPMENT.md) — pinned tools, setup, commands,
  test layers, environments, service patterns, and upgrades.
- [Publishing runbook](docs/PUBLISHING_RUNBOOK.md) — safe universe/place setup,
  private publishing, verification, promotion, and rollback.
- [Decision log](docs/DECISIONS.md) — durable product and architecture decisions.

## Repository layout

```text
src/                 Rojo-mapped runtime Luau source
tests/               Pure Luau and Studio integration tests
docs/                Production blueprint and runbooks
scripts/             Bootstrap, build, type, and blueprint validation
.github/workflows/   Pull-request and main-branch checks
rokit.toml           Exact Roblox development-tool versions
*.project.json       Game and integration-test DataModel mappings
```

## Getting started

Install [Rokit](https://github.com/rojo-rbx/rokit#installation), then trust the
five reviewed tool sources once and bootstrap:

```bash
rokit trust rojo-rbx/rojo johnnymorganz/stylua kampfkarren/selene lune-org/lune johnnymorganz/luau-lsp
npm run bootstrap
```

Bootstrap installs the exact versions in `rokit.toml`, validates the blueprint,
formats/lints/type-checks the Luau foundation, runs pure tests, and builds
`build/LastLight.rbxlx` plus `build/LastLightTest.rbxlx`.

For Windows testing without command-line tools, download and extract the
repository ZIP from GitHub, then open `build/LastLight.rbxlx` directly in Roblox
Studio. Open `build/LastLightTest.rbxlx` and press Play for the automated Studio
assertions. Both files are regenerated and committed with every completed phase.

For the live source-to-Studio loop:

```bash
rojo serve default.project.json
```

Connect the Rojo Studio plugin to `localhost:34872`. For the current Studio
integration test, open `build/LastLightTest.rbxlx`, press Play, and confirm the
server output contains `[Last Light] PASS FoundationIntegration`. Full setup and
Windows instructions are in [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md).

## Delivery workflow

All substantive changes use an `agent/*` branch, a pull request to `main`,
required checks, merge after green, and a final local `main` sync. See
[AGENTS.md](AGENTS.md) and [CONTRIBUTING.md](CONTRIBUTING.md).

## Original-IP and safety boundary

Last Light is an original property. Inspiration may inform genres and mechanics,
but shipped names, characters, environments, icons, meshes, music, dialogue, and
marketing must be original or properly licensed. The design excludes paid power,
random paid rewards, purchasable revives, manipulative streak loss, and artificial
frustration sold back as relief.
