# Last Light visual quality standard

This document is the source of truth for environment, character, prop, mesh,
lighting, and world-presentation work. Read it before changing visible content.
It translates “premium” into implementation and review gates that another
developer or AI agent can verify.

## Target

The first playable world is the vertical slice: Emberhollow, the complete
Bramblewake expedition, its residents, events, enemies, rewards, and return
experience must look like one authored game. Later worlds inherit this standard;
they do not lower it.

Use successful stylized survival games only as a quality reference. Never copy a
recognizable building, character, map layout, prop, logo, texture, sound, or
asset. Rebuild the underlying quality principles with original Last Light forms.

## Style formula

Polished stylized low-poly dark-fantasy woodland with hand-shaped faceted forms,
softened bevels, asymmetrical silhouettes, and visible craft details. Use
rain-dark umber timber, deep moss greens, slate blue-gray stone, muted meadow
gold, and charcoal-indigo shadow. Safe objectives use restrained lantern amber;
memory cues use foxfire cyan. Materials stay matte, rough, and tactile under warm
practical light and cool atmospheric moonlight. Maintain strong gameplay-scale
silhouettes, sparse surface noise, readable negative space, and consistent
three-quarter 3D proportions.

Glow is semantic, not decoration. Neon is limited to flame, foxfire, magic,
hazard telegraphs, and brief reward feedback. It must never substitute for
physical geometry.

## Universal construction rules

1. A gameplay object must be recognizable before its billboard or prompt is
   read. Floating text and icons are secondary confirmation.
2. Never ship a visible interaction as a plain block, pedestal, orb, or ring.
   Preserve invisible stable anchors for code, then surround them with original
   physical geometry.
3. Build in layers: primary silhouette, structural frame, functional object,
   small lived-in details, then restrained light/VFX.
4. Use asymmetry and believable support. Roofs need rafters or beams, platforms
   need posts or braces, tools need handles and heads, and stored goods need a
   shelf, crate, rack, table, or carrier.
5. Every hero location needs a distinct silhouette, purpose, and prop story.
   Recoloring the same assembly does not make new content.
6. Place clutter in purposeful clusters, not uniform noise. Keep navigation,
   combat sightlines, prompts, and mobile camera space clear.
7. Decorative parts are anchored, non-touching, and non-querying when they do
   not own gameplay. Collision comes from simple stable shells, not detailed
   mesh triangles.
8. Do not block joining on optional visual assets. Procedural construction is a
   complete fallback, not an empty placeholder.
9. Review placement before surface detail: footprint, orientation, entrance,
   access path, clearance, sightline, then decoration. Reversing this order is
   not an acceptable visual workflow.

An emergency fallback is not finished art. When a vetted authored asset loads,
every visible fallback part and effect for that object must be hidden. A visible
production prop may not be approved merely because its block, orb, wedge, or
debug assembly is recognizable enough to keep gameplay running. Structural
shells, collision, terrain, and roads may remain purpose-built Roblox geometry;
inspectable props and practical-light vessels must use reviewed art assets.

## Environment standard

### Site planning and circulation

World layout is authored from player movement outward. Do not begin by placing
finished props and trying to fit paths around them afterward.

1. Establish the primary route, destination sightline, public square, side
   paths, and building lots before adding structures or decoration.
2. Every building entrance faces a road, square, porch, or deliberate access
   path. The route must physically reach the doorway with enough clearance for
   a character and a normal third-person camera.
3. Preserve believable setbacks and negative space. Separate neighboring
   footprints, keep doors and stairs unobstructed, and never place public props
   in a building's entrance apron.
4. Organize related activity into districts. Homes belong on readable lots;
   workshops, gardens, communal areas, mastery spaces, and service boards each
   need their own usable footprint instead of sharing one crowded center.
5. Make the critical road a distinct raised or layered surface so clearing
   patches, terrain, or square materials cannot visually erase it. Keep its
   center and junctions open to movement.
6. Reserve four kinds of clearance before detail: walking width, interaction
   reach, camera orbit, and combat or event sightline. Decorative edging is
   non-colliding and leaves explicit gates at every connected path.
7. Validate the spatial plan in code where possible: entrance direction,
   building separation, road elevation, clear route corridors, and district
   bounds. A detailed model in an implausible or unplayable location still
   fails this standard.

For Emberhollow, the First Lantern is the civic center. The main dirt street
passes through its square; the two arrival cabins occupy opposing lots and face
inward; their paths meet the square; workshops, Greenward, the commons, archive,
inn, and mastery clearings remain outside that central circulation envelope.

### Buildings and rooms

- A room has a floor, enclosing walls, a roof or ceiling, a readable entrance,
  structural framing, and an interior purpose.
- Cabins need roof volume, corner posts, rafters, openings, a hearth or practical
  light source, furniture, storage, textiles, and exterior activity props.
