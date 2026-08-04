# Development guide

For cross-project Roblox lessons that are not specific to a Last Light
milestone, read [ROBLOX_GAME_PLAYBOOK.md](ROBLOX_GAME_PLAYBOOK.md) before
changing runtime generation, meshes, mobile HUD, moving platforms, remotes,
commerce, or publishing behavior.

## Supported toolchain

Last Light uses a project-local [Rokit](https://github.com/rojo-rbx/rokit)
manifest so Linux, macOS, Windows, and CI run exact tool versions.

| Tool | Pinned version | Purpose |
|---|---:|---|
| Rokit | 1.2.0 installer | toolchain manager |
| Rojo | 7.7.0 | filesystem-to-Studio sync and place builds |
| StyLua | 2.5.2 | deterministic Luau formatting |
| Selene | 0.31.0 | Roblox-aware linting |
| Lune | 0.10.5 | standalone pure-Luau test runtime |
| Luau LSP | 1.69.0 | strict static analysis for engine-independent modules |

Rokit itself is pinned by the tagged installer URL in CI. The remaining tools
are pinned in `rokit.toml`.

## First setup

Install Node.js 20 or newer, Git, and Rokit. On Windows, download `rokit.exe`
from Rokit's release page, run it once, then reopen PowerShell. On Linux or
macOS, use the tagged or current official Rokit installer.

From the repository root:

```bash
rokit trust rojo-rbx/rojo johnnymorganz/stylua kampfkarren/selene lune-org/lune johnnymorganz/luau-lsp
npm run bootstrap
rojo plugin install
```

The trust command is intentionally explicit. Do not use `--no-trust-check`
locally; CI uses it only after reviewing the exact pinned manifest.

## Daily commands

```bash
npm test             # complete CI-equivalent validation
npm run test:luau    # pure service/content/environment tests
npm run typecheck    # engine-independent strict Luau modules
npm run lint         # Selene
npm run format       # rewrite Luau with StyLua
npm run build        # game and Studio test places
npm run verify:build # inspect the generated DataModel trees
rojo serve default.project.json
```

Generated `.rbxlx` files live under `build/`. Source and project mappings remain
the source of truth, but the two current outputs are committed after every
completed milestone so Windows testers can download the GitHub ZIP and open
Studio without installing the command-line toolchain:

- `build/LastLight.rbxlx` — playable game place;
- `build/LastLightTest.rbxlx` — automated Studio integration place.

Do not hand-edit either place. Regenerate both with `npm test` from the exact
source revision before committing.

## Studio integration test

The pure Lune suite cannot emulate Roblox networking, physics, streaming, or the
full DataModel. The first engine integration test is intentionally separate:

1. Run `npm run build`.
2. Open `build/LastLightTest.rbxlx` in Roblox Studio.
3. Start a server with one player.
4. Confirm server output contains `[Last Light] PASS FoundationIntegration`.
5. Confirm `server_boot_complete` reports the build version and save schema
   declared in `src/shared/Config.luau`, a service count matching the services
   registered in `src/server/init.server.luau`, and no infinite-yield warning.
6. Confirm the loader leaves the player at `ArrivalSpawn` on solid ground and
   the first objective is `FREE MARA`.
7. Complete the journey in [MILESTONE_2_PLAYTEST.md](MILESTONE_2_PLAYTEST.md).
8. Enter and traverse the generated route using
   [MILESTONE_3_EXPEDITION_FOUNDATION.md](MILESTONE_3_EXPEDITION_FOUNDATION.md).
9. Complete and deliberately expire events using
   [MILESTONE_3_BRAMBLEWAKE_EVENTS.md](MILESTONE_3_BRAMBLEWAKE_EVENTS.md).
10. Bank rewards and return through Wayhome using
    [MILESTONE_3_INVENTORY_EXTRACTION.md](MILESTONE_3_INVENTORY_EXTRACTION.md).
11. Complete two-player down, revive, interruption, and safe retreat using
    [MILESTONE_3_PLAYER_SURVIVAL.md](MILESTONE_3_PLAYER_SURVIVAL.md).
12. Validate stamina, dodge, Rootling telegraph, cover, and input switching using
    [MILESTONE_3_COMBAT_MOBILITY.md](MILESTONE_3_COMBAT_MOBILITY.md).
13. Validate all four profession kits, persistence, selection gating, cooldowns,
    controller focus, and mobile layout using
    [MILESTONE_3_PROFESSION_KITS.md](MILESTONE_3_PROFESSION_KITS.md).
14. Validate all six Bramblewake enemies, telegraphs, solo counterplay, queue
    cleanup, and mobile readability using
    [MILESTONE_3_BRAMBLEWAKE_ENEMIES.md](MILESTONE_3_BRAMBLEWAKE_ENEMIES.md).
15. Validate the Old Growth activation, attacks, shield fire, rewards, mobile
    HUD, kill switch, and cleanup using
    [MILESTONE_3_OLD_GROWTH_ELITE.md](MILESTONE_3_OLD_GROWTH_ELITE.md).
16. Validate the Warden Stag unlock, three phases, roots, antler consequence,
    attacks, recovery, rewards, mobile HUD, kill switch, and cleanup using
    [MILESTONE_3_WARDEN_STAG_BOSS.md](MILESTONE_3_WARDEN_STAG_BOSS.md).
17. Validate the chained rootfire relay, recoverable overtime, Old Growth and
    Warden gates, Greenward vote, immutable story save, mobile rail, and kill
    switch using
    [MILESTONE_3_BRAMBLEWAKE_BLACKOUT.md](MILESTONE_3_BRAMBLEWAKE_BLACKOUT.md).
18. Stop immediately if any assertion errors.

The test verifies the real Rojo tree, shared module replication, seven-region
registry, save-schema-v4 constant, eight tutorial interactions, 13 active event
interactions, two dormant elite interactions, six locked boss interactions,
seven dormant Blackout interactions, one extraction interaction, runtime remotes,
Input Action System rollout, world readiness, arrival collision, deterministic
Bramblewake replay, 12 streamed modules, four POIs, eight event state contracts,
mobile part budget, shared survival/revive, six-enemy combat/telegraph,
profession contracts, Old Growth shield/fire/rooted/model contracts, Warden Stag
phase/root/choice/model contracts, Blackout relay/vote/story contracts, and
service initialization/start lifecycle.
Human play is still required for physics,
streaming, device layout, input switching, multiplayer revive timing, and
usability.

## Runtime boundaries

### Environments

- **local:** Studio by default; no persistent production data.
- **test:** Studio with `LastLightEnvironment` set to `test`.
- **staging:** unknown/private published places by default.
- **production:** only a place ID explicitly listed in
  `Config.ProductionPlaceIds`.

An unregistered place cannot request production. This is deliberate fail-closed
behavior.

### Services

Server systems register with `ServiceRegistry`, then every service initializes
before any service starts. Duplicate names, late registration, initialization
failure, and start failure stop boot with the responsible service name.

Dependencies enter through the service context. Services do not reach into
another service's private state or silently create remotes.

### Content

Content definitions have stable lowercase IDs, versions, localization and
analytics keys, asset bundles, tags, dependencies, and optional feature flags.
`Content.Registry` rejects malformed definitions, duplicates, unknown fields,
and missing dependency references before gameplay uses them.

Shipped IDs are tombstoned or migrated, never silently reassigned.

## Tool upgrades

1. Create a dedicated `agent/toolchain-...` branch.
2. Check the official release notes and platform artifacts.
3. Change one or a tightly related set of pins in `rokit.toml`.
4. Run `rokit install --force`, `npm test`, and the Studio integration test.
5. Record breaking behavior or project-format changes in `docs/DECISIONS.md`.
6. Merge only through a green PR.

Never use floating `latest` versions in the committed manifest or CI.
