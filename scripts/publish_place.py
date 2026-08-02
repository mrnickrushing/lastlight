"""Publish the built start place to Roblox through Open Cloud.

Publishes assets/../build/LastLight.rbxlx to the universe and place recorded
below. The API key is read only from ROBLOX_API_KEY and is never written or
printed.

  python3 scripts/publish_place.py            # publish
  python3 scripts/publish_place.py --saved     # upload without releasing

Run `npm test` first: this uploads whatever is currently in build/, so the
place file must have been regenerated from the same commit it was tested at.
"""

from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path

import requests

ROOT = Path(__file__).resolve().parents[1]
PLACE_FILE = ROOT / "build" / "LastLight.rbxlx"
UNIVERSE_ID = 10611704810
PLACE_ID = 115897110071287
URL = "https://apis.roblox.com/universes/v1/{universe}/places/{place}/versions"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--saved",
        action="store_true",
        help="upload as a saved version instead of releasing it to players",
    )
    parser.add_argument("--timeout", type=int, default=300)
    args = parser.parse_args()

    api_key = os.environ.get("ROBLOX_API_KEY", "")
    if not api_key:
        raise RuntimeError("ROBLOX_API_KEY is missing")
    if not PLACE_FILE.is_file():
        raise RuntimeError(f"missing built place {PLACE_FILE}; run npm run build")

    version_type = "Saved" if args.saved else "Published"
    response = requests.post(
        URL.format(universe=UNIVERSE_ID, place=PLACE_ID),
        params={"versionType": version_type},
        headers={"x-api-key": api_key, "Content-Type": "application/xml"},
        data=PLACE_FILE.read_bytes(),
        timeout=args.timeout,
    )
    if not response.ok:
        raise RuntimeError(f"publish failed ({response.status_code}): {response.text[:400]}")
    version = response.json().get("versionNumber")
    print(f"{version_type} place {PLACE_ID} as version {version}", file=sys.stdout)


if __name__ == "__main__":
    main()
