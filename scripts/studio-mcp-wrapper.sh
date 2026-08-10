#!/usr/bin/env bash
#
# Launches Roblox Studio's built-in MCP server so an MCP client running on Linux
# can drive a Studio that is itself running under Wine (Vinegar).
#
# Why a wrapper exists at all: the MCP client speaks stdio, so it spawns the
# server as a child process and talks over pipes. Studio's server lives inside
# the Wine prefix, so something has to bridge the two. That is all this does --
# find the launcher, run it under the right prefix, and keep the pipe clean.
#
# ---------------------------------------------------------------------------
# Four things earlier versions of this script got wrong, each measured on real
# hardware rather than reasoned out from documentation:
#
#   1. **The launcher is `mcp.bat`, not `StudioMCP.exe`.** Enabling "Studio as
#      MCP server" writes a small batch file. `mcp.bat` itself, in turn, is a
#      thin dispatcher: its first branch runs the real `StudioMCP.exe` for the
#      Studio version currently installed, when that exists.
#
#   2. **It is not under `drive_c`.** Vinegar redirects `%LOCALAPPDATA%` out of
#      the prefix entirely, onto the host filesystem through Wine's `Z:` drive.
#      On the machine this was measured on, Wine reports:
#
#        %LOCALAPPDATA% = Z:\home\<user>\.var\app\org.vinegarhq.Vinegar\data\vinegar\appdata
#
#      while `drive_c/users/*/AppData/Local/Roblox/` exists and holds only
#      plugin and instance directories. So a search rooted at `drive_c` -- which
#      is what the old script did -- searches the one place the file is not.
#
#   3. **A host-resolved Windows path handed to `cd` is not the same thing as
#      the identical string resolved by Wine's own `%LOCALAPPDATA%`, even
#      though they print identically.** A version that fixed both bugs above
#      still failed to launch:
#
#        cd /d "Z:\home\<user>\.var\app\org.vinegarhq.Vinegar\data\vinegar\appdata\Roblox"
#        Path not found.
#
#      for the *exact same string* `%LOCALAPPDATA%\Roblox` resolves to and
#      reaches without complaint one line up. Separate investigation of the
#      same failure also found that an *unquoted* `cd` to that path, and
#      direct execution of the resolved `.exe`, both succeed where the quoted,
#      host-translated `cd /d "Z:\..."` does not. Nobody chased the exact Wine
#      internals responsible -- the fix does not need the cause, only to stop
#      building a string cd refuses and use one of the two that are proven to
#      work: launch the resolved executable directly (needs no `cd` at all,
#      and is what this script now prefers), or hand `cd` Wine's own
#      unresolved `%LOCALAPPDATA%` and let Wine expand its own variable.
#      Launching the executable directly also sidesteps a `Syntax error:
#      unexpected ELSE` Wine's batch parser can emit from `mcp.bat` after the
#      MCP process exits.
#
#   4. **A discovered path is not automatically Wine's own answer.** The
#      literal-`%LOCALAPPDATA%` fix for bug 3 is only sound when the file
#      discovery found really is what Wine's `%LOCALAPPDATA%\Roblox` resolves
#      to. That holds by construction for a Vinegar install (Flatpak or
#      native), which has exactly one appdata directory -- but a plain Wine
#      prefix can hold more than one Windows user profile under
#      `drive_c/users/*`, and the glob below can match a stale one while Wine
#      itself is currently answering for a different, active user. Discovery
#      succeeding is then not the same as the literal being safe to use, so
#      that one ambiguous candidate is checked against Wine's own answer
#      before being trusted; every other candidate is unambiguous by
#      construction and skips the check.
#
# None of the four was visible by reading the script. The first two were
# obvious the moment it ran against a directory tree; the third and fourth
# only on the machine Studio actually runs on.
# ---------------------------------------------------------------------------
#
# The other non-obvious part is the stderr redirect at the bottom. MCP over
# stdio is JSON-RPC on stdout, and Wine prints `fixme:` chatter constantly.
# Anything that leaks into stdout corrupts the stream and the connection dies
# with a parse error that says nothing about Wine. Sending Wine's noise to a log
# keeps stdout clean and gives you somewhere to look when it misbehaves.
#
# Usage, once (from the repository root):
#
#   claude mcp add roblox-studio --scope user --transport stdio -- \
#       "$PWD/scripts/studio-mcp-wrapper.sh"
#
# No `--stdio` argument: neither `mcp.bat` nor the `.exe` it launches takes
# one. Anything passed here is forwarded anyway, so an old registration still
# runs.
#
# Override any of these if your install differs:
#
#   STUDIO_MCP_BAT   full host path to mcp.bat
#   WINEPREFIX       the Wine prefix Studio runs in
#   STUDIO_MCP_LOG   where Wine's stderr goes (default /tmp/studio-mcp.log)
#   WINE_BIN         wine binary to use (default: wine on PATH)

