"""Download a reviewed Creator Store model as its .rbxm payload.

The download half of the workflow in docs/VISUAL_QUALITY_STANDARD.md. The
first Creator Store pass was downloaded by hand, so nothing recorded how to
repeat it and the next session had to rediscover the endpoint.

  fish -c 'source ~/.secrets/roblox.fish; \
    python3 scripts/download_creator_store_model.py 5613094175 --slug wooden-bed'

Only download models that have already been thumbnail-reviewed. Use
scripts/search_creator_store.py to find and look at candidates first.

The key is read from ROBLOX_API_KEY and never written or printed.

Note on endpoints: assetdelivery.roblox.com does NOT accept an Open Cloud API
key and answers 401 no matter how valid the key is. The Open Cloud
asset-delivery-api below returns a signed `location` for the actual bytes,
which is then fetched unauthenticated.
"""

from __future__ import annotations

import argparse
import gzip
import json
import os
import sys
import urllib.request
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CANDIDATE_DIR = ROOT / "assets" / "meshes" / "candidates" / "creator-store-full-pass"
DELIVERY_URL = "https://apis.roblox.com/asset-delivery-api/v1/assetId/{asset_id}"

# assetTypeId 10 is Model. Anything else is not a placeable prop and the
# rest of the pipeline (sanitize, measure, MeshTemplateLoader) assumes a Model.
MODEL_ASSET_TYPE = 10


def resolve_location(asset_id: int, api_key: str, timeout: int) -> str:
    request = urllib.request.Request(
        DELIVERY_URL.format(asset_id=asset_id),
        headers={"x-api-key": api_key, "Accept": "application/json"},
    )
    with urllib.request.urlopen(request, timeout=timeout) as response:
        payload = json.loads(response.read().decode("utf8"))
    if payload.get("isArchived"):
        raise RuntimeError(f"{asset_id}: asset is archived")
    asset_type = payload.get("assetTypeId")
    if asset_type != MODEL_ASSET_TYPE:
        raise RuntimeError(f"{asset_id}: expected a Model (10), got assetTypeId {asset_type}")
    location = payload.get("location")
    if not location:
        raise RuntimeError(f"{asset_id}: delivery response carried no location")
    return str(location)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("asset_id", type=int, help="numeric Creator Store asset ID")
    parser.add_argument("--slug", help="unused today; kept so calls read self-documenting")
    parser.add_argument("--timeout", type=int, default=60)
    args = parser.parse_args()

    api_key = os.environ.get("ROBLOX_API_KEY", "")
    if not api_key:
        raise RuntimeError("ROBLOX_API_KEY is missing")

    location = resolve_location(args.asset_id, api_key, args.timeout)
    with urllib.request.urlopen(location, timeout=args.timeout) as response:
        payload = response.read()
    if not payload:
        raise RuntimeError(f"{args.asset_id}: delivery returned an empty body")

    # The content CDN serves the payload gzip-compressed and urllib does not
    # decompress it. Written straight to disk the file looks plausible -- it
    # has a size, and nothing errors -- but every downstream tool rejects it
    # with "Unknown document format", which reads like a corrupt asset rather
    # than a transport detail.
    if payload[:2] == b"\x1f\x8b":
        payload = gzip.decompress(payload)

    # Lune's Roblox document reader accepts XML models rooted at <roblox>, but
    # not the optional XML declaration some CDN payloads include. Normalize
    # that transport variation before validation and storage.
    if payload.startswith(b"<?xml"):
        root_offset = payload.find(b"<roblox")
        if root_offset == -1:
            raise RuntimeError(f"{args.asset_id}: XML payload has no Roblox root")
        payload = payload[root_offset:]

    # A binary .rbxm starts with "<roblox!"; normalized XML starts with the
    # Roblox root element.
    # Checking here means a bad download fails at the download, not three
    # steps later inside a Lune script.
    if not payload.startswith(b"<roblox"):
        raise RuntimeError(
            f"{args.asset_id}: payload is not a Roblox model "
            f"(starts with {payload[:8]!r})"
        )

    CANDIDATE_DIR.mkdir(parents=True, exist_ok=True)
    destination = CANDIDATE_DIR / f"{args.asset_id}.rbxm"
    destination.write_bytes(payload)
    print(f"{args.asset_id}: wrote {destination.relative_to(ROOT)} ({len(payload)} bytes)")


if __name__ == "__main__":
    try:
        main()
    except (urllib.error.URLError, RuntimeError, ValueError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        raise SystemExit(1)
