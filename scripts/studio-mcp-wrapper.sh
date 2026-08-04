#!/usr/bin/env bash
#
# Launches Roblox Studio's built-in MCP server so an MCP client running on Linux
# can drive a Studio that is itself running under Wine (Vinegar).
#
# Why a wrapper exists at all: the MCP client speaks stdio, so it spawns the
# server as a child process and talks over pipes. Studio's server ships as a
# Windows executable inside the Wine prefix, so something has to bridge the two.
# That is all this does -- find the executable, run it under the right prefix,
# and keep the pipe clean.
#
# The one non-obvious part is the stderr redirect at the bottom. MCP over stdio
# is JSON-RPC on stdout, and Wine prints `fixme:` chatter constantly. Anything
# that leaks into stdout corrupts the stream and the connection dies with a
# parse error that says nothing about Wine. Sending Wine's noise to a log keeps
# stdout clean and gives you somewhere to look when it misbehaves.
#
# Usage, once (from the repository root):
#
#   claude mcp add roblox-studio --transport stdio -- \
#       "$PWD/scripts/studio-mcp-wrapper.sh" --stdio
#
# Override any of these if your install differs:
#
#   STUDIO_MCP_EXE   full path to StudioMCP.exe
#   WINEPREFIX       the Wine prefix Studio runs in
#   STUDIO_MCP_LOG   where Wine's stderr goes (default /tmp/studio-mcp.log)
#   WINE_BIN         wine binary to use (default: wine on PATH)

set -euo pipefail

log="${STUDIO_MCP_LOG:-/tmp/studio-mcp.log}"
wine_bin="${WINE_BIN:-wine}"

# Prefix candidates, most specific first. Vinegar's location differs between a
# native install and a Flatpak one, which is exactly the kind of thing that is
# wrong in a hardcoded path six months from now.
if [[ -z "${WINEPREFIX:-}" ]]; then
    for candidate in \
        "$HOME/.local/share/vinegar/prefixes/studio" \
        "$HOME/.var/app/org.vinegarhq.Vinegar/data/vinegar/prefixes/studio" \
        "$HOME/.local/share/vinegar/prefix" \
        "$HOME/.wine"
    do
        if [[ -d "$candidate/drive_c" ]]; then
            WINEPREFIX="$candidate"
            break
        fi
    done
fi

if [[ -z "${WINEPREFIX:-}" || ! -d "$WINEPREFIX/drive_c" ]]; then
    echo "studio-mcp-wrapper: no Wine prefix found. Set WINEPREFIX to the" \
         "directory containing drive_c." >&2
    exit 1
fi
export WINEPREFIX

# Studio's version directory changes with every update, so the executable is
# searched for rather than pinned. Newest match wins, because an old version
# directory often lingers after an update and would otherwise be picked first.
if [[ -z "${STUDIO_MCP_EXE:-}" ]]; then
    STUDIO_MCP_EXE="$(
        find "$WINEPREFIX/drive_c" -name 'StudioMCP.exe' -type f -printf '%T@ %p\n' 2>/dev/null \
            | sort -rn | head -1 | cut -d' ' -f2-
    )"
fi

if [[ -z "${STUDIO_MCP_EXE:-}" || ! -f "$STUDIO_MCP_EXE" ]]; then
    {
        echo "studio-mcp-wrapper: StudioMCP.exe not found under $WINEPREFIX/drive_c."
        echo "Enable it first in Studio: Assistant -> ... -> Manage MCP Servers ->"
        echo "\"Enable Studio as MCP server\", then set STUDIO_MCP_EXE if it still"
        echo "cannot be found automatically."
    } >&2
    exit 1
fi

if ! command -v "$wine_bin" >/dev/null 2>&1; then
    echo "studio-mcp-wrapper: '$wine_bin' is not on PATH. Set WINE_BIN." >&2
    exit 1
fi

# Stamp the log so a stale one is not mistaken for the current run.
{
    echo "--- studio-mcp-wrapper $(date -Is)"
    echo "    WINEPREFIX=$WINEPREFIX"
    echo "    STUDIO_MCP_EXE=$STUDIO_MCP_EXE"
} >>"$log" 2>/dev/null || true

# stdout stays untouched: it is the JSON-RPC stream.
exec "$wine_bin" "$STUDIO_MCP_EXE" "$@" 2>>"$log"
