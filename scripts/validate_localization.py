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

**Five batches later it is empty except for one file, and that is the finished
state rather than an unfinished one.** `src/first/LoadingController.client.luau`
runs from ReplicatedFirst to cover the wait for the shared root, so reaching for
a module inside that root would make it block on the thing it exists to hide.
Three further files are on a *different* list, `NOT_TRANSLATED`, because their
text is not player-facing at all -- and keeping the two lists apart is the point:
one says "not yet", the other says "never", and a reader who cannot tell them
apart cannot tell whether this wave is done.

Four checks, and the second and third are the ones that catch an unwired
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
  4. **No decision is made by comparing a translated string.** This one was
     written last and is the one a migration creates rather than leaves behind.
     Moving a string into the table makes it a translator's to change; if the
     code then branches on its value, translating it changes what the game
     does -- in the localized build only, with nothing failing anywhere. Batches
     one and two did exactly that to four identifiers across twenty-four sites,
     including which dressing a night raises and how a profession's id is
     spelled.
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
#
# **This list is at its floor and the floor is one.** The migration is finished;
# what is left is the one file that cannot reach the table, and the reason is
# structural rather than a matter of effort. Anything added here from now on is
# a new promise, and a promise is what the pin exists to make somebody argue
# for.
ALLOWED: dict[str, str] = {
    "src/first/LoadingController.client.luau": (
        "runs from ReplicatedFirst, before the shared root replicates. It is the "
        "screen that covers that wait, and it only ever asks for the runtime with "
        "a non-blocking FindFirstChild -- requiring Strings would mean "
        "WaitForChild(\"LastLight\"), so the loading screen would block on the very "
        "replication it exists to cover, against its own first rule that a player "
        "must never be trapped behind it. Five stage captions and the title, "
        "written where they are read."
    ),
}

# Pinned. It shrinks; it does not grow. It is at its floor.
ALLOWLIST_SIZE = 1

# A different thing from the allowlist, and worth keeping different.
#
# The allowlist is *not yet migrated*. This is *not player-facing at all*: text
# read by whoever is holding the console or running the soak, which the guard's
# generous heuristic cannot tell apart from copy because a metric's label and a
# button's label are both a run of capitals. It is the same judgement the
# DIAGNOSTIC set above already makes for anything handed to `warn` -- a stack
# trace is not worth translating and translating it only makes it harder to
# search -- arriving one seam later, because a label stored in a table and
# concatenated into a report much later is invisible from the call site.
#
# Every entry has to say who reads it. That is the whole discipline: "operator
# text" is exactly the sentence somebody reaches for when they want a string out
# of the way, so the reason names the reader and the surface, and the count is
# pinned harder than the allowlist's, because this list does not shrink on its
# own the way that one does.
NOT_TRANSLATED: dict[str, str] = {
    "src/shared/MusicCatalog.luau": (
        "track titles and their publishers, and nothing reads either one: "
        "MusicController takes assetId, volume and intensity and never touches "
        "name or creator. The publisher is also the field validate_audio_assets.py "
        "and ASSET_PROVENANCE.md hold the licence claim against, so translating it "
        "would break an audit rather than serve a player"
    ),
    "src/shared/PerformanceBudget.luau": (
        "metric labels for the admin readout PerformanceBudget.format builds. Its "
        "first line goes to a toast and is in the table; every other line goes to "
        "the log, for whoever closes the exit gate"
    ),
    "src/shared/SoakProbe.luau": (
        "metric labels and the sentence explaining what a breach in each one means, "
        "read in a soak report by whoever is running the soak. No player ever sees a "
        "soak"
    ),
}

# Pinned, and harder than the allowlist's. A file arrives here by an argument
# about who reads it, never by a migration being inconvenient.
NOT_TRANSLATED_SIZE = 3

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
        if relative in ALLOWED or relative in NOT_TRANSLATED:
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

    both = sorted(set(ALLOWED) & set(NOT_TRANSLATED))
    if both:
        failures.append(
            "on both lists: "
            + ", ".join(both)
            + ". A file is either waiting to be migrated or decided not to be, and "
            "one of those two lists is telling the reader something untrue"
        )

    stale = sorted(
        name for name in list(ALLOWED) + list(NOT_TRANSLATED) if not (ROOT / name).is_file()
    )
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

    silent = sorted(name for name in NOT_TRANSLATED if not scan(ROOT / name)) if not stale else []
    if silent:
        failures.append(
            "declared not player-facing and holding no strings at all: "
            + ", ".join(silent)
            + ". The declaration is about text that exists; a file with none of it "
            "is covered like any other and does not need an exemption"
        )

    if len(NOT_TRANSLATED) != NOT_TRANSLATED_SIZE:
        failures.append(
            f"the not-translated list holds {len(NOT_TRANSLATED)} files and is pinned "
            f"at {NOT_TRANSLATED_SIZE}. A file arrives on it by an argument about who "
            f"reads its text, never by a migration being inconvenient, so the count "
            f"moves in the commit that makes the argument"
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
        f"{len(ALLOWED)} file(s) not yet migrated holding {remaining} string(s), "
        f"{len(NOT_TRANSLATED)} file(s) declared not player-facing."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
