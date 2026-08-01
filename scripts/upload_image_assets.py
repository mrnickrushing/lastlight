"""Upload original Last Light image assets through Roblox Open Cloud.

The API key is read only from ROBLOX_API_KEY. It is never written to the
repository or included in output. Roblox does not support content updates for
Image/Decal assets, so changed pixels require a new stable manifest entry.

Run through the local Fish secret:

  fish -c 'source ~/.secrets/roblox.fish; python3 scripts/upload_image_assets.py --all'
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import sys
import time
from pathlib import Path

import requests


ROOT = Path(__file__).resolve().parents[1]
MANIFEST_PATH = ROOT / "assets" / "images" / "manifest.json"
CREATE_URL = "https://apis.roblox.com/assets/v1/assets"
OPERATION_URL = "https://apis.roblox.com/assets/v1/operations/{operation_id}"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--asset-id", action="append", help="Stable manifest image ID; repeatable")
    parser.add_argument("--all", action="store_true", help="Upload every image missing a Roblox ID")
    parser.add_argument("--creator-user-id", default="1213625298")
    parser.add_argument("--timeout", type=int, default=300)
    return parser.parse_args()


def operation_id(path: str) -> str:
    prefix = "operations/"
    if not path.startswith(prefix) or len(path) <= len(prefix):
        raise RuntimeError(f"unexpected operation path: {path!r}")
    return path[len(prefix) :]


def source_path(asset: dict[str, object]) -> Path:
    return ROOT / "assets" / "images" / str(asset["file"])


def validate_source(asset: dict[str, object]) -> Path:
    asset_id = str(asset["id"])
    path = source_path(asset)
    if not path.is_file():
        raise RuntimeError(f"{asset_id}: missing source image {path}")
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    if digest != asset.get("sha256"):
        raise RuntimeError(f"{asset_id}: SHA-256 mismatch; pixels changed without a manifest revision")
    if path.stat().st_size > 20 * 1024 * 1024:
        raise RuntimeError(f"{asset_id}: source exceeds Roblox's 20 MB asset limit")
    return path


def upload(asset: dict[str, object], creator_user_id: str, api_key: str, timeout: int) -> int:
    asset_id = str(asset["id"])
    path = validate_source(asset)
    request_body = {
        "assetType": "Decal",
        "displayName": str(asset["displayName"]),
        "description": f"Original Last Light world art. Stable ID: {asset_id}.",
        "creationContext": {"creator": {"userId": creator_user_id}},
    }
    with path.open("rb") as file_handle:
        response = requests.post(
            CREATE_URL,
            headers={"x-api-key": api_key},
            data={"request": json.dumps(request_body)},
            files={"fileContent": (path.name, file_handle, "image/png")},
            timeout=90,
        )
    if not response.ok:
        raise RuntimeError(f"{asset_id}: upload failed ({response.status_code}): {response.text[:800]}")
    op_id = operation_id(str(response.json().get("path", "")))
    print(f"{asset_id}: accepted as operation {op_id}", flush=True)

    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        status = requests.get(
            OPERATION_URL.format(operation_id=op_id),
            headers={"x-api-key": api_key},
            timeout=30,
        )
        if not status.ok:
            raise RuntimeError(
                f"{asset_id}: operation check failed ({status.status_code}): {status.text[:800]}"
            )
        payload = status.json()
        if payload.get("done"):
            if payload.get("error"):
                raise RuntimeError(f"{asset_id}: Roblox processing failed: {json.dumps(payload['error'])}")
            resolved_id = str((payload.get("response") or {}).get("assetId", ""))
            if not resolved_id.isdigit():
                raise RuntimeError(f"{asset_id}: completed operation had no numeric asset ID")
            print(f"{asset_id}: upload complete ({resolved_id})", flush=True)
            return int(resolved_id)
        time.sleep(2)
    raise RuntimeError(f"{asset_id}: upload timed out after {timeout}s")


def main() -> None:
    args = parse_args()
    api_key = os.environ.get("ROBLOX_API_KEY", "")
    if not api_key:
        raise RuntimeError("ROBLOX_API_KEY is missing")
    if not args.all and not args.asset_id:
        raise RuntimeError("choose --asset-id or --all")

    manifest = json.loads(MANIFEST_PATH.read_text())
    requested = set(args.asset_id or [])
    available = {str(asset["id"]) for asset in manifest["assets"]}
    unknown = requested - available
    if unknown:
        raise RuntimeError(f"unknown image IDs: {', '.join(sorted(unknown))}")

    selected = [
        asset
        for asset in manifest["assets"]
        if (args.all or asset["id"] in requested) and asset.get("robloxAssetId") is None
    ]
    if not selected:
        print("No missing image assets selected.")
        return
    for asset in selected:
        asset["robloxAssetId"] = upload(asset, args.creator_user_id, api_key, args.timeout)
        MANIFEST_PATH.write_text(json.dumps(manifest, indent=2) + "\n")


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, requests.RequestException, ValueError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        raise SystemExit(1)
