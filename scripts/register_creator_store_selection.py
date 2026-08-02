"""Merge the reviewed first-world Creator Store selection into mesh fixtures."""

from __future__ import annotations

import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MESH_ROOT = ROOT / "assets" / "meshes"
SELECTION_PATH = MESH_ROOT / "candidates" / "creator-store-full-pass" / "selection.json"


def asset_slug(name: str) -> str:
    slug = re.sub(r"[^A-Za-z0-9]+", "-", name).strip("-")
    return slug or "asset"


def main() -> None:
    selection = json.loads(SELECTION_PATH.read_text())["assets"]
    manifest_path = MESH_ROOT / "manifest.json"
    manifest = json.loads(manifest_path.read_text())
    manifest_assets = {entry["id"]: entry for entry in manifest["assets"]}

    measurement_path = MESH_ROOT / manifest["measurementFile"]
    measurement_document = json.loads(measurement_path.read_text())
    measurements = measurement_document["assets"]

    for selected in selection:
        stable_id = selected["id"]
        asset_id = selected["assetId"]
        source_file = f"candidates/creator-store-full-pass/{asset_id}.rbxm"
        preview_file = f"previews/full-pass/{asset_id}.png"
        role = selected["role"]
        placement_band = (
            "curated_enemy"
            if role.startswith("enemy_")
            else "curated_hero"
            if role in {"bramblewake_memory_beacon", "old_growth_elite_visual_shell"}
            else "curated_core"
        )
        entry = {
            "id": stable_id,
            "displayName": selected["displayName"],
            "role": selected["role"],
            "placementBand": placement_band,
            "source": "roblox_creator_store_model",
            "provenance": (
                f"Free Creator Store model by creator "
                f"{selected['creator']}; asset {asset_id}. Completed 420px Roblox thumbnail "
                "and downloaded model payload inspected on 2026-08-01."
            ),
            "sourceUrl": (
                f"https://create.roblox.com/store/asset/{asset_id}/"
                f"{asset_slug(selected['name'])}"
            ),
            "file": source_file,
            "previewFile": preview_file,
            "targetLongestDimension": selected["targetLongestDimension"],
            "maxTriangles": selected["maxTriangles"],
            "maxMaterialSlots": selected["maxMaterialSlots"],
            "preserveSourceMaterials": True,
            "robloxAssetId": asset_id,
        }
        existing = manifest_assets.get(stable_id)
        if existing is None:
            manifest["assets"].append(entry)
            manifest_assets[stable_id] = entry
        elif existing != entry:
            existing_without_provenance = dict(existing)
            expected_without_provenance = dict(entry)
            existing_without_provenance.pop("provenance", None)
            expected_without_provenance.pop("provenance", None)
            if existing_without_provenance != expected_without_provenance:
                raise AssertionError(
                    f"{stable_id}: manifest entry differs from reviewed selection"
                )
            existing["provenance"] = entry["provenance"]

        measured = {
            "boundsMin": selected["boundsMin"],
            "boundsMax": selected["boundsMax"],
            "dimensions": selected["dimensions"],
            "longestDimension": selected["longestDimension"],
            "triangles": selected["triangles"],
            "meshObjects": selected["meshObjects"],
            "materials": ["creator_source_preserved"],
            "baseParts": selected["baseParts"],
            "scripts": 0,
            "bytes": selected["bytes"],
        }
        existing_measurement = measurements.get(stable_id)
        if existing_measurement is None:
            measurements[stable_id] = measured
        elif existing_measurement != measured:
            existing_without_bytes = dict(existing_measurement)
            expected_without_bytes = dict(measured)
            existing_without_bytes.pop("bytes", None)
            expected_without_bytes.pop("bytes", None)
            if existing_without_bytes != expected_without_bytes:
                raise AssertionError(
                    f"{stable_id}: measurement differs from reviewed selection"
                )
            existing_measurement["bytes"] = measured["bytes"]

    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")
    measurement_path.write_text(json.dumps(measurement_document, indent=2) + "\n")
    print(f"Registered {len(selection)} reviewed Creator Store assets.")


if __name__ == "__main__":
    main()
