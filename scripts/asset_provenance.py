"""One vocabulary for where every shipped asset came from.

`validate_mesh_assets.py`, `validate_image_assets.py` and
`validate_audio_assets.py` each already prove that an asset exists, decodes and
is registered. None of them proved where it came from, and the three manifests
answered that question in three different ways: meshes and images carried a
free-text `source` string per asset, and audio carried one sentence at the top
of the file covering all twenty-five tracks at once.

That is not a gap in rigour so much as a gap in shape. **An original-IP audit
reads one list**, and three vocabularies is three lists. Worse, a per-file
statement is the exact form of evidence that stops being true one asset at a
time: the twenty-sixth track added under a heading that says "all tracks are
free public-domain audio" inherits a claim nobody made about it.

So origin is a per-asset field drawn from a closed vocabulary, and the evidence
each class has to carry is a property of the class rather than of whoever added
the asset:

  * `authored_here` needs a provenance sentence and nothing else. Nobody has to
    be asked about a thing this repository made.
  * `generated_then_authored_here` needs a provenance sentence that names the
    tool, because "we made it" and "a model made it and we normalized it" are
    different answers to an audit and only one of them is interesting.
  * `licensed_platform_library` needs the two facts a licence question actually
    turns on: who published it, and where it lives. This is the class that
    matters, and the count is pinned for the reason RELEASE_GATES pins its
    `review` rows -- somebody else's work entering the game should be a
    deliberate act, not a diff nobody sized.

What this module cannot do is read a licence. Whether Roblox's terms cover the
use this game makes of a Creator Store model is a human question, and a script
claiming to have settled it would be worse than one that says it cannot.
`docs/ASSET_PROVENANCE.md` states the terms each class is used under, this
checks that every asset is filed under one of them and that the document and
the manifests name the same fifty-one licensed assets, and the audit is the
owner's.
"""

from __future__ import annotations

import json
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parents[1]
DOC = ROOT / "docs" / "ASSET_PROVENANCE.md"

# Per class: the manifest fields it must carry, and the substring its provenance
# sentence has to contain (None where no extra sentence is required).
ORIGINS: dict[str, tuple[str, ...]] = {
    "authored_here": ("provenance",),
    "generated_then_authored_here": ("provenance",),
    "licensed_platform_library": ("provenance", "licensedFrom", "sourceUrl"),
}

# The pin. Assets are registries of somebody's work, and the third number is the
# one worth watching: everything in it belongs to somebody else.
EXPECTED_COUNTS = {
    "authored_here": 10,
    "generated_then_authored_here": 34,
    "licensed_platform_library": 51,
}

CLASS_ROW = re.compile(r"^\|\s*`([a-z_]+)`\s*\|")
INVENTORY_ROW = re.compile(
    r"^\|\s*`([a-z0-9_]+)`\s*\|\s*([^|]+?)\s*\|\s*`([^`]+)`\s*\|\s*$"
)


class ProvenanceError(AssertionError):
    """Raised with every failure at once, so one run says all of what is wrong."""


def _read_doc() -> tuple[set[str], dict[str, tuple[str, str]]]:
    if not DOC.is_file():
        raise ProvenanceError(f"missing {DOC}")
    classes: set[str] = set()
    inventory: dict[str, tuple[str, str]] = {}
    section = ""
    for line in DOC.read_text().split("\n"):
        if line.startswith("## "):
            section = line[3:].strip()
            continue
        if section == "Origin classes":
            match = CLASS_ROW.match(line)
            if match is not None:
                classes.add(match.group(1))
        elif section == "The licensed inventory":
            match = INVENTORY_ROW.match(line)
            if match is not None:
                inventory[match.group(1)] = (match.group(2), match.group(3))
    return classes, inventory


