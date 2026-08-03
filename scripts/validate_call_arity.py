#!/usr/bin/env python3
"""Catch calls that pass fewer arguments than a local function requires.

This exists because of a specific outage. `buildEventSocket` gained a
required `extra` collector, its one call site was not updated, and the
resulting `table.insert(nil, ...)` killed ExpeditionService on every server
for nine published versions. Bramblewake did not exist in the game that whole
time, and nothing in `npm test` noticed.

Nothing could have noticed. `npm run typecheck` runs with `--platform
standard`, so it can only cover `src/shared` -- every builder under
`src/server/World` traffics in Part, CFrame and Color3, which that platform
has no types for. Covering them properly needs the Roblox API definitions
vendored into the repo, which is a larger decision than this bug deserved to
wait on.

Definitions and calls are read in either shape, single line or wrapped. The
first version of this script read only wrapped ones, and the very next
mistake it failed to catch was `buildBackdrop(expedition, centers)` -- a
one-line call to a one-line definition, missing its new third argument,
written minutes after the script was added to guard that exact mistake.

A parameter typed `T?` counts as optional. Methods taking `self` are skipped,
because they are called with `:` and the arity does not line up. Comments are
blanked before scanning, and when one name is defined twice in a file the
smallest requirement wins, because this has no scope tracking and a false
positive in a required check is worse than a missed one.
"""

import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
ROOTS = ["src/server", "src/client", "src/shared", "src/first"]
DEFINITION = re.compile(r"local function ([A-Za-z_]\w*)\(")
OPTIONAL = re.compile(r":\s*.*\?\s*$")

OPENERS = "([{"
CLOSERS = ")]}"


def close_paren(text: str, start: int) -> int:
    """Index of the `)` matching the `(` at `start`, or -1 if unbalanced."""
    depth = 0
    for index in range(start, len(text)):
        char = text[index]
        if char in OPENERS:
            depth += 1
        elif char in CLOSERS:
            depth -= 1
            if depth == 0:
                return index
    return -1


def split_top_level(inner: str) -> list:
    parts, depth, current = [], 0, ""
    for char in inner:
        if char in OPENERS:
            depth += 1
        elif char in CLOSERS:
            depth -= 1
        if char == "," and depth == 0:
            parts.append(current)
            current = ""
            continue
        current += char
    if current.strip():
        parts.append(current)
    return [p.strip() for p in parts if p.strip()]


def main() -> None:
    failures = []
    for root in ROOTS:
        for path in sorted((ROOT / root).rglob("*.luau")):
            raw = path.read_text(encoding="utf-8")
            # Comments mention calls like `part()` in prose; blank them out but
            # keep the line count so reported positions stay true.
            text = re.sub(r"--\[\[.*?\]\]", lambda m: re.sub(r"[^\n]", " ", m.group(0)), raw, flags=re.S)
            text = re.sub(r"--[^\n]*", lambda m: " " * len(m.group(0)), text)

            signatures = {}
            for match in DEFINITION.finditer(text):
                open_at = match.end() - 1
                close_at = close_paren(text, open_at)
                if close_at < 0:
                    continue
                params = split_top_level(text[open_at + 1 : close_at])
                if params and params[0].split(":")[0].strip() == "self":
                    continue
                required = sum(1 for p in params if not OPTIONAL.search(p))
                # A name can be defined twice in a file -- an inner helper
                # shadowing an outer one. Without scope tracking the safe
                # reading is the smallest requirement any of them has.
                name = match.group(1)
                seen = signatures.get(name)
                if seen is None or required < seen[1]:
                    signatures[name] = (len(params), required)

            for name, (total, required) in signatures.items():
                if required == 0:
                    continue
                pattern = re.compile(r"(?<![\w.:])" + re.escape(name) + r"\(")
                for call in pattern.finditer(text):
                    open_at = call.end() - 1
                    close_at = close_paren(text, open_at)
                    if close_at < 0:
                        continue
                    inner = text[open_at + 1 : close_at]
                    passed = len(split_top_level(inner)) if inner.strip() else 0
                    if passed < required:
                        line = text[: call.start()].count("\n") + 1
                        failures.append(
                            f"{path.relative_to(ROOT)}:{line}: {name}() is called with "
                            f"{passed} argument(s) but requires {required} of {total}"
                        )

    if failures:
        print("Call arity validation failed:", file=sys.stderr)
        for failure in failures:
            print(f"  {failure}", file=sys.stderr)
        sys.exit(1)
    print("Call arity validation passed.")


if __name__ == "__main__":
    main()
