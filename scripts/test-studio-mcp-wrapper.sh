#!/usr/bin/env bash
#
# Tests for scripts/studio-mcp-wrapper.sh.
#
# This wrapper has shipped wrong twice. The first version looked for a
# StudioMCP.exe that does not exist, under a drive_c that does not hold it. The
# second fixed both of those and still paired an explicitly chosen Wine prefix
# with another installation's launcher. Neither failure is visible by reading
# the script; both are obvious the moment it is run against a directory tree.
#
# So it gets run. Each case builds a throwaway $HOME with a known layout and a
# stub `wine` that prints its argv instead of executing anything, then asserts
# on what the wrapper resolved. What is NOT covered is Wine itself -- whether
# mcp.bat actually launches and speaks JSON-RPC needs the machine Studio runs
# on, and no fixture here can stand in for that.

set -uo pipefail

wrapper="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/studio-mcp-wrapper.sh"
root="$(mktemp -d)"
trap 'rm -rf "$root"' EXIT

passed=0
failed=0

fail() {
    printf '  FAIL %s\n       %s\n' "$1" "$2" >&2
    failed=$((failed + 1))
}

pass() {
    printf '  PASS %s\n' "$1"
    passed=$((passed + 1))
}

# A home with a stub wine, a stub winepath, and nothing else.
make_home() {
    local home="$root/$1"
    mkdir -p "$home/bin"
    cat >"$home/bin/wine" <<'STUB'
#!/bin/sh
# `cmd /c echo %LOCALAPPDATA%` is answered from the environment so a fixture can
# drive the authoritative-fallback path; anything else echoes its argv.
if [ "$1" = "cmd" ] && [ "$3" = "echo %LOCALAPPDATA%" ]; then
    printf '%s\n' "${STUB_LOCALAPPDATA:-%LOCALAPPDATA%}"
    exit 0
fi
printf 'WINE-ARGS:'
for a in "$@"; do printf ' [%s]' "$a"; done
printf '\n'
STUB
    cat >"$home/bin/winepath" <<'STUB'
#!/bin/sh
# -u maps a Z: path back to the host root; -w does the reverse. That is Wine's
# own default mapping, and it is what the real thing reports on a Vinegar
# install.
case "$1" in
    -u) printf '%s\n' "$(printf '%s' "$2" | sed 's|^[Zz]:||; s|\\|/|g')" ;;
    -w) printf 'Z:%s\n' "$(printf '%s' "$2" | sed 's|/|\\|g')" ;;
esac
STUB
    chmod +x "$home/bin/wine" "$home/bin/winepath"
    printf '%s' "$home"
}

