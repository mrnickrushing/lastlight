#!/usr/bin/env bash
#
# Tests for scripts/studio-mcp-wrapper.sh.
#
# This wrapper has shipped wrong three times. The first version looked for a
# StudioMCP.exe that does not exist, under a drive_c that does not hold it. The
# second fixed both of those and still paired an explicitly chosen Wine prefix
# with another installation's launcher. The third fixed that too and still
# failed to launch on the real machine: it pre-resolved a host path to a
# Windows path and handed cmd.exe that literal string, and cmd refused it with
# "Path not found" for the exact string that Wine's own expansion of
# %LOCALAPPDATA% resolves to without complaint. None of the three was visible
# by reading the script; the first two were obvious the moment it ran against
# a directory tree, and the third only on the machine Studio runs on.
#
# So it gets run, as far as it can be. Each case builds a throwaway $HOME with
# a known layout and a stub `wine` that prints its argv instead of executing
# anything, then asserts on what the wrapper resolved and what it would launch.
#
# What is NOT covered, and could not have caught bug 3: the stub never runs a
# real `cd`, so it cannot distinguish a Windows path string that merely looks
# right from one Wine actually accepts. That gap is why the fix for bug 3 is
# to stop building such strings at all wherever a proven one (Wine's own
# %LOCALAPPDATA%, left for Wine to expand) is available -- the harness can
# confirm the wrapper reaches for the literal instead of inventing an
# equivalent, but only the real machine can confirm the literal still works
# after the next Vinegar or Wine update.

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
    # The launch command uses Wine's own %LOCALAPPDATA%, unresolved -- not a
    # host-translated absolute path. That literal is the fix for bug 3.
    if [[ "$out" == *'[cd /d "%LOCALAPPDATA%\Roblox" && .\mcp.bat]'* ]]; then
        pass "Vinegar Flatpak: finds the launcher and launches via %LOCALAPPDATA%"
    else
        fail "Vinegar Flatpak: finds the launcher and launches via %LOCALAPPDATA%" "$out"
    fi
    if [[ "$(resolved "$home")" == "$home$vinegar_flatpak/appdata/Roblox/mcp.bat" ]]; then
        pass "Vinegar Flatpak: discovery still finds the redirected appdata launcher"
    else
        fail "Vinegar Flatpak: discovery still finds the redirected appdata launcher" "$(resolved "$home")"
    fi
}

