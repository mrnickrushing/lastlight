# Inspected Creator Store props

These are downloaded source snapshots of the public, free Creator Store models
used by Emberhollow. Runtime placement still goes through
`MeshTemplateLoader:place`; the files exist for provenance, inspection, and
repeatable measurement.

All four selected models had `Completed` 420 x 420 Roblox thumbnails inspected
on 2026-08-01. Their downloaded payloads were deserialized with
`scripts/inspect_creator_store_model.luau` and contained zero scripts.

| Stable ID | Creator Store model | Native longest side | Triangles | Parts |
| --- | --- | ---: | ---: | ---: |
| `mesh_creator_kerosene_lantern_a` | [Lantern by lospakos](https://create.roblox.com/store/asset/11865884168/Lantern) | 1.9893 | 3,600 | 3 MeshParts |
| `mesh_creator_first_lantern_a` | [Dynamically Lit Lantern by EndorsedModel](https://create.roblox.com/store/asset/285454336/Dynamically-Lit-Lantern) | 2.2 | 3,302 | 13 BaseParts |
| `mesh_creator_street_lantern_a` | [Low poly Street Lantern by I4supraa](https://create.roblox.com/store/asset/8990192177/Low-poly-Street-Lantern) | 22.3427 | 700 | 8 MeshParts |
| `mesh_creator_campfire_a` | [Campfire by hipodrava](https://create.roblox.com/store/asset/8752362543/Campfire) | 4.994 | 2,982 | 26 BaseParts |

The 80,204-triangle realistic fire, script-bearing copies, glowing-box
lanterns, and ornate photoreal fireplaces were rejected before placement.