- A facade with side walls but open sky is not a finished room.
- Construction sites show materials, tools, supports, and the shape of work in
  progress. Completed buildings retain structural and occupational details.
- For Emberhollow cabins, the supplied Place6 cabin is the approved construction
  template: preserve its segmented-wall, gabled-roof, rafter, framed-window,
  doorway, stair, foundation, and chimney layering. Adapt dimensions, palette,
  props, and identifying details to Last Light. Do not replace that assembly
  with a low-detail mesh unless Studio evidence proves equal or better quality.

### Routes and terrain

- The critical route is visually continuous through worn ground, edge language,
  repeated landmarks, and direction signs. Players should not need a HUD arrow
  to infer the intended direction.
- Tutorial interactions branch off the critical route onto short, readable
  activity spurs. Never place a gathering node, tool display, worksite, sign,
  or decorative landmark directly across the path the player is following.
- Establish a visual hierarchy at gameplay distance: route surface first,
  current objective landmark second, side activities third, decorative skyline
  last. A decorative mesh that outshouts the objective must move, shrink, or
  lose contrast.
- Use at least three mutually reinforcing route cues for the arrival sequence:
  contrasting ground, repeated physical landmarks, and directional edge or
  inlay geometry. Floating labels are close-range confirmation, not navigation.
- Terrain needs foreground, playable midground, and horizon depth. Avoid flat
  rectangles, abrupt terrain seams, inverted water volumes, and repeated tree
  walls.
- Water surfaces must read from the playable side and be checked above, below,
  and at shoreline transitions.

### Landmarks and events

- Each POI and event must have its own physical scene model and visual kind.
- Event anchors remain invisible. Event steps belong to the scene they modify.
- A landmark should survive a screenshot with all labels disabled: its role must
  still be understandable from shape and props.

## Character standard

Debug mannequins are prohibited in player-facing builds. A resident or story NPC
requires:

- an articulated silhouette with torso, separated limbs, hands, feet or boots,
  shoulders, and a shaped head;
- layered clothing such as coat tails, lapels, belts, cuffs, scarf, shawl, apron,
  hood, or hat rather than one torso block;
- a readable face at normal conversation distance: eyes plus at least nose and
  mouth or an intentional mask equivalent;
- hair or headwear shaped beyond one sphere;
- a role-specific carried or nearby prop;
- a distinct palette and silhouette that does not rely only on the nameplate;
- preserved stable interaction target, resident ID, routine pivots, and motion
  tags.

Enemies follow the same silhouette rule, with additional telegraph and hitbox
clarity. Cosmetic geometry must not alter authoritative combat bounds.

## Interaction, crafting, and reward standard

- Tools are displayed in racks, open supply crates, work areas, or character
  hands—not on naked slabs.
- Crafting stations show a real work surface, supports, supplies, and a physical
  sample of the recipe output.
- Rewards arrive in containers, bundles, pallets, satchels, or staged displays.
  The animation reinforces the physical object; a pulse alone is insufficient.
- Semantic anchors may be transparent and non-colliding, but their names,
  attributes, prompts, and server-authoritative action routes must remain stable.

## Mesh and asset workflow

1. Prefer original source assets in `assets/meshes/source/` and reproducible
   exports in `assets/meshes/export/`.
2. Record the intended Roblox size, measured native bounds, source revision, and
   asset ID in the mesh manifest. Never guess scale from a thumbnail.
3. Measure downloaded Roblox meshes with the repository tools. A parser refusal
   for a newer compressed format is an unknown measurement, not proof that the
   asset is restricted or empty.
4. Author hero assets around stable collision shells. Sanitize loaded models and
   remove scripts, prompts, constraints, sounds, body movers, post-processing,
   and unapproved descendants. Run downloaded Creator Store payloads through
   `lune run scripts/sanitize_creator_store_model <file.rbxm>` before commit;
   `MeshTemplateLoader` repeats the sanitization at runtime as defense in depth.
5. Keep material slots and triangle counts bounded. Use high detail only where
   players can inspect it.
6. Built-in Roblox materials already provide PBR response. Add custom
   `SurfaceAppearance` maps only when they match the mesh UVs and materially
   improve a hero asset.
7. API keys live only in the operator environment. Never commit, print, log, or
   embed credentials in source or generated places.

### Picking an asset

Start from [`assets/meshes/manifest.json`](../assets/meshes/manifest.json), the
machine-readable source of truth, not memory or a screenshot. Each entry's `id`
is the stable ID used everywhere else (registry, loader, logs, clone
attributes); its `robloxAssetId` is the numeric Roblox asset, present only after
Open Cloud finishes processing an upload. `placementBand` (`core`, `core_near`,
`core_near_town_edge`, `curated_core`, `curated_expedition`, `curated_enemy`,
`curated_hero`) is an advisory hint
for where in the world the asset was authored to live — nothing at runtime
enforces it, so respecting it is the placing agent's responsibility, not a
guardrail that will catch a mistake.

