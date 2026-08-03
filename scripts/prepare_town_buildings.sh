#!/usr/bin/env bash
# Normalize the eleven generated town buildings through the Blender pipeline.
#
# Meshy returns a GLB at whatever scale and density it likes. This puts each one
# through prepare_mesh_candidate.py to land it on its intended stud size, inside
# the triangle budget, with a preview render and a measurement report the
# manifest entry is written from. No Meshy credits involved.
#
# Target sizes are in studs and chosen against the town they sit in: the plaza
# is 72 across and the arrival cabins are about 26, so a building between 16 and
# 26 reads as a real structure without swallowing the square.

set -uo pipefail

ROOT="/home/Nitehawk/Desktop/lastlight"
OUT="$ROOT/meshy_output"
GENERATED="$ROOT/assets/meshes/generated"
PREVIEWS="$ROOT/assets/meshes/previews"
REPORTS="$OUT/reports"

mkdir -p "$GENERATED" "$PREVIEWS" "$REPORTS"

# id|target longest dimension in studs
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

failed=0
for entry in "${TARGETS[@]}"; do
    id="${entry%%|*}"
    target="${entry#*|}"
    input="$OUT/$id/$id.glb"

    if [ ! -f "$input" ]; then
        echo "MISSING $id"
        failed=$((failed + 1))
        continue
    fi

    blender --background --python "$ROOT/scripts/prepare_mesh_candidate.py" -- \
        --input "$input" \
        --output "$GENERATED/$id.glb" \
        --preview "$PREVIEWS/$id.png" \
        --report "$REPORTS/$id.json" \
        --asset-id "$id" \
        --target "$target" \
        --max-triangles 8000 \
        > "$REPORTS/$id.log" 2>&1

    if [ -f "$GENERATED/$id.glb" ]; then
        echo "OK $id (target ${target} studs)"
    else
        echo "FAILED $id — see $REPORTS/$id.log"
        failed=$((failed + 1))
    fi
done

echo ""
echo "prepared: $(ls "$GENERATED"/mesh_*_a.glb 2>/dev/null | wc -l) glb in assets/meshes/generated"
echo "failures: $failed"
