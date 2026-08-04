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
   tester can open either place directly from a checkout or a GitHub ZIP,
   without installing the command-line toolchain.
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

**Start every session by reading
[docs/PROJECT_STATUS.md](docs/PROJECT_STATUS.md), and update it before the
session ends.** It is the living handoff between sessions: what just landed,
what is in flight, what is blocked on the owner, and the environment gotchas
that cost previous sessions real time. This project is worked on across many
short sessions -- anything not written there is invisible to the next one.

Then read [README.md](README.md) and follow the linked design documents. If
code and plans disagree, record a decision in [docs/DECISIONS.md](docs/DECISIONS.md)
before changing scope.

For practical Roblox implementation details, also read
[docs/ROBLOX_GAME_PLAYBOOK.md](docs/ROBLOX_GAME_PLAYBOOK.md). It covers Rojo and
generated-place provenance, mesh/PBR sizing, streaming, moving-platform
physics, mobile layout, remotes, persistence, commerce, and Open Cloud
publishing.

Before creating or changing any player-visible environment, character, prop,
mesh, reward, lighting, or VFX, read and satisfy
[docs/VISUAL_QUALITY_STANDARD.md](docs/VISUAL_QUALITY_STANDARD.md). The entire
Emberhollow and Bramblewake first-world slice is the minimum quality reference
for later content. Plain blocks, floating markers, decorative glow, labels, and
recolors are not substitutes for recognizable physical construction.
