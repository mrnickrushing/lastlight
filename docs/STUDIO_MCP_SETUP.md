# Connecting an AI session to Roblox Studio

Roblox Studio can act as an MCP server, which lets an AI coding session read the
DataModel, run Luau in the live session, drive playtests, and capture
screenshots. For this project that matters more than it might elsewhere: nearly
every open exit gate in the milestone runbooks is blocked on somebody looking at
Studio, and this is how a session looks for itself.

## The constraint that decides everything else

**The session has to run on the same machine as Studio.** MCP over stdio means
the client *spawns* the server as a child process and talks over pipes — there
is no socket and no address, so a session running anywhere else cannot reach it,
and no amount of configuration changes that. A cloud session (Claude Code on the
web, a CI runner, a remote container) can write code for this project but can
never see it running.

That is not a limitation to work around by exposing the server to a network. It
is the reason the server is safe: the scene, the code, and every edit stay on
the machine.

## Setup

### 1. Enable Studio's MCP server

In Studio: **Assistant → … → Manage MCP Servers → "Enable Studio as MCP
server."**

If that menu does not exist, the Studio build predates it; use Roblox's
standalone [`studio-rust-mcp-server`](https://github.com/Roblox/studio-rust-mcp-server)
instead, which installs a plugin plus a local binary.

### 2. Point a client at it

**Windows and macOS** — Studio's own quick-connect handles Claude Code, Claude
Desktop, Cursor, VS Code, Codex CLI, and Gemini CLI directly. Nothing below is
needed.

**Linux, with Studio under Wine (Vinegar)** — Studio's MCP server is a Windows
executable inside the Wine prefix, so it needs a wrapper.
[`scripts/studio-mcp-wrapper.sh`](../scripts/studio-mcp-wrapper.sh) is that
wrapper: it finds the prefix, finds the newest `StudioMCP.exe` inside it, and
runs it under Wine.

```bash
claude mcp add roblox-studio --transport stdio -- \
    "$PWD/scripts/studio-mcp-wrapper.sh" --stdio
claude mcp list
```

Override `WINEPREFIX`, `STUDIO_MCP_EXE`, `WINE_BIN`, or `STUDIO_MCP_LOG` if the
install differs from the defaults it probes.

### 3. Confirm it is actually connected

Open `build/LastLight.rbxlx` in Studio, start a session in the repository root,
and ask it to list the children of `Workspace`. Real instance names mean it
works. Anything else, see the troubleshooting table.

## Troubleshooting

| Symptom | Cause |
|---|---|
| JSON parse errors, connection drops immediately | Something is writing to stdout besides the protocol. Wine's `fixme:` chatter is the usual culprit; the wrapper redirects stderr to `/tmp/studio-mcp.log` for exactly this reason. Check that log. |
| `StudioMCP.exe not found` | The MCP server has not been enabled in Studio yet, or the prefix probe missed. Run `find ~ -name StudioMCP.exe` and set `STUDIO_MCP_EXE`. |
| Connects, but sees nothing | Studio is open without a place loaded, or a different place is in focus. |
| Worked yesterday, not today | Roblox ships Studio updates that periodically break under Wine. VinegarHQ states plainly that they cannot guarantee functionality and that fixes can take days. Check the Vinegar issue tracker before debugging your own setup. |

## What a connected session can and cannot close

This is the honest split, because a session that overstates what it verified is
worse than one that verifies nothing.

**Can be closed by a connected session:**

- Studio Output assertions — build version, save schema, service count,
  `[Last Light] PASS FoundationIntegration`, `fallbacks=0`, `styledParts > 0`,
  and the absence of runtime errors.
- Anything about placement, scale, orientation, clipping, or whether an asset
  loaded — the historical failures here (buried roads, sideways cylinders,
  blown-out cabins, a beacon hidden inside its own fallback) were all visible in
  a screenshot.
- Per-building damage and repair behaviour: run a night, look at which buildings
  broke, repair one, confirm the others are untouched.
- Interaction reachability and prompt text.
- Deterministic replay — the same night number striking the same buildings
  across a restart.

**Cannot be closed, no matter how good the connection:**

- **Baseline-phone performance, touch reach, and safe areas.** Studio's device
  emulator is for layout and controls; `TECHNICAL_ARCHITECTURE` says outright
  that emulator memory is not hardware evidence.
- **The ten-tester gate.** It requires ten people who have not seen the design
  finishing unaided. A session is not a tester.
- **DataStore behaviour across servers** — session locking, cross-server
  reconnect, backup capture and restore. Studio local/test is session-backed by
  design; this needs a published staging place.
- **Real multiplayer** — 8-player desync, revive timing, loot contention.
- **Whether the game is fun.** The Milestone 3 decision gate asks whether the
  slice is fun, readable, and shows credible D1 intent. Nothing automates that.

## Driving gameplay from a session

Clicking through UI via synthesized input is slow and brittle. The reliable
way to drive real gameplay state — fast-forward a tutorial, defeat an enemy,
select a profession — is firing the same `RemoteEvent` the client fires, with
the same payload shape, from `execute_luau` on the `Client` datamodel:

```lua
local RuntimeIds = require(ReplicatedStorage.LastLight.RuntimeIds)
local remotes = ReplicatedStorage[RuntimeIds.FolderName][RuntimeIds.Remotes.ActionRequest]
remotes:FireServer({ schemaVersion = 1, kind = RuntimeIds.Actions.UseTool })
```

Find the exact payload shape each action expects in `src/client/init.client.luau`'s
`send()` calls (e.g. `Interact` needs `interactionId`, `SelectProfession` needs
`professionId`) — do not guess it. This is how the night-combat audit drove
several real day/dusk/night cycles end to end, defeated enemies across all six
species to drain the wave queue, and reached a Town Guard Last Stand, all
without waiting on wall-clock time or a mouse.

Two things about Studio Play mode that read as bugs the first time but are not:

- **A local Play-mode profile is session-only.** It lives in memory and is not
  persisted across Play stop/start, so any progress used to reach a test
  scenario — tutorial completion, a chosen profession, unlocked content — has
  to be re-driven after every restart. This is Studio's local-testing
  behaviour, not a save-system bug.
- **`EnemyService` queues; it does not force-clear.** A new enemy queues
  behind whichever one is already active; nothing skips or times out an
  undefeated enemy except defeating it or the night ending. A passive test
  that never fights back will see the wave schedule stall behind the first
  enemy — correct behaviour, not evidence the spawn system is broken.

And two tool-shape gotchas in the MCP server itself, each worth a wasted call
to rediscover:

- `multi_edit` takes `datamodel_type: "Edit"` — the only value it accepts, and
  a different thing from the `Server`/`Client` datamodels `execute_luau` uses.
  It edits the Edit-mode DataModel directly and works whether or not Play mode
  is running; `Server`/`Client` datamodels for `execute_luau` only exist while
  a Play session is live.
- `start_stop_play` takes a boolean `is_start`, not a string `action`.

## Recording evidence

A connected session must write what it saw into the runbook it was closing, the
same way any other gate evidence is recorded — build version, place file, what
was checked, what was seen, and screenshots where the gate asks for them. A gate
row marked closed without that is an assertion, not evidence, and this project
has a documented history of checks that read correctly and verified nothing.
