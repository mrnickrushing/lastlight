# Milestone 3: Authored Mesh Environment

## Outcome

Replace the most visible procedural foliage silhouettes with an original,
measured mesh kit while preserving Last Light's streaming, navigation, and
mobile performance. The existing terrain remains the structural foundation.
Authored meshes add the recognizable trunks, roots, canopies, stones, and
landmarks that make Bramblewake feel inhabited instead of assembled from
primitive parts.

This pass is deliberately not a replica of another Roblox experience. It uses
Last Light's own world bible, palette, safe-light language, and foxfire memory
language.

## Style formula

The following formula is the source prompt for generated visual assets. Keep it
byte-for-byte identical whenever an external generator is used:

> Polished stylized low-poly dark-fantasy woodland with hand-shaped faceted forms, softened bevels, asymmetrical silhouettes, and visible craft details. Environment uses rain-dark umber timber, deep moss greens, slate blue-gray stone, muted meadow gold, and charcoal indigo shadow; safe objectives use restrained lantern amber and memory cues use foxfire cyan. Materials stay matte, rough, and tactile under warm practical light and cool atmospheric moonlight. Maintain strong gameplay-scale silhouettes, sparse surface noise, readable negative space, and consistent three-quarter 3D proportions.

## Asset plan

The machine-readable source of truth is
[`assets/meshes/manifest.json`](../assets/meshes/manifest.json). Each asset has:

- an original source and provenance note;
- a gameplay role and placement band;
- a target longest dimension in studs;
- an authored bounding box measured by Blender;
- triangle and material budgets;
- a Roblox model asset ID only after Open Cloud finishes processing it.

Scale is always computed from measured data:

```text
uniform scale = target longest dimension / authored longest dimension
```

No guessed native sizes are allowed.

Regenerate and validate the complete committed kit with:

```bash
./scripts/regenerate_mesh_assets.sh
```

The command first rebuilds the deterministic Blender kit, then reprocesses the
committed original PBR root-arch generation, and finally checks GLB headers,
bounds, triangle budgets, material budgets, texture presence, and Roblox ID
mappings. It does not read an API key or upload anything.

Upload only missing assets with the local secret already described in the
publishing runbook:

```fish
fish -c 'source ~/.secrets/roblox.fish; python3 scripts/upload_mesh_assets.py --all'
```

## First-pass kit

| Stable ID | Role | Target | Placement |
| --- | --- | ---: | --- |
| `mesh_conifer_hero_a` | Tall evergreen silhouette | 27 studs | Core and near forest |
| `mesh_conifer_hero_b` | Crooked evergreen variant | 24 studs | Core and near forest |
| `mesh_broadleaf_hero_a` | Dense old-growth canopy | 23 studs | Core forest and town edge |
| `mesh_boulder_cluster_a` | Traversable landmark stone | 10 studs | Core forest and trails |
| `mesh_deadfall_a` | Fallen-log path framing | 17 studs | Core and near forest |
| `mesh_root_arch_a` | Hero landmark and route gate | 25 studs | Curated core location only |
| `mesh_fern_cluster_a` | Ground silhouette breakup | 5 studs | Core forest only |
| `mesh_hollow_lantern_shrine_a` | Walk-through arrival sanctuary | 28 studs | Curated arrival landmark only |
| `mesh_wayfarer_cabin_a` | Open-front gabled camp shelter | 20 studs | Two arrival shelters |
| `mesh_lantern_post_a` | Crooked caged safe-route light | 9 studs | Arrival road rhythm |

The hollow lantern shrine starts from the committed original concept in
`assets/meshes/concepts`, then the deterministic Blender pipeline authors the
shipping geometry. Its 28-stud measured silhouette, open centre, stone
threshold, timber braces, moss, and three restrained amber cues make the arrival
clearing recognizable without adding collision or blocking world readiness. It
loads through the same sanitized template cache as the rest of the kit and falls
back to the procedural root-arch language if Roblox asset loading fails.

Far forest bands continue using the inexpensive procedural silhouettes. This
keeps the horizon full without spending unique mesh, texture, collision, or
shadow budget where the player cannot inspect the asset.

## Runtime rules

1. Load each Roblox model asset at most once per server and cache a sanitized
   template.
2. Clone the cached template for placements; never fetch once per tree.
3. Remove scripts, prompts, constraints, and unexpected descendants from loaded
   models before they become templates.
4. Decorative geometry is anchored and has touch/query/collision disabled.
5. Failure to load an authored asset never blocks joining. The procedural
   builder remains the fallback.
6. Hero meshes appear in the core/near bands only. Distant bands retain the
   current low-cost geometry and no-shadow behavior.
7. Asset load failures are logged with the stable asset ID, never with secrets.

## Acceptance gates

- Blender exports and the manifest agree on every authored bounding box.
- No asset exceeds its triangle or material-slot budget.
- Generated places contain the registry and loader, but no API key or local
  filesystem path.
- The arrival area remains playable before optional mesh assets finish loading.
- A failed asset request produces the established procedural equivalent.
- Studio review covers phone, tablet, desktop, low graphics, and maximum
  graphics before the mesh kit replaces additional forest bands.
- Studio Output reports client build `0.32.0`, world version
  `bramblewake-blackout-v13`, and an `AuthoredMeshFallbackCount` of zero before
  the shrine is accepted as live visual evidence.
