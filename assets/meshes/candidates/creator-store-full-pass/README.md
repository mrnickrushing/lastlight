# First-world Creator Store asset pass

These source models replace visible procedural props in Emberhollow. Every selected model was:

1. found through the live Roblox Creator Store search API;
2. rendered through Roblox's completed `420x420` thumbnail endpoint and visually reviewed;
3. downloaded as its actual `.rbxm` payload;
4. inspected by `scripts/inspect_creator_store_model.luau` for scripts, part count, bounds, materials, and triangle cost; and
5. registered through `scripts/register_creator_store_selection.py` before placement through `MeshTemplateLoader:place`.

`selection.json` is the provenance and measurement ledger. The reviewed thumbnails are in
`assets/meshes/previews/full-pass/`, with the final contact sheet at
`assets/meshes/previews/first-world-full-asset-selection.png`.

Runtime loading strips scripts, prompts, GUI, cameras, values, humanoids, joints, and constraints from all external models. Source materials are preserved. Procedural geometry remains only as an invisible collision-safe fallback when a reviewed asset fails to load.

The selected kit covers roads, field rows, crops, fences, signs, boards, workbenches, tools,
crates, barrels, barricades, stalls, tables, stumps, watchtowers, and the Dawn Gate. The retired
`mesh_wayfarer_cabin_a` is not part of this pass and must never be placed.
