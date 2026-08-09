#!/usr/bin/env python3
"""Every string a player reads, in one table -- and a guard that arrives first.

Milestone 13's deliverable list asks for localization source coverage so that
"finalize supported languages from localization QA capacity" is a capacity
decision rather than an archaeology project. You cannot decide whether to ship
a language without knowing what a language costs, and you cannot know that
while the strings are scattered across eighty-seven files.

The obvious way to do this wave is the reason it sat unbuilt through two
sessions. Routing every player-visible string through one table touches nearly
every file that speaks to a player, and the check that gives the wave its value
-- *no player-visible literal outside the table* -- cannot be switched on until
the migration is finished. So the obvious version is a very large diff with no
guard on it, and a half-migrated string table is worse than none: it looks
finished from every direction except the one that matters.

**So the guard lands first, with an explicit list of the files it does not yet
cover.** That is the shape `validate_monetization.py`'s allowlist already has
and the shape `Config.SaveSchemaFreeze` has: the rule is live from the first
commit, the exceptions are named individually with a reason, and the count is
pinned so the list can shrink and cannot quietly grow. A file leaves the list in
the batch that migrates it, and the wave is finished when the list is empty.
Every batch in between is guarded.

Three checks, and the second and third are the ones that catch an unwired
string the way `ActionWiring.spec` catches an unwired action:

  1. **No player-visible literal in a covered file.** What counts as
     player-visible is deliberately generous -- a run of capitals, or a
     capitalized phrase with a space in it -- because the cost of a false
     positive is one more string in the table and the cost of a false negative
     is a sentence no translator ever sees.
  2. **Every key a caller asks for exists.** `Strings.get` on a key nobody
     defined is the localization version of a button wired to nothing.
  3. **Every key in the table is asked for.** A string in the table that
     nothing reads is a string a translator is paid to translate and no player
     ever sees, and it is also what a migration leaves behind when it moves a
     line and forgets to delete the old one.
"""

from __future__ import annotations

import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
TABLE = SRC / "shared" / "Strings.luau"

# Files that still hold their own player-visible text. Each entry is a promise
# to migrate it, not permission to leave it. The list may only shrink -- see
# ALLOWLIST_SIZE below, which is pinned for the same reason
# validate_monetization.py pins its own: a list nobody counts is a list that
# grows.
ALLOWED: dict[str, str] = {
    "src/first/LoadingController.client.luau": (
        "loads before the shared root replicates, which is the whole point of it; reaching for the table would make the loading screen wait for the thing it exists to cover"
    ),
    "src/shared/Consumables.luau": (
        "content catalog; 82 authored strings, migrating with the content batch"
    ),
    "src/shared/Content/Definitions/BramblewakeExpedition.luau": (
        "content catalog; 121 authored strings, migrating with the content batch"
    ),
    "src/shared/Content/Definitions/CinderfallExpedition.luau": (
        "content catalog; 108 authored strings, migrating with the content batch"
    ),
    "src/shared/Content/Definitions/FrostmereExpedition.luau": (
        "content catalog; 93 authored strings, migrating with the content batch"
    ),
    "src/shared/Content/Definitions/IronrootExpedition.luau": (
        "content catalog; 111 authored strings, migrating with the content batch"
    ),
    "src/shared/Content/Definitions/MireglassExpedition.luau": (
        "content catalog; 111 authored strings, migrating with the content batch"
    ),
    "src/shared/Content/Definitions/TempestExpedition.luau": (
        "content catalog; 95 authored strings, migrating with the content batch"
    ),
    "src/shared/CraftingCatalog.luau": (
        "content catalog; 220 authored strings, migrating with the content batch"
    ),
    "src/shared/Equipment.luau": (
        "content catalog; 148 authored strings, migrating with the content batch"
    ),
    "src/shared/GearTraits.luau": (
        "content catalog; 10 authored strings, migrating with the content batch"
    ),
    "src/shared/MusicCatalog.luau": (
        "content catalog; 30 authored strings, migrating with the content batch"
    ),
    "src/shared/PerformanceBudget.luau": (
        "content catalog; 9 authored strings, migrating with the content batch"
    ),
    "src/shared/ResidentDialogue.luau": (
        "content catalog; 76 authored strings, migrating with the content batch"
    ),
    "src/shared/ResidentRoster.luau": (
        "content catalog; 106 authored strings, migrating with the content batch"
    ),
    "src/shared/SoakProbe.luau": (
        "content catalog; 10 authored strings, migrating with the content batch"
    ),
    "src/shared/ToolCatalog.luau": (
        "content catalog; 16 authored strings, migrating with the content batch"
    ),
}

