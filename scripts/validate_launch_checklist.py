#!/usr/bin/env python3
"""Make "complete launch checklist" a check rather than a claim.

Milestone 14's deliverable list ends with a launch checklist, and until this
script existed that checklist was prose bullets in QA_RELEASE_PLAN.md. A bullet
cannot be unticked. It is completed by whoever says it is, and the person
saying it is normally the person who most wants to ship.

So the checklist is a table with a status vocabulary, and this script reads it.
The interesting design decision is *when* it is allowed to fail, because almost
every row is owner-gated -- a Creator Dashboard product, a trailer, a triage
record. A checklist enforced from the day it lands would fail `npm run check`
on every commit forever, and a check that fails on every commit is a check
somebody comments out. That is the same trap `Config.SaveSchemaFreeze` was
built to avoid, so this uses the same escape: the gate is off until a launch
candidate is declared, and declaring one is a deliberate act.

What is live from day one is the structure, and that half is worth having on
its own:

  * every row parses, and its id is unique;
  * a `check` row names a check that actually exists in this repository, so an
    item whose spec was renamed away stops being satisfiable on the day of the
    rename rather than on release day;
  * a `done` or `n/a` row carries evidence, because `n/a` is the cheap way past
    a blocker and an unexplained one is an exemption nobody remembers granting;
  * the counts are pinned -- total rows, blocking rows, and rows the repository
    decides for itself -- so a blocker cannot be quietly downgraded into `n/a`,
    and an owner row cannot be quietly promoted into an automatic one.

Declaring a candidate additionally requires the save schema freeze to be set.
A launch candidate whose schema is still moving is precisely the failure wave A
exists to prevent, and treating the two declarations as one act means nobody
can do half of it.
"""

import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
PLAN = ROOT / "docs" / "QA_RELEASE_PLAN.md"
CONFIG = ROOT / "src" / "shared" / "Config.luau"
PACKAGE = ROOT / "package.json"

# The counts this checklist is pinned at. They are here rather than in the
# document because a pin that lives beside the thing it pins is a pin that gets
# edited in the same keystroke as the thing it pins.
EXPECTED_ITEMS = 39
EXPECTED_BLOCKING = 38
EXPECTED_CHECK_ROWS = 6

STATUSES = ("check", "done", "open", "n/a")

COMMENT = re.compile(r"--\[\[.*?\]\]|--[^\n]*", re.DOTALL)
ROW = re.compile(
    r"^\|\s*`([a-z0-9_]+)`\s*\|\s*(yes|no)\s*\|\s*([a-z/]+)\s*\|\s*(.+?)\s*\|\s*$"
)
# A `check` row's evidence names either an npm script or a file in the tree.
NPM_SCRIPT = re.compile(r"`npm run ([a-z:]+)`")
REPO_FILE = re.compile(r"`([A-Za-z0-9_./]+\.(?:py|mjs|luau|spec))`")


def config_value(name: str) -> str | None:
    """Read `Name = <value>` out of Config, ignoring comments and `nil`."""
    source = COMMENT.sub("", CONFIG.read_text())
    match = re.search(rf"\b{re.escape(name)}\s*=\s*([^,\n]+)", source)
    if match is None:
        return None
    value = match.group(1).strip()
    if value.startswith("nil"):
        return None
    quoted = re.match(r"""["'](.*?)["']""", value)
    if quoted is not None:
        return quoted.group(1)
    number = re.match(r"(\d+)", value)
    if number is not None:
        return number.group(1)
    return None


def find_check(evidence: str, npm_scripts: set[str]) -> str | None:
    """Return the failure reason if a check row's evidence does not resolve."""
    script = NPM_SCRIPT.search(evidence)
    if script is not None:
        if script.group(1) not in npm_scripts:
            return f"names `npm run {script.group(1)}`, which package.json does not define"
        return None

    named = REPO_FILE.search(evidence)
    if named is None:
        return (
            "is a `check` row whose evidence names no check. A check row has to "
            "name the thing that decides it, or it is an owner row wearing an "
            "automatic row's clothes"
        )

    name = named.group(1)
    candidates = [ROOT / name]
    if name.endswith(".spec"):
        candidates.append(ROOT / "tests" / "specs" / f"{name}.luau")
    if any(path.is_file() for path in candidates):
        return None
    return f"names `{name}`, which does not exist in this repository"


