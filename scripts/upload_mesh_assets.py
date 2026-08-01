"""Upload measured Last Light GLBs with Roblox Open Cloud.

The API key is read only from ROBLOX_API_KEY. It is never written to the
repository or included in output. Run this script through the local Fish secret:

  fish -c 'source ~/.secrets/roblox.fish; python3 scripts/upload_mesh_assets.py --asset-id mesh_root_arch_a'
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
from pathlib import Path

import requests


ROOT = Path(__file__).resolve().parents[1]
MANIFEST_PATH = ROOT / "assets" / "meshes" / "manifest.json"
CREATE_URL = "https://apis.roblox.com/assets/v1/assets"
UPDATE_URL = "https://apis.roblox.com/assets/v1/assets/{asset_id}"
OPERATION_URL = "https://apis.roblox.com/assets/v1/operations/{operation_id}"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--asset-id", action="append", help="Stable manifest asset ID; repeat to upload several")
    parser.add_argument("--all", action="store_true", help="Upload every manifest asset missing a Roblox ID")
    parser.add_argument(
        "--update-existing",
        action="store_true",
        help=(
            "Replace the content of already-uploaded assets (selected by --asset-id "
            "or --all) with the current GLB on disk, instead of skipping them. "
            "Regenerating a GLB does not change what is live in the game until "
            "this runs -- see PATCH /assets/v1/assets/{assetId} in Roblox's Open "
            "Cloud reference, which the API confirms only supports updating "
            "content for the Model asset type this kit already uses. This "
            "overwrites the currently live mesh; there is no undo."
        ),
    )
    parser.add_argument("--creator-user-id", default="1213625298")
    parser.add_argument("--timeout", type=int, default=300)
    return parser.parse_args()


def operation_id(path: str) -> str:
    prefix = "operations/"
    if not path.startswith(prefix) or len(path) <= len(prefix):
        raise RuntimeError(f"unexpected operation path: {path!r}")
    return path[len(prefix) :]


def _submit_and_await(
    asset_id: str,
    method: str,
    url: str,
    request_body: dict[str, object],
    file_path: Path,
    api_key: str,
    timeout: int,
    verb: str,
) -> int:
    """POST or PATCH the multipart request, then poll the returned operation
    to completion. Both create and update return the same Operation shape, so
    this is the one place that knows how to wait for either.
    """
    with file_path.open("rb") as file_handle:
        response = requests.request(
            method,
            url,
            headers={"x-api-key": api_key},
            data={"request": json.dumps(request_body)},
            files={"fileContent": (file_path.name, file_handle, "model/gltf-binary")},
            timeout=90,
        )
    if not response.ok:
        raise RuntimeError(f"{asset_id}: {verb} failed ({response.status_code}): {response.text[:800]}")
    operation = response.json()
    op_id = operation_id(str(operation.get("path", "")))
    print(f"{asset_id}: accepted as operation {op_id}", flush=True)

    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        status = requests.get(
            OPERATION_URL.format(operation_id=op_id),
            headers={"x-api-key": api_key},
            timeout=30,
        )
        if not status.ok:
            raise RuntimeError(f"{asset_id}: operation check failed ({status.status_code}): {status.text[:800]}")
        payload = status.json()
        if payload.get("done"):
            if payload.get("error"):
                raise RuntimeError(f"{asset_id}: Roblox processing failed: {json.dumps(payload['error'])}")
            response_payload = payload.get("response") or {}
            resolved_id = str(response_payload.get("assetId", asset_id if method == "PATCH" else ""))
            if method == "POST" and not resolved_id.isdigit():
                raise RuntimeError(f"{asset_id}: completed operation had no numeric asset ID")
            print(f"{asset_id}: {verb} complete ({resolved_id})", flush=True)
            return int(resolved_id) if resolved_id.isdigit() else int(asset_id)
        time.sleep(2)
    raise RuntimeError(f"{asset_id}: {verb} operation timed out after {timeout}s")


def upload(asset: dict[str, object], creator_user_id: str, api_key: str, timeout: int) -> int:
    """Create a brand-new Roblox Model asset from the manifest's GLB."""
    asset_id = str(asset["id"])
    file_path = ROOT / "assets" / "meshes" / str(asset["file"])
    if not file_path.is_file():
        raise RuntimeError(f"{asset_id}: missing prepared GLB {file_path}")

    request_body = {
        "assetType": "Model",
        "displayName": str(asset["displayName"]),
        "description": f"Original Last Light environment mesh. Stable ID: {asset_id}.",
        "creationContext": {"creator": {"userId": creator_user_id}},
    }
    return _submit_and_await(asset_id, "POST", CREATE_URL, request_body, file_path, api_key, timeout, "upload")


def update_content(asset: dict[str, object], api_key: str, timeout: int) -> int:
    """Replace an already-uploaded asset's content with the current GLB on
    disk, keeping the same Roblox asset ID. This is the only way a
    regenerated GLB (a shading fix, a remeasured bound, anything that is not
    a first-time upload) reaches the live game: `upload()` only ever creates,
    and main() below skips any asset that already has a robloxAssetId unless
    --update-existing is passed.
    """
    asset_id = str(asset["id"])
    roblox_asset_id = asset.get("robloxAssetId")
    if roblox_asset_id is None:
        raise RuntimeError(f"{asset_id}: --update-existing requires an existing robloxAssetId; use upload() instead")
    file_path = ROOT / "assets" / "meshes" / str(asset["file"])
    if not file_path.is_file():
        raise RuntimeError(f"{asset_id}: missing prepared GLB {file_path}")

    # No updateMask: per Roblox's Open Cloud reference, updateMask governs
    # metadata fields (description, displayName, icon, previews) and is
    # documented separately from content replacement, which this call does
    # not touch. Only the model's binary content is being changed here.
    request_body = {"assetType": "Model"}
    url = UPDATE_URL.format(asset_id=roblox_asset_id)
    return _submit_and_await(asset_id, "PATCH", url, request_body, file_path, api_key, timeout, "content update")


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
        raise RuntimeError(f"unknown manifest asset IDs: {', '.join(sorted(unknown))}")

    in_scope = [asset for asset in manifest["assets"] if args.all or asset["id"] in requested]

    if args.update_existing:
        selected = [asset for asset in in_scope if asset.get("robloxAssetId") is not None]
        if not selected:
            print("No already-uploaded assets selected.")
            return
        print(
            f"Replacing live content for {len(selected)} asset(s): "
            f"{', '.join(str(asset['id']) for asset in selected)}",
            flush=True,
        )
        for asset in selected:
            update_content(asset, api_key, args.timeout)
        return

    selected = [asset for asset in in_scope if asset.get("robloxAssetId") is None]
    if not selected:
        print("No missing assets selected.")
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
