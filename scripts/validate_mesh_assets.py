"""Validate committed mesh artifacts without requiring Blender or credentials."""

from __future__ import annotations

import json
import struct
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MESH_ROOT = ROOT / "assets" / "meshes"


def fail(message: str) -> None:
    raise AssertionError(message)


def main() -> None:
    manifest = json.loads((MESH_ROOT / "manifest.json").read_text())
    measurements = json.loads((MESH_ROOT / manifest["measurementFile"]).read_text())["assets"]
    assets = manifest["assets"]
    registry_text = (ROOT / "src" / "server" / "World" / "MeshAssetRegistry.luau").read_text()
    ids = [asset["id"] for asset in assets]
    if len(ids) != len(set(ids)):
        fail("mesh manifest has duplicate stable IDs")
    if set(ids) != set(measurements):
        fail("mesh manifest and measurement fixture contain different stable IDs")

    roblox_ids: list[int] = []
    for asset in assets:
        stable_id = asset["id"]
        measured = measurements[stable_id]
        path = MESH_ROOT / asset["file"]
        if not path.is_file():
            fail(f"{stable_id}: missing GLB {path}")
        data = path.read_bytes()
        if len(data) < 12 or data[:4] != b"glTF" or struct.unpack_from("<I", data, 4)[0] != 2:
            fail(f"{stable_id}: file is not a glTF 2 binary")
        if struct.unpack_from("<I", data, 8)[0] != len(data):
            fail(f"{stable_id}: GLB header length does not match file size")
        json_length, json_type = struct.unpack_from("<II", data, 12)
        if json_type != 0x4E4F534A:
            fail(f"{stable_id}: first GLB chunk is not JSON")
        gltf = json.loads(data[20 : 20 + json_length].decode("utf-8").rstrip(" \x00"))
        mesh_names = [str(mesh.get("name", "")) for mesh in gltf.get("meshes", [])]
        expected_prefix = f"{stable_id}__"
        if not asset.get("pbrMaps") and (
            not mesh_names or any(not name.startswith(expected_prefix) for name in mesh_names)
        ):
            fail(
                f"{stable_id}: exported mesh datablock names must preserve the authored material group"
            )
        if measured["bytes"] != len(data):
            fail(f"{stable_id}: measured byte count is stale")
        if abs(measured["longestDimension"] - asset["targetLongestDimension"]) > 0.001:
            fail(f"{stable_id}: authored size does not match target")
        if measured["triangles"] > asset["maxTriangles"]:
            fail(f"{stable_id}: triangle budget exceeded")
        if measured["meshObjects"] > asset["maxMaterialSlots"]:
            fail(f"{stable_id}: MeshPart/material budget exceeded")
        roblox_id = asset.get("robloxAssetId")
        if not isinstance(roblox_id, int) or roblox_id <= 0:
            fail(f"{stable_id}: missing uploaded Roblox model ID")
        roblox_ids.append(roblox_id)
        marker = f'id = "{stable_id}"'
        marker_index = registry_text.find(marker)
        if marker_index < 0:
            fail(f"{stable_id}: missing from runtime mesh registry")
        registry_block = registry_text[marker_index : marker_index + 520]
        if f"assetId = {roblox_id}" not in registry_block:
            fail(f"{stable_id}: runtime Roblox ID differs from manifest")
        if f"targetLongestDimension = {asset['targetLongestDimension']}" not in registry_block:
            fail(f"{stable_id}: runtime target size differs from manifest")
        if f'placementBand = "{asset["placementBand"]}"' not in registry_block:
            fail(f"{stable_id}: runtime placement band differs from manifest")
        expected_pbr = "pbr = true" if asset.get("pbrMaps") else "pbr = false"
        if expected_pbr not in registry_block:
            fail(f"{stable_id}: runtime PBR classification differs from manifest")
        source_file = asset.get("sourceFile")
        if source_file and not (MESH_ROOT / source_file).is_file():
            fail(f"{stable_id}: missing original generation source")
        if asset.get("pbrMaps"):
            textures = measured.get("textures", [])
            if len(textures) < 3 or any(not texture.get("packed") for texture in textures):
                fail(f"{stable_id}: expected embedded PBR texture set")

    if len(roblox_ids) != len(set(roblox_ids)):
        fail("mesh manifest reuses a Roblox asset ID")
    print(f"Validated {len(assets)} measured GLBs and Roblox asset mappings.")


if __name__ == "__main__":
    main()
