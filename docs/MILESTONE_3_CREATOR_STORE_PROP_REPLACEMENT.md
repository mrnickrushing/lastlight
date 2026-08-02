# Milestone 3 Creator Store Prop Replacement

## Outcome

The Emberhollow arrival route no longer presents procedural glowing shapes as its finished lanterns or cabin fires. Reviewed, script-free Roblox models now replace those fallback visuals through `MeshTemplateLoader:place`.

## Reviewed assets

| Stable ID | Roblox asset | Use | Measured budget |
| --- | ---: | --- | --- |
| `mesh_creator_kerosene_lantern_a` | `11865884168` | Mara's hand lantern | 3 MeshParts, 3,600 triangles max |
| `mesh_creator_first_lantern_a` | `285454336` | Distinct First Lantern vessel | 13 BaseParts, 3,400 triangles max |
| `mesh_creator_street_lantern_a` | `8990192177` | Six arrival-route lantern posts | 8 MeshParts, 800 triangles max |
| `mesh_creator_campfire_a` | `8752362543` | Two cabin hearth fires | 24 MeshParts, 3,200 triangles max |

The downloaded `.rbxm` sources, creator attribution, measurements, rejection notes, and the rendered thumbnails inspected before selection are committed under `assets/meshes/candidates/creator-store` and `assets/meshes/previews`.

## Runtime rules

- Third-party free models load through `AssetService:LoadAssetAsync`; the generated places enable `AllowInsertFreeAssets`.
- The loader removes scripts and unsafe interactive descendants before caching a template.
- Reviewed source materials and authored light/fire effects are preserved.
- Procedural emergency fallbacks remain for load failure only. A successful placement hides every fallback part and disables its light, fire, and particle effects.
- `mesh_wayfarer_cabin_a` remains retired and is never placed.

## Town Board correction

The three Town Board papers have unique `TownNotice_<panelId>` instance names and retain their `NoticePanelId` and `NoticeAssetId` metadata. Studio integration requires exactly three Town Board notices backed by three distinct illustrated atlas panels.

## Acceptance

- `npm test` passes all 290 Luau tests plus formatting, lint, type checking, asset validation, both place builds, and generated-place verification.
- Studio must report all four sourced stable IDs as `mesh_asset_ready`, with six street lanterns, two cabin campfires, one Mara lantern, one First Lantern, and no visible fallback geometry.
- The Town Board assertion must pass with `3 notices / 3 panels`.
