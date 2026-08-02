# Milestone 3: First-world full asset pass

## Outcome

Emberhollow's readable world props now use inspected Roblox assets instead of visible placeholder geometry. Purpose-built parts remain for terrain, floors, walls, roofs, invisible interaction anchors, and collision-safe fallbacks; recognizable objects use the asset registry and `MeshTemplateLoader:place`.

## Visible asset coverage

- The arrival route, town main street, district roads, and cabin approaches receive a continuous worn-cobblestone asset layer over a raised, high-contrast road foundation.
- The Greenward uses cultivated field rows, wheat clusters where appropriate, and twelve rustic fence sections instead of rock-like planting slabs.
- Route signs, warning signs, the Archive, and Town Board use sourced timber silhouettes while Last Light's illustrated notice atlas and readable text remain authoritative.
- Tool yards, crafting bays, supply areas, barricades, commons furniture, watchtowers, the Dawn Gate, Heartwood, mastery clearings, cabin hearths, and carried lanterns use reviewed assets.
- Repeated organic assets receive authored rotation and nonuniform profile variation. Road stones stretch only along travel direction to preserve a readable width.

## Acceptance gates

- Creator Store models are free, script-stripped, measured, thumbnail-reviewed, and recorded in `assets/meshes/candidates/creator-store-full-pass/selection.json`.
- All selected models remain inside their manifest triangle and material budgets.
- Studio integration requires the road asset layer, field asset, fence perimeter, sourced work areas, physical notice-board frames, and three distinct Town Board illustrations.
- `mesh_wayfarer_cabin_a` remains retired and is rejected by Studio integration if placed.
- Visual acceptance is performed from the generated `LastLightTest` place, not inferred from source validation alone.
