#!/usr/bin/env python3
"""Every authored building keeps clear of every other one.

Milestone 4's exit gate asks that "the town remains navigable under every
allowed building state." Nothing checks that today. The eleven buildings
added for the sixteen-building deliverable were positioned by a generation
script rather than an artist's eye specifically so their footprints would not
collide -- but nothing enforces that going forward, and a building's centre
is a bare Vector3 literal at its call site. Moving one by hand to fix an
unrelated problem is a one-line change with no test standing between it and
two buildings occupying the same ground.

This is deliberately not a pathfinding check. Verifying a character can
actually walk between every pair of buildings under every tier needs a
NavMesh and a live Studio session, which is what the Milestone 3 playtest
runbook is for. What is checkable from source alone, and what this checks, is
the narrower and still real claim that two building footprints do not
overlap and keep a minimum clearance between them, treating each footprint as
a circle sized to its diagonal regardless of which way it faces. That is a
deliberate over-approximation -- a building's real footprint is its
(possibly rotated) rectangle, smaller than the circle drawn around it -- so
this can report two buildings as too close when the true rotated rectangles
would just clear each other, but it can never miss a real overlap. A false
alarm here costs someone a look at two coordinates; a missed one costs a
player standing inside a wall.

Scoped to the fourteen buildings placed through authoredBuilding or a direct
buildingShell call, where a literal centre and footprint sit at the call
site and can be read without executing Luau. building_town_board and
building_first_lantern are placed through bespoke, older code with no
equivalent literal pair, and are long-established fixed landmarks rather
than content this check exists to guard.
"""

import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
WORLD_SERVICE = ROOT / "src" / "server" / "Services" / "WorldService.luau"

MINIMUM_CLEARANCE = 6.0

VECTOR = r"Vector3\.new\(\s*(-?[\d.]+)\s*,\s*0\s*,\s*(-?[\d.]+)\s*\)"
# A display name is either a literal or a lookup, since M13 wave D moved the
# player-visible half of these call sites into the string table. Both shapes are
# read here rather than only the newer one: this file is parsed as text, and a
# reader that knew one shape reported zero buildings and said so.
NAME = r'(?:"[^"]*"|Strings\.get\("[a-z0-9_.]+"\))'

AUTHORED_BUILDING = re.compile(
    r'authoredBuilding\(\s*"([a-z_]+)"\s*,\s*' + NAME + r"\s*,\s*" + NAME + r"\s*,\s*"
    + VECTOR
    + r"\s*,\s*"
    + VECTOR,
)
BUILDING_SHELL = re.compile(
    r'buildingShell\(\s*"([a-z_]+)"\s*,\s*' + NAME + r"\s*,\s*" + VECTOR + r"\s*,\s*" + VECTOR,
)


def extract_buildings(text: str) -> dict:
    buildings = {}
    for pattern in (AUTHORED_BUILDING, BUILDING_SHELL):
        for match in pattern.finditer(text):
            building_id, cx, cz, fx, fz = match.groups()
            if building_id in buildings:
                continue
            buildings[building_id] = {
                "center": (float(cx), float(cz)),
                "footprint": (float(fx), float(fz)),
            }
    return buildings


def bounding_radius(footprint: tuple) -> float:
    fx, fz = footprint
    return ((fx / 2) ** 2 + (fz / 2) ** 2) ** 0.5


def main() -> None:
    if not WORLD_SERVICE.exists():
        print(f"missing {WORLD_SERVICE}", file=sys.stderr)
        sys.exit(1)

    text = WORLD_SERVICE.read_text(encoding="utf-8")
    buildings = extract_buildings(text)

    if len(buildings) < 10:
        print(
            f"Town layout validation found only {len(buildings)} authored buildings "
            "-- expected at least 10. The call-site shape this script parses may have "
            "changed; update AUTHORED_BUILDING/BUILDING_SHELL rather than silently "
            "passing with fewer buildings checked than exist.",
            file=sys.stderr,
        )
        sys.exit(1)

    ids = sorted(buildings)
    failures = []
    for i, left_id in enumerate(ids):
        left = buildings[left_id]
        for right_id in ids[i + 1 :]:
            right = buildings[right_id]
            lx, lz = left["center"]
            rx, rz = right["center"]
            distance = ((lx - rx) ** 2 + (lz - rz) ** 2) ** 0.5
            required = (
                bounding_radius(left["footprint"])
                + bounding_radius(right["footprint"])
                + MINIMUM_CLEARANCE
            )
            if distance < required:
                failures.append(
                    f"{left_id} and {right_id} are {distance:.1f} studs apart centre to "
                    f"centre but need {required:.1f} for their footprints plus "
                    f"{MINIMUM_CLEARANCE:.0f} studs of clearance"
                )

    if failures:
        print(f"Town layout validation failed for {len(failures)} pair(s):", file=sys.stderr)
        for failure in failures:
            print(f"  {failure}", file=sys.stderr)
        sys.exit(1)

    print(f"Town layout validation passed for {len(buildings)} buildings.")


if __name__ == "__main__":
    main()