# Leading VAR=value arguments become environment for the run; anything after
# them is passed through to the wrapper itself. (A wrapper argument containing
# an "=" would be misread as environment -- no such argument exists, and the
# alternative is a separator that every call site would have to carry.)
run_wrapper() {
    local home="$1"; shift
    local envs=()
    while [[ $# -gt 0 && "$1" == *=* ]]; do
        envs+=("$1")
        shift
    done
    env -i HOME="$home" PATH="$home/bin:/usr/bin:/bin" WINE_BIN="$home/bin/wine" \
        STUDIO_MCP_LOG="$home/log" "${envs[@]}" bash "$wrapper" "$@" 2>&1
}

# What the wrapper resolved, read back out of its own log.
# A run that died before it resolved anything writes no log at all, which is a
# failure to report rather than one to print sed errors about.
resolved() {
    sed -n 's/^ *STUDIO_MCP_BAT=//p' "$1/log" 2>/dev/null | tail -1
}

vinegar_flatpak="/.var/app/org.vinegarhq.Vinegar/data/vinegar"
vinegar_native="/.local/share/vinegar"

# --- Cases ---------------------------------------------------------------

case_flatpak_default() {
    local home; home="$(make_home flatpak)"
    mkdir -p "$home$vinegar_flatpak/prefixes/studio/drive_c" "$home$vinegar_flatpak/appdata/Roblox"
    : >"$home$vinegar_flatpak/appdata/Roblox/mcp.bat"
    local out; out="$(run_wrapper "$home")"
    if [[ "$out" == *"appdata\\Roblox\" && mcp.bat"* ]]; then
        pass "Vinegar Flatpak: finds the redirected appdata launcher"
    else
        fail "Vinegar Flatpak: finds the redirected appdata launcher" "$out"
    fi
}

case_plain_wine() {
    local home; home="$(make_home plain)"
    mkdir -p "$home/.wine/drive_c/users/nick/AppData/Local/Roblox"
    : >"$home/.wine/drive_c/users/nick/AppData/Local/Roblox/mcp.bat"
    local out; out="$(run_wrapper "$home")"
    if [[ "$out" == *"drive_c\\users\\nick\\AppData\\Local\\Roblox\" && mcp.bat"* ]]; then
        pass "plain Wine: finds the launcher inside drive_c"
    else
        fail "plain Wine: finds the launcher inside drive_c" "$out"
    fi
}

# The regression Codex caught. Both installations present, each with its own
# launcher, and WINEPREFIX naming one of them explicitly. Picking the other
# one's mcp.bat starts a server that cannot see the Studio you are looking at.
case_two_installs_native_selected() {
    local home; home="$(make_home both_native)"
    mkdir -p "$home$vinegar_flatpak/prefixes/studio/drive_c" "$home$vinegar_flatpak/appdata/Roblox" \
             "$home$vinegar_native/prefixes/studio/drive_c" "$home$vinegar_native/appdata/Roblox"
    : >"$home$vinegar_flatpak/appdata/Roblox/mcp.bat"
    : >"$home$vinegar_native/appdata/Roblox/mcp.bat"
    run_wrapper "$home" WINEPREFIX="$home$vinegar_native/prefixes/studio" >/dev/null
    if [[ "$(resolved "$home")" == "$home$vinegar_native/appdata/Roblox/mcp.bat" ]]; then
        pass "two installs, native prefix chosen: uses the native launcher"
    else
        fail "two installs, native prefix chosen: uses the native launcher" "$(resolved "$home")"
    fi
}

case_two_installs_flatpak_selected() {
    local home; home="$(make_home both_flatpak)"
    mkdir -p "$home$vinegar_flatpak/prefixes/studio/drive_c" "$home$vinegar_flatpak/appdata/Roblox" \
             "$home$vinegar_native/prefixes/studio/drive_c" "$home$vinegar_native/appdata/Roblox"
    : >"$home$vinegar_flatpak/appdata/Roblox/mcp.bat"
    : >"$home$vinegar_native/appdata/Roblox/mcp.bat"
    run_wrapper "$home" WINEPREFIX="$home$vinegar_flatpak/prefixes/studio" >/dev/null
    if [[ "$(resolved "$home")" == "$home$vinegar_flatpak/appdata/Roblox/mcp.bat" ]]; then
        pass "two installs, Flatpak prefix chosen: uses the Flatpak launcher"
    else
        fail "two installs, Flatpak prefix chosen: uses the Flatpak launcher" "$(resolved "$home")"
    fi
}

# A layout none of the patterns match, where only Wine itself knows the answer.
case_wine_query_fallback() {
    local home; home="$(make_home unknown_layout)"
    mkdir -p "$home/odd/prefix/drive_c" "$home/somewhere/else/Roblox"
    : >"$home/somewhere/else/Roblox/mcp.bat"
    run_wrapper "$home" WINEPREFIX="$home/odd/prefix" \
        STUB_LOCALAPPDATA="Z:${home//\//\\}\\somewhere\\else" >/dev/null
    if [[ "$(resolved "$home")" == "$home/somewhere/else/Roblox/mcp.bat" ]]; then
        pass "unknown layout: asks Wine where LOCALAPPDATA points"
    else
        fail "unknown layout: asks Wine where LOCALAPPDATA points" "$(resolved "$home")"
    fi
}

case_override_wins() {
    local home; home="$(make_home override)"
    mkdir -p "$home$vinegar_flatpak/prefixes/studio/drive_c" "$home$vinegar_flatpak/appdata/Roblox" \
             "$home/custom"
    : >"$home$vinegar_flatpak/appdata/Roblox/mcp.bat"
    : >"$home/custom/mcp.bat"
    run_wrapper "$home" STUDIO_MCP_BAT="$home/custom/mcp.bat" >/dev/null
    if [[ "$(resolved "$home")" == "$home/custom/mcp.bat" ]]; then
        pass "STUDIO_MCP_BAT overrides discovery"
    else
        fail "STUDIO_MCP_BAT overrides discovery" "$(resolved "$home")"
    fi
}

case_path_with_space() {
    local home; home="$(make_home 'spaced')"
    mkdir -p "$home/My Prefix/drive_c/users/nick/AppData/Local/Roblox"
    : >"$home/My Prefix/drive_c/users/nick/AppData/Local/Roblox/mcp.bat"
    local out; out="$(run_wrapper "$home" WINEPREFIX="$home/My Prefix")"
    if [[ "$out" == *'[cd /d "Z:'*'My Prefix'*'" && mcp.bat]'* ]]; then
        pass "a prefix path containing a space stays quoted"
    else
        fail "a prefix path containing a space stays quoted" "$out"
    fi
}

case_forwards_arguments() {
    local home; home="$(make_home args)"
    mkdir -p "$home$vinegar_flatpak/prefixes/studio/drive_c" "$home$vinegar_flatpak/appdata/Roblox"
    : >"$home$vinegar_flatpak/appdata/Roblox/mcp.bat"
    local out; out="$(run_wrapper "$home" --stdio)"
    if [[ "$out" == *"&& mcp.bat --stdio]"* ]]; then
        pass "an older --stdio registration still forwards its argument"
    else
        fail "an older --stdio registration still forwards its argument" "$out"
    fi
}

case_direct_exe_from_generated_batch() {
    local home; home="$(make_home direct_exe)"
    local root_dir="$home$vinegar_flatpak"
    local exe="$root_dir/versions/version-current/StudioMCP.exe"
    mkdir -p "$root_dir/prefixes/studio/drive_c" "$root_dir/appdata/Roblox" \
             "$(dirname "$exe")"
    : >"$exe"
    printf 'if exist "Z:%s" ( "Z:%s" %%* )\n' \
        "${exe//\//\\}" "${exe//\//\\}" >"$root_dir/appdata/Roblox/mcp.bat"
    local out; out="$(run_wrapper "$home" --stdio)"
    if [[ "$out" == *"WINE-ARGS: [$exe] [--stdio]"* ]]; then
        pass "generated batch: launches its exact StudioMCP executable directly"
    else
        fail "generated batch: launches its exact StudioMCP executable directly" "$out"
    fi
}

case_no_launcher() {
    local home; home="$(make_home no_bat)"
    mkdir -p "$home$vinegar_flatpak/prefixes/studio/drive_c"
    local out; out="$(run_wrapper "$home")"
    if [[ "$out" == *"mcp.bat not found"* ]]; then
        pass "MCP server never enabled: says so, and names the prefix"
    else
        fail "MCP server never enabled: says so, and names the prefix" "$out"
    fi
}

case_no_prefix() {
    local home; home="$(make_home no_prefix)"
    local out; out="$(run_wrapper "$home")"
    if [[ "$out" == *"no Wine prefix found"* ]]; then
        pass "no prefix anywhere: asks for WINEPREFIX"
    else
        fail "no prefix anywhere: asks for WINEPREFIX" "$out"
    fi
}

case_no_wine() {
    local home; home="$(make_home no_wine)"
    mkdir -p "$home$vinegar_flatpak/prefixes/studio/drive_c" "$home$vinegar_flatpak/appdata/Roblox"
    : >"$home$vinegar_flatpak/appdata/Roblox/mcp.bat"
    local out
    out="$(env -i HOME="$home" PATH="/usr/bin:/bin" \
        WINE_BIN="$home/bin/missing-wine" STUDIO_MCP_LOG="$home/log" \
        /usr/bin/bash "$wrapper" 2>&1)"
    if [[ "$out" == *"is not on PATH"* ]]; then
        pass "no wine on PATH: explains the Flatpak/host split"
    else
        fail "no wine on PATH: explains the Flatpak/host split" "$out"
    fi
}

echo "Suite: studio-mcp-wrapper"
case_flatpak_default
case_plain_wine
case_two_installs_native_selected
case_two_installs_flatpak_selected
case_wine_query_fallback
case_override_wins
case_path_with_space
case_forwards_arguments
case_direct_exe_from_generated_batch
case_no_launcher
case_no_prefix
case_no_wine

printf 'studio-mcp-wrapper tests complete: %d passed, %d failed\n' "$passed" "$failed"
[[ $failed -eq 0 ]]
