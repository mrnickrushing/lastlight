"""Search the Roblox Creator Store and report reviewable candidates.

The first pass of the Creator Store kit was sourced by hand, which left no
reproducible record of how a candidate was found or why it was rejected. This
covers the search-and-review half of the workflow in
docs/VISUAL_QUALITY_STANDARD.md; scripts/download_creator_store_model.py
handles the download half.

Nothing here writes to the repository. It prints candidates with their
creator, part counts, and a completed thumbnail URL so a human or an agent
with image support can actually look at them before anything is committed.

  python3 scripts/search_creator_store.py "wooden bed" --limit 8

An API key is only needed for the download step, not for search or thumbnails.
"""

from __future__ import annotations

import argparse
import json
import sys
import time
import urllib.parse
import urllib.request


SEARCH_URL = "https://apis.roblox.com/toolbox-service/v1/marketplace/10"
DETAILS_URL = "https://apis.roblox.com/toolbox-service/v1/items/details"
THUMBNAIL_URL = "https://thumbnails.roblox.com/v1/assets"


def _get_json(url: str, timeout: int = 30) -> dict:
    request = urllib.request.Request(url, headers={"Accept": "application/json"})
    with urllib.request.urlopen(request, timeout=timeout) as response:
        return json.loads(response.read().decode("utf8"))


def search(keyword: str, limit: int) -> list[int]:
    query = urllib.parse.urlencode(
        {"keyword": keyword, "limit": limit, "sortType": "Relevance"}
    )
    payload = _get_json(f"{SEARCH_URL}?{query}")
    return [int(entry["id"]) for entry in payload.get("data", []) if entry.get("id")]


def details(asset_ids: list[int]) -> dict[int, dict]:
    if not asset_ids:
        return {}
    query = urllib.parse.urlencode({"assetIds": ",".join(str(i) for i in asset_ids)})
    payload = _get_json(f"{DETAILS_URL}?{query}")
    resolved: dict[int, dict] = {}
    for entry in payload.get("data", []):
        asset = entry.get("asset") or {}
        creator = entry.get("creator") or {}
        asset_id = asset.get("id")
        if asset_id is None:
            continue
        resolved[int(asset_id)] = {
            "name": asset.get("name", "?"),
            "creator": creator.get("name", "?"),
            "verified": bool(creator.get("hasVerifiedBadge")),
            "price": (asset.get("price") if asset.get("price") is not None else 0),
        }
    return resolved


def thumbnails(asset_ids: list[int], timeout: int) -> dict[int, str]:
    """Resolve completed thumbnail URLs, polling past the Pending state.

    A Pending entry carries a placeholder image, not the asset, so returning it
    would invite exactly the mistake this whole workflow exists to prevent.
    """
    pending = {int(i) for i in asset_ids}
    resolved: dict[int, str] = {}
    deadline = time.monotonic() + timeout
    while pending and time.monotonic() < deadline:
        query = urllib.parse.urlencode(
            {
                "assetIds": ",".join(str(i) for i in sorted(pending)),
                "size": "420x420",
                "format": "Png",
            }
        )
        payload = _get_json(f"{THUMBNAIL_URL}?{query}")
        for entry in payload.get("data", []):
            if entry.get("state") == "Completed" and entry.get("imageUrl"):
                asset_id = int(entry["targetId"])
                resolved[asset_id] = entry["imageUrl"]
                pending.discard(asset_id)
        if pending:
            time.sleep(2)
    return resolved


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("keyword", help="what to search the Creator Store for")
    parser.add_argument("--limit", type=int, default=10)
    parser.add_argument("--timeout", type=int, default=30)
    args = parser.parse_args()

    asset_ids = search(args.keyword, args.limit)
    if not asset_ids:
        print(f"no results for {args.keyword!r}")
        return
    info = details(asset_ids)
    images = thumbnails(asset_ids, args.timeout)

    for asset_id in asset_ids:
        entry = info.get(asset_id, {})
        print(f"{asset_id}")
        print(f"  name    : {entry.get('name', '?')}")
        print(f"  creator : {entry.get('creator', '?')}")
        print(f"  price   : {entry.get('price', '?')}")
        print(f"  thumb   : {images.get(asset_id, 'UNRESOLVED')}")


if __name__ == "__main__":
    try:
        main()
    except (urllib.error.URLError, ValueError, KeyError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        raise SystemExit(1)