case_plain_wine() {
    local home; home="$(make_home plain)"
    mkdir -p "$home/.wine/drive_c/users/nick/AppData/Local/Roblox"
    : >"$home/.wine/drive_c/users/nick/AppData/Local/Roblox/mcp.bat"
    # The drive_c/users/* candidate is only trusted for the %LOCALAPPDATA%
    # literal once Wine's own answer confirms it (bug 4) -- a real single-user
    # Wine would confirm it, so the fixture must say so too.
    local out
    out="$(run_wrapper "$home" \
        STUB_LOCALAPPDATA="Z:${home//\//\\}\\.wine\\drive_c\\users\\nick\\AppData\\Local")"
    if [[ "$out" == *'[cd /d "%LOCALAPPDATA%\Roblox" && .\mcp.bat]'* ]]; then
        pass "plain Wine: finds the launcher and launches via %LOCALAPPDATA%"
    else
        fail "plain Wine: finds the launcher and launches via %LOCALAPPDATA%" "$out"
    fi
    if [[ "$(resolved "$home")" == "$home/.wine/drive_c/users/nick/AppData/Local/Roblox/mcp.bat" ]]; then
        pass "plain Wine: discovery still finds the launcher inside drive_c"
    else
        fail "plain Wine: discovery still finds the launcher inside drive_c" "$(resolved "$home")"
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
    local out
    out="$(run_wrapper "$home" WINEPREFIX="$home/odd/prefix" \
        STUB_LOCALAPPDATA="Z:${home//\//\\}\\somewhere\\else")"
    if [[ "$(resolved "$home")" == "$home/somewhere/else/Roblox/mcp.bat" ]]; then
        pass "unknown layout: asks Wine where LOCALAPPDATA points"
    else
        fail "unknown layout: asks Wine where LOCALAPPDATA points" "$(resolved "$home")"
    fi
    # Found via the wine-query fallback rather than a pattern match, but it is
    # still %LOCALAPPDATA%\Roblox by definition -- the launch stays literal.
    if [[ "$out" == *'[cd /d "%LOCALAPPDATA%\Roblox" && .\mcp.bat]'* ]]; then
        pass "unknown layout: still launches via %LOCALAPPDATA%, not a resolved path"
    else
        fail "unknown layout: still launches via %LOCALAPPDATA%, not a resolved path" "$out"
    fi
}

# The one case that still needs a host->Windows path translation: an explicit
# STUDIO_MCP_BAT pointing somewhere %LOCALAPPDATA%\Roblox does not reach. This
# is also the only remaining place bug 3's class of failure could still recur,
# since it is the only launch path that builds a resolved string instead of
# handing Wine its own variable.
case_override_wins() {
    local home; home="$(make_home override)"
    mkdir -p "$home$vinegar_flatpak/prefixes/studio/drive_c" "$home$vinegar_flatpak/appdata/Roblox" \
             "$home/custom"
    : >"$home$vinegar_flatpak/appdata/Roblox/mcp.bat"
    : >"$home/custom/mcp.bat"
    local out; out="$(run_wrapper "$home" STUDIO_MCP_BAT="$home/custom/mcp.bat")"
    if [[ "$(resolved "$home")" == "$home/custom/mcp.bat" ]]; then
        pass "STUDIO_MCP_BAT overrides discovery"
    else
        fail "STUDIO_MCP_BAT overrides discovery" "$(resolved "$home")"
    fi
    if [[ "$out" == *'[cd /d "Z:'*'custom" && .\mcp.bat]'* ]]; then
        pass "an override launches from its own translated directory, not %LOCALAPPDATA%"
    else
        fail "an override launches from its own translated directory, not %LOCALAPPDATA%" "$out"
    fi
}

# A prefix path containing a space, discovered through the ordinary candidate
# list (not an override). This exercises the common case -- %LOCALAPPDATA% is
# left for Wine to expand, so a space in WINEPREFIX never reaches a
# hand-built command-line string at all.
case_prefix_with_space() {
    local home; home="$(make_home 'spaced prefix')"
    mkdir -p "$home/My Prefix/drive_c/users/nick/AppData/Local/Roblox"
    : >"$home/My Prefix/drive_c/users/nick/AppData/Local/Roblox/mcp.bat"
    local out
    out="$(run_wrapper "$home" WINEPREFIX="$home/My Prefix" \
        STUB_LOCALAPPDATA="Z:${home//\//\\}\\My Prefix\\drive_c\\users\\nick\\AppData\\Local")"
    if [[ "$(resolved "$home")" == "$home/My Prefix/drive_c/users/nick/AppData/Local/Roblox/mcp.bat" ]]; then
        pass "a prefix path containing a space is still discovered correctly"
    else
        fail "a prefix path containing a space is still discovered correctly" "$(resolved "$home")"
    fi
    if [[ "$out" == *'[cd /d "%LOCALAPPDATA%\Roblox" && .\mcp.bat]'* ]]; then
        pass "a spaced prefix still launches via the %LOCALAPPDATA% literal"
    else
        fail "a spaced prefix still launches via the %LOCALAPPDATA% literal" "$out"
    fi
}

# A directory containing a space, this time on the one path that DOES build a
# literal Windows path string -- an explicit override. Proves the quoting
# still holds where it actually matters now.
case_override_path_with_space() {
    local home; home="$(make_home 'spaced override')"
    mkdir -p "$home$vinegar_flatpak/prefixes/studio/drive_c" "$home/My Custom Roblox"
    : >"$home/My Custom Roblox/mcp.bat"
    local out
    out="$(run_wrapper "$home" WINEPREFIX="$home$vinegar_flatpak/prefixes/studio" \
        STUDIO_MCP_BAT="$home/My Custom Roblox/mcp.bat")"
    if [[ "$out" == *'[cd /d "Z:'*'My Custom Roblox" && .\mcp.bat]'* ]]; then
        pass "an overridden path containing a space stays quoted"
    else
        fail "an overridden path containing a space stays quoted" "$out"
    fi
}

# Codex's finding on the prefix-tied fix above: a plain-Wine prefix can hold
# more than one Windows user profile, and the drive_c/users/* glob can match a
# stale one while Wine itself currently answers %LOCALAPPDATA% for someone
# else. Trusting the literal there would make discovery succeed (it found a
# real mcp.bat) while launch still fails (Wine's own %LOCALAPPDATA%\Roblox
# does not hold that file). The mismatch must fall back to the translated path
# of the file actually found, never to a directory that might belong to
# another profile.
case_multi_user_mismatch_falls_back() {
    local home; home="$(make_home multi_user_mismatch)"
    mkdir -p "$home/.wine/drive_c/users/alice/AppData/Local/Roblox"
    : >"$home/.wine/drive_c/users/alice/AppData/Local/Roblox/mcp.bat"
    local out
    out="$(run_wrapper "$home" \
        STUB_LOCALAPPDATA="Z:${home//\//\\}\\.wine\\drive_c\\users\\bob\\AppData\\Local")"
    if [[ "$(resolved "$home")" == "$home/.wine/drive_c/users/alice/AppData/Local/Roblox/mcp.bat" ]]; then
        pass "multi-user mismatch: still discovers the file that actually exists"
    else
        fail "multi-user mismatch: still discovers the file that actually exists" "$(resolved "$home")"
    fi
    if [[ "$out" == *'[cd /d "Z:'*'alice'*'Roblox" && .\mcp.bat]'* ]]; then
        pass "multi-user mismatch: launches from alice's directory, not bob's %LOCALAPPDATA%"
    else
        fail "multi-user mismatch: launches from alice's directory, not bob's %LOCALAPPDATA%" "$out"
    fi
}

# The matching counterpart: when Wine's active user genuinely is the one whose
# mcp.bat was found, the literal stays trusted -- the check should not make
# the common, unambiguous case pay for the rare one.
case_single_user_confirmed_uses_literal() {
    local home; home="$(make_home single_user_confirmed)"
    mkdir -p "$home/.wine/drive_c/users/carol/AppData/Local/Roblox"
    : >"$home/.wine/drive_c/users/carol/AppData/Local/Roblox/mcp.bat"
    local out
    out="$(run_wrapper "$home" \
        STUB_LOCALAPPDATA="Z:${home//\//\\}\\.wine\\drive_c\\users\\carol\\AppData\\Local")"
    if [[ "$out" == *'[cd /d "%LOCALAPPDATA%\Roblox" && .\mcp.bat]'* ]]; then
        pass "single user confirmed: still launches via the %LOCALAPPDATA% literal"
    else
        fail "single user confirmed: still launches via the %LOCALAPPDATA% literal" "$out"
    fi
}

case_forwards_arguments() {
    local home; home="$(make_home args)"
    mkdir -p "$home$vinegar_flatpak/prefixes/studio/drive_c" "$home$vinegar_flatpak/appdata/Roblox"
    : >"$home$vinegar_flatpak/appdata/Roblox/mcp.bat"
    local out; out="$(run_wrapper "$home" --stdio)"
    if [[ "$out" == *'&& .\mcp.bat --stdio]'* ]]; then
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
case_prefix_with_space
case_override_path_with_space
case_multi_user_mismatch_falls_back
case_single_user_confirmed_uses_literal
case_forwards_arguments
case_direct_exe_from_generated_batch
case_no_launcher
case_no_prefix
case_no_wine

printf 'studio-mcp-wrapper tests complete: %d passed, %d failed\n' "$passed" "$failed"
[[ $failed -eq 0 ]]
