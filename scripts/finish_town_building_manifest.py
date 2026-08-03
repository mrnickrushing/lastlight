#!/usr/bin/env python3
"""Complete the town building wiring: measurements fixture and PBR declaration.

validate_mesh_assets.py checks three things agree with each other and with the
bytes on disk: the manifest, the measurement fixture, and the runtime registry.
This writes the first two from the Blender reports. The registry entries need
the Roblox asset IDs, so they are written after upload.

Meshy names its maps Image_0..Image_3 rather than Color/NormalGL/ORM, so the
declared map list is positional. That ordering is Meshy's glTF export order --
base colour, metallic-roughness, normal, emissive -- and is recorded here rather
than renamed on disk, so the manifest describes what the GLB actually contains.
"""

import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
MESH_ROOT = ROOT / "assets/meshes"
MANIFEST = MESH_ROOT / "manifest.json"
REPORTS = ROOT / "meshy_output/reports"

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

# Meshy's glTF export order for a PBR refine.
MAP_ORDER = ["Color", "MetallicRoughness", "NormalGL", "Emissive"]


def main() -> int:
    manifest = json.loads(MANIFEST.read_text())
    measurement_path = MESH_ROOT / manifest["measurementFile"]
    measurements = json.loads(measurement_path.read_text())

    by_id = {asset["id"]: asset for asset in manifest["assets"]}

    for asset_id in BUILDING_IDS:
        report = json.loads((REPORTS / f"{asset_id}.json").read_text())
        textures = report["textures"]

        measurements["assets"][asset_id] = {
            "boundsMin": report["boundsMin"],
            "boundsMax": report["boundsMax"],
            "dimensions": report["dimensions"],
            "longestDimension": report["longestDimension"],
            "triangles": report["trianglesAfter"],
            "meshObjects": report["meshObjects"],
            "materials": ["embedded_pbr"],
            "textures": textures,
            "bytes": report["bytes"],
        }

        asset = by_id[asset_id]
        asset["pbrMaps"] = MAP_ORDER[: len(textures)]
        asset["preserveSourceMaterials"] = True

        print(f"  {asset_id}: {len(textures)} maps, {report['bytes'] / 1024 / 1024:.2f} MB")

    measurement_path.write_text(json.dumps(measurements, indent=2) + "\n")
    MANIFEST.write_text(json.dumps(manifest, indent=2) + "\n")

    print(f"\nmeasurements now hold {len(measurements['assets'])} assets")
    return 0


if __name__ == "__main__":
    sys.exit(main())