set -euo pipefail

log="${STUDIO_MCP_LOG:-/tmp/studio-mcp.log}"
wine_bin="${WINE_BIN:-wine}"

die() {
    printf 'studio-mcp-wrapper: %s\n' "$@" >&2
    exit 1
}

# --- The prefix -----------------------------------------------------------
#
# Vinegar's location differs between a Flatpak install and a native one, which
# is exactly the kind of thing that is wrong in a hardcoded path six months
# from now. Flatpak first: that is the supported install and the one measured.
if [[ -z "${WINEPREFIX:-}" ]]; then
    for candidate in \
        "$HOME/.var/app/org.vinegarhq.Vinegar/data/vinegar/prefixes/studio" \
        "$HOME/.local/share/vinegar/prefixes/studio" \
        "$HOME/.local/share/vinegar/prefix" \
        "$HOME/.wine"
    do
        if [[ -d "$candidate/drive_c" ]]; then
            WINEPREFIX="$candidate"
            break
        fi
    done
fi

if [[ -z "${WINEPREFIX:-}" || ! -d "${WINEPREFIX:-}/drive_c" ]]; then
    die "no Wine prefix found. Set WINEPREFIX to the directory containing drive_c."
fi
export WINEPREFIX

[[ -x "$wine_bin" ]] || command -v "$wine_bin" >/dev/null 2>&1 \
    || die "'$wine_bin' is not on PATH. Set WINE_BIN." \
           "Vinegar's own Flatpak runtime does not export a wine binary; this needs" \
           "a host Wine (Debian/Kali: apt install wine)."

# --- The launcher -----------------------------------------------------------
#
# **Every candidate is derived from the prefix chosen above, never from a fixed
# global path.** An earlier version listed Vinegar's Flatpak and native appdata
# directories absolutely, which meant that on a machine carrying both -- or one
# with stale Flatpak appdata left over from a migration -- an explicitly set
# WINEPREFIX could be paired with the *other* installation's mcp.bat. That runs
# one install's launcher against another install's prefix, and the failure is
# the confusing kind: it starts, and then cannot see the Studio you are
# actually looking at.
#
# Vinegar keeps its prefix and its appdata as siblings under one root --
# <root>/prefixes/studio beside <root>/appdata -- so the appdata is derivable
# from the prefix rather than guessable. The third form is plain Wine, where
# LOCALAPPDATA is not redirected and lives inside drive_c.
#
# `bat_is_localappdata_roblox` tracks whether whatever STUDIO_MCP_BAT ends up
# holding is, by construction or by verification, what this prefix's Wine
# calls `%LOCALAPPDATA%\Roblox` -- the launch section below reads this flag to
# decide whether it is safe to hand Wine that literal, unresolved variable
# (proven correct, bug 3) instead of a host-computed translation of a
# specific path (not, for the same reason). An explicit override can point
# anywhere, so it always starts this false. The two appdata-anchored
# candidates are unambiguous by construction -- a Vinegar install has exactly
# one appdata directory -- so they stay true without asking Wine anything. The
# plain-Wine `drive_c/users/*` candidate is the one pattern that is not
# unambiguous (bug 4): a prefix can hold more than one Windows user profile,
# so it is checked against Wine's own answer before being trusted.
bat_is_localappdata_roblox=true
if [[ -n "${STUDIO_MCP_BAT:-}" ]]; then
    bat_is_localappdata_roblox=false
