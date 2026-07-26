# Repository operating rules

## Scope

This repository contains the original Roblox game **Last Light**. Do not introduce
copyrighted characters, locations, logos, audio, or recognizable replicas of
third-party games.

## Delivery workflow

1. Synchronize local `main` with `origin/main`.
2. Create an `agent/*` branch for every completed change.
3. Keep commits scoped and exclude unrelated local files.
4. Run `npm test` plus the milestone-specific checks.
5. Commit the freshly generated `build/LastLight.rbxlx` and
   `build/LastLightTest.rbxlx` from that exact validated source revision so a
   Windows tester can download the GitHub ZIP and open either place directly.
6. Push the branch and open a pull request to `main`.
7. Inspect the actual GitHub check rollup.
8. Merge after required checks pass, then synchronize local `main`.

Do not push implementation commits directly to `main`.

## Product gates

- Mobile-first does not mean mobile-only. Touch, keyboard/mouse, and controller
  must share action semantics through Roblox's Input Action System.
- The server is authoritative for inventory, combat, building, rewards,
  purchases, progression, teleport payloads, and save data.
- A feature is incomplete without failure states, analytics, accessibility,
  performance budgets, automated validation where practical, and a playtest gate.
- Do not sell combat power, random paid rewards, extra lives, or relief from
  intentionally created frustration.
- Never block joining on the whole world loading. Use streaming and a playable
  first area.
- Content definitions use stable IDs. Never reuse or silently repurpose an ID
  that has shipped in save data.

## Planning source of truth

Start with [README.md](README.md), then follow the linked design documents. If
code and plans disagree, record a decision in [docs/DECISIONS.md](docs/DECISIONS.md)
before changing scope.
