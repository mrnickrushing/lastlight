"""Validate committed image sources and their Roblox asset mappings."""

from __future__ import annotations

import hashlib
import json
import struct
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MANIFEST_PATH = ROOT / "assets" / "images" / "manifest.json"


def png_dimensions(path: Path) -> tuple[int, int]:
    header = path.read_bytes()[:24]
    if len(header) != 24 or header[:8] != b"\x89PNG\r\n\x1a\n" or header[12:16] != b"IHDR":
        raise RuntimeError(f"{path}: expected a PNG with a valid IHDR")
    return struct.unpack(">II", header[16:24])


def main() -> None:
    manifest = json.loads(MANIFEST_PATH.read_text())
    seen_ids: set[str] = set()
    seen_roblox_ids: set[int] = set()
    for asset in manifest["assets"]:
        asset_id = str(asset["id"])
        if asset_id in seen_ids:
            raise RuntimeError(f"duplicate stable image ID: {asset_id}")
        seen_ids.add(asset_id)
        path = ROOT / "assets" / "images" / str(asset["file"])
        if not path.is_file():
            raise RuntimeError(f"{asset_id}: missing source {path}")
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        if digest != asset["sha256"]:
            raise RuntimeError(f"{asset_id}: SHA-256 mismatch")
        width, height = png_dimensions(path)
        if (width, height) != (asset["width"], asset["height"]):
            raise RuntimeError(f"{asset_id}: PNG dimensions do not match the manifest")
        roblox_id = asset.get("robloxAssetId")
        if not isinstance(roblox_id, int) or roblox_id <= 0:
            raise RuntimeError(f"{asset_id}: missing positive Roblox asset ID")
        if roblox_id in seen_roblox_ids:
            raise RuntimeError(f"duplicate Roblox image asset ID: {roblox_id}")
        seen_roblox_ids.add(roblox_id)
        layout = asset.get("layout") or {}
        panels = layout.get("panels") or []
        if len(panels) != int(layout.get("columns", 0)) * int(layout.get("rows", 0)):
            raise RuntimeError(f"{asset_id}: atlas panel count does not match its grid")
    print(f"Validated {len(seen_ids)} source image asset(s) and Roblox mappings.")


if __name__ == "__main__":
    main()