else
    prefix_parent="$(dirname "$WINEPREFIX")"
    flatpak_appdata_bat="$(dirname "$prefix_parent")/appdata/Roblox/mcp.bat"
    native_appdata_bat="$prefix_parent/appdata/Roblox/mcp.bat"
    if [[ -f "$flatpak_appdata_bat" ]]; then
        STUDIO_MCP_BAT="$flatpak_appdata_bat"
    elif [[ -f "$native_appdata_bat" ]]; then
        STUDIO_MCP_BAT="$native_appdata_bat"
    else
        for candidate in "$WINEPREFIX"/drive_c/users/*/AppData/Local/Roblox/mcp.bat; do
            if [[ -f "$candidate" ]]; then
                STUDIO_MCP_BAT="$candidate"
                bat_is_localappdata_roblox=false
                if command -v winepath >/dev/null 2>&1; then
                    localappdata_win="$(
                        "$wine_bin" cmd /c 'echo %LOCALAPPDATA%' 2>>"$log" | tr -d '\r\n' || true
                    )"
                    if [[ -n "$localappdata_win" && "$localappdata_win" != '%LOCALAPPDATA%' ]]; then
                        localappdata_host="$(
                            winepath -u "$localappdata_win" 2>>"$log" | tr -d '\r\n' || true
                        )"
                        if [[ -n "$localappdata_host" && "$localappdata_host/Roblox/mcp.bat" == "$candidate" ]]; then
                            bat_is_localappdata_roblox=true
                        fi
                    fi
                fi
                break
            fi
        done
    fi
fi

# Last resort, for a layout none of the three patterns match: ask Wine where
# LOCALAPPDATA points *for this prefix*, directly. That is true by
# construction rather than by pattern, so it survives a layout nobody here has
# seen -- and it cannot stray to another installation or another user's
# profile, which is the whole point. It is last because it costs a Wine
# startup, and a slow launcher reads to the client as a failed handshake
# rather than as a slow one. What it finds is `%LOCALAPPDATA%\Roblox` by
# definition -- it is the same variable, just asked for directly -- so the
# flag stays true.
if [[ -z "${STUDIO_MCP_BAT:-}" ]] && command -v winepath >/dev/null 2>&1; then
    localappdata_win="$("$wine_bin" cmd /c 'echo %LOCALAPPDATA%' 2>>"$log" | tr -d '\r\n' || true)"
    if [[ -n "$localappdata_win" && "$localappdata_win" != '%LOCALAPPDATA%' ]]; then
        localappdata_host="$(winepath -u "$localappdata_win" 2>>"$log" | tr -d '\r\n' || true)"
        if [[ -n "$localappdata_host" && -f "$localappdata_host/Roblox/mcp.bat" ]]; then
            STUDIO_MCP_BAT="$localappdata_host/Roblox/mcp.bat"
        fi
    fi
fi

if [[ -z "${STUDIO_MCP_BAT:-}" || ! -f "$STUDIO_MCP_BAT" ]]; then
    die "mcp.bat not found for prefix $WINEPREFIX." \
        "Enable it first in Studio: Assistant -> ... -> Manage MCP Servers ->" \
        "\"Enable Studio as MCP server\". Studio writes mcp.bat when you do." \
        "Then, if it still cannot be found: find ~ -name mcp.bat, and set" \
        "STUDIO_MCP_BAT to whichever one belongs to this prefix. If you have" \
        "both a Flatpak and a native Vinegar, they have one each -- setting" \
        "WINEPREFIX alone does not pick between them."
fi

# --- Prefer the executable mcp.bat itself would run ------------------------
#
# Roblox currently writes the exact StudioMCP.exe for the running Studio
# version into the first `if exist` branch of mcp.bat. Resolving and launching
# that executable directly is the fix for bug 3: it needs no `cd` at all,
# so there is no host-translated path for Wine to refuse, and it sidesteps
# the batch parser entirely, so it cannot hit the `Syntax error: unexpected
# ELSE` Wine's parser can emit from mcp.bat after the MCP process exits.
studio_mcp_exe=""
studio_mcp_exe_win="$(
    sed -n 's/^[[:space:]]*if exist "\([^"]*StudioMCP\.exe\)".*/\1/p' \
        "$STUDIO_MCP_BAT" | head -n 1
)"
if [[ -n "$studio_mcp_exe_win" ]]; then
    if command -v winepath >/dev/null 2>&1; then
        studio_mcp_exe="$(winepath -u "$studio_mcp_exe_win" 2>>"$log" | tr -d '\r\n' || true)"
    elif [[ "$studio_mcp_exe_win" =~ ^[Zz]:\\ ]]; then
        studio_mcp_exe="/${studio_mcp_exe_win:3}"
        studio_mcp_exe="${studio_mcp_exe//\\//}"
    fi