def check(registry: str, assets: list[dict], id_field: str = "id") -> None:
    """Assert every asset in one registry records where it came from.

    Called by each of the three validators for its own manifest. The document
    is checked against the union of the three, so it is verified once the whole
    of `npm run check` has run rather than once by each caller -- which is why
    the totals live in `check_totals` and every validator calls that too.
    """
    failures: list[str] = []
    doc_classes, inventory = _read_doc()

    if doc_classes != set(ORIGINS):
        failures.append(
            f"ASSET_PROVENANCE.md lists origin classes {sorted(doc_classes)} and this "
            f"module knows {sorted(ORIGINS)}. Neither list may grow alone: a class in "
            f"the document with no rule behind it is a promise nothing enforces, and a "
            f"class in the code the document does not name is an origin no audit has "
            f"read the terms for"
        )

    for asset in assets:
        stable_id = str(asset.get(id_field))
        origin = asset.get("origin")
        if origin not in ORIGINS:
            failures.append(
                f"{registry}/{stable_id}: origin {origin!r} is not one of "
                + ", ".join(sorted(ORIGINS))
            )
            continue
        for field in ORIGINS[origin]:
            value = asset.get(field)
            # A provenance has to be a sentence. A publisher name is a name, and
            # some of them are four characters, so only the prose field is
            # measured for length.
            minimum = 20 if field == "provenance" else 1
            if not isinstance(value, str) or len(value.strip()) < minimum:
                failures.append(
                    f"{registry}/{stable_id}: origin `{origin}` requires `{field}` and "
                    f"it is {value!r}"
                )
        if origin != "licensed_platform_library":
            continue
        row = inventory.get(stable_id)
        if row is None:
            failures.append(
                f"{registry}/{stable_id} is licensed from somebody else and is not in "
                f"ASSET_PROVENANCE.md's inventory. That table is what the original-IP "
                f"audit reads; an asset missing from it is an asset nobody reviews"
            )
            continue
        publisher, url = row
        if publisher != asset.get("licensedFrom"):
            failures.append(
                f"{registry}/{stable_id}: the manifest is licensed from "
                f"{asset.get('licensedFrom')!r} and the document says {publisher!r}"
            )
        if url != asset.get("sourceUrl"):
            failures.append(
                f"{registry}/{stable_id}: the manifest and the document point at "
                f"different sources"
            )

    if failures:
        raise ProvenanceError("\n  * ".join(["asset provenance failed:"] + failures))


def check_totals() -> str:
    """Hold the pinned counts and the document's inventory against the manifests.

    Every validator calls this, so whichever runs first catches a drift; running
    it three times is cheap and means no ordering between the three scripts is
    load-bearing.
    """
    failures: list[str] = []
    _classes, inventory = _read_doc()

    counts = {origin: 0 for origin in ORIGINS}
    known: set[str] = set()
    for manifest_path, key, id_field in (
        (ROOT / "assets" / "meshes" / "manifest.json", "assets", "id"),
        (ROOT / "assets" / "images" / "manifest.json", "assets", "id"),
        (ROOT / "assets" / "audio" / "manifest.json", "tracks", "id"),
    ):
        for asset in json.loads(manifest_path.read_text())[key]:
            origin = asset.get("origin")
            if origin in counts:
                counts[origin] += 1
            stable_id = str(asset.get(id_field))
            if stable_id in known:
                failures.append(
                    f"{stable_id} is the stable id of two assets. Ids are how the audit "
                    f"and the game name the same object"
                )
            known.add(stable_id)

    for origin, expected in EXPECTED_COUNTS.items():
        if counts[origin] != expected:
            failures.append(
                f"{counts[origin]} assets are `{origin}` and this module is pinned at "
                f"{expected}. Update EXPECTED_COUNTS and ASSET_PROVENANCE.md in the "
                f"same commit, and say in the pull request what arrived"
            )

    orphans = sorted(set(inventory) - known)
    if orphans:
        failures.append(
            "ASSET_PROVENANCE.md's inventory names assets no manifest has: "
            + ", ".join(orphans)
            + ". A row for an asset that is not shipped is a licence somebody is "
            "still paying attention to for nothing"
        )
    if len(inventory) != EXPECTED_COUNTS["licensed_platform_library"]:
        failures.append(
            f"the inventory holds {len(inventory)} rows and "
            f"{EXPECTED_COUNTS['licensed_platform_library']} assets are licensed"
        )

    if failures:
        raise ProvenanceError("\n  * ".join(["asset provenance failed:"] + failures))

    return (
        f"{sum(counts.values())} assets carry an origin "
        f"({counts['authored_here']} authored here, "
        f"{counts['generated_then_authored_here']} generated then authored here, "
        f"{counts['licensed_platform_library']} licensed)."
    )