# Pinned. It shrinks; it does not grow.
ALLOWLIST_SIZE = 17

COMMENT = re.compile(r"--\[\[.*?\]\]|--[^\n]*", re.DOTALL)
LITERAL = re.compile(r'"((?:[^"\\\n]|\\.)*)"')
KEY_USE = re.compile(r'Strings\.get\(\s*"([a-z0-9_.]+)"')
# A lookup standing on either side of an equality test. This is the check that
# arrived latest and matters most: batch two moved four *identifiers* into the
# table -- a night's theme, a cabin's name, a profession altar's, a phase --
# and every one of them was then compared to decide what the world builds.
# Translating any of them changes the game, in the localized build only, with
# nothing failing anywhere. The whole point of one table is that a translator
# can change every string in it, so nothing may be true only while a string
# stays in English.
COMPARED = re.compile(
    r'(?:[=~]=\s*Strings\.get\(\s*"[a-z0-9_.]+"\s*\)'
    r'|Strings\.get\(\s*"[a-z0-9_.]+"\s*\)\s*[=~]=)'
)
KEY_DEF = re.compile(r'^\s*\["([a-z0-9_.]+)"\]\s*=\s*"', re.M)

# A player-visible string is a run of capitals, or a capitalized phrase with a
# space in it. Deliberately generous: one more string in the table costs a line,
# and a sentence no translator sees costs a language.
SHOUTED = re.compile(r"^[A-Z][A-Z0-9 ,.!?:;''—’·()%/-]{3,}$")
SENTENCE = re.compile(r"^[A-Z][^\n]*[a-z][^\n]*$")
# Things that look like copy and are not.
TECHNICAL = re.compile(
    r"^(rbxasset|rbxassetid|http|Enum\.|[A-Z][a-zA-Z]*\.[A-Za-z])|^[A-Za-z]+[A-Z][a-z]"
)


# A format specifier is a hole a number goes in, not a word. Judging the string
# with the holes still in it makes "%d THINGS ARE YOURS" invisible, because the
# tests below all start by asking whether the first character is a letter -- and
# that is how forty-eight live strings sat inside files this check had already
# called covered, including "STAMINA · %d" on the HUD. Every specifier becomes
# one capital letter first, so a string is judged on the shape it has once a
# number is in it.
SPECIFIER = re.compile(r"%[-+ #0-9.]*[a-zA-Z]")


def player_visible(value: str) -> bool:
    value = SPECIFIER.sub("X", value)
    if len(value) < 4 or not re.search(r"[A-Za-z]{2}", value):
        return False
    if TECHNICAL.search(value):
        return False
    if re.fullmatch(r"[A-Za-z0-9_.:/%\\-]+", value) and " " not in value:
        # A single token with no space is an id, a path, a class name or a
        # format specifier. The exception is a shouted word, which in this
        # game's interface is a button.
        return bool(re.fullmatch(r"[A-Z]{4,}", value))
    if SHOUTED.match(value):
        return True
    return bool(SENTENCE.match(value) and " " in value and len(value) > 12)


# A message handed to warn, error, print, assert or the analytics log is read by
# whoever is holding the console, not by a player. Translating it would be paying
# to make a stack trace harder to search.
DIAGNOSTIC = {"warn", "error", "print", "assert", "info", "log", "logEvent", "emit"}
CALLEE = re.compile(r"([A-Za-z_][A-Za-z0-9_]*)\s*$")


def enclosing_call(source: str, at: int) -> str | None:
    """The call a position sits inside, with parentheses balanced.

    Reading backwards along the line stops working the moment the diagnostic
    takes an argument that is itself a call: in `assert(thing:method(), "...")`
    the inner parentheses close before the pattern reaches the `assert`, so the
    message reads as copy and the file cannot leave the allowlist. Four real
    asserts sat behind that, and none of them is a sentence a player sees.
    """
    depth = 0
    index = at - 1
    while index >= 0:
        char = source[index]
        if char == ")":
            depth += 1
        elif char == "(":
            if depth == 0:
                match = CALLEE.search(source[:index])
                return match.group(1) if match else None
            depth -= 1
        elif char in "{}" and depth == 0:
            # A table constructor is not an argument list, so the search stops
            # rather than wandering into whatever call the table is passed to.
            return None
        index -= 1
    return None


