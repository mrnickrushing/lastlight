#!/usr/bin/env bash
# Generate the remaining town buildings, all at once.
#
# The sequential version took roughly four minutes per building because each
# one waited on the previous: preview, poll, refine, poll, next. Meshy runs
# tasks concurrently, so the wall clock was self-inflicted -- eleven buildings
# in series is forty minutes, eleven in parallel is the time of the slowest one.
#
# Each building runs in its own subshell writing its own log. Failures stay
# isolated: one building erroring out does not take the batch with it, and the
# skip-if-done logic means a rerun only picks up what is missing.

set -uo pipefail

SKILL="/home/Nitehawk/Desktop/lastlight/.agents/skills/meshy-3d-generation"
CLI="$SKILL/scripts/meshy_task.py"
OUT="/home/Nitehawk/Desktop/lastlight/meshy_output"

mkdir -p "$OUT"

STYLE="Stylized low-poly dark-fantasy architecture, faceted forms, soft bevels, \
visible craft detail, rain-dark umber timber, slate blue-grey stone, meadow gold \
trim, matte rough materials, strong readable silhouette. Clean flat underside. \
NO ground, NO terrain, NO rocks, NO trees, NO plants, NO grass, NO path, NO \
fence, NO scenery, NO diorama base, NO environment, NO characters."

BUILDINGS=(
"mesh_celebration_stage_a|an open timber celebration stage, low plank platform, four carved corner posts, draped banner canopy, hanging lantern hooks"
"mesh_sawmill_a|a sawmill building, timber frame, large vertical waterwheel on one side, stacked cut logs, open cutting floor, shingled roof"
"mesh_union_forge_a|a blacksmith forge building, stone chimney stack, open-fronted work bay, anvil and quench barrel, iron tool racks"
"mesh_engineer_yard_a|an engineer workshop building, half-open timber shed, raised testing deck, coiled rope and pulley rigging, trap parts on trestles"
"mesh_common_kitchen_a|a communal kitchen building, long covered cooking hearth, stone oven dome, hanging herb bundles, open serving counter"
"mesh_hearthmarket_stalls_a|three joined market stalls, patched awnings, open display counters, crates of goods, hanging sign bracket"
"mesh_trade_post_a|a small trade post cabin, wide shuttered exchange window, covered porch, strongbox bench, ledger desk inside"
"mesh_guardhouse_a|a stout guardhouse, thick timber walls, narrow reinforced door, weapon racks under the eaves, shuttered watch window"
"mesh_watchtower_a|a tall narrow watchtower, stone footing, timber ladder shaft, enclosed railed lookout platform, signal brazier on top"
"mesh_trapworks_a|a trapworks shed, open workbench front, racked spring traps and stakes, spool of wire, low sandbag berm along one side"
"mesh_waterworks_a|a waterworks building, raised stone cistern, hand pump wheel, wooden trough channels, bucket hooks on the frame"
)

generate_one() {
    local id="$1"
    local subject="$2"
    local dir="$OUT/$id"
    local log="$dir/build.log"
    mkdir -p "$dir"

    if [ -f "$dir/$id.glb" ]; then
        echo "SKIP $id (already generated)"
        return 0
    fi

    local prompt="Isolated 3D model of $subject, floating on plain white background, nothing else in frame. $STYLE"
    if [ "${#prompt}" -gt 600 ]; then
        echo "FAIL $id: prompt ${#prompt} chars, over the 600 cap"
        return 1
    fi

    # A stale task file from an aborted run would be reused as a valid preview.
    rm -f "$dir"/task_*.json

    local preview
    preview=$(python3 "$CLI" create --endpoint /openapi/v2/text-to-3d --payload "{
        \"mode\": \"preview\",
        \"prompt\": $(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$prompt"),
        \"ai_model\": \"latest\",
        \"topology\": \"triangle\",
        \"target_polycount\": 12000
    }" 2>>"$log" | tail -1)
    [ -z "$preview" ] && { echo "FAIL $id: preview not created"; return 1; }

    python3 "$CLI" poll --endpoint /openapi/v2/text-to-3d --task-id "$preview" \
        --project-dir "$dir" --timeout 900 >>"$log" 2>&1

    local refine
    refine=$(python3 "$CLI" create --endpoint /openapi/v2/text-to-3d --payload "{
        \"mode\": \"refine\",
        \"preview_task_id\": \"$preview\",
        \"enable_pbr\": true,
        \"ai_model\": \"latest\"
    }" 2>>"$log" | tail -1)
    [ -z "$refine" ] && { echo "FAIL $id: refine not created"; return 1; }

    python3 "$CLI" poll --endpoint /openapi/v2/text-to-3d --task-id "$refine" \
        --project-dir "$dir" --timeout 900 >>"$log" 2>&1
    python3 "$CLI" download --task-json "$dir/task_$refine.json" --format glb \
        --output "$dir/$id.glb" >>"$log" 2>&1
    python3 "$CLI" thumbnail --project-dir "$dir" \
        --task-json "$dir/task_$refine.json" >>"$log" 2>&1

    if [ -f "$dir/$id.glb" ]; then
        echo "OK $id"
    else
        echo "FAIL $id: download produced no glb"
        return 1
    fi
}

for entry in "${BUILDINGS[@]}"; do
    generate_one "${entry%%|*}" "${entry#*|}" &
done

wait
echo "=== all done $(date -Is) ==="
ls "$OUT"/*/*.glb 2>/dev/null | wc -l