`retired_visual_failure` is not a location, it is a rejection. An entry carrying
that band (currently `mesh_wayfarer_cabin_a`) failed Studio review and must
never be placed as visible world dressing; its manifest and registry entries
exist only for provenance and measurement history. Check this field before
reusing any asset ID you have not personally placed before.

### Checking how an asset actually renders, before placing it

Reading the manifest or the generator script is not seeing the asset. Flat
shading, blown-out materials, and missing geometry are invisible in JSON and
Luau source; they only show up in a render. Before placing — or re-placing after
any generator change — an asset that already has a `robloxAssetId`, fetch its
real Roblox thumbnail and look at it. No API key is required:

```bash
curl -s "https://thumbnails.roblox.com/v1/assets?assetIds=<robloxAssetId>&size=420x420&format=Png"
```

The response looks like
`{"data":[{"targetId":...,"state":"Completed","imageUrl":"..."}]}`. Rendering is
asynchronous: `state: "Pending"` means the render is not ready and any
`imageUrl` returned with it is a placeholder, not the asset. Poll again after a
few seconds until `state` is `Completed`, then download `imageUrl` and actually
view the image — an agent with image-reading tool support can view it directly;
one without must hand the file to the operator. Do not report a visual fix as
verified from a 200 status code or a non-empty `imageUrl` alone: `state` has to
say `Completed`, and someone has to look at the pixels.

This renders one asset at a time, standalone, against a neutral backdrop. It
does not substitute for the Studio evidence required below for terrain,
lighting, multi-asset composition, or anything a player would see in place — it
only proves whether the mesh itself is shaped and shaded correctly before a
placement is spent on it.

**The thumbnail will look gray, and that is correct.** Roblox's model thumbnail
renderer falls back to gray SmoothPlastic; it does not apply the runtime
material and color that `MeshMaterialPlan.luau` assigns at placement time (pine
green, bark brown, slate, lantern amber, and so on). A gray render is therefore
evidence about *silhouette, topology, and shading only*. Do not read gray as a
missing texture, do not "fix" a mesh because its thumbnail is colorless, and do
not use this endpoint to judge palette — palette is a Studio question. What a
thumbnail can legitimately catch is faceted or flat-shaded geometry, wrong
proportions, missing pieces, and an unrecognizable silhouette.

There is no equivalent endpoint for scenes, terrain, or lighting.
`assets-thumbnail-3d` exists but returned `state: "Error"` for every Model-type
asset in this kit tested against it and cannot be relied on. There is no
headless Roblox Studio and no full-place cloud renderer reachable from an agent
session. Do not design a workflow around either existing.

### Placing an asset

Placement always goes through
`MeshTemplateLoader:place(stableId, parent, at, placementScale)`
(`src/server/World/MeshTemplateLoader.luau`), never a direct
`InsertService:LoadAsset` call at the placement site. `place` loads and
sanitizes the Roblox model once per server (stripping scripts, prompts,
constraints, and joints), normalizes it to the manifest's measured
`targetLongestDimension`, then clones, scales, pivots to `at`, and tags the
clone with `MeshAssetId` and `PlacementScale` attributes for later inspection. A
failed load returns `nil` and the call site must fall back to the existing
procedural builder for that spot — a load failure must never block joining or
leave a gap.

Before writing a new placement call: confirm the asset's `placementBand` fits
the location, confirm the band is not `retired_visual_failure`, and confirm
someone has actually looked at a `Completed` thumbnail for it since the last
generator or upload change that could have affected its shading or geometry.

## Performance and mobile gates

- Preserve streaming cells and a playable arrival area inside the bootstrap
  timeout.
- Prefer a few strong silhouettes over hundreds of tiny parts. Reuse templates
  and disable shadows on small decorative pieces.
- Test low and maximum graphics on phone, tablet, and desktop. Review camera
  obstruction, prompt reach, collision, navigation width, and enemy readability.
- Added detail must remain within the content definition part budgets. Raise a
  budget only with measured evidence and a documented reason.

## Required evidence before calling a visual pass complete

1. `npm test` passes, including format, lint, type, pure tests, generated-place
   builds, and place verification.
2. Studio integration assertions verify stable contracts and minimum physical
   construction for the changed content.
3. Fresh `build/LastLight.rbxlx` and `build/LastLightTest.rbxlx` artifacts come
   from the same validated source revision.
4. Studio screenshots show the changed content with labels both enabled and
   disabled, in day and night lighting where applicable.
5. Studio Output has no new runtime error and reports the expected build and
   world versions.
6. A device pass confirms phone navigation, camera clearance, interaction reach,
   and acceptable performance.

Repository validation proves the artifact was built correctly; it does not prove
that the published Roblox version or final appearance was inspected. Record those
as separate gates.