def scan(path: pathlib.Path) -> list[str]:
    source = COMMENT.sub("", path.read_text())
    found: list[str] = []
    for match in LITERAL.finditer(source):
        value = match.group(1)
        if not player_visible(value) or value in found:
            continue
        if enclosing_call(source, match.start()) in DIAGNOSTIC:
            continue
        found.append(value)
    return found


def main() -> int:
    if not TABLE.is_file():
        print(f"Localization validation failed: missing {TABLE}", file=sys.stderr)
        return 1

    failures: list[str] = []
    table_source = TABLE.read_text()
    defined = set(KEY_DEF.findall(COMMENT.sub("", table_source)))
    if not defined:
        failures.append(
            "no keys could be read out of Strings.luau. A reader that has stopped "
            "matching reports an empty table as a complete migration"
        )

    used: set[str] = set()
    compared: list[str] = []
    uncovered: dict[str, list[str]] = {}
    for path in sorted(SRC.rglob("*.luau")):
        relative = str(path.relative_to(ROOT))
        source = COMMENT.sub("", path.read_text())
        used.update(KEY_USE.findall(source))
        for match in COMPARED.finditer(source):
            line = source.count("\n", 0, match.start()) + 1
            compared.append(f"{relative}:{line} {match.group(0).strip()}")
        if path == TABLE:
            continue
        if relative in ALLOWED:
            continue
        literals = scan(path)
        if literals:
            uncovered[relative] = literals

    for relative, literals in uncovered.items():
        shown = ", ".join(f'"{value}"' for value in literals[:4])
        more = f" and {len(literals) - 4} more" if len(literals) > 4 else ""
        failures.append(
            f"{relative} holds {len(literals)} player-visible string(s) outside the "
            f"table: {shown}{more}. Route them through Strings, or -- if this file is "
            f"a batch for later -- add it to ALLOWED with the reason and raise "
            f"ALLOWLIST_SIZE in the same commit"
        )

    if compared:
        failures.append(
            "a decision is made by comparing a translated string: "
            + "; ".join(compared)
            + ". Translating the string changes what the code does, which is a "
            "defect that exists only in the localized build and fails nothing. "
            "Compare an id and read the string for display"
        )

    missing = sorted(used - defined)
    if missing:
        failures.append(
            "asked for by name and not in the table: "
            + ", ".join(missing)
            + ". A key nobody defined is a label that renders as nothing, which is "
            "the localization version of a button wired to nothing"
        )

    unread = sorted(defined - used)
    if unread:
        failures.append(
            "in the table and read by nothing: "
            + ", ".join(unread)
            + ". A string nothing reads is a string a translator is paid for and no "
            "player ever sees, and it is what a migration leaves behind when it moves "
            "a line and forgets to delete the old one"
        )

    stale = sorted(name for name in ALLOWED if not (ROOT / name).is_file())
    if stale:
        failures.append(
            "on the allowlist and not in the tree: "
            + ", ".join(stale)
            + ". An exemption for a file that no longer exists is an exemption nobody "
            "remembers granting"
        )

    empty = sorted(name for name in ALLOWED if not scan(ROOT / name)) if not stale else []
    if empty:
        failures.append(
            "on the allowlist with no player-visible strings left: "
            + ", ".join(empty)
            + ". These are migrated -- take them off the list and lower "
            "ALLOWLIST_SIZE, which is the only direction it moves"
        )

    if len(ALLOWED) > ALLOWLIST_SIZE:
        failures.append(
            f"the allowlist holds {len(ALLOWED)} files and is pinned at "
            f"{ALLOWLIST_SIZE}. It shrinks; it does not grow. A new file that speaks "
            f"to a player routes its text through the table on the day it is written"
        )
    elif len(ALLOWED) < ALLOWLIST_SIZE:
        failures.append(
            f"the allowlist holds {len(ALLOWED)} files and ALLOWLIST_SIZE still says "
            f"{ALLOWLIST_SIZE}. Lower the pin in the commit that empties the entries, "
            f"so the number always says how far there is left to go"
        )

    if failures:
        print("Localization validation failed:", file=sys.stderr)
        for failure in failures:
            print(f"  * {failure}", file=sys.stderr)
        return 1

    remaining = sum(len(scan(ROOT / name)) for name in ALLOWED)
    print(
        f"Localization validation passed: {len(defined)} source strings in the table, "
        f"{len(ALLOWED)} file(s) not yet migrated holding {remaining} string(s)."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