def main() -> int:
    for path in (PLAN, CONFIG, PACKAGE):
        if not path.is_file():
            print(f"Launch checklist validation failed: missing {path}", file=sys.stderr)
            return 1

    npm_scripts = set(re.findall(r'^\s{4}"([a-z:]+)":', PACKAGE.read_text(), re.M))

    failures: list[str] = []
    rows: list[tuple[str, str, str, str]] = []
    seen: set[str] = set()

    inside = False
    for line in PLAN.read_text().split("\n"):
        if line.startswith("## "):
            inside = line.strip() == "## Release checklist"
            continue
        if not inside or not line.startswith("|"):
            continue
        if line.startswith("| Item ") or set(line) <= set("|-: "):
            continue
        match = ROW.match(line)
        if match is None:
            failures.append(f"unparseable checklist row: {line.strip()}")
            continue
        item, blocking, status, evidence = match.groups()
        if item in seen:
            failures.append(f"`{item}` appears twice; a checklist id names one item")
        seen.add(item)
        if status not in STATUSES:
            failures.append(
                f"`{item}` has status `{status}`, which is not one of "
                + ", ".join(f"`{value}`" for value in STATUSES)
            )
            continue
        rows.append((item, blocking, status, evidence))

    if not rows:
        print(
            "Launch checklist validation failed: no checklist rows found under "
            "QA_RELEASE_PLAN.md's Release checklist heading.",
            file=sys.stderr,
        )
        return 1

    for item, _blocking, status, evidence in rows:
        if status == "check":
            reason = find_check(evidence, npm_scripts)
            if reason is not None:
                failures.append(f"`{item}` {reason}")
        elif status in ("done", "n/a") and len(evidence) < 12:
            failures.append(
                f"`{item}` is `{status}` with no evidence. A status somebody can "
                f"set without writing down why is a status that means nothing"
            )

    blocking = [row for row in rows if row[1] == "yes"]
    checks = [row for row in rows if row[2] == "check"]

    for count, expected, what in (
        (len(rows), EXPECTED_ITEMS, "checklist items"),
        (len(blocking), EXPECTED_BLOCKING, "blocking items"),
        (len(checks), EXPECTED_CHECK_ROWS, "items the repository decides"),
    ):
        if count != expected:
            failures.append(
                f"the checklist holds {count} {what} and this script is pinned at "
                f"{expected}. Changing the shape of the checklist is a deliberate "
                f"act; update EXPECTED_* in this script in the same commit and say "
                f"in the pull request which item moved and why"
            )

    if failures:
        print("Launch checklist validation failed:", file=sys.stderr)
        for failure in failures:
            print(f"  * {failure}", file=sys.stderr)
        return 1

    candidate = config_value("LaunchCandidate")
    if candidate is None:
        unticked = [row[0] for row in blocking if row[2] == "open"]
        print(
            f"Launch checklist validation passed: {len(rows)} items well formed, "
            f"{len(checks)} decided by this repository, no launch candidate "
            f"declared ({len(unticked)} blocking items still open)."
        )
        return 0

    freeze = config_value("SaveSchemaFreeze")
    if freeze is None:
        print(
            f"Launch checklist validation failed: Config.LaunchCandidate is "
            f'"{candidate}" and Config.SaveSchemaFreeze is nil.\n\n'
            f"  A launch candidate whose save schema is still free to move is the "
            f"failure the freeze exists to prevent: the migration path validated "
            f"against the candidate stops being the one that runs. Declaring a "
            f"candidate and freezing the schema are one act. Set "
            f"Config.SaveSchemaFreeze to the schema version this candidate ships "
            f"on.",
            file=sys.stderr,
        )
        return 1

    unticked = [row for row in blocking if row[2] == "open"]
    if unticked:
        print(
            f"Launch checklist validation failed: Config.LaunchCandidate is "
            f'"{candidate}" and {len(unticked)} blocking checklist items are still '
            f"open.\n",
            file=sys.stderr,
        )
        for item, _blocking, _status, evidence in unticked:
            print(f"    * {item} -- {evidence}", file=sys.stderr)
        print(
            "\n  Each one is either done, in which case mark it `done` and record "
            "in the evidence column what was done, or deliberately out of scope, "
            "in which case mark it `n/a` and say why. Withdrawing the candidate by "
            "clearing Config.LaunchCandidate is also an answer, and an honest one.",
            file=sys.stderr,
        )
        return 1

    print(
        f'Launch checklist validation passed: launch candidate "{candidate}" has '
        f"all {len(blocking)} blocking items satisfied."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