fi
if [[ -n "$studio_mcp_exe" && ! -f "$studio_mcp_exe" ]]; then
    studio_mcp_exe=""
fi

# --- Batch fallback: host path to Windows path, or not ---------------------
#
# Used only when the executable above could not be resolved -- mcp.bat did not
# parse the way Roblox currently writes it, or the file it named is missing.
# This is why discovery above only ever inspects the host filesystem to check
# *whether* mcp.bat exists (for a fast, specific error before Wine even
# starts) rather than to build the string handed to `cd`: the string actually
# used here is Wine's own `%LOCALAPPDATA%`, unresolved, for the reason bug 3
# exists. The one case that still needs a host->Windows translation is an
# explicit STUDIO_MCP_BAT override pointing somewhere `%LOCALAPPDATA%\Roblox`
# does not reach -- or the plain-Wine multi-user case from bug 4, when the
# check there could not confirm the two agree.
if [[ -z "$studio_mcp_exe" ]]; then
    if [[ "$bat_is_localappdata_roblox" == true ]]; then
        target_dir='%LOCALAPPDATA%\Roblox'
    else
        bat_dir="$(dirname "$STUDIO_MCP_BAT")"
        if command -v winepath >/dev/null 2>&1; then
            win_dir="$(winepath -w "$bat_dir" 2>>"$log" || true)"
            win_dir="${win_dir%$'\r'}"
        else
            win_dir=""
        fi
        if [[ -z "$win_dir" ]]; then
            win_dir="Z:${bat_dir//\//\\}"
        fi
        target_dir="$win_dir"
    fi
fi

# Stamp the log so a stale one is not mistaken for the current run.
{
    echo "--- studio-mcp-wrapper $(date -Is)"
    echo "    WINEPREFIX=$WINEPREFIX"
    echo "    STUDIO_MCP_BAT=$STUDIO_MCP_BAT"
    echo "    STUDIO_MCP_EXE=${studio_mcp_exe:-<batch fallback>}"
    if [[ -z "$studio_mcp_exe" ]]; then
        echo "    target_dir=$target_dir"
    fi
} >>"$log" 2>/dev/null || true

if [[ -n "$studio_mcp_exe" ]]; then
    exec "$wine_bin" "$studio_mcp_exe" "$@" 2>>"$log"
fi

# `cd /d` first because mcp.bat resolves what it launches relative to its own
# directory. `.\mcp.bat` rather than a bare `mcp.bat`, matching the exact
# invocation confirmed working, for the same reason `target_dir` above avoids
# inventing an equivalent string when a proven one is available. stdout stays
# untouched: it is the JSON-RPC stream.
command_line="cd /d \"$target_dir\" && .\\mcp.bat"
if [[ $# -gt 0 ]]; then
    command_line="$command_line $*"
fi
exec "$wine_bin" cmd /c "$command_line" 2>>"$log"
