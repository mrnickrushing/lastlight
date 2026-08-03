#!/usr/bin/env bash
# Halve the town building textures to 1024 and re-measure.
#
# Meshy returns four 2048-square PBR maps per asset. Eleven buildings of that is
# real memory on the baseline phone the performance budget is written against,
# and a town building is not something a player inspects at arm's length.
#
# The re-measure afterwards is not optional: validate_mesh_assets.py compares
# the manifest's recorded texture list and byte count against what is on disk,
# so downscaling without refreshing the report fails the build.

set -uo pipefail

ROOT="/home/Nitehawk/Desktop/lastlight"
GENERATED="$ROOT/assets/meshes/generated"
PREVIEWS="$ROOT/assets/meshes/previews"
REPORTS="$ROOT/meshy_output/reports"

TARGETS=(
"mesh_celebration_stage_a|22"
"mesh_sawmill_a|24"
"mesh_union_forge_a|20"
"mesh_engineer_yard_a|20"
"mesh_common_kitchen_a|20"
"mesh_hearthmarket_stalls_a|24"
"mesh_trade_post_a|16"
"mesh_guardhouse_a|16"
"mesh_watchtower_a|26"
"mesh_trapworks_a|16"
"mesh_waterworks_a|18"
)

for entry in "${TARGETS[@]}"; do
    id="${entry%%|*}"
    target="${entry#*|}"

    blender --background --python "$ROOT/scripts/downscale_mesh_textures.py" -- \
        --input "$GENERATED/$id.glb" --max-size 1024 \
        > "$REPORTS/$id.downscale.log" 2>&1

    blender --background --python "$ROOT/scripts/prepare_mesh_candidate.py" -- \
        --input "$GENERATED/$id.glb" \
        --output "$GENERATED/$id.glb" \
        --preview "$PREVIEWS/$id.png" \
        --report "$REPORTS/$id.json" \
        --asset-id "$id" \
        --target "$target" \
        --max-triangles 8000 \
        > "$REPORTS/$id.remeasure.log" 2>&1

    echo "done $id"
done
