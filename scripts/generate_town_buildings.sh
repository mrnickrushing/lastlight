#!/usr/bin/env bash
# Generate the eleven Milestone 4 town buildings through Meshy.
#
# Every prompt is built from the docs/VISUAL_QUALITY_STANDARD.md style formula
# so the new buildings sit beside the existing set rather than beside each
# other. Shared language goes in STYLE; only the building itself varies.
#
# Runs preview -> refine (PBR) -> download per building, sequentially, because
# Meshy bills per task and a failed batch halfway through should leave the
# finished ones intact. Progress lands in meshy_output/ per the skill's layout.

set -uo pipefail

SKILL="/home/Nitehawk/Desktop/lastlight/.agents/skills/meshy-3d-generation"
CLI="$SKILL/scripts/meshy_task.py"
OUT="/home/Nitehawk/Desktop/lastlight/meshy_output"
LOG="$OUT/generation.log"

mkdir -p "$OUT"

# Isolation is the hard part, not the style.
#
# The first pass asked for a building and got a diorama: the sawmill arrived
# with a pine tree, a stone path and grass tufts, the celebration stage with
# scattered boulders and dead trees. Two phrasings caused it. "On a small stone
# base" reads as an invitation to model the ground, and a trailing "no terrain,
# no scenery" is too weak and too late to overcome it.
#
# What works is leading with the isolation instead of appending it: name the
# thing as an isolated model on a plain background before describing it, ask
# for a clean flat underside rather than a base, and list the exclusions
# explicitly and in capitals. These buildings sit on authored town terrain
# beside the plaza, so anything that brings its own ground fights the roads and
# the foliage system.
# Meshy caps a text-to-3d prompt at 600 characters and answers 400 for anything
# longer, so the style block has to earn its room. The exclusions are kept in
# full and the descriptive language is what got compressed: losing an adjective
# costs a little polish, while losing a NO brings back the pine tree.
STYLE="Stylized low-poly dark-fantasy architecture, faceted forms, soft bevels, \
visible craft detail, rain-dark umber timber, slate blue-grey stone, meadow gold \
trim, matte rough materials, strong readable silhouette. Clean flat underside. \
NO ground, NO terrain, NO rocks, NO trees, NO plants, NO grass, NO path, NO \
fence, NO scenery, NO diorama base, NO environment, NO characters."

# id|prompt subject
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

echo "=== Town building generation started $(date -Is) ===" | tee -a "$LOG"

for entry in "${BUILDINGS[@]}"; do
    id="${entry%%|*}"
    subject="${entry#*|}"
    prompt="Isolated 3D model of $subject, floating on plain white background, nothing else in frame. $STYLE"

    echo "" | tee -a "$LOG"
    echo "--- $id ---" | tee -a "$LOG"

    dir="$OUT/$id"
    mkdir -p "$dir"

    # Already finished. Skipping is what makes this script safe to rerun after
    # a partial batch, which is the only reason the earlier failures cost 20
    # credits instead of 300.
    if [ -f "$dir/$id.glb" ]; then
        echo "OK $id (already generated)" | tee -a "$LOG"
        continue
    fi

    # Meshy rejects a prompt over 600 characters with a bare 400. Checking here
    # turns that into a message naming the building, before any credit is spent.
    length=${#prompt}
    if [ "$length" -gt 600 ]; then
        echo "FAILED $id: prompt is $length characters, over the 600 cap" | tee -a "$LOG"
        continue
    fi

    # Reuse a preview that already succeeded. Previews cost 20 credits each, so
    # a rerun after a partial batch must not pay for them twice.
    preview=$(find "$dir" -maxdepth 1 -name 'task_*.json' -print 2>/dev/null \
        | head -1 \
        | sed 's/.*task_//; s/\.json$//')

    if [ -n "$preview" ]; then
        echo "reusing preview task: $preview" | tee -a "$LOG"
    else
        preview=$(python3 "$CLI" create --endpoint /openapi/v2/text-to-3d --payload "{
            \"mode\": \"preview\",
            \"prompt\": $(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$prompt"),
            \"ai_model\": \"latest\",
            \"topology\": \"triangle\",
            \"target_polycount\": 12000
        }" 2>>"$LOG" | tail -1)

        if [ -z "$preview" ]; then
            echo "FAILED to create preview for $id" | tee -a "$LOG"
            continue
        fi
        echo "preview task: $preview" | tee -a "$LOG"

        python3 "$CLI" poll --endpoint /openapi/v2/text-to-3d --task-id "$preview" \
            --project-dir "$dir" --timeout 900 >>"$LOG" 2>&1
    fi

    refine=$(python3 "$CLI" create --endpoint /openapi/v2/text-to-3d --payload "{
        \"mode\": \"refine\",
        \"preview_task_id\": \"$preview\",
        \"enable_pbr\": true,
        \"ai_model\": \"latest\"
    }" 2>>"$LOG" | tail -1)

    if [ -z "$refine" ]; then
        echo "FAILED to create refine for $id" | tee -a "$LOG"
        continue
    fi
    echo "refine task: $refine" | tee -a "$LOG"

    python3 "$CLI" poll --endpoint /openapi/v2/text-to-3d --task-id "$refine" \
        --project-dir "$dir" --timeout 900 >>"$LOG" 2>&1
    python3 "$CLI" download --task-json "$dir/task_$refine.json" --format glb \
        --output "$dir/$id.glb" >>"$LOG" 2>&1
    python3 "$CLI" thumbnail --project-dir "$dir" --task-json "$dir/task_$refine.json" \
        >>"$LOG" 2>&1

    if [ -f "$dir/$id.glb" ]; then
        echo "OK $id -> $dir/$id.glb" | tee -a "$LOG"
    else
        echo "FAILED to download $id" | tee -a "$LOG"
    fi
done

echo "" | tee -a "$LOG"
echo "=== Finished $(date -Is) ===" | tee -a "$LOG"
ls -la "$OUT"/*/*.glb 2>/dev/null | tee -a "$LOG"
