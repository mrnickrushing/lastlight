#!/usr/bin/env python3
"""Keep a frozen save schema frozen.

Milestone 14's deliverable list says "frozen save schema except blocker fixes".
That is a promise nobody can keep by remembering, and the cost of forgetting is
not a broken build -- it is a player's save. A launch candidate is declared, a
schema bump lands two weeks later for a reason that felt small at the time, and
the migration path that was validated against the candidate is no longer the
one that runs.

So the freeze is a value rather than an intention. `Config.SaveSchemaFreeze` is
nil during development, which is the correct state: a freeze that is on while
the schema is still moving is a freeze somebody turns off and forgets to turn
back on. When a launch candidate is declared it is set to the version that
candidate ships on, and from that moment this script refuses any bump past it.

There are exactly two ways through, and both are deliberate acts:

  1. Raise `SaveSchemaFreeze` -- which is unfreezing, and should be reviewed as
     unfreezing rather than slipped in beside a schema change.
  2. Set `SaveSchemaFreezeOverride` to the exact version being allowed, and say
     in the pull request why the fix is a blocker. It has to be typed out,
     because a number that has to be typed is a number somebody looked at.

The script also refuses an override that is not exactly one past the freeze, so
"override" cannot become a way to skip several versions at once, and it refuses
an override left behind after the freeze moves -- a stale exemption is an
exemption nobody remembers granting.
"""

import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
CONFIG = ROOT / "src" / "shared" / "Config.luau"

COMMENT = re.compile(r"--\[\[.*?\]\]|--[^\n]*", re.DOTALL)


def read_number(source: str, name: str) -> int | None:
    """Read `Name = <number>` from Config, ignoring comments and `nil`."""
    match = re.search(rf"\b{re.escape(name)}\s*=\s*([^,\n]+)", source)
    if match is None:
        return None
    value = match.group(1).strip()
    if value.startswith("nil"):
        return None
    number = re.match(r"(\d+)", value)
    if number is None:
        return None
    return int(number.group(1))


def main() -> int:
    if not CONFIG.is_file():
        print(f"Schema freeze validation failed: missing {CONFIG}", file=sys.stderr)
        return 1

    source = COMMENT.sub("", CONFIG.read_text())
    version = read_number(source, "SaveSchemaVersion")
    freeze = read_number(source, "SaveSchemaFreeze")
    override = read_number(source, "SaveSchemaFreezeOverride")

    if version is None:
        print(
            "Schema freeze validation failed: Config.SaveSchemaVersion is not a number",
            file=sys.stderr,
        )
        return 1

    if freeze is None:
        if override is not None:
            print(
                "Schema freeze validation failed: SaveSchemaFreezeOverride is set "
                "while nothing is frozen. An exemption with no rule to be exempt "
                "from is an exemption nobody remembers granting -- clear it.",
                file=sys.stderr,
            )
            return 1
        print(f"Schema freeze validation passed: schema {version} is not frozen.")
        return 0

    if version <= freeze:
        if override is not None:
            print(
                f"Schema freeze validation failed: SaveSchemaFreezeOverride is set to "
                f"{override} but the schema is at {version}, which the freeze at "
                f"{freeze} already allows. Clear the override.",
                file=sys.stderr,
            )
            return 1
        print(
            f"Schema freeze validation passed: schema {version} is at or under the "
            f"freeze at {freeze}."
        )
        return 0

    if override is None:
        print(
            f"Schema freeze validation failed: the save schema is frozen at {freeze} "
            f"and source declares {version}.\n\n"
            f"  A frozen schema is Milestone 14's promise that the migration path "
            f"validated against the launch candidate is the one that runs. Two ways "
            f"through, both deliberate:\n\n"
            f"    * raise Config.SaveSchemaFreeze to {version} -- this is unfreezing, "
            f"and belongs in a pull request that says so;\n"
            f"    * set Config.SaveSchemaFreezeOverride = {version} and say in the "
            f"pull request why this fix is a blocker.",
            file=sys.stderr,
        )
        return 1

    if override != version:
        print(
            f"Schema freeze validation failed: the override is {override} but source "
            f"declares schema {version}. The override names the exact version it "
            f"allows, so it cannot be left behind to cover a later bump nobody "
            f"reviewed.",
            file=sys.stderr,
        )
        return 1

    if version != freeze + 1:
        print(
            f"Schema freeze validation failed: the override allows {version}, which is "
            f"{version - freeze} past the freeze at {freeze}. A blocker fix is one "
            f"version. Several at once is unfreezing wearing an override's clothes.",
            file=sys.stderr,
        )
        return 1

    print(
        f"Schema freeze validation passed: schema {version} is one blocker fix past "
        f"the freeze at {freeze}, allowed by an explicit override."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
