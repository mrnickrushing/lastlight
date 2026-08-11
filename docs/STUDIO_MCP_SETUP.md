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

**Linux, with Studio under Wine (Vinegar)** — Studio's MCP server runs inside
the Wine prefix, so it needs a wrapper.
[`scripts/studio-mcp-wrapper.sh`](../scripts/studio-mcp-wrapper.sh) is that
wrapper: it finds the prefix, finds `mcp.bat`, and launches the real
`StudioMCP.exe` that batch file would run — directly, under Wine, when it can
resolve one — falling back to running the batch file itself otherwise.

```bash
claude mcp add roblox-studio --scope user --transport stdio -- \
    "$PWD/scripts/studio-mcp-wrapper.sh"
claude mcp list
```

You want `roblox-studio: … - ✔ Connected` in that list. There is no `--stdio`
argument — `mcp.bat` takes none.

Override `WINEPREFIX`, `STUDIO_MCP_BAT`, `WINE_BIN`, or `STUDIO_MCP_LOG` if the
install differs from the defaults it probes.

**Wine must be the host's, not Vinegar's.** Vinegar's Flatpak runtime does not
export a `wine` binary — `flatpak run --command=sh org.vinegarhq.Vinegar -c
'command -v wine'` finds nothing — so the wrapper needs Wine installed on the
host (`apt install wine` on Debian/Kali). It still uses Vinegar's *prefix*; only
the binary is the host's.

#### Four things about where Studio's MCP server actually lives, and how it launches

None of these were guessable — every one was measured, on real hardware, by
two people hitting the same failure from different angles.

1. **The launcher is `mcp.bat`.** Enabling "Studio as MCP server" writes a small
   batch file — but that batch file's own first branch names the exact,
   versioned `StudioMCP.exe` Roblox generated it alongside, and the wrapper
   prefers launching that directly (see point 3).
2. **It is not under `drive_c`.** Vinegar redirects `%LOCALAPPDATA%` out of the
   prefix entirely, onto the host filesystem through Wine's `Z:` drive:

   ```console
   $ WINEPREFIX=~/.var/app/org.vinegarhq.Vinegar/data/vinegar/prefixes/studio \
       wine cmd /c "echo %LOCALAPPDATA%"
   Z:\home\<user>\.var\app\org.vinegarhq.Vinegar\data\vinegar\appdata
   ```

   Meanwhile `drive_c/users/*/AppData/Local/Roblox/` exists and holds only
   plugin and instance directories. So `find "$WINEPREFIX/drive_c" -name
   mcp.bat` searches the one place the file is not, and the honest search is
   `find ~ -name mcp.bat`.
3. **Wine's `cmd.exe` accepts a Windows path built one way and refuses the
   identical string built another.** A version that fixed both bugs above
   still failed to launch:

   ```console
   win_dir=Z:\home\<user>\.var\app\org.vinegarhq.Vinegar\data\vinegar\appdata\Roblox
   Path not found.
   ```

   for the *exact same string* that Wine's own expansion of `%LOCALAPPDATA%`
   resolves to and reaches without complaint — the one in step 2's `echo`
   output, one line up. Two fixes for this landed close together, both real:
   invoking the exact `StudioMCP.exe` `mcp.bat` would have run needs no `cd`
   at all, so there is nothing for `cmd.exe` to refuse — this is what the
   wrapper prefers, and it also sidesteps a `Syntax error: unexpected ELSE`
   Wine's batch parser can emit from `mcp.bat` after the MCP process exits.
   When that `.exe` can't be resolved (an unusual `mcp.bat`, or the named file
   missing), the wrapper falls back to running the batch file itself, and for
   that fallback hands Wine the **literal, unresolved** `%LOCALAPPDATA%\Roblox`
   rather than a host-translated path, letting Wine expand its own variable
   under the `WINEPREFIX` already exported. Discovery still walks the host
   filesystem first in both cases — that only decides *whether* `mcp.bat`
   exists, so a missing server fails fast with a specific message instead of a
   slow, opaque Wine startup.
4. **A file discovery finds is not automatically what Wine's own
   `%LOCALAPPDATA%` currently answers for.** The literal fix in point 3 is only
   sound when the two agree, which holds by construction for a Vinegar install
   (Flatpak or native) — it has exactly one appdata directory — but not for a
   plain Wine prefix holding more than one Windows user profile: the
   `drive_c/users/*` glob can match a stale profile's `mcp.bat` while Wine
   itself currently answers `%LOCALAPPDATA%` for someone else. Discovery
   succeeding is then not the same as the literal being safe to use, so that
   one candidate is checked against Wine's own answer (`echo %LOCALAPPDATA%`,
   under the prefix already exported) before being trusted. Every other
   candidate is unambiguous and skips the check.

