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

**Milestone 1 executable foundation implemented; Studio integration playtest pending.**

The repository currently contains:

- the complete launch vision, world, story, systems, content targets, and economy;
- a milestone-by-milestone implementation and release plan;
- mobile, accessibility, performance, security, analytics, and QA gates;
- a pinned Rokit toolchain and reproducible game/test-place builds;
- typed environment, logging, feature-flag, service-lifecycle, and content-registry foundations;
- pure Luau tests plus a dedicated Studio integration-test place;
- automated documentation, format, lint, type, test, and build validation;
- a hosted visual direction report for the gameplay HUD.

The next player-visible milestone is the graybox first ten minutes: a safe arrival,
gathering, rescue, construction, one enemy, and the first authored night.

The current UI direction is documented in the
[Last Light mobile gameplay HUD report](https://www.lazyweb.com/report/lazyweb/a5059523-0d43-4386-b0f5-bda12ca3d7ea/?source=create).
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
   structure, survive one authored night, receive a reveal.
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
