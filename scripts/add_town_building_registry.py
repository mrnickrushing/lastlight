#!/usr/bin/env python3
"""Append the town building entries to MeshAssetRegistry.luau.

validate_mesh_assets.py compares the runtime registry against the manifest and
fails if the PBR flag, the source-material policy, or the Creator Store policy
disagree. Generating the block from the manifest rather than typing it means
those three can only ever say what the manifest already says.
"""

import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
MANIFEST = ROOT / "assets/meshes/manifest.json"
REGISTRY = ROOT / "src/server/World/MeshAssetRegistry.luau"

BUILDING_IDS = [
    "mesh_celebration_stage_a",
    "mesh_sawmill_a",
    "mesh_union_forge_a",
    "mesh_engineer_yard_a",
    "mesh_common_kitchen_a",
    "mesh_hearthmarket_stalls_a",
    "mesh_trade_post_a",
    "mesh_guardhouse_a",
    "mesh_watchtower_a",
    "mesh_trapworks_a",
    "mesh_waterworks_a",
]


def lua_number(value: float) -> str:
    return str(int(value)) if float(value).is_integer() else str(value)


def main() -> int:
    manifest = json.loads(MANIFEST.read_text())
    by_id = {asset["id"]: asset for asset in manifest["assets"]}
    source = REGISTRY.read_text()

    blocks = []
    for asset_id in BUILDING_IDS:
        if f'id = "{asset_id}"' in source:
            print(f"  skip {asset_id} (already registered)")
            continue
        asset = by_id[asset_id]
        roblox_id = asset.get("robloxAssetId")
        if not roblox_id:
            print(f"  MISSING robloxAssetId for {asset_id}", file=sys.stderr)
            return 1

        pbr = "true" if asset.get("pbrMaps") else "false"
        preserve = (
            "true"
            if asset.get("preserveSourceMaterials") or asset.get("pbrMaps")
            else "false"
        )
        creator_store = "true" if asset.get("source") == "roblox_creator_store_model" else "false"

        blocks.append(
            "    {\n"
            f'        id = "{asset_id}",\n'
            f"        assetId = {roblox_id},\n"
            f"        targetLongestDimension = {lua_number(asset['targetLongestDimension'])},\n"
            f"        maxTriangles = {asset['maxTriangles']},\n"
            f"        maxMaterialSlots = {asset['maxMaterialSlots']},\n"
            f'        placementBand = "{asset["placementBand"]}",\n'
            f"        pbr = {pbr},\n"
            f"        preserveSourceMaterials = {preserve},\n"
            f"        creatorStore = {creator_store},\n"
            "    },\n"
        )
        print(f"  add {asset_id} -> {roblox_id}")

    if not blocks:
        print("nothing to add")
        return 0

    # Close of the ENTRIES table: the last "}," line before the bare "}".
    marker = "    },\n}\n\nlocal BY_ID"
    if marker not in source:
        print("could not find the end of the ENTRIES table", file=sys.stderr)
        return 1
    source = source.replace(marker, "    },\n" + "".join(blocks) + "}\n\nlocal BY_ID", 1)

    REGISTRY.write_text(source)
    print(f"\n{len(blocks)} entries appended")
    return 0


if __name__ == "__main__":
    sys.exit(main())
