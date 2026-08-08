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

## Restarting a stale Studio from the terminal

A long-lived Studio session drifts behind `main` — one was found running
code from twenty-one PRs ago, old enough that the file a bug lived in did
not exist in any of its loaded scripts. A session on the same machine can
replace it without touching the desktop, as long as the user's display
session is alive (check `who` for a seat and `ls /tmp/.X11-unix/` for
sockets):

```bash
pkill -f "RobloxStudioBeta.exe"
DISPLAY=:1 XDG_RUNTIME_DIR=/run/user/1000 \
DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus \
flatpak run --command=vinegar --file-forwarding org.vinegarhq.Vinegar \
    @@ /path/to/build/LastLightTest.rbxlx @@
```

The `@@` markers are Flatpak file-forwarding (they hand the place file
through the document portal); the invocation comes straight from Vinegar's
own desktop entry. Run it in the background — Studio takes a couple of
minutes to boot the place. The MCP bridge (`StudioMCP.exe`) survives the
kill because it belongs to the session's wrapper, not to Studio; after the
relaunch, `list_roblox_studios` shows the new instance and
`set_active_studio` attaches to it. This is how the profession-roster wave
was live-verified minutes after being written: rebuild with `npm run
build`, relaunch Studio on the fresh place file, and the world under test
IS the working tree.

Two cautions. Killing Studio discards anything unsaved in it — fine for a
throwaway test session, not for one holding real edits; check with the
owner if there is any doubt about what the open session contains. And
chat-based admin commands (`TextChannel:SendAsync`) hang under this setup
— the text-filtering round-trip never resolves in a local Wine session —
so drive state with the remotes below or DataModel edits instead.

**The relaunch after a `pkill` opens a modal, and the modal is silent from
where a session sits.** Studio noticed it "was not shut down properly" and
puts up an Auto-Recovery dialog before it will do anything else. It is
**modal to Studio's main thread**, so the MCP plugin never answers: every
tool call returns `Request timeout`, which is exactly what a Studio that is
still booting the place looks like, and waiting longer never helps. Worse,
synthesized clicks and keystrokes do not reach it under Wine — `xdotool`
reports success on every one of them and the dialog does not move, which is
the same silent-success failure the portrait-click section below is about.

Diagnose it by listing windows rather than by waiting:

```bash
DISPLAY=:1 wmctrl -l          # an "Auto-Recovery" window beside the place
```

Clear it by removing the snapshots it is offering, then relaunching. They
are Studio's own periodic copies; this place is generated by `npm run
build`, so there is never anything in them worth recovering:

```bash
rm -f ~/.var/app/org.vinegarhq.Vinegar/data/vinegar/appdata/Roblox/RobloxStudio/AutoSaves/*.rbxl
```

Do it **before** the relaunch, not after, because the dialog goes up early
enough to swallow the whole boot.

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

Four DataModel attributes exist purely so a session can reach a surface that
would otherwise be correctly empty, and every one of them is Studio-only and
logged loudly when it fires:

| Attribute | Value | What it does |
|---|---|---|
| `LastLightSkipTutorial` | `true` | Completes First Light and wakes the world the same way a loaded complete profile does. |
| `LastLightStockProfile` | a number | Fills the purse so crafting and equipping can be driven without playing an hour. |
| `LastLightStudioStore` | Robux price | Turns the `cosmetic_store_enabled` flag on and gives every product that price, so the outfitter's cards render. It is a **price**, not a product id — `promptPurchase` still refuses with `product_not_configured`, because a Creator Dashboard product genuinely does not exist. |
| `LastLightStudioGrant` | a product id | Pushes a synthetic receipt through `applyReceipt`, the real and only grant authority, for every player in the server. The platform's own `ProcessReceipt` cannot be driven in Studio; this is the closest honest thing to it. |
| `LastLightSoak` | `true` | Turns on the soak: one sample per town cycle at dawn, into `SoakProbe`. Read **every cycle** rather than at boot, because a Play session starts from a fresh DataModel that does not carry attributes set in Edit mode -- a boot read is unreachable from a playtest, which is how it shipped broken once. Grants nothing and changes no rule; it only makes the server write down what it is holding. |
| `LastLightStudioPrivateServer` | a user ID | Makes the private-server control rail answer to that user. A Studio session is neither a private server nor a reserved one, so this is the only way to reach the rail from a playtest at all. It fakes exactly one thing — the owner — and every refusal, the practice latch and all four consequences are the real path. |

Driving several town cycles quickly, which the soak needs and a 20-minute
cycle does not give you: set `LastLightStudioPrivateServer`, then fire
`Interact` with `interactionId = "private_control_call_phase"` on a loop, once
every five seconds or so, standing at the rail (pivot the character to about
`21.5, 6, -182`). Three presses is one cycle. Two things to know about the
result. The rail latches **practice** on the first press, so the profile is
never written and `profile_bytes` will read flat for a reason that is not the
profile holding steady. And `private_control` is a *kind* with no payload field
of its own -- the rail is reached through `Interact`, so sending
`kind = PrivateControl` is refused as a smuggled field.

The reason the store and grant attributes exist is written into the wave that
added them: a live
pass on a store with no priced products sees an empty panel, and an empty panel
and a broken panel look identical. That is the same failure `LastLightSkipTutorial`
was written against.

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

## Clicking a HUD button at a portrait viewport

The M7 runbook says GUI buttons are best clicked by `instance_path`, and that
was true of a maximized window. It is **not** true of the resized window a
portrait check needs, and the failure is silent: the tool reports Success, the
button's `Activated` never fires, and nothing distinguishes that from a dead
handler.

What is actually going on, measured on 2026-08-08 with the window at 805 x 1002
(which gives a 392 x 608 viewport, the owner's phone):

- `user_mouse_input` hit-tests at the coordinate it is given, in the same space
  as a GUI object's `AbsolutePosition`. So **pass the button's own
  `AbsolutePosition` centre as `x`/`y`** and the press lands.
- `UserInputService:GetMouseLocation()` then reports that point **plus the
  58-pixel top inset**. That is a reporting artifact of this setup, not an
  error -- do not "correct" for it, or every click lands an inset below its
  target, which is exactly what `instance_path` does here.
- The proof a click landed is not the tool's return value. Connect a probe
  (`button.Activated`) or watch `UserInputService.InputBegan`'s `processed`
  flag: `processed = false` on a MouseButton1 means the GUI did not take it.

```lua
-- read the target first, then click its centre
local b = player.PlayerGui.LastLightHUD.SafeCanvas.QuickChat
local p, s = b.AbsolutePosition, b.AbsoluteSize
-- click at (p.X + s.X / 2, p.Y + s.Y / 2)
```

Getting the viewport itself to 392 x 608 is arithmetic on the window, because
Studio's docked panels take a fixed slice: measure once, subtract, resize. On
this machine that was 805 x 1002 for the window. The MCP resize tool is not
available for Studio; `xdotool windowsize` is, and it enforces a 640-pixel
minimum width, which is why the window is sized around the viewport rather
than to the phone's own dimensions.

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
