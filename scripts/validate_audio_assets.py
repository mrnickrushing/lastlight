#!/usr/bin/env python3
"""Validate the reviewed, open-use Roblox music ledger."""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "assets" / "audio" / "manifest.json"
REGIONS = {
    "region_emberhollow",
    "region_bramblewake",
    "region_ironroot",
    "region_mireglass",
    "region_tempest",
    "region_frostmere",
    "region_cinderfall",
    "region_hollow",
}
PHASES = {"day", "dusk", "night"}


def main() -> None:
    payload = json.loads(MANIFEST.read_text(encoding="utf-8"))
    verification = payload.get("verification")
    assert isinstance(verification, dict) and all(verification.values()), "audio review is incomplete"
    tracks = payload.get("tracks")
    assert isinstance(tracks, list) and len(tracks) == 25, "expected 24 regional tracks and one Blackout track"

    ids: set[str] = set()
    asset_ids: set[int] = set()
    coverage: dict[str, set[str]] = {region: set() for region in REGIONS}
    for track in tracks:
        stable_id = track.get("id")
        asset_id = track.get("assetId")
        assert isinstance(stable_id, str) and stable_id.startswith("music_"), "invalid music ID"
        assert stable_id not in ids, f"duplicate music ID: {stable_id}"
        assert isinstance(asset_id, int) and asset_id > 0, f"invalid asset ID: {stable_id}"
        assert asset_id not in asset_ids, f"reused asset ID: {asset_id}"
        assert track.get("creator") in {"APMOfficial", "DistrokidOfficial"}, f"unreviewed provider: {stable_id}"
        assert track.get("codec") in {"ogg", "mp3"}, f"unsupported codec: {stable_id}"
        assert int(track.get("durationSeconds", 0)) >= 60, f"track is too short to loop: {stable_id}"
        ids.add(stable_id)
        asset_ids.add(asset_id)
        region_id = track.get("regionId")
        phase = track.get("phase")
        if region_id in REGIONS:
            assert phase in PHASES, f"invalid phase: {stable_id}"
            coverage[region_id].add(phase)

    assert ids.__contains__("music_blackout_pulse"), "Blackout score is missing"
    for region_id, phases in coverage.items():
        assert phases == PHASES, f"incomplete score for {region_id}: {sorted(phases)}"
    print("Validated 25 decoded, reviewed Roblox music assets across 8 worlds.")


if __name__ == "__main__":
    main()
