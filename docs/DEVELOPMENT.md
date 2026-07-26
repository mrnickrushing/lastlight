# Development guide

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

Generated `.rbxlx` files live under ignored `build/`. They are test and local
publishing artifacts, never source of truth.

## Studio integration test

The pure Lune suite cannot emulate Roblox networking, physics, streaming, or the
full DataModel. The first engine integration test is intentionally separate:

1. Run `npm run build`.
2. Open `build/LastLightTest.rbxlx` in Roblox Studio.
3. Start a server with one player.
4. Confirm server output contains `[Last Light] PASS FoundationIntegration`.
5. Confirm `server_boot_complete` appears without an infinite-yield warning.
6. Stop immediately if either assertion errors.

The test verifies the real Rojo tree, shared module replication, seven-region
registry, save-schema constant, and service initialization/start lifecycle.
Milestone 2 expands this place with spawn, collision, input, and bounded-loader
journeys.

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
