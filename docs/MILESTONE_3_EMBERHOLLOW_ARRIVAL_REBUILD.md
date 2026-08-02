# Milestone 3: Emberhollow Arrival Rebuild

## Why this pass exists

Studio screenshots from build `0.41.0` failed the visual acceptance gate. The
arrival cabins were hidden beneath oversized solid roof wedges, progression
scaffolds crowded the space behind them, the Greenward starting state read as
rocks on a flat slab, the main road disappeared into the terrain, and the
First Lantern, cabin hearths, and Mara's lantern used glowing balls instead of
recognizable constructed objects.

Build `0.42.0` treats those screenshots as regression evidence rather than an
approved visual baseline.

## Spatial correction

- The main road is a continuous raised cobblestone foundation with a broad mud
  surface, worn center, and paired travel ruts from arrival through town.
- Five physical side roads connect the archive, workbench, inn, Greenward, and
  commons districts to the main street.
- The archive, workbench, inn, Greenward, commons, and town board are moved out
  of the two arrival cabin lots and their camera sightline.
- Foliage keep-outs cover the new district roads and relocated lots.

## Object correction

- Cabin roofs use thin pitched slate planes, eave beams, and a ridge beam. The
  old six-stud-thick wedge volumes no longer exist.
- Cabin hearths use layered wedge flames over an ash bed and physical firewood.
- The First Lantern has four glass panels, corner cage posts, perimeter rails,
  a pitched slate rain hood, a metal crown, and a restrained wedge flame.
- Mara carries a glass-and-metal caged lantern with its own small flame.
- Route-lantern fallback geometry contains a post, arm, cage, glass, caps, and
  flame; its authored mesh remains the preferred visible asset.
- The unresolved Greenward state is now planted soil rows with furrows, leafy
  seedlings, stakes, and fencing. No `SeedGroundMarker` rocks remain.
- Progression buildings and construction sites use thin pitched roof/tarp
  planes instead of large flat overhead slabs.

## Mesh material repair

Roblox imports MeshPart names from Blender mesh datablocks. The generator used
authored object names but left datablocks named `Cone.###`, `Cube.###`, and
similar defaults. `MeshMaterialPlan` therefore could not recognize any material
group in Studio and logged `styledParts=0`.

The generator now stamps both object and datablock names with the stable asset
ID plus material group. The validator rejects future non-PBR GLBs that lose
those names and also verifies that manifest placement bands match the runtime
registry. The separately UV-authored root arch is preserved rather than
overwritten by the general procedural generator.

Eleven original Model assets were content-updated through Open Cloud after
local validation. All twelve manifest asset thumbnails reached `Completed` and
their rendered silhouettes were viewed. `mesh_wayfarer_cabin_a` is explicitly
`retired_visual_failure` in both manifest and registry and is never placed.

## Acceptance gate

Repository validation does not approve this visual pass. A fresh Studio run of
`build/LastLightTest.rbxlx` must show:

1. both cabin walls and entrances visible beneath thin pitched roofs;
2. no construction or progression clutter directly behind the cabins;
3. a continuous road surface visible without the HUD;
4. recognizable First Lantern, route lanterns, Mara lantern, and cabin fires;
5. a fenced, planted Greenward with soil beds and no rock-marker fallback;
6. `styledParts > 0` and `unstyledParts = 0` for every non-PBR authored mesh in
   Studio Output;
7. no new runtime errors, followed by phone camera and navigation checks.
