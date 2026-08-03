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

So this checks the narrow thing that actually broke: a multi-line call to a
locally defined function that passes fewer arguments than the function has
required parameters. It is deliberately conservative -- it only reads
multi-line definitions and multi-line calls, and it treats any parameter
typed `T?` as optional -- because a false positive in a required check costs
more than the handful of single-line calls it declines to inspect.
"""

import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
ROOTS = ["src/server", "src/client", "src/shared", "src/first"]

DEFINITION = re.compile(
    r"local function ([A-Za-z_]\w*)\(\s*\n((?:\s+[A-Za-z_]\w*:[^\n]*\n)+)\s*\)"
)
OPTIONAL = re.compile(r":\s*.*\?\s*,?\s*$")


def required_parameters(block: str) -> tuple[int, int]:
    params = [line.strip() for line in block.strip().split("\n") if line.strip()]
    required = sum(1 for p in params if not OPTIONAL.search(p))
    return len(params), required


def argument_count(inner: str) -> int:
    depth = 0
    count = 1
    for char in inner:
        if char in "([{":
            depth += 1
        elif char in ")]}":
            depth -= 1
        elif char == "," and depth == 0:
            count += 1
    return count


def main() -> None:
    failures = []
    for root in ROOTS:
        for path in sorted((ROOT / root).rglob("*.luau")):
            text = path.read_text(encoding="utf-8")
            signatures = {}
            for match in DEFINITION.finditer(text):
                signatures[match.group(1)] = required_parameters(match.group(2))
            for name, (total, required) in signatures.items():
                call = re.compile(
                    r"(?<![\w.:])" + re.escape(name) + r"\(\s*\n((?:[^()]|\([^()]*\))*?)\n\s*\)"
                )
                for match in call.finditer(text):
                    passed = argument_count(match.group(1).strip().rstrip(","))
                    if passed < required:
                        line = text[: match.start()].count("\n") + 1
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
