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

STYLE="Polished stylized low-poly dark-fantasy woodland building, hand-shaped \
faceted forms, softened bevels, asymmetrical silhouette, visible craft details. \
Rain-dark umber timber, deep moss green accents, slate blue-gray stone \
foundation, muted meadow gold trim, charcoal-indigo shadow. Matte rough tactile \
materials, no gloss. Strong readable gameplay-scale silhouette, sparse surface \
noise, readable negative space, consistent three-quarter proportions. Single \
freestanding structure on a small stone base, no ground plane, no terrain, no \
surrounding scenery, no characters."

# id|prompt subject
BUILDINGS=(
"mesh_celebration_stage_a|An open timber celebration stage with a low plank platform, four carved corner posts, a draped banner canopy, and hanging lantern hooks"
"mesh_sawmill_a|A working sawmill with a timber frame, a large vertical waterwheel on one side, stacked cut logs, and an open cutting floor under a shingled roof"
"mesh_union_forge_a|A blacksmith forge building with a stone chimney stack, an open-fronted work bay, a visible anvil and quench barrel, and iron tool racks on the wall"
"mesh_engineer_yard_a|An engineer workshop yard with a half-open timber shed, a raised testing platform, coiled rope and pulley rigging, and mechanical trap parts on trestles"
"mesh_common_kitchen_a|A communal outdoor kitchen with a long covered cooking hearth, a stone oven dome, hanging herb bundles, and a serving counter along the open side"
"mesh_hearthmarket_stalls_a|A cluster of three joined market stalls under patched awnings, with open display counters, crates of goods, and a hanging sign bracket"
"mesh_trade_post_a|A small trade post cabin with a wide shuttered exchange window, a covered porch, a strongbox bench, and a ledger desk visible through the opening"
"mesh_guardhouse_a|A stout guardhouse with thick timber walls, a narrow reinforced door, weapon racks under the eaves, and a small shuttered watch window"
"mesh_watchtower_a|A tall narrow watchtower with a stone base, a timber ladder shaft, an enclosed railed lookout platform, and a signal brazier on top"
"mesh_trapworks_a|A trapworks shed with an open workbench front, racked spring traps and stakes, a spool of wire, and a low sandbag testing berm along one side"
"mesh_waterworks_a|A waterworks structure with a raised stone cistern, a hand pump wheel, wooden trough channels running from its base, and bucket hooks on the frame"
)

echo "=== Town building generation started $(date -Is) ===" | tee -a "$LOG"

for entry in "${BUILDINGS[@]}"; do
    id="${entry%%|*}"
    subject="${entry#*|}"
    prompt="$subject. $STYLE"

    echo "" | tee -a "$LOG"
    echo "--- $id ---" | tee -a "$LOG"

    dir="$OUT/$id"
    mkdir -p "$dir"

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