`%LOCALAPPDATA%\Roblox` is the right answer in both layouts — redirected under
Vinegar, inside `drive_c` under a plain prefix — which is why letting Wine
resolve it directly (point 3's fallback) works for either, once point 4's
check confirms it is safe to.

**If you have both a Flatpak and a native Vinegar, they have one `mcp.bat`
each.** The wrapper derives the launcher from whichever prefix it selected —
Vinegar keeps `<root>/prefixes/studio` beside `<root>/appdata`, so the pairing
is derivable rather than guessable — and it never reaches into a fixed global
path. Setting `WINEPREFIX` therefore picks the launcher too. If discovery still
lands on the wrong one, set `STUDIO_MCP_BAT` to the one belonging to that
prefix; `find ~ -name mcp.bat` will show you both. An explicit `STUDIO_MCP_BAT`
override is one case that still needs a host→Windows translation for the batch
fallback (it can point somewhere `%LOCALAPPDATA%\Roblox` does not reach), and
the other is a plain-Wine multi-user prefix where point 4's check could not
confirm the two agree — both are the one place point 3's class of failure
could still resurface, and both fall back to a translated path rather than
guess.

`scripts/test-studio-mcp-wrapper.sh` runs the wrapper against twenty-one
throwaway directory layouts with a stub `wine`, and is part of `npm test`. It
covers discovery, the exact launch-command shape (direct-exe launch from a
generated batch file, the literal `%LOCALAPPDATA%` form versus the
translated-path form and that the right one is chosen for each case,
including the multi-user mismatch), quoting, argument forwarding, and every
failure message. It does not cover Wine itself — the stub never runs a real
`cd` or launches a real process, so it cannot tell a Windows path string or an
`.exe` that merely looks right from one Wine actually accepts. That is
precisely the gap bugs 3 and 4 lived in; whether the server actually launches
and speaks JSON-RPC still needs the machine Studio runs on.

#### The relay hosts the socket; Studio dials it

This one is worth more than the four above put together, because it makes the
difference between a session that can see the game and one that cannot, and
every symptom it produces reads as "Studio is broken".

**Studio is the WebSocket *client*.** Its own log shows the direction plainly:

```console
[DFLog::WebSocketTraceError] ws: 61 url: http://localhost:13469/studio error: HttpError: ConnectFail
```

Studio retries that connection every three seconds, forever. `StudioMCP.exe` is
what *hosts* port 13469. So the relay process has to **outlive individual tool
calls**: a client that spawns the wrapper per call, or any wrapper that exits
between calls, tears the host down before Studio finishes dialling it, and every
call answers `Not connected to the WS host` — which looks exactly like a Studio
that has not finished loading, and waiting longer never helps. A long-lived MCP
session is not an optimization here, it is the protocol.

**A latched `start_stop_play` is cleared by restarting the relay, not Studio.**
The previous handoff recorded that only a Studio restart clears it. It does not:
killing `StudioMCP.exe` and reconnecting gives a responsive session with Studio
left alone and its place still loaded, which turns a four-minute recovery into a
ten-second one.

#### Play mode is unreachable on a Wayland session, and this is why

Measured on 2026-08-10, KDE Plasma on Wayland with a rootless Xwayland
(`/usr/bin/Xwayland :1 ... -rootless -enable-ei-portal`). **No synthetic input
reaches Studio by any route**, so the Play button cannot be pressed:

| Route | Result |
|---|---|
| `xdotool key --window <wid> F5` (XSendEvent) | ignored |
| `xdotool key F5` (XTEST) | ignored |
| A real `/dev/uinput` virtual keyboard | ignored |

The uinput device is genuinely created and seated — it appears in
`/proc/bus/input/devices` with `Handlers=kbd mouse2 event17` — and it still
changes nothing. Two independent witnesses confirm the input never reaches the
compositor's focus chain rather than being dropped by Studio: Studio's own log
reports `No user input within the last 5000 ms` throughout, and pressing **Meta**
does not open KDE's launcher either.

**The trap is that the pointer half of XTEST works.** `xdotool mousemove` moves
the cursor and `getmouselocation` reports the new position, so input looks alive
while every keystroke and click is going nowhere. Do not take a moving cursor as
evidence.

The cause is `-enable-ei-portal`: XTEST from X clients is routed through the
RemoteDesktop portal, and granting that portal needs a dialog that can only be
clicked by somebody at the machine. So `start_stop_play` never completes (it
answers `Start play hasn't finished yet` forever) and `F5` never lands.

**What this costs, stated plainly: there is no Play mode, so there is no live
walk, so no region can have its flag flipped.** A region ships open only in the
pull request of its own live walk, and that gate cannot be cleared from a session
in this state. Ask the owner to press Play at the keyboard, or run the session on
a seat where input is not portal-gated.

**What still works is the entire Edit datamodel**, and it is more than it sounds:
`execute_luau` against the real place, `screen_capture` from an arbitrary camera
position, `search_game_tree`, `inspect_instance`. That is enough to build a
region for real inside Roblox's own VM, drive the pure encounter modules through
their full state machines against the shared wiring, sweep thousands of
generation seeds in the engine rather than in Lune, and photograph the result at
player height in any lighting. It is **not** a walk — no player character, no
server-validated interaction, no real click — and a session that blurs those two
is worth less than one that verifies nothing, because the next reader cannot tell
which it did.

### 3. Confirm it is actually connected

Open `build/LastLight.rbxlx` in Studio, start a session in the repository root,
and ask it to list the children of `Workspace`. Real instance names mean it
works. Anything else, see the troubleshooting table.

## Troubleshooting

| Symptom | Cause |
|---|---|
| JSON parse errors, connection drops immediately | Something is writing to stdout besides the protocol. Wine's `fixme:` chatter is the usual culprit; the wrapper redirects stderr to `/tmp/studio-mcp.log` for exactly this reason. Check that log. |
| `mcp.bat not found` | The MCP server has not been enabled in Studio yet — Studio writes the file when you enable it — or the probe missed. Run `find ~ -name mcp.bat` (search `~`, not the prefix; see above) and set `STUDIO_MCP_BAT`. |
| `'wine' is not on PATH` | Vinegar's Flatpak runtime does not export a wine binary. Install Wine on the host, or set `WINE_BIN`. |
| `Path not found.` in the log, connection closes immediately | The wrapper is invoking `cd` with a resolved absolute path instead of the `%LOCALAPPDATA%` literal — expected only when `STUDIO_MCP_BAT` is set explicitly to a custom location (see bug 3 above). Confirm the override actually points at `mcp.bat`, or unset it and let discovery find the standard one. |
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
minutes to boot the place. The MCP bridge survives the
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
