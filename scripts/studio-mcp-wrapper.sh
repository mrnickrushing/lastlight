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
# Two things the first version of this script got wrong, both measured since:
#
#   1. **The launcher is `mcp.bat`, not `StudioMCP.exe`.** Enabling "Studio as
#      MCP server" writes a small batch file; there is no such executable to
#      find, so the old probe could only ever fail.
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
# `%LOCALAPPDATA%\Roblox` is the correct answer in *both* layouts: under Vinegar
# it resolves to the redirected host directory, and under a plain Wine prefix it
# resolves inside `drive_c`. This script still locates the file host-side first,
# so a failure names a path instead of dying inside `cmd`.
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
# No `--stdio` argument: `mcp.bat` takes none. Anything passed here is forwarded
# to it anyway, so an old registration still runs.
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

command -v "$wine_bin" >/dev/null 2>&1 \
    || die "'$wine_bin' is not on PATH. Set WINE_BIN." \
           "Vinegar's own Flatpak runtime does not export a wine binary; this needs" \
           "a host Wine (Debian/Kali: apt install wine)."

# --- The launcher ---------------------------------------------------------
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
if [[ -z "${STUDIO_MCP_BAT:-}" ]]; then
    prefix_parent="$(dirname "$WINEPREFIX")"
    for candidate in \
        "$(dirname "$prefix_parent")/appdata/Roblox/mcp.bat" \
        "$prefix_parent/appdata/Roblox/mcp.bat" \
        "$WINEPREFIX"/drive_c/users/*/AppData/Local/Roblox/mcp.bat
    do
        if [[ -f "$candidate" ]]; then
            STUDIO_MCP_BAT="$candidate"
            break
        fi
    done
fi

# Last resort, and the authoritative one: ask Wine where LOCALAPPDATA points
# *for this prefix*. That is true by construction rather than by pattern, so it
# survives a layout nobody here has seen -- and it cannot stray to another
# installation, which is the whole point. It is last because it costs a Wine
# startup, and a slow launcher reads to the client as a failed handshake rather
# than as a slow one.
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

# --- Host path to Windows path -------------------------------------------
#
# winepath is authoritative and ships with Wine. The fallback is the same
# mapping by hand: Wine's Z: drive is the host root, universally and by
# default -- which is exactly what `wine cmd /c echo %LOCALAPPDATA%` reports on
# a Vinegar install.
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

# Stamp the log so a stale one is not mistaken for the current run.
{
    echo "--- studio-mcp-wrapper $(date -Is)"
    echo "    WINEPREFIX=$WINEPREFIX"
    echo "    STUDIO_MCP_BAT=$STUDIO_MCP_BAT"
    echo "    win_dir=$win_dir"
} >>"$log" 2>/dev/null || true

# `cd /d` first because mcp.bat resolves what it launches relative to its own
# directory. stdout stays untouched: it is the JSON-RPC stream.
command_line="cd /d \"$win_dir\" && mcp.bat"
if [[ $# -gt 0 ]]; then
    command_line="$command_line $*"
fi
exec "$wine_bin" cmd /c "$command_line" 2>>"$log"
