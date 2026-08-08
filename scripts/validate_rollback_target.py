#!/usr/bin/env python3
"""Keep the rollback target a thing you could actually restore.

ROLLBACK.md's second step says "republish the last known-good place revision"
and, until this script, pointed at the PROJECT_STATUS header for the revision
and the flag state that go together. That header reads:

    Last updated: ..., at `main` = `HEAD` (PR #353)

**`HEAD` is not a revision.** It is whatever the reader happens to be standing
on, which during an incident is the build that is on fire. The one place in the
repository where the revision and the flag state were written side by side
recorded neither. Nothing failed, because nothing was checking, and the cost
lands in the only minute the record exists for.

So the target is a table now, and this checks it. Four rules, each a way a
recorded rollback target is quietly useless:

  1. **The revision exists and is an ancestor.** A rollback target on a branch
     nobody merged is a build nobody has.
  2. **It is not the current tip.** A build you are already running is not
     somewhere to roll back to.
  3. **Its save schema equals the current one.** This is the rule with teeth.
     Rolling back past a schema bump strands every profile the newer build
     wrote: the old build does not know the fields, and a save it writes back
     is a save it has narrowed. So a schema bump *forces the target forward*,
     which is the same fact M14 wave A's freeze is about, arriving from the
     other side.
  4. **The recorded flag state is the flag state at that revision**, read out
     of that revision rather than out of the working tree. A matrix describing
     a build it does not match is worse than no matrix, because it will be
     followed.

What this does not check is that the target builds. That needs a build, so it
lives in `npm run verify:rollback`, which builds the revision in a worktree and
runs the same DataModel verification the normal build runs.
"""

from __future__ import annotations

import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
DOC = ROOT / "docs" / "ROLLBACK.md"
CONFIG = ROOT / "src" / "shared" / "Config.luau"

COMMENT = re.compile(r"--\[\[.*?\]\]|--[^\n]*", re.DOTALL)
FIELD = re.compile(r"^\| \*\*([A-Za-z ]+)\*\* \| `?([^|`]+)`? \|$", re.M)
FLAG_ROW = re.compile(r"^\| `([a-z0-9_]+)` \| (true|false) \|$", re.M)


def git(*args: str) -> str:
    result = subprocess.run(
        ["git", *args], capture_output=True, text=True, cwd=ROOT
    )
    return result.stdout.strip() if result.returncode == 0 else ""


def feature_flags(source: str) -> dict[str, bool]:
    """Read `Config.FeatureFlags` out of a copy of Config.luau."""
    if "FeatureFlags = table.freeze({" not in source:
        return {}
    body = source.split("FeatureFlags = table.freeze({", 1)[1]
    depth, collected = 1, []
    for char in body:
        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                break
        collected.append(char)
    stripped = COMMENT.sub("", "".join(collected))
    return {
        name: value == "true"
        for name, value in re.findall(r"([a-z0-9_]+)\s*=\s*(true|false)", stripped)
    }


def schema_version(source: str) -> int | None:
    match = re.search(r"SaveSchemaVersion\s*=\s*(\d+)", COMMENT.sub("", source))
    return int(match.group(1)) if match else None


def main() -> int:
    if not DOC.is_file():
        print(f"Rollback target validation failed: missing {DOC}", file=sys.stderr)
        return 1

    text = DOC.read_text()
    section = text.split("## The rollback target", 1)
    if len(section) < 2:
        print(
            "Rollback target validation failed: ROLLBACK.md has no "
            "'## The rollback target' section. Step two of a rollback is a build, "
            "and a build is a revision.",
            file=sys.stderr,
        )
        return 1
    section = section[1].split("\n## ", 1)[0]

    fields = {name.strip().lower(): value.strip() for name, value in FIELD.findall(section)}
    recorded_flags = {name: value == "true" for name, value in FLAG_ROW.findall(section)}

    failures: list[str] = []
    revision = fields.get("revision", "")

    if not re.fullmatch(r"[0-9a-f]{40}", revision):
        failures.append(
            f"the recorded revision is {revision!r}, which is not a full commit id. "
            f"`HEAD` and `main` are not revisions -- they are whatever the reader is "
            f"standing on, which during an incident is the build that is on fire"
        )
        revision = ""

    if revision:
        if git("cat-file", "-t", revision) != "commit":
            failures.append(f"{revision} is not a commit in this repository")
        elif subprocess.run(
            ["git", "merge-base", "--is-ancestor", revision, "HEAD"], cwd=ROOT
        ).returncode != 0:
            failures.append(
                f"{revision} is not an ancestor of HEAD. A rollback target on a branch "
                f"nobody merged is a build nobody has"
            )
        elif git("rev-parse", "HEAD") == revision:
            failures.append(
                "the rollback target is the current tip. A build you are already "
                "running is not somewhere to roll back to"
            )
        else:
            source = git("show", f"{revision}:src/shared/Config.luau")
            target_schema = schema_version(source)
            current_schema = schema_version(CONFIG.read_text())
            if target_schema != current_schema:
                failures.append(
                    f"the target is at save schema {target_schema} and source is at "
                    f"{current_schema}. Rolling back past a schema bump strands every "
                    f"profile the newer build wrote -- the old build does not know the "
                    f"fields, and the first save it writes back is a save it has "
                    f"narrowed. A schema bump moves the rollback target forward; that "
                    f"is the same fact Config.SaveSchemaFreeze is about, from the "
                    f"other side"
                )
            target_flags = feature_flags(source)
            if not target_flags:
                failures.append(f"no feature flags could be read out of {revision}")
            elif target_flags != recorded_flags:
                for flag in sorted(set(target_flags) | set(recorded_flags)):
                    if target_flags.get(flag) != recorded_flags.get(flag):
                        failures.append(
                            f"`{flag}` is {target_flags.get(flag)} at the target and "
                            f"{recorded_flags.get(flag)} in the matrix. A matrix "
                            f"describing a build it does not match is worse than no "
                            f"matrix, because it will be followed"
                        )

    for name in ("place version", "save schema", "build"):
        if not fields.get(name):
            failures.append(f"the rollback target records no {name}")

    if failures:
        print("Rollback target validation failed:", file=sys.stderr)
        for failure in failures:
            print(f"  * {failure}", file=sys.stderr)
        return 1

    print(
        f"Rollback target validation passed: {revision[:12]} "
        f"(place {fields.get('place version')}, schema {fields.get('save schema')}), "
        f"{len(recorded_flags)} flags matching that revision."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
